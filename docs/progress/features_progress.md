# Features progress

Status: Code complete, waiting for the user's check on a device
Last updated: 2026-10-11

## Checklist
Order agreed: Folder (with Home), Record and Save, Move to, Player.

| Feature | Code | ViewModel tests | Widget tests | Checked on a device |
|---|---|---|---|---|
| UI kit without Material (`core/widgets/`) | [x] | n/a | [x] (guard test) | [ ] |
| Folder and Home (list, create, rename, delete, rearrange, tap to play) | [x] | [x] | [x] | [ ] |
| Recorder device layer (interface, `RecorderRepository`, use cases) | [x] | [x] (use cases, fake) | n/a | [ ] |
| Record and Save | [x] | [x] | [x] | [ ] |
| Move to (folder picker) | [x] | [x] | [x] | [ ] |
| Player device layer (interface, `PlayerRepository`, use cases) | [x] | [x] (use cases, fake) | n/a | [ ] |
| Player and mini player | [x] | [x] | [x] | [ ] |
| Recording tile: Rename, Move to folder, Delete | [x] | [x] | [x] | [ ] |
| Integration tests (`integration_test/app_test.dart`, 6 journeys) | [x] | n/a | n/a | [ ] (needs a device) |

## Test status
Passing, 254 tests (whole suite), 2026-10-11. `flutter analyze` is clean. `flutter build apk --debug` works.
The integration journeys are not part of that count. Only the first one was run (on the host, as a copy of the file). The other five have not been run anywhere.

## Change log
Newest first.

| Date | Change | Why |
|---|---|---|
| 2026-10-11 | App is portrait only (`screenOrientation` in the manifest and `SystemChrome` in `main.dart`) | User request |
| 2026-10-11 | New launcher icon (record button: white ring, red dot, dark tile; adaptive and themed layers) and app name "Study Recorder" in the manifest, the app title, `pubspec.yaml` and `README.md` | User request |
| 2026-10-11 | Play folder button removed. `PlayFolderUsecase` deleted. Tapping a recording plays it with the whole folder as the queue (`PlayRecordingUsecase` now builds the playlist, `PlayableItem.folderId` added) | User request: the queue should always be the folder |
| 2026-10-11 | Record and Player screens redesigned: full-screen camera or video, controls shown on tap, hidden 3 s after a video take or play starts. Audio keeps its controls. Done is a ✓. Up next is a sheet. Added `ChromeController`, `AppChromeBar`, `AppPillTabs` and slider colours | User request, from the mockup |
| 2026-10-11 | Camera preview fills the viewfinder, and switching cameras closes the old one before opening the next | Preview was small, and the front camera did not open (two cameras were open at once) |
| 2026-10-11 | Rearranging drags from the whole row, not only the handle | User request |
| 2026-10-11 | UI rebuilt without any Material widget (`WidgetsApp`, `CupertinoIcons` only) after the mockup. `no_material_test` guards this | User request ("do not use any material widgets at all", "use mockup.html") |
| 2026-10-11 | Widget tests and integration tests added to the Features phase (also in `flutter_development_process.md`) | User request |
| 2026-10-11 | `permission_handler` removed. The camera and record packages ask for the permissions, and a refusal shows "Permission was denied" with Try again | `permission_handler_android` 14.1.0 failed to compile |
| 2026-10-11 | Record, Save, Move to, Player and mini player features added, with the recorder and player device layers | The Features phase |
| 2026-10-11 | Folder feature added: `FolderView`, `FolderViewModel`. `main.dart` calls `AppDependencies.init()` | First feature |
| 2026-10-11 | Home and Folder are one feature, `FolderBundle(folderId: null)` is Home | They differ only in the title, no Rearrange, and no Record here. Two copies would drift apart |
| 2026-10-11 | Helpers added in `core/utils`: `generateId`, `messageFor`, `format`, `ChromeController` | Shared by all features |
| 2026-10-11 | Phase started | Use cases phase approved by the user |

## Decisions in this phase
- Rearrange mode keeps its own copy of the list, so live changes do not move rows under the user's finger. Back cancels it. Home cannot be rearranged.
- One `actionState` per screen covers create, rename, delete and save order, so the blocking rule has one place. Errors show as a toast, then go back to Idle.
- Record opens Save on top of itself. Save closes both and returns the message ("Saved to X", "Recording discarded") to the folder screen.
- Recordings delete without a confirmation (as in the mockup). Folders ask "Delete this folder?".
- The player shows the folder name, not the full path.
- Hardware (camera, microphone, audio, video) is behind repository interfaces, so every test uses a fake.
- Notification skip buttons for background audio are not wired.
- The default test runner needs no device. The integration tests do, so they were checked only on the host for the first journey.

## Open issues / decisions
- **Nothing has been run on a phone or emulator by me.** The user has run the app and reported problems (preview size, front camera, mirrored front-camera playback), which were fixed or reverted. The recorder and player repositories (camera, audio, video) are covered only by compile checks and the user's runs.
- Front-camera videos play back mirrored compared with the preview (the preview is a mirror, the file is not). A flip of the preview was tried and reverted at the user's request. Open.
- Background audio with the screen off and the notification are unverified.
- The other five integration journeys have not been run. Run `flutter test integration_test -d <device>`.
- The Android package id is still `com.example.study_recorder`. Change it before any release.
