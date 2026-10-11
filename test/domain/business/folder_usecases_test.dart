import 'package:flutter_test/flutter_test.dart';
import 'package:study_recorder/core/errors/failure.dart';
import 'package:study_recorder/core/errors/result.dart';
import 'package:study_recorder/domain/use_cases/business/create_folder/create_folder_argument_model.dart';
import 'package:study_recorder/domain/use_cases/business/create_folder/create_folder_usecase.dart';
import 'package:study_recorder/domain/use_cases/business/delete_folder/delete_folder_usecase.dart';
import 'package:study_recorder/domain/use_cases/business/rename_folder/rename_folder_usecase.dart';

import '../fakes/fake_folder_repository.dart';

void main() {
  late FakeFolderRepository folders;
  setUp(() => folders = FakeFolderRepository());

  group('CreateFolderUsecase', () {
    final fixedNow = DateTime(2026, 1, 1);

    test('saves a trimmed name with the current time', () async {
      final usecase = CreateFolderUsecase(folders, now: () => fixedNow);

      final result = await usecase(
        const CreateFolderArgumentModel(
          folderId: 'f1',
          parentId: 'parent',
          name: '  Physics ',
        ),
      );

      expect(result, isA<Ok<void>>());
      final saved = folders.created.single;
      expect(saved.id, 'f1');
      expect(saved.parentId, 'parent');
      expect(saved.name, 'Physics');
      expect(saved.createdAt, fixedNow);
      expect(saved.sortIndex, isNull);
    });

    test('top-level folder has no parent', () async {
      await CreateFolderUsecase(folders)(
        const CreateFolderArgumentModel(
          folderId: 'f1',
          parentId: null,
          name: 'Maths',
        ),
      );

      expect(folders.created.single.parentId, isNull);
    });

    test('blank name is rejected and nothing is saved', () async {
      final result = await CreateFolderUsecase(folders)(
        const CreateFolderArgumentModel(
          folderId: 'f1',
          parentId: null,
          name: '   ',
        ),
      );

      expect((result as Err).failure, isA<ValidationFailure>());
      expect(result.failure.message, 'name_required');
      expect(folders.created, isEmpty);
    });

    test('passes a repository failure on', () async {
      folders.failure = const StorageFailure('disk');

      final result = await CreateFolderUsecase(folders)(
        const CreateFolderArgumentModel(
          folderId: 'f1',
          parentId: null,
          name: 'Maths',
        ),
      );

      expect((result as Err).failure, isA<StorageFailure>());
    });
  });

  group('RenameFolderUsecase', () {
    test('saves the trimmed name', () async {
      final result = await RenameFolderUsecase(folders)('f1', ' New ');

      expect(result, isA<Ok<void>>());
      expect(folders.renamed, {'f1': 'New'});
    });

    test('blank name is rejected', () async {
      final result = await RenameFolderUsecase(folders)('f1', '  ');

      expect((result as Err).failure.message, 'name_required');
      expect(folders.renamed, isEmpty);
    });

    test('passes a repository failure on', () async {
      folders.failure = const StorageFailure('disk');

      final result = await RenameFolderUsecase(folders)('f1', 'x');

      expect(result, isA<Err<void>>());
    });
  });

  group('DeleteFolderUsecase', () {
    test('deletes the folder', () async {
      final result = await DeleteFolderUsecase(folders)('f1');

      expect(result, isA<Ok<void>>());
      expect(folders.deleted, ['f1']);
    });

    test('passes a repository failure on', () async {
      folders.failure = const StorageFailure('disk');

      expect(await DeleteFolderUsecase(folders)('f1'), isA<Err<void>>());
    });
  });
}
