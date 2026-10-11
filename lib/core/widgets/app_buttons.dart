import 'package:flutter/widgets.dart';
import 'package:study_recorder/core/widgets/app_theme.dart';

/// Tap target with a pressed look and a disabled look. The base of the
/// buttons and rows below.
class AppPressable extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final String? semanticLabel;

  const AppPressable({
    super.key,
    required this.onPressed,
    required this.child,
    this.semanticLabel,
  });

  @override
  State<AppPressable> createState() => _AppPressableState();
}

class _AppPressableState extends State<AppPressable> {
  bool _pressed = false;

  void _set(bool pressed) {
    if (_pressed != pressed && mounted) setState(() => _pressed = pressed);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => _set(true) : null,
        onTapUp: enabled ? (_) => _set(false) : null,
        onTapCancel: enabled ? () => _set(false) : null,
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _pressed ? 0.94 : 1,
          duration: const Duration(milliseconds: 120),
          child: AnimatedOpacity(
            opacity: enabled ? 1 : 0.3,
            duration: const Duration(milliseconds: 200),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// A round icon button (40 px by default). [selected] draws it as "on".
class AppIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool selected;
  final double size;
  final double iconSize;
  final Color? background;
  final Color? color;

  const AppIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.selected = false,
    this.size = 40,
    this.iconSize = 22,
    this.background,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final bg = background ?? (selected ? AppColors.text : null);
    final fg = color ?? (selected ? AppColors.onDark : AppColors.text);
    return AppPressable(
      onPressed: onPressed,
      semanticLabel: label,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Icon(icon, size: iconSize, color: fg),
      ),
    );
  }
}

enum AppButtonStyle { primary, ghost, text, record, danger }

/// A pill button. [block] makes it as wide as its parent allows.
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonStyle style;
  final bool block;
  final bool loading;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.style = AppButtonStyle.primary,
    this.block = false,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg, Color border) = switch (style) {
      AppButtonStyle.primary => (
        AppColors.text,
        AppColors.onDark,
        AppColors.text,
      ),
      AppButtonStyle.ghost => (
        AppColors.background,
        AppColors.text,
        AppColors.border,
      ),
      AppButtonStyle.text => (
        const Color(0x00000000),
        AppColors.record,
        const Color(0x00000000),
      ),
      AppButtonStyle.record => (
        AppColors.record,
        AppColors.onDark,
        AppColors.record,
      ),
      AppButtonStyle.danger => (
        AppColors.record,
        AppColors.onDark,
        AppColors.record,
      ),
    };

    return AppPressable(
      onPressed: loading ? null : onPressed,
      semanticLabel: label,
      child: Container(
        width: block ? double.infinity : null,
        padding: EdgeInsets.symmetric(
          horizontal: 18,
          vertical: block ? 14 : 12,
        ),
        alignment: block ? Alignment.center : null,
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppText.button.copyWith(color: fg),
        ),
      ),
    );
  }
}
