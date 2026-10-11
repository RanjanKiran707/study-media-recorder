# Use cases progress

Status: Done (approved by the user, 2026-10-11). Later additions are in the change log
Last updated: 2026-10-11

## Checklist
| Item | Code | Tests |
|---|---|---|
| core: `combineLatest2` | [x] | [x] |
| Business: `CreateFolderUsecase` | [x] | [x] |
| Business: `RenameFolderUsecase` | [x] | [x] |
| Business: `DeleteFolderUsecase` | [x] | [x] |
| Business: `SaveRecordingUsecase` | [x] | [x] |
| Business: `RenameRecordingUsecase` | [x] | [x] |
| Business: `MoveRecordingUsecase` | [x] | [x] |
| Business: `DeleteRecordingUsecase` | [x] | [x] |
| Business: `SaveOrderUsecase` | [x] | [x] |
| UI: `ListFolderItemsUsecase` (Home and Folder lists) | [x] | [x] |
| UI: `ListSubfoldersUsecase` (Move to picker) | [x] | [x] |
| UI: `GetFolderPathUsecase` (breadcrumb) | [x] | [x] |
| UI: `GetPlaylistUsecase` (queue of a folder) | [x] | [x] |
| UI: `GetPlayableRecordingUsecase` (play one recording) | [x] | [x] |
| `AppDependencies` wiring (`init`, `fromRepositories`) | [x] | [ ] (`init` needs the device; `fromRepositories` is used by the Features tests) |

## Test status
Passing, 254 tests (whole suite), 2026-10-11

## Change log
Newest first.

| Date | Change | Why |
|---|---|---|
| 2026-10-11 | `PlayFolderUsecase` removed. `PlayRecordingUsecase` builds the playlist of the recording's folder and starts at the tapped one. `PlayableItem` has `folderId` | There is no Play folder button, tapping a recording queues the folder |
| 2026-10-11 | Added (Features phase): business use cases `PrepareRecorder`, `StartRecording`, `PauseRecording`, `ResumeRecording`, `StopRecording`, `SwitchCamera`, `DiscardTake`, `ReleaseRecorder`, `PlayPlayer`, `PausePlayer`, `NextTrack`, `PreviousTrack`, `SeekPlayer`, `SetRepeatAll`, `SkipToTrack`, `StopPlayback`, `PlayRecording`. UI use cases `GetRecorderPreview`, `GetRecordingElapsed`, `GetPlayerVideo`, `WatchPlayer` (with the queue, `hasNext`, `progress`). `AppDependencies.fromRepositories` takes the recorder and the player too | The recorder and player device layers proposed under open issues, needed by the Record and Player features |
| 2026-10-11 | `ListSubfoldersReturnModel` has `recordingCounts` | The Move to picker shows the recursive recording count |
| 2026-10-11 | Phase started. Use cases, fakes (`test/domain/fakes/`) and wiring added | Data phase approved by the user |
| 2026-10-11 | `combineLatest2` added in `core/utils` instead of a package such as rxdart | The folder list joins three streams (folders, recordings, counts). The architecture guide asks for no extra packages. It is not an `async*` function, so cancelling it cancels the sources |
| 2026-10-11 | `AppDependencies.fromRepositories` factory added | `init` needs plugins (database, path provider), so tests and the Features phase build the real use cases on fake repositories |

## Rules decided in this phase
- Names are trimmed. A blank folder name or recording title gives `ValidationFailure('name_required')` or `'title_required'`.
- Failure messages are keys for the ViewModel to translate: `name_required`, `title_required`, `duration_invalid`, `folder_not_found`, `recording_not_found`, `same_folder`, `duplicate_items`.
- `createdAt` is set by the use case from an injectable clock, so tests are exact.
- The ViewModel creates the ids (as in the architecture guide), and passes them in.
- `SaveOrderUsecase` gets the list in the order shown, folders and recordings together, and writes positions 0..n-1.
- The moved-recording rule stays in the Data layer: it loses its position and sorts by created time.

## Open issues / decisions
- Resolved in the Features phase (see the change log): the recorder and player interfaces and use cases were added. Original note: **Recording and playback devices were not built yet.** Recording (`camera`, `record`) and playback (`just_audio`, `video_player`) talk to the device, and are not covered by this phase's use cases. They need their own interfaces in `data/` (for example a recorder and a player repository), and use cases such as start, pause and stop recording, and the player controls. Proposal: add them at the start of the Features phase, just before the Record and Player features, and log the additions here and in the data layer progress file. Please confirm.
- `AppDependencies.init()` is now called from `main.dart` (Folder feature, see `features_progress.md`).
