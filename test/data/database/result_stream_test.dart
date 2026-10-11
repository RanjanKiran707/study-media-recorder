import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:study_recorder/core/errors/failure.dart';
import 'package:study_recorder/core/errors/result.dart';
import 'package:study_recorder/data/database/result_stream.dart';

void main() {
  test('wraps values in Ok and errors in Err', () async {
    final source = StreamController<int>();
    final events = <Result<int>>[];
    toResultStream(source.stream).listen(events.add);

    source.add(1);
    source.addError(Exception('boom'));
    await pumpEventQueue();

    expect(events[0], isA<Ok<int>>());
    expect((events[0] as Ok<int>).value, 1);
    expect(events[1], isA<Err<int>>());
    expect((events[1] as Err<int>).failure, isA<StorageFailure>());
    await source.close();
  });

  test('cancelling the result stream cancels the source', () async {
    var cancelled = false;
    final source = StreamController<int>(onCancel: () => cancelled = true);
    final sub = toResultStream(source.stream).listen((_) {});

    await sub.cancel();

    expect(cancelled, isTrue);
  });
}
