# Flutter Architecture — General Guide (Class / Student example)

A simple, project-neutral reference for starting any new Flutter app. It uses a small school app, with two tables (**Class** and **Student**), to show every rule once.

The Class/Student names are only an example. Replace them with your own entities, use cases and features.

Layers: **core**, **data**, **domain**, **features**.

---

## 1. Principles

1. Keep it simple. Add an abstraction only when it solves a real problem.
2. Dependencies point one way: `features -> domain -> data`. Data imports nothing from Domain or Features. Domain imports nothing from Features.
3. **Every future is a `ViewState`**, and **the user is blocked while a future is running**.
4. **Every operation that can fail returns `Result<T>`** (`Result` is defined in `core/errors/result.dart`).
5. No third-party package is required by this architecture. Wiring is written by hand (section 4.4). The storage package (database, API client) is chosen per project and is used only inside `data/`.

---

## 2. Folder Structure

```
lib/
├── core/
│   ├── di/            app_dependencies.dart
│   ├── errors/        failure.dart, result.dart
│   ├── utils/         view_state.dart
│   └── widgets/       obx_value.dart
│
├── data/
│   ├── class/
│   │   ├── class_model.dart
│   │   ├── class_repository_interface.dart
│   │   └── class_repository.dart
│   └── student/
│       ├── student_model.dart
│       ├── student_repository_interface.dart
│       └── student_repository.dart
│
├── domain/
│   └── use_cases/
│       ├── add_student/
│       │   ├── add_student_argument_model.dart
│       │   └── add_student_usecase.dart
│       ├── list_students/
│       │   ├── list_students_return_model.dart
│       │   └── list_students_usecase.dart
│       └── update_student_class/
│           └── update_student_class_usecase.dart
│
└── features/
    ├── add_student/    add_student_view.dart, add_student_view_model.dart
    └── student_list/   student_list_view.dart, student_list_view_model.dart
```

| Layer | Answers | Organised by |
|---|---|---|
| core | What is shared by the whole app? | kind of utility |
| data | Which entities exist, and how are they stored and read? | table / entity |
| domain | What can the app do? | use case |
| features | What does the user see? | one View = one feature |

The folder counts grow with the app. The responsibilities of each layer stay the same.

---

## 3. Result type

No package is needed. The app defines its own sealed `Result<T>` in `core/errors/result.dart`:

```dart
import 'package:<app_name>/core/errors/failure.dart';

sealed class Result<T> {
  const Result();

  R fold<R>(R Function(Failure) onFailure, R Function(T) onSuccess) =>
      switch (this) {
        Ok<T>(:final value) => onSuccess(value),
        Err<T>(:final failure) => onFailure(failure),
      };
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.failure);
  final Failure failure;
}
```

- `Ok(value)` is success. `Err(failure)` is failure.
- An action with no data returns `Result<void>`, and succeeds with `const Ok(null)`.
- Read a result with `fold`, or with an exhaustive `switch`:

```dart
switch (result) {
  case Ok(:final value): ...
  case Err(:final failure): ...
}
```

---

## 4. Core

### 4.1 Failure — `core/errors/failure.dart`

```dart
sealed class Failure {
  final String message;
  const Failure(this.message);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class StorageFailure extends Failure {
  const StorageFailure(super.message);
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure(super.message);
}
```

Rules:
- Add a new `Failure` subclass only when a caller handles it differently.
- `message` is for developers/logs. Text shown to the user is chosen by the ViewModel/View from the Failure type (for example from localisation files).
- Expected failures are returned as `Err`. Unexpected exceptions are caught in the **repository implementation** and turned into `Err(StorageFailure(...))` or `Err(UnexpectedFailure(...))`. Use cases, ViewModels and Views never use `try/catch` for flow control.

### 4.2 ViewState — `core/utils/view_state.dart`

