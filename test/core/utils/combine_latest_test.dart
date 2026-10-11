import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:study_recorder/core/utils/combine_latest.dart';

void main() {
  test('waits for both, then emits on every change of either', () async {
    final a = StreamController<int>();
    final b = StreamController<String>();
    final events = <String>[];
    combineLatest2(a.stream, b.stream, (x, y) => '$x$y').listen(events.add);

    a.add(1);
    await pumpEventQueue();
    expect(events, isEmpty);

    b.add('a');
    await pumpEventQueue();
    a.add(2);
    await pumpEventQueue();
    b.add('b');
    await pumpEventQueue();

    expect(events, ['1a', '2a', '2b']);
    await a.close();
    await b.close();
  });

  test('closes when both sources are done', () async {
    final a = StreamController<int>();
    final b = StreamController<int>();
    var done = false;
    combineLatest2(
      a.stream,
      b.stream,
      (x, y) => x + y,
    ).listen((_) {}, onDone: () => done = true);

    await a.close();
    await pumpEventQueue();
    expect(done, isFalse);
    await b.close();
    await pumpEventQueue();
    expect(done, isTrue);
  });

  test('cancelling cancels both sources', () async {
    var cancelledA = false;
    var cancelledB = false;
    final a = StreamController<int>(onCancel: () => cancelledA = true);
    final b = StreamController<int>(onCancel: () => cancelledB = true);

    final sub = combineLatest2(
      a.stream,
      b.stream,
      (x, y) => x + y,
    ).listen((_) {});
    await sub.cancel();

    expect(cancelledA, isTrue);
    expect(cancelledB, isTrue);
  });
}
