# Study Recorder

An Android app that records short (about two minute) audio or video explanations,
keeps them in folders and subfolders, and plays a folder as a playlist for
revision. One user, offline, no login.

- Product spec and UI mockup: `project_specs/`
- Architecture and process: `project_specs/flutter_arch_general.md`, `project_specs/flutter_development_process.md`
- Progress and decisions: `docs/progress/`
- Dependencies and why: `docs/dependencies.md`

## Run

```
flutter pub get
flutter run                      # on a connected Android phone
flutter test                     # unit and widget tests
flutter test integration_test -d <device>
```

The app is portrait only. The launcher icon is the record button (white ring, red
dot) on a dark tile; its source layers are in `android/app/src/main/res/mipmap-*`.
