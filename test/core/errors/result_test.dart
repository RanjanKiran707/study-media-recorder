import 'package:flutter_test/flutter_test.dart';
import 'package:study_recorder/core/errors/failure.dart';
import 'package:study_recorder/core/errors/result.dart';

void main() {
  const failure = ValidationFailure('bad');

  test('fold picks the matching branch', () {
    expect(const Ok(2).fold((_) => -1, (v) => v), 2);
    expect(const Err<int>(failure).fold((f) => f.message, (_) => ''), 'bad');
  });

  test('map transforms Ok and keeps Err', () {
    expect((const Ok(2).map((v) => v * 2) as Ok<int>).value, 4);
    expect(const Err<int>(failure).map((v) => v * 2), isA<Err<int>>());
  });

  test('flatMap chains Ok and short-circuits Err', () {
    expect(const Ok(2).flatMap((v) => Ok(v + 1)), isA<Ok<int>>());
    expect(
      const Ok(2).flatMap((_) => const Err<int>(failure)),
      isA<Err<int>>(),
    );
    expect(const Err<int>(failure).flatMap((v) => Ok(v)), isA<Err<int>>());
  });
}
