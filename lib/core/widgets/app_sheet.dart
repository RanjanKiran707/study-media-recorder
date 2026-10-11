import 'package:flutter/widgets.dart';
import 'package:study_recorder/core/widgets/app_buttons.dart';
import 'package:study_recorder/core/widgets/app_text_field.dart';
import 'package:study_recorder/core/widgets/app_theme.dart';

/// Shows a bottom sheet (like the mockup's sheets) over a dimmed screen.
/// Returns what the sheet passes to `Navigator.pop`, or null when dismissed.
Future<T?> showAppSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close',
    barrierColor: AppColors.scrim,
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (context, _, _) => Align(
      alignment: Alignment.bottomCenter,
      child: _SheetFrame(child: builder(context)),
    ),
    transitionBuilder: (context, animation, _, child) => SlideTransition(
      position: Tween(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
      child: child,
    ),
  );
}

class _SheetFrame extends StatelessWidget {
  final Widget child;
  const _SheetFrame({required this.child});

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        20,
        22,
        20,
        24 + media.viewInsets.bottom + media.padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: DefaultTextStyle(
        style: AppText.base,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [child],
        ),
      ),
    );
  }
}

/// One choice in an options sheet.
class AppChoice<T> {
  final T value;
  final String label;
  final bool danger;

  const AppChoice({
    required this.value,
    required this.label,
    this.danger = false,
  });
}

/// A sheet with a title and a list of choices (for example Rename, Delete).
Future<T?> showOptionsSheet<T>(
  BuildContext context, {
  required String title,
  required List<AppChoice<T>> choices,
}) {
  return showAppSheet<T>(
    context,
    builder: (context) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: AppText.sheetTitle),
        const SizedBox(height: 6),
        for (var i = 0; i < choices.length; i++)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.pop(context, choices[i].value),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                border: i < choices.length - 1
                    ? const Border(bottom: BorderSide(color: AppColors.line))
                    : null,
              ),
              child: Text(
                choices[i].label,
                style: AppText.base.copyWith(
                  color: choices[i].danger ? AppColors.record : AppColors.text,
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

/// A sheet that asks for a name or title. Returns the text, or null when
/// dismissed.
Future<String?> showNameSheet(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  String initialText = '',
  String hint = 'Name',
}) {
  return showAppSheet<String>(
    context,
    builder: (context) => _NameSheet(
      title: title,
      confirmLabel: confirmLabel,
      initialText: initialText,
      hint: hint,
    ),
  );
}

class _NameSheet extends StatefulWidget {
  final String title;
  final String confirmLabel;
  final String initialText;
  final String hint;

  const _NameSheet({
    required this.title,
    required this.confirmLabel,
    required this.initialText,
    required this.hint,
  });

  @override
  State<_NameSheet> createState() => _NameSheetState();
}

class _NameSheetState extends State<_NameSheet> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialText,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.pop(context, _controller.text);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.title, style: AppText.sheetTitle),
        const SizedBox(height: 12),
        AppTextField(
          controller: _controller,
          hint: widget.hint,
          autofocus: true,
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: 16),
        AppButton(label: widget.confirmLabel, block: true, onPressed: _submit),
      ],
    );
  }
}

/// A sheet that asks the user to confirm. Returns true when confirmed.
Future<bool> showConfirmSheet(
  BuildContext context, {
  required String title,
  String? message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final confirmed = await showAppSheet<bool>(
    context,
    builder: (context) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: AppText.sheetTitle),
        if (message != null) ...[
          const SizedBox(height: 12),
          Text(message, style: AppText.rowSubtitle.copyWith(fontSize: 14)),
        ],
        const SizedBox(height: 16),
        AppButton(
          label: confirmLabel,
          block: true,
          style: destructive ? AppButtonStyle.danger : AppButtonStyle.primary,
          onPressed: () => Navigator.pop(context, true),
        ),
        const SizedBox(height: 12),
        AppButton(
          label: 'Cancel',
          block: true,
          style: AppButtonStyle.ghost,
          onPressed: () => Navigator.pop(context, false),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
