import 'package:flutter/services.dart' show TextCapitalization;
import 'package:flutter/widgets.dart';
import 'package:study_recorder/core/widgets/app_theme.dart';

/// A single-line text field with a muted label above it and a line below it
/// that turns dark when focused. The caller owns the [controller].
class AppTextField extends StatefulWidget {
  final TextEditingController controller;
  final String? label;
  final String? hint;
  final bool enabled;
  final bool autofocus;
  final ValueChanged<String>? onSubmitted;

  const AppTextField({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.enabled = true,
    this.autofocus = false,
    this.onSubmitted,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() => setState(() {});

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      color: AppColors.text,
      fontSize: 17,
      decoration: TextDecoration.none,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(widget.label!, style: AppText.small),
          ),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: _focusNode.hasFocus
                    ? AppColors.text
                    : AppColors.fieldLine,
              ),
            ),
          ),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              if (widget.hint != null)
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: widget.controller,
                  builder: (context, value, _) => value.text.isEmpty
                      ? Text(
                          widget.hint!,
                          style: style.copyWith(color: AppColors.dim),
                        )
                      : const SizedBox.shrink(),
                ),
              EditableText(
                controller: widget.controller,
                focusNode: _focusNode,
                autofocus: widget.autofocus,
                readOnly: !widget.enabled,
                style: style,
                cursorColor: AppColors.text,
                backgroundCursorColor: AppColors.track,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: widget.onSubmitted,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
