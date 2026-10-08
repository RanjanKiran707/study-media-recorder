# Flutter Initial Setup

Run these steps once, after reviewing the product spec provided by the user and before any app code is written. Afterwards the user will ask you to build the app based on `flutter_arch_general.md`.

Ask the user for anything missing: the product spec, the app name (snake_case), and the git `origin` URL.

1. **Initialize git and push to origin**
   - `git init -b main`, add the `origin` remote, commit, and `git push -u origin main`.
   - If the push fails, report the error and ask the user. Never force-push.

2. **Analyse the dependencies**
   - List every third-party Flutter package (pub.dev) the product spec needs, such as storage, networking, UI, device features and dev tools.
   - Do not add packages for what `flutter_arch_general.md` already provides: Result, ViewState, state management and dependency wiring.
   - Save the list to `docs/dependencies.md`, with each package's purpose, and get the user's approval before installing.

3. **Create the data modelling for the data layer**
   - Identify the entities, fields, primary and foreign keys, and relationships from the spec.
   - Create an ER diagram in Mermaid (`erDiagram`) and save it to `docs/data_model.md`.
   - Get the user's approval of the model.

4. **Run `flutter create`**
   - `flutter create . --project-name <app_name>` inside the repository.
   - Add the approved packages with `flutter pub add`, then run `flutter analyze`.
   - Commit and push.
   - Do not write any `lib/` code yet.