```dart
import 'package:flutter/widgets.dart';
import 'package:<app_name>/core/errors/failure.dart';

/// State of any asynchronous operation or data load.
sealed class ViewState<T> {
  const ViewState();
}

/// Nothing has been started yet (an action that waits for the user).
class ViewStateIdle<T> extends ViewState<T> {
  const ViewStateIdle();
}

class ViewStateLoading<T> extends ViewState<T> {
  const ViewStateLoading();
}

class ViewStateLoaded<T> extends ViewState<T> {
  final T data;
  const ViewStateLoaded(this.data);
}

class ViewStateError<T> extends ViewState<T> {
  final Failure failure;
  const ViewStateError(this.failure);
}

extension ViewStateExtension<T> on ViewState<T> {
  bool get isLoading => this is ViewStateLoading<T>;

  Widget when({
    Widget Function()? idle,
    required Widget Function() loading,
    required Widget Function(Failure failure) error,
    required Widget Function(T data) loaded,
  }) {
    return switch (this) {
      ViewStateIdle() => idle?.call() ?? const SizedBox.shrink(),
      ViewStateLoading() => loading(),
      ViewStateError(failure: final f) => error(f),
      ViewStateLoaded(data: final d) => loaded(d),
    };
  }
}
```

Which states each kind of future uses:

| Kind | Example | States used | Initial value |
|---|---|---|---|
| Data load / stream | student list | Loading, Loaded, Error | `Loading` |
| User action | add student | Idle, Loading, Loaded, Error | `Idle` |

An action uses `ViewState<void>` (or the returned model), and `Loaded` means "done".

### 4.3 Widgets — `core/widgets/obx_value.dart`

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Rebuilds when one ValueNotifier changes.
class ObxValue<T> extends StatelessWidget {
  final ValueListenable<T> listenable;
  final Widget Function(T value) builder;

  const ObxValue({super.key, required this.listenable, required this.builder});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<T>(
        valueListenable: listenable,
        builder: (context, value, child) => builder(value),
      );
}

/// Rebuilds when any of several notifiers change.
class ObxMulti extends StatelessWidget {
  final List<Listenable> listenables;
  final Widget Function() builder;

  const ObxMulti({super.key, required this.listenables, required this.builder});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: Listenable.merge(listenables),
        builder: (context, child) => builder(),
      );
}
```

### 4.4 Dependencies without a package — `core/di/app_dependencies.dart`

Everything global is built once, at startup, in one place. Nothing else creates repositories or use cases.

```dart
class AppDependencies {
  // Set once in main() before runApp. Tests can replace it.
  static late AppDependencies instance;

  final AddStudentUsecase addStudent;
  final ListStudentsUsecase listStudents;
  final UpdateStudentClassUsecase updateStudentClass;

  AppDependencies._({
    required this.addStudent,
    required this.listStudents,
    required this.updateStudentClass,
  });

  static Future<void> init() async {
    // 1. Data layer (the only place that knows the real implementations).
    final ClassRepositoryInterface classRepository = ClassRepository(/* db */);
    final StudentRepositoryInterface studentRepository = StudentRepository(/* db */);

    // 2. Domain layer.
    instance = AppDependencies._(
      addStudent: AddStudentUsecase(studentRepository),
      listStudents: ListStudentsUsecase(studentRepository, classRepository),
      updateStudentClass: UpdateStudentClassUsecase(studentRepository),
    );
  }
}
```

`main.dart`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppDependencies.init();
  runApp(const MyApp());
}
```

---

## 5. Data

Organised per table/entity. Each folder has three files:
- `x_model.dart` — the model of the table/entity.
- `x_repository_interface.dart` — what can be done with the entity.
- `x_repository.dart` — the implementation, which talks to the storage.

### 5.1 Models

`data/class/class_model.dart`

```dart
class ClassModel {
  final String id;
  final int classNumber;
  final String section;

  const ClassModel({
    required this.id,
    required this.classNumber,
    required this.section,
  });
}
```

`data/student/student_model.dart`

```dart
class StudentModel {
  final String id;
  final String name;
  final int age;
  final String classId; // foreign key -> ClassModel.id

  const StudentModel({
    required this.id,
    required this.name,
    required this.age,
    required this.classId,
  });
}
```

Relationship: `ClassModel.id` is referenced by `StudentModel.classId`.

A model may contain conversion code (`toMap` / `fromMap`) if the storage needs it. It contains no UI code.

### 5.2 Repository interfaces

`data/class/class_repository_interface.dart`

```dart
import 'package:<app_name>/core/errors/result.dart';

abstract interface class ClassRepositoryInterface {
  Future<Result<List<ClassModel>>> getClasses();
}
```

`data/student/student_repository_interface.dart`

