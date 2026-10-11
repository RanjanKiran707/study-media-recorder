import 'package:flutter/widgets.dart';
import 'package:study_recorder/core/errors/failure.dart';

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
