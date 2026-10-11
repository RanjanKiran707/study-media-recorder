import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:study_recorder/core/errors/failure.dart';
import 'package:study_recorder/core/utils/failure_message.dart';
import 'package:study_recorder/core/widgets/app_theme.dart';

OverlayEntry? _current;
Timer? _timer;

/// Shows a dark pill with [text] at the top of the screen for a moment.
void showAppToast(BuildContext context, String text) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  _remove();
  final entry = OverlayEntry(
    builder: (context) => Positioned(
      top: MediaQuery.of(context).padding.top + 18,
      left: 24,
      right: 24,
      child: IgnorePointer(
        child: Align(
          alignment: Alignment.topCenter,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.text,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.onDark,
                fontSize: 13,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  _current = entry;
  overlay.insert(entry);
  _timer = Timer(const Duration(milliseconds: 2200), _remove);
}

/// Shows the user-facing text of [failure] as a toast.
void showFailureToast(BuildContext context, Failure failure) =>
    showAppToast(context, messageFor(failure));

/// Removes the toast now. Tests call this so no timer stays pending.
void dismissAppToast() => _remove();

void _remove() {
  _timer?.cancel();
  _timer = null;
  _current?.remove();
  _current = null;
}