```dart
import 'package:<app_name>/core/errors/result.dart';

abstract interface class StudentRepositoryInterface {
  Future<Result<void>> addStudent(StudentModel student);

  Future<Result<void>> updateStudentClass(
    String studentId,
    String classId,
  );

  /// Emits the full list again whenever any student changes.
  Stream<Result<List<StudentModel>>> watchStudents();
}
```

Rules:
- One-shot operations return `Future<Result<T>>`.
- Anything the UI must keep up to date returns `Stream<Result<T>>`. A stream emits a new value whenever the data changes, and emits `Err` for an error instead of throwing.
- The interface says what can be done, not how the data is stored.

### 5.3 Repository implementations

`data/student/student_repository.dart`

```dart
class StudentRepository implements StudentRepositoryInterface {
  @override
  Future<Result<void>> addStudent(StudentModel student) async {
    try {
      // insert into the student table
      return const Ok(null);
    } catch (e) {
      return Err(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> updateStudentClass(
    String studentId,
    String classId,
  ) async {
    try {
      // update classId in the student table
      return const Ok(null);
    } catch (e) {
      return Err(StorageFailure(e.toString()));
    }
  }

  @override
  Stream<Result<List<StudentModel>>> watchStudents() {
    // Return a stream that emits a new list whenever any student changes.
    // Map stream errors to Err(StorageFailure).
    throw UnimplementedError();
  }
}
```

`ClassRepository` follows the same pattern for `getClasses()`.

Rules:
- This is the **only** layer that catches exceptions.
- This is the only layer that imports the storage package.

---

## 6. Domain

Domain contains **only use cases**. A use case is one operation the app can perform. It depends on the repository interfaces and models in `data/`.

### 6.1 When a use case is required

- It contains logic: validation, rules, combining several repositories, or computing a derived value.
- Or it is used by more than one feature.

A plain pass-through (one repository call, no logic, one feature) may still have a use case for consistency, but it takes plain parameters instead of an Argument Model, and gets no extra folder.

### 6.2 Naming and models

- Use case class names end with `Usecase` (`AddStudentUsecase`), and the file ends with `_usecase.dart`.
- If the use case takes more than two or three inputs, it has an `...ArgumentModel`.
- If it returns data (not just `void`), it has a `...ReturnModel`.
- A Return Model may hold Data models directly, or a type defined in the use case's own folder when the use case computes something new.

### 6.3 Return types

| Use case | Returns |
|---|---|
| Action, no data | `Future<Result<void>>` |
| Action with result | `Future<Result<XReturnModel>>` |
| Live data | `Stream<Result<XReturnModel>>` |

### 6.3.1 Business use cases and UI use cases

When an app has many use cases, split `domain/use_cases/` into two folders:

- `business/`: actions that **write and validate** (add, record, change, delete). They return `Future<Result<..>>` and enforce the rules.
- `ui/`: **read-only**, presentation-only use cases that shape data for one screen (lists, totals, computed statuses, form options). They return a `Stream<Result<..>>` for live screens or a one-time `Future<Result<..>>` for forms. They never write.

Rules: a UI use case never calls a business use case; if reads need data to exist first (for example monthly records), a ViewModel runs the business use case, then subscribes to the UI use case. Shared pure helpers for the UI use cases (for example a status calculation) live in a folder next to them under `ui/`. A use case with no I/O and no failure may return its model directly instead of a `Result`.

### 6.4 Action with logic — `AddStudentUsecase`

`domain/use_cases/add_student/add_student_argument_model.dart`

```dart
class AddStudentArgumentModel {
  final String studentId;
  final String name;
  final int age;
  final String classId;

  const AddStudentArgumentModel({
    required this.studentId,
    required this.name,
    required this.age,
    required this.classId,
  });
}
```

`domain/use_cases/add_student/add_student_usecase.dart`

```dart
class AddStudentUsecase {
  final StudentRepositoryInterface _students;

  AddStudentUsecase(this._students);

  Future<Result<void>> call(AddStudentArgumentModel model) {
    if (model.name.trim().isEmpty) {
      return Future.value(const Err(ValidationFailure('name_required')));
    }
    if (model.age < 3 || model.age > 100) {
      return Future.value(const Err(ValidationFailure('age_out_of_range')));
    }

    return _students.addStudent(
      StudentModel(
        id: model.studentId,
        name: model.name.trim(),
        age: model.age,
        classId: model.classId,
      ),
    );
  }
}
```

