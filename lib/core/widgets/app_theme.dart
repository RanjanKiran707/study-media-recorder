import 'package:flutter/widgets.dart';

/// Colours and text styles of the app, taken from `project_specs/mockup.html`.
/// The whole UI is built on `package:flutter/widgets.dart` only: no Material
/// widgets.
class AppColors {
  static const background = Color(0xFFFFFFFF);
  static const text = Color(0xFF111111);
  static const muted = Color(0xFF8A8A8A);
  static const line = Color(0xFFECECEC);
  static const record = Color(0xFFE5392F);
  static const onDark = Color(0xFFFFFFFF);
  static const stage = Color(0xFFF4F4F4);
  static const border = Color(0xFFD6D6D6);
  static const fieldLine = Color(0xFFD4D4D4);
  static const track = Color(0xFFE3E3E3);
  static const pressed = Color(0xFFF6F6F6);
  static const scrim = Color(0x59000000);
  static const dim = Color(0xFFBDBDBD);
}

class AppText {
  static const base = TextStyle(
    color: AppColors.text,
    fontSize: 16,
    decoration: TextDecoration.none,
    fontWeight: FontWeight.w400,
  );
  static const appBar = TextStyle(
    color: AppColors.text,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    decoration: TextDecoration.none,
  );
  static const rowTitle = TextStyle(
    color: AppColors.text,
    fontSize: 16,
    decoration: TextDecoration.none,
  );
  static const rowSubtitle = TextStyle(
    color: AppColors.muted,
    fontSize: 13,
    decoration: TextDecoration.none,
  );
  static const small = TextStyle(
    color: AppColors.muted,
    fontSize: 12,
    decoration: TextDecoration.none,
  );
  static const button = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    decoration: TextDecoration.none,
  );
  static const sheetTitle = TextStyle(
    color: AppColors.text,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    decoration: TextDecoration.none,
  );
  static const timer = TextStyle(
    color: AppColors.text,
    fontSize: 58,
    fontWeight: FontWeight.w300,
    letterSpacing: -1,
    fontFeatures: [FontFeature.tabularFigures()],
    decoration: TextDecoration.none,
  );
  static const nowPlaying = TextStyle(
    color: AppColors.text,
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: -0.5,
    decoration: TextDecoration.none,
  );
}
