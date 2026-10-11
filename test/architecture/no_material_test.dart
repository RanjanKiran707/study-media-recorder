import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The UI uses only `package:flutter/widgets.dart` (and `CupertinoIcons`).
/// No Material widgets and no Material app anywhere in `lib/`.
void main() {
  final files = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  test('no file in lib/ imports Material', () {
    final offenders = [
      for (final file in files)
        if (file.readAsStringSync().contains('package:flutter/material.dart'))
          file.path,
    ];

    expect(offenders, isEmpty);
  });

  test('Cupertino is used only to read CupertinoIcons', () {
    final offenders = [
      for (final file in files)
        for (final line in file.readAsLinesSync())
          if (line.contains('package:flutter/cupertino.dart') &&
              !line.contains('show CupertinoIcons'))
            '${file.path}: $line',
    ];

    expect(offenders, isEmpty);
  });

  test('no Material widget is referenced by name', () {
    const materialWidgets = [
      'Scaffold',
      'AppBar',
      'MaterialApp',
      'ElevatedButton',
      'TextButton',
      'OutlinedButton',
      'FilledButton',
      'TextField',
      'ListTile',
      'Slider',
      'SnackBar',
      'AlertDialog',
      'CircularProgressIndicator',
      'LinearProgressIndicator',
      'PopupMenuButton',
      'IconButton',
      'Icons',
    ];
    // A whole word that is not part of a longer name such as AppTextField.
    final patterns = {
      for (final name in materialWidgets)
        name: RegExp(r'(?<![A-Za-z_])' + name + r'\b'),
    };

    final offenders = [
      for (final file in files)
        for (final entry in patterns.entries)
          if (entry.value.hasMatch(file.readAsStringSync()))
            '${file.path}: ${entry.key}',
    ];

    expect(offenders, isEmpty);
  });
}
