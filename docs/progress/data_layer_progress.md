# Data layer progress

Status: Done (waiting for user review)
Last updated: 2026-10-11

## Checklist
| Item | Code | Tests |
|---|---|---|
| core: `Failure`, `Result` | [x] | [x] |
| database (`AppDatabase`, tables `folder` and `recording`) | [x] | [x] (through the repository tests) |
| result stream helper (`toResultStream`) | [x] | [x] |
| Folder: model, interface, `FolderRepository` | [x] | [x] |
| Recording: model, interface, `RecordingRepository` | [x] | [x] |

## Test status
Passing, 32 tests (31 for the data layer and core, plus the default `widget_test.dart` from `flutter create`, which is replaced in the Features phase), 2026-10-11

## Change log
Newest first.

| Date | Change | Why |
|---|---|---|
| 2026-10-11 | Tests moved into `test/data/folder/`, `test/data/recording/`, `test/data/database/` and `test/core/errors/` | `flutter_development_process.md` says tests mirror `lib/` |
| 2026-10-11 | `toResultStream` rewritten without `async*` | The first version kept the database query running after the subscription was cancelled, which would leak when a ViewModel is disposed. A test now checks that cancelling cancels the source |
| 2026-10-11 | `moveRecording` clears `sort_index` | A moved recording is a new item in the other folder, so it must not keep a position from the old folder. It is placed by created time, which may not be the end of the list |
| 2026-10-11 | `Result.map` and `Result.flatMap` added | Used by the live-data use case in `flutter_arch_general.md` |
| 2026-10-11 | Phase started | Data model approved by the user |

## Open issues / decisions
- Rearranging saves folders and recordings through two `updateSortOrder` calls (one per repository). Each call is atomic, but the pair is not. The worst case is a half-saved order that can be rearranged again. The use case phase can revisit this.
- A moved recording is placed by created time, not at the end of the new folder. Ask the user if that should change.
