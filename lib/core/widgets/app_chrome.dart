import 'package:flutter/widgets.dart';

/// A bar of controls pinned to the top or the bottom of a `Stack` that holds
/// a full-screen picture. It fades and slides away when [visible] is false,
/// and then lets touches through to the picture.
///
/// [scrim] draws a dark fade behind the controls so they stay readable over
/// a video.
class AppChromeBar extends StatelessWidget {
  final bool visible;
  final bool atTop;
  final bool scrim;
  final Widget child;

  const AppChromeBar({
    super.key,
    required this.visible,
    required this.atTop,
    required this.child,
    this.scrim = false,
  });

  @override
  Widget build(BuildContext context) {
    final fade = scrim
        ? BoxDecoration(
            gradient: LinearGradient(
              begin: atTop ? Alignment.topCenter : Alignment.bottomCenter,
              end: atTop ? Alignment.bottomCenter : Alignment.topCenter,
              colors: [
                Color(atTop ? 0x8C000000 : 0xB3000000),
                const Color(0x00000000),
              ],
            ),
          )
        : null;
    return Positioned(
      left: 0,
      right: 0,
      top: atTop ? 0 : null,
      bottom: atTop ? null : 0,
      child: IgnorePointer(
        ignoring: !visible,
        child: AnimatedSlide(
          offset: visible ? Offset.zero : Offset(0, atTop ? -0.25 : 0.25),
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          child: AnimatedOpacity(
            opacity: visible ? 1 : 0,
            duration: const Duration(milliseconds: 250),
            child: DecoratedBox(
              decoration: fade ?? const BoxDecoration(),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
