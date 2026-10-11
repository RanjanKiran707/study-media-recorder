# Features progress

Status: In progress
Last updated: 2026-10-11

## Checklist
Order agreed: Folder (with Home), Record and Save, Move to, Player.

| Feature | Code | ViewModel tests | Checked on a device |
|---|---|---|---|
| Folder and Home (list, create, rename, delete, rearrange) | [x] | [x] | [ ] |
| Recording device layer (recorder interface, use cases) | [ ] | [ ] | n/a |
| Record and Save | [ ] | [ ] | [ ] |
| Move to (folder picker) | [ ] | [ ] | [ ] |
| Player device layer (player interface, use cases) | [ ] | [ ] | n/a |
| Player, mini player and Play folder | [ ] | [ ] | [ ] |
| Recording tile: Move and tap to play | [ ] | [ ] | [ ] |

## Test status
Passing, 112 tests (whole suite), 2026-10-11. `flutter analyze` is clean.

## Change log
Newest first.

| Date | Change | Why |
|---|---|---|
| 2026-10-11 | Folder feature added: `FolderView`, `FolderViewModel`, name and delete dialogs. `main.dart` now calls `AppDependencies.init()` and opens it | First feature. The default counter app and `test/widget_test.dart` were removed (no widget tests for now) |
| 2026-10-11 | Home and Folder are one feature, `FolderBundle(folderId: null)` is Home | They differ only in the title, no Rearrange, and no Record here or Play folder. Two copies of the same list, menus and dialogs would drift apart |
| 2026-10-11 | Helpers added in `core/utils`: `generateId`, `messageFor` (failure key to text), `format` (duration, date, counts) | Shared by all features |
| 2026-10-11 | Phase started | Use cases phase approved by the user (they asked to start the Features phase) |

## Decisions in this phase
- Rearrange mode keeps its own copy of the list, so live changes do not move rows under the user's finger. Back cancels it (spec section 6). Home cannot be rearranged (out of scope).
- One `actionState` per screen covers create, rename, delete and save order, so the blocking rule has one place. Errors show as a snackbar, then go back to Idle.
- Folder tile ⋮ menu on Home has Rename and Delete too (the spec puts them on the folder's own tile).

## Open issues / decisions
- **Not yet run on a device or emulator.** The Folder feature is only checked by analysis and ViewModel tests. Needs a run on the phone.
- Folder screen has no **Record here**, **Play folder**, recording **Move** or tap-to-play yet. They are added with their features (last row of the checklist).
- Recorder and player device layers: proceeding as proposed in `use_cases_progress.md` (interfaces and use cases added just before their features, logged in the progress files). The user started this phase without objecting.