No Return Model, because the use case returns `Result<void>`.

### 6.5 Live data — `ListStudentsUsecase`

`domain/use_cases/list_students/list_students_return_model.dart`

```dart
/// Defined here because the use case computes it: a student plus the class label.
class StudentItem {
  final String id;
  final String name;
  final int age;
  final String classLabel; // e.g. "10-A"

  const StudentItem({
    required this.id,
    required this.name,
    required this.age,
    required this.classLabel,
  });
}

class ListStudentsReturnModel {
  final List<StudentItem> students;
  const ListStudentsReturnModel({required this.students});
}
```

`domain/use_cases/list_students/list_students_usecase.dart`

```dart
class ListStudentsUsecase {
  final StudentRepositoryInterface _students;
  final ClassRepositoryInterface _classes;

  ListStudentsUsecase(this._students, this._classes);

  Stream<Result<ListStudentsReturnModel>> call() {
    return _students.watchStudents().asyncMap((studentsResult) async {
      final classesResult = await _classes.getClasses();

      return studentsResult.flatMap(
        (students) => classesResult.map((classes) {
          final labels = {
            for (final c in classes) c.id: '${c.classNumber}-${c.section}',
          };

          return ListStudentsReturnModel(
            students: students
                .map((s) => StudentItem(
                      id: s.id,
                      name: s.name,
                      age: s.age,
                      classLabel: labels[s.classId] ?? '-',
                    ))
                .toList(),
          );
        }),
      );
    });
  }
}
```

Flow: a student changes -> `StudentRepository` -> `Stream<Result<List<StudentModel>>>` -> `ListStudentsUsecase` -> `Stream<Result<ListStudentsReturnModel>>` -> ViewModel -> View.

### 6.6 Pass-through — `UpdateStudentClassUsecase`

`domain/use_cases/update_student_class/update_student_class_usecase.dart`

```dart
class UpdateStudentClassUsecase {
  final StudentRepositoryInterface _students;

  UpdateStudentClassUsecase(this._students);

  Future<Result<void>> call(String studentId, String classId) {
    return _students.updateStudentClass(studentId, classId);
  }
}
```

Two plain parameters, no Argument Model, no extra folder. It exists as a use case because more than one feature (student list, student details) can use it.

### 6.7 Reusing use cases

Several features can use the same use case. The operation is written once, not copied into each ViewModel.

```
Student list feature  ──┐
                        ├──▶ UpdateStudentClassUsecase
Student details feature ┘
```

---

## 7. Features (View + ViewModel)

One View = one feature = two files: `x_view.dart` and `x_view_model.dart`. The `Bundle` (initial arguments) lives in the ViewModel file.

### 7.1 The blocking rule

Whenever a future is running (`ViewStateLoading`):
1. **The ViewModel ignores a second call** to the same action.
2. **The View cannot be closed**, using `PopScope(canPop: !isLoading)`. This covers the system back button and the back gesture. The AppBar back arrow uses the same check, so it is blocked as well.
3. **Controls are disabled** (or covered by an overlay), so the user can't edit the form halfway.

Because the screen can't be closed while a future is running, the ViewModel never updates a disposed notifier, and no `_disposed` guard is needed for actions.

Streams are different: they stay open for the whole life of the screen. The ViewModel stores the `StreamSubscription` and cancels it in `dispose()`, so no event arrives after the screen is gone.

### 7.2 Action feature — Add Student

`features/add_student/add_student_view_model.dart`

```dart
import 'package:flutter/foundation.dart';
import 'package:<app_name>/core/errors/result.dart';

class AddStudentBundle {
  final String? initialClassId;
  const AddStudentBundle({this.initialClassId});
}

class AddStudentViewModel {
  final AddStudentBundle bundle;
  final AddStudentUsecase _addStudent;

  /// State of the save action.
  final ValueNotifier<ViewState<void>> saveState =
      ValueNotifier(const ViewStateIdle());

  AddStudentViewModel({
    required this.bundle,
    required AddStudentUsecase addStudent,
  }) : _addStudent = addStudent;

  Future<void> onSave({
    required String name,
    required String ageText,
    required String classId,
  }) async {
    if (saveState.value.isLoading) return; // blocking rule: ignore re-entry

    final age = int.tryParse(ageText);
    if (age == null) {
      saveState.value = const ViewStateError(ValidationFailure('age_invalid'));
      return;
    }

    saveState.value = const ViewStateLoading();

    final result = await _addStudent(
      AddStudentArgumentModel(
        studentId: generateId(),
        name: name,
        age: age,
        classId: classId,
      ),
    );

    saveState.value = result.fold(
      (failure) => ViewStateError(failure),
      (_) => const ViewStateLoaded(null),
    );
  }

  void dispose() {
    saveState.dispose();
  }
}
```

