import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:study_recorder/core/errors/failure.dart';
import 'package:study_recorder/core/errors/result.dart';
import 'package:study_recorder/data/player/player_model.dart';
import 'package:study_recorder/data/player/player_repository_interface.dart';

/// A player that plays nothing. It keeps the queue, index, playing flag and
/// position, so screens can be driven. Set [failure] to make calls return Err.
class FakePlayerRepository implements PlayerRepositoryInterface {
  Failure? failure;
  PlayerStateModel state = PlayerStateModel.idle;
  final List<String> calls = [];
  final _changes = StreamController<PlayerStateModel>.broadcast();

  /// Sets the state as if the player had moved on by itself.
  void emit(PlayerStateModel next) {
    state = next;
    _changes.add(next);
  }

  Result<void> _result(String call) {
    calls.add(call);
    if (failure != null) return Err(failure!);
    return const Ok(null);
  }

  @override
  Stream<Result<PlayerStateModel>> watchState() {
    return Stream.multi((controller) {
      controller.add(Ok(state));
      final sub = _changes.stream.listen((s) => controller.add(Ok(s)));
      controller.onCancel = () {
        sub.cancel();
      };
    });
  }

  @override
  Widget? buildVideo() => state.current?.type.name == 'video'
      ? const SizedBox(key: Key('fake-video'), height: 100)
      : null;

  @override
  Future<Result<void>> start(List<PlayerTrack> queue, int index) async {
    final result = _result('start');
    if (result is Err) return result;
    emit(
      PlayerStateModel(
        queue: queue,
        index: index,
        playing: true,
        repeatAll: state.repeatAll,
        positionMs: 0,
        durationMs: queue[index].durationMs,
      ),
    );
    return result;
  }

  @override
  Future<Result<void>> play() async {
    final result = _result('play');
    if (result is Ok) emit(state.copyWith(playing: true));
    return result;
  }

  @override
  Future<Result<void>> pause() async {
    final result = _result('pause');
    if (result is Ok) emit(state.copyWith(playing: false));
    return result;
  }

  @override
  Future<Result<void>> next() async {
    final result = _result('next');
    if (result is! Ok) return result;
    final last = state.queue.length - 1;
    if (state.index < last) {
      emit(state.copyWith(index: state.index + 1, positionMs: 0));
    } else if (state.repeatAll) {
      emit(state.copyWith(index: 0, positionMs: 0));
    }
    return result;
  }

  @override
  Future<Result<void>> previous() async {
    final result = _result('previous');
    if (result is! Ok) return result;
    if (state.positionMs > 3000 || state.index == 0) {
      emit(state.copyWith(positionMs: 0));
    } else {
      emit(state.copyWith(index: state.index - 1, positionMs: 0));
    }
    return result;
  }

  @override
  Future<Result<void>> skipTo(int index) async {
    final result = _result('skipTo');
    if (result is Ok && index >= 0 && index < state.queue.length) {
      emit(state.copyWith(index: index, positionMs: 0, playing: true));
    }
    return result;
  }

  @override
  Future<Result<void>> seekTo(int positionMs) async {
    final result = _result('seekTo');
    if (result is Ok) emit(state.copyWith(positionMs: positionMs));
    return result;
  }

  @override
  Future<Result<void>> setRepeatAll(bool repeatAll) async {
    final result = _result('setRepeatAll');
    if (result is Ok) emit(state.copyWith(repeatAll: repeatAll));
    return result;
  }

  @override
  Future<Result<void>> stop() async {
    final result = _result('stop');
    if (result is Ok) {
      emit(PlayerStateModel.idle.copyWith(repeatAll: state.repeatAll));
    }
    return result;
  }
}
