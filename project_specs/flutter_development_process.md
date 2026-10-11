# Flutter Development Process

How the app is built after `flutter_initial_setup.md` is finished. The structure, naming and rules of the code come from `flutter_arch_general.md`. This file says in what order the work is done, when a phase is finished, and how progress is recorded.

There are three phases: **Data**, **Use cases** and **Features**.

---

## 1. Rules for all phases

1. Phases run in order. A phase starts only when the one before it is done.
2. A phase is **done** when all of these are true:
   - all its code is written;
   - `flutter analyze` reports no issues;
   - **all tests pass**, including the tests of earlier phases;
   - its progress file is up to date.
3. **Review pause.** At the end of a phase, summarise it for the user (what was built, test count, decisions). The next phase starts only after the user approves.
4. Tests are in `test/` and mirror `lib/`. For example, `lib/data/folder/folder_repository.dart` is tested in `test/data/folder/folder_repository_test.dart`. Shared test helpers sit next to the tests that use them.
5. Fakes implement the interfaces of the layer below. Use `mocktail` only where a hand-written fake would be longer.
6. Commit at the end of each phase, and after each big step inside it. Push each time. Never force-push.
7. The progress file is updated in the same commit as the code it describes.
8. A bug found later gets a failing test first, then the fix, then a row in the change log.

---

## 2. Phase 1: Data

- **Build:** models, repository interfaces, repository implementations and the database, from `docs/data_model.md`. Also the `core/` files the data layer needs (`Failure`, `Result`).
- **Tests:** every repository, against an in-memory database. Check the normal behaviour, ordering, live streams, and that every failure becomes an `Err` and is never thrown. Models are tested only if they have conversion logic.
- **Done when:** every repository method has a test and the whole suite passes.
- **Progress file:** `docs/progress/data_layer_progress.md`

## 3. Phase 2: Use cases

- **Build:** `domain/use_cases/business/` (actions that write and validate) and `domain/use_cases/ui/` (read-only, shape data for one screen), with Argument and Return models where needed. Create them in `AppDependencies.init()`.
- **Tests:** every use case, with fake repositories.
  - Business: valid input gives `Ok` and calls the repository correctly. Each rule gives the right `Err`.
  - UI: a new list from the repository gives a new Return Model, and an `Err` from the repository is passed on.
- **Done when:** every use case has a test and the whole suite passes.
- **Progress file:** `docs/progress/use_cases_progress.md`

## 4. Phase 3: Features

- **Build:** one feature at a time (View and ViewModel), using the checklist in section 10 of `flutter_arch_general.md`. The order of the features comes from the product spec, and is agreed with the user before the phase starts.
- **Tests:** **ViewModel unit tests only**, with fake use cases. Check the `Idle -> Loading -> Loaded/Error` sequence, that a second call during `Loading` is ignored, and that stream subscriptions are cancelled in `dispose()`. There are **no widget tests and no integration tests for now**. The View is checked by running the app.
- **Done when (per feature):** the ViewModel tests pass, the whole suite passes, and the feature works in the app on a device or emulator.
- **Progress file:** `docs/progress/features_progress.md`, with one section per feature.

---

## 5. Changes to an earlier phase

If a later phase needs a change in an earlier layer:
1. Make the change in that layer.
2. Add a row to that phase's change log, with the reason.
3. Rerun the tests of that phase, and then the whole suite.
4. Update `docs/data_model.md` too if the model changed.
5. Then continue with the later phase.

---

## 6. Progress file format

Create the file when the phase starts. Use this template:

```markdown
# <Phase name> progress

Status: Not started | In progress | Done
Last updated: YYYY-MM-DD

## Checklist
| Item | Code | Tests |
|---|---|---|
| <entity / use case / feature> | [ ] | [ ] |

## Test status
<Passing | Failing>, <N> tests, YYYY-MM-DD

## Change log
Newest first.

| Date | Change | Why |
|---|---|---|
| YYYY-MM-DD | Phase started | |

## Open issues / decisions
- <anything postponed or waiting for the user>
```

Rules:
- Tick Code and Tests separately.
- Every change to code that was already finished (a changed method, a renamed field, a design change) gets a row in the change log, with the reason.
- Update the test count and date each time the suite is run for a commit.

---

## 7. Later additions

An optional Phase 4 (widget tests and integration tests for key journeys) can be added when the user asks for it. It is left out for now.