`features/add_student/add_student_view.dart`

```dart
class AddStudentView extends StatefulWidget {
  final AddStudentBundle bundle;
  const AddStudentView({super.key, required this.bundle});

  static Future<void> open(BuildContext context, AddStudentBundle bundle) {
    return Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddStudentView(bundle: bundle)),
    );
  }

  @override
  State<AddStudentView> createState() => _AddStudentViewState();
}

class _AddStudentViewState extends State<AddStudentView> {
  late final AddStudentViewModel ctrl;
  final nameController = TextEditingController(); // owned here, disposed below
  final ageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    ctrl = AddStudentViewModel(
      bundle: widget.bundle,
      addStudent: AppDependencies.instance.addStudent,
    );
    ctrl.saveState.addListener(_onSaveStateChanged);
  }

  void _onSaveStateChanged() {
    // Leave the screen when the save finished.
    if (ctrl.saveState.value is ViewStateLoaded && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    ctrl.saveState.removeListener(_onSaveStateChanged);
    nameController.dispose();
    ageController.dispose();
    ctrl.dispose(); // crucial: prevents memory leaks
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ObxValue<ViewState<void>>(
      listenable: ctrl.saveState,
      builder: (state) {
        final busy = state.isLoading;

        return PopScope(
          canPop: !busy, // blocks back button and gesture while saving
          child: Scaffold(
            appBar: AppBar(title: const Text('Add student')),
            body: Column(
              children: [
                TextField(
                  controller: nameController,
                  enabled: !busy,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: ageController,
                  enabled: !busy,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Age'),
                ),
                state.when(
                  loading: () => const SizedBox.shrink(),
                  loaded: (_) => const SizedBox.shrink(),
                  error: (failure) => Text(messageFor(failure)), // text chosen from the Failure
                ),
                ElevatedButton(
                  onPressed: busy
                      ? null
                      : () => ctrl.onSave(
                            name: nameController.text,
                            ageText: ageController.text,
                            classId: /* selected class */ '',
                          ),
                  child: state.when(
                    idle: () => const Text('Save'),
                    loading: () => const CircularProgressIndicator(),
                    error: (_) => const Text('Save'),
                    loaded: (_) => const Text('Save'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
```

Notes:
- `Navigator.pop` called from code is not blocked by `PopScope`. This is fine, because it runs only after the state has left `Loading`.
- `TextEditingController`s are created once in the State (not in `build()`) and disposed with it.

### 7.3 Live-data feature — Student List

`features/student_list/student_list_view_model.dart`

```dart
import 'dart:async';

class StudentListViewModel {
  final ListStudentsUsecase _listStudents;

  final ValueNotifier<ViewState<ListStudentsReturnModel>> state =
      ValueNotifier(const ViewStateLoading());

  StreamSubscription<Result<ListStudentsReturnModel>>? _subscription;

  StudentListViewModel({required ListStudentsUsecase listStudents})
      : _listStudents = listStudents {
    _subscription = _listStudents().listen((result) {
      state.value = result.fold(
        (failure) => ViewStateError(failure),
        (data) => ViewStateLoaded(data),
      );
    });
  }

  void dispose() {
    _subscription?.cancel(); // cancel first, so no event arrives after dispose
    state.dispose();
  }
}
```

`features/student_list/student_list_view.dart` (the part that renders the state)

```dart
ObxValue<ViewState<ListStudentsReturnModel>>(
  listenable: ctrl.state,
  builder: (state) => state.when(
    loading: () => const Center(child: CircularProgressIndicator()),
    error: (failure) => Center(child: Text(messageFor(failure))),
    loaded: (data) => ListView(
      children: [
        for (final s in data.students)
          ListTile(title: Text(s.name), subtitle: Text('${s.classLabel}, age ${s.age}')),
      ],
    ),
  ),
)
```

