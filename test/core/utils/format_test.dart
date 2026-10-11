import 'package:flutter_test/flutter_test.dart';
import 'package:study_recorder/core/utils/format.dart';

void main() {
  test('formatDuration', () {
    expect(formatDuration(0), '0:00');
    expect(formatDuration(90000), '1:30');
    expect(formatDuration(3725000), '1:02:05');
  });

  test('formatDate', () {
    expect(formatDate(DateTime(2026, 10, 11)), '11 Oct 2026');
  });

  test('formatCounts', () {
    expect(formatCounts(subfolders: 0, recordings: 0), 'Empty');
    expect(
      formatCounts(subfolders: 1, recordings: 4),
      '4 recordings · 1 subfolder',
    );
    expect(
      formatCounts(subfolders: 2, recordings: 1),
      '1 recording · 2 subfolders',
    );
  });
}
