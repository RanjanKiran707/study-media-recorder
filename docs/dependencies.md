# Dependencies (pub.dev)

Packages needed by `project_specs/product_spec.md`. Result, ViewState, state management (`ValueNotifier`) and dependency wiring come from `flutter_arch_general.md`, so no package is added for them. Versions are resolved by `flutter pub add` at install time.

## Runtime

| Package | Purpose | Used in |
|---|---|---|
| `drift` + `drift_flutter` | Local SQLite database for folders and recordings. Its `watch` queries give the `Stream<Result<..>>` the architecture asks for, so lists update live. Foreign keys give cascade delete for "delete folder and everything inside". | `data/` only |
| `path_provider` | App-private directory where the recording files are stored. | `data/` only |
| `path` | Build and split file paths. | `data/` only |
| `camera` | Video recording with front and back camera, switching camera, pause and resume. | `data/` (recorder) |
| `record` | Audio-only recording from the microphone, with pause and resume. | `data/` (recorder) |
| `just_audio` | Playlist playback: next, previous, seek, repeat all, gapless advance. Plays the audio of audio recordings and keeps going with the screen off. | `data/` (player) |
| `just_audio_background` | Background playback with a notification and lock-screen controls, so night revision keeps playing. | `data/` (player), `main.dart` |
| `video_player` | Shows the picture while a video recording plays. | `features/` (player view) |
| `permission_handler` | Ask for camera, microphone and notification permission, and explain a refusal. | `data/` |
| `uuid` | Ids for folders and recordings. | ViewModels / use cases |
| `wakelock_plus` | Keep the screen on while recording. | `features/` (record view) |

## Dev

| Package | Purpose |
|---|---|
| `drift_dev` | Generates the database code. |
| `build_runner` | Runs the drift generator. |
| `mocktail` | Fakes for the ViewModel and use case unit tests. |
| `integration_test` (Flutter SDK) | Key journeys: record, save, play folder. |

## Points to decide

1. **Playback engine.** `just_audio` plays audio and handles background and notification well, but shows no picture. `video_player` shows video but has no background service. I propose using `just_audio` for audio recordings and `video_player` for video recordings, behind one `PlayerRepositoryInterface` so the rest of the app sees a single playlist. The alternative is `media_kit`, a single engine for both, but it is heavier and needs more Android set-up. Video recordings are not expected to keep their picture in the background.
2. **Database.** `drift` is proposed for the live streams. The alternative is `sqflite`, which is smaller but has no watch queries, so the repositories would have to build the streams by hand.

## Deliberately not added

State management (`ValueNotifier` is enough), dependency injection (hand-written in `AppDependencies`), navigation (`Navigator.push`), cloud, sharing and analytics packages (out of scope).
