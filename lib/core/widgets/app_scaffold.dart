import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/widgets.dart';
import 'package:study_recorder/core/widgets/app_buttons.dart';
import 'package:study_recorder/core/widgets/app_theme.dart';

/// A page: an optional top bar, a body that fills the space, and an optional
/// bottom area (buttons, mini player).
class AppPage extends StatelessWidget {
  final Widget? topBar;
  final Widget body;
  final Widget? bottom;

  const AppPage({super.key, this.topBar, required this.body, this.bottom});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ?topBar,
            Expanded(child: body),
            ?bottom,
          ],
        ),
      ),
    );
  }
}

/// The bar at the top of a page: a back or close button, a title, and
/// buttons on the right.
class AppTopBar extends StatelessWidget {
  final Widget? leading;
  final Widget title;
  final List<Widget> actions;

  const AppTopBar({
    super.key,
    this.leading,
    required this.title,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 52),
      padding: EdgeInsets.fromLTRB(leading == null ? 20 : 8, 6, 12, 6),
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 2)],
          Expanded(
            child: DefaultTextStyle(
              style: AppText.appBar,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              child: title,
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}

class AppBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String label;

  const AppBackButton({
    super.key,
    required this.onPressed,
    this.icon = CupertinoIcons.chevron_back,
    this.label = 'Back',
  });

  @override
  Widget build(BuildContext context) =>
      AppIconButton(icon: icon, label: label, onPressed: onPressed);
}

/// One line of muted text under the top bar (the folder path).
class AppCrumbs extends StatelessWidget {
  final String text;
  const AppCrumbs(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 18),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
      child: Text(text, style: AppText.small),
    );
  }
}

/// Buttons at the bottom of a page.
class AppActionBar extends StatelessWidget {
  final List<Widget> children;
  const AppActionBar({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Row(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(child: children[i]),
          ],
        ],
      ),
    );
  }
}