A stream-driven list screen has no blocking rule, since the user is not waiting on a one-off operation. A one-off action on that screen (for example "change class") gets its own `ViewState` notifier and follows 7.1.

### 7.4 Rules for features

1. ViewModels hold presentation state, handle user actions, and call use cases. They never call a repository or storage directly.
2. A ViewModel receives its use cases through its constructor. The View passes them from `AppDependencies.instance`. Tests pass fakes.
3. Every `ValueNotifier` is disposed in `dispose()`. Every `StreamSubscription` is cancelled there too.
4. Every `TextEditingController`, `FocusNode` and `ScrollController` is created in `initState` (or as a State field) and disposed in `dispose()`.
5. The View displays state and forwards user actions. It performs no business logic. In `build()`, render a `ViewState` with `state.when(...)`, not with `if` statements or `is` checks.
6. When a screen has many fields, group them into one immutable form-state object instead of one notifier per field.
7. Small reusable widgets are not features. Split out a reusable unit only when it is reused or genuinely complex.
8. Several features may share a use case.

---

## 8. Data Flow

```
FEATURES                         DOMAIN                  DATA
View ──▶ ViewModel ──▶ UseCase ──▶ RepositoryInterface ◀── Repository ──▶ Database
 ▲           │                          │
 │ ObxValue  │ fold(Result)             │ Result<T>
 └─ ViewState ◀─────────────────────────┘
```

---

## 9. Testing

| What | Kind | Notes |
|---|---|---|
| Repository (implementation) | Unit | Against a real or in-memory database. Check that exceptions become `Err`. |
| Model | Unit | Only when it has conversion logic. |
| Use case | Unit | Fake that implements the Data repository interface. `AddStudentUsecase`: `Err` for an empty name or bad age, `Ok` otherwise. `ListStudentsUsecase`: a new student list produces a new Return Model. |
| ViewModel | Unit | Fake use case. Check the state sequence `Idle -> Loading -> Loaded/Error`, and that a second `onSave` during `Loading` is ignored. Stream ViewModels: check the subscription is cancelled in `dispose()`. |
| View | Widget | While `Loading`: controls disabled and back is blocked (`PopScope`). Error and loaded states render. |
| Key journeys | Integration | For example: open Add Student -> fill the form -> Save -> the student appears in the list. |

---

## 10. Creating a New Feature (checklist)

1. **Data:** add or reuse the model, repository interface and repository implementation for each entity involved. Catch exceptions in the implementation and return `Err`.
2. **Domain:** add the use case (`Result` return type), with an Argument/Return Model if needed.
3. **Wire:** create the new objects in `AppDependencies.init()`.
4. **Feature:** create `x_view_model.dart` (Bundle, `ViewState` notifiers, `dispose()`) and `x_view.dart` (`PopScope`, disabled controls while loading, disposed controllers).
5. **Tests:** repository, use case, ViewModel, View (see section 9).
6. **Navigate:** `XView.open(context, XBundle(...))`.

---

## 11. Starting a New Project

1. `flutter create <app_name>`
2. `flutter pub add` your storage package.
3. Create the `core/` files from sections 3 and 4: `failure.dart`, `result.dart`, `view_state.dart`, `obx_value.dart`, `app_dependencies.dart`. Replace `<app_name>` in imports.
4. Update `main.dart` to call `AppDependencies.init()` (section 4.4).
5. For the first entity, create its three files in `data/<entity>/`.
6. Build the first feature using the checklist in section 10.

---

## 12. Quick Rules

1. Dependencies point one way: features -> domain -> data.
2. Data holds models, repository interfaces and repository implementations, one folder per entity. Domain holds only use cases.
3. Operations that can fail return `Result<T>`. Only repository implementations catch exceptions.
4. Every future and stream is exposed to the UI as a `ViewState`.
5. While a future is running, the ViewModel ignores repeat calls, and the View blocks back navigation and disables controls.
6. Streams are cancelled in `dispose()`. Notifiers and controllers are disposed in `dispose()`.
7. A use case is required when there is logic or reuse. Pure pass-throughs take plain parameters. Use case class names end with `Usecase`.
8. Return Models may hold Data models, or a type defined next to the use case.
9. A use case may use one entity or several.
10. ViewModels never touch repositories or storage directly.
11. Data behaviour, use cases and ViewModels get unit tests. Views get widget tests. Key journeys get integration tests.
12. No third-party package is required by this architecture.
