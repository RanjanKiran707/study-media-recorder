import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:study_recorder/core/errors/failure.dart';
import 'package:study_recorder/core/errors/result.dart';
import 'package:study_recorder/data/player/player_model.dart';
import 'package:study_recorder/data/player/player_repository_interface.dart';
import 'package:study_recorder/data/recording/recording_model.dart';
import 'package:video_player/video_player.dart';

/// Plays a queue one track after another. Only one engine is active at a
/// time: `just_audio` for audio tracks and `video_player` for video tracks.
/// Needs a device, so it is covered by the fake in tests and checked by
/// running the app. `JustAudioBackground.init` must run in `main` first.
class PlayerRepository implements PlayerRepositoryInterface {
  /// "Previous" restarts the track when it is further along than this.
  static const _restartAfterMs = 3000;

  AudioPlayer? _audioPlayer;
  VideoPlayerController? _video;
  PlayerStateModel _state = PlayerStateModel.idle;
  final _changes = StreamController<PlayerStateModel>.broadcast();

  /// Increases on every load or stop, so events of an old track are ignored.
  int _generation = 0;
  bool _completionHandled = false;

  AudioPlayer get _audio {
    final existing = _audioPlayer;
    if (existing != null) return existing;
    final player = AudioPlayer();
    player.positionStream.listen((position) {
      if (_isAudio && _state.isActive) {
        _emit(_state.copyWith(positionMs: position.inMilliseconds));
      }
    });
    player.playerStateStream.listen((state) {
      if (_isAudio &&
          state.processingState == ProcessingState.completed &&
          !_completionHandled) {
        _completionHandled = true;
        _onCompleted();
      }
    });
    return _audioPlayer = player;
  }

  bool get _isAudio => _state.current?.type == RecordingType.audio;

  void _emit(PlayerStateModel state) {
    _state = state;
    _changes.add(state);
  }

  @override
  Stream<Result<PlayerStateModel>> watchState() {
    return Stream.multi((controller) {
      controller.add(Ok(_state));
      final sub = _changes.stream.listen((s) => controller.add(Ok(s)));
      controller.onCancel = () {
        sub.cancel();
      };
    });
  }

  @override
  Widget? buildVideo() {
    final video = _video;
    if (_state.current?.type != RecordingType.video ||
        video == null ||
        !video.value.isInitialized) {
      return null;
    }
    return AspectRatio(
      aspectRatio: video.value.aspectRatio,
      child: VideoPlayer(video),
    );
  }

  @override
  Future<Result<void>> start(List<PlayerTrack> queue, int index) async {
    if (queue.isEmpty || index < 0 || index >= queue.length) {
      return const Err(ValidationFailure('playlist_empty'));
    }
    _emit(
      PlayerStateModel(
        queue: queue,
        index: index,
        playing: true,
        repeatAll: _state.repeatAll,
        positionMs: 0,
        durationMs: queue[index].durationMs,
      ),
    );
    return _load(index);
  }

  /// Loads and plays the track at [index].
  Future<Result<void>> _load(int index) async {
    final generation = ++_generation;
    _completionHandled = false;
    try {
      final track = _state.queue[index];
      await _releaseVideo();
      await _audioPlayer?.stop();
      _emit(
        _state.copyWith(
          index: index,
          playing: true,
          positionMs: 0,
          durationMs: track.durationMs,
        ),
      );

      if (track.type == RecordingType.audio) {
        final duration = await _audio.setAudioSource(
          AudioSource.file(
            track.filePath,
            tag: MediaItem(
              id: track.recordingId,
              title: track.title,
              album: track.folderName,
            ),
          ),
        );
        if (generation != _generation) return const Ok(null);
        if (duration != null) {
          _emit(_state.copyWith(durationMs: duration.inMilliseconds));
        }
        // play() completes only when playback ends, so it is not awaited.
        unawaited(_audio.play());
      } else {
        final video = VideoPlayerController.file(File(track.filePath));
        await video.initialize();
        if (generation != _generation) {
          await video.dispose();
          return const Ok(null);
        }
        _video = video;
        video.addListener(() => _onVideoTick(video, generation));
        _emit(_state.copyWith(durationMs: video.value.duration.inMilliseconds));
        await video.play();
      }
      return const Ok(null);
    } catch (e) {
      if (generation == _generation) _emit(_state.copyWith(playing: false));
      return Err(UnexpectedFailure(e.toString()));
    }
  }

