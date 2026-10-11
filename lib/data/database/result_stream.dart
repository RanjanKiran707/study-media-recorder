import 'dart:async';

import 'package:study_recorder/core/errors/failure.dart';
import 'package:study_recorder/core/errors/result.dart';

/// Wraps each event in `Ok`, and turns a stream error into `Err`.
///
/// Not an `async*` function on purpose: cancelling the subscription must
/// cancel the source straight away.
Stream<Result<T>> toResultStream<T>(Stream<T> source) {
  return source.transform(
    StreamTransformer<T, Result<T>>.fromHandlers(
      handleData: (value, sink) => sink.add(Ok(value)),
      handleError: (error, stackTrace, sink) =>
          sink.add(Err(StorageFailure(error.toString()))),
    ),
  );
}
