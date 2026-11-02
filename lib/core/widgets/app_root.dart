import 'package:flutter/widgets.dart';
import 'package:study_recorder/core/widgets/app_route.dart';
import 'package:study_recorder/core/widgets/app_theme.dart';
import 'package:study_recorder/core/widgets/web_showcase_shell.dart';

/// The app shell, with no Material or Cupertino app. Tests use it too.
class AppRoot extends StatelessWidget {
  final Widget home;

  const AppRoot({super.key, required this.home});

  @override
  Widget build(BuildContext context) {
    return WidgetsApp(
      title: 'Study Recorder',
      color: AppColors.background,
      debugShowCheckedModeBanner: false,
      home: home,
      pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) =>
          appRoute<T>(builder, settings: settings),
      builder: (context, child) => DefaultTextStyle(
        style: AppText.base,
        child: WebShowcaseShell(
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}