  void _onVideoTick(VideoPlayerController video, int generation) {
    if (generation != _generation || !_state.isActive) return;
    final value = video.value;
    final duration = value.duration.inMilliseconds;
    final position = value.position.inMilliseconds;
    if (duration > 0 && position >= duration && !_completionHandled) {
      _completionHandled = true;
      _onCompleted();
      return;
    }
    if (position != _state.positionMs || value.isPlaying != _state.playing) {
      // While buffering, isPlaying can be false for a moment. Keep what the
      // user asked for, unless playback really stopped at the end.
      _emit(_state.copyWith(positionMs: position));
    }
  }

  Future<void> _onCompleted() async {
    final last = _state.queue.length - 1;
    if (_state.index < last) {
      await _load(_state.index + 1);
    } else if (_state.repeatAll) {
      await _load(0);
    } else {
      await _pauseEngines();
      _emit(_state.copyWith(playing: false, positionMs: _state.durationMs));
    }
  }

  Future<void> _pauseEngines() async {
    if (_isAudio) {
      await _audioPlayer?.pause();
    } else {
      await _video?.pause();
    }
  }

  Future<void> _releaseVideo() async {
    final video = _video;
    _video = null;
    await video?.dispose();
  }

  Future<Result<void>> _guard(Future<void> Function() action) async {
    try {
      await action();
      return const Ok(null);
    } catch (e) {
      return Err(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> play() {
    if (!_state.isActive) return Future.value(const Ok(null));
    return _guard(() async {
      final atEnd =
          _state.durationMs > 0 && _state.positionMs >= _state.durationMs;
      if (atEnd) {
        // Finished the last track earlier: start over.
        _completionHandled = false;
        await _seek(0);
      }
      _emit(_state.copyWith(playing: true));
      if (_isAudio) {
        unawaited(_audio.play());
      } else {
        await _video?.play();
      }
    });
  }

  @override
  Future<Result<void>> pause() {
    if (!_state.isActive) return Future.value(const Ok(null));
    return _guard(() async {
      _emit(_state.copyWith(playing: false));
      await _pauseEngines();
    });
  }

  @override
  Future<Result<void>> next() {
    if (!_state.isActive) return Future.value(const Ok(null));
    return _guard(() async {
      final last = _state.queue.length - 1;
      if (_state.index < last) {
        await _load(_state.index + 1);
      } else if (_state.repeatAll) {
        await _load(0);
      }
    });
  }

  @override
  Future<Result<void>> previous() {
    if (!_state.isActive) return Future.value(const Ok(null));
    return _guard(() async {
      if (_state.positionMs > _restartAfterMs || _state.index == 0) {
        await _seek(0);
      } else {
        await _load(_state.index - 1);
      }
    });
  }

  @override
  Future<Result<void>> skipTo(int index) {
    if (!_state.isActive || index < 0 || index >= _state.queue.length) {
      return Future.value(const Ok(null));
    }
    return _guard(() async {
      await _load(index);
    });
  }

  @override
  Future<Result<void>> seekTo(int positionMs) {
    if (!_state.isActive) return Future.value(const Ok(null));
    return _guard(() => _seek(positionMs));
  }

  Future<void> _seek(int positionMs) async {
    final target = Duration(milliseconds: positionMs);
    if (_isAudio) {
      await _audio.seek(target);
    } else {
      await _video?.seekTo(target);
    }
    _emit(_state.copyWith(positionMs: positionMs));
  }

  @override
  Future<Result<void>> setRepeatAll(bool repeatAll) async {
    _emit(_state.copyWith(repeatAll: repeatAll));
    return const Ok(null);
  }

  @override
  Future<Result<void>> stop() {
    return _guard(() async {
      _generation++;
      _emit(PlayerStateModel.idle.copyWith(repeatAll: _state.repeatAll));
      await _releaseVideo();
      await _audioPlayer?.stop();
    });
  }
}
