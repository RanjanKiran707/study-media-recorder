import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

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
