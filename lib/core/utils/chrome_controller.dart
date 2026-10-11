import 'dart:async';

import 'package:flutter/foundation.dart';

/// Whether the controls over a full-screen picture (camera or video) are
/// showing. They can hide by themselves a few seconds after the last touch,
/// and a tap on the picture brings them back.
class ChromeController {
  final Duration hideAfter;
  final ValueNotifier<bool> visible = ValueNotifier(true);
  Timer? _timer;

  ChromeController({this.hideAfter = const Duration(seconds: 3)});

  /// Shows the controls. With [autoHide] they hide again after [hideAfter].
  void show({bool autoHide = false}) {
    _timer?.cancel();
    _timer = null;
    visible.value = true;
    if (autoHide) _timer = Timer(hideAfter, hide);
  }

  void hide() {
    _timer?.cancel();
    _timer = null;
    visible.value = false;
  }

  void dispose() {
    _timer?.cancel();
    visible.dispose();
  }
}
