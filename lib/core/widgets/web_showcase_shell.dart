import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:study_recorder/core/utils/url_helper.dart';
import 'package:study_recorder/core/widgets/app_theme.dart';

/// Wraps the application on desktop web in a split-screen showcase:
/// - Left side: App presentation, Feynman study method, and feature guide.
/// - Right side: A realistic live mobile phone frame running the interactive app.
/// On mobile browsers, renders a tailored landing page with GitHub APK download details.
/// On desktop web, renders a split-screen showcase with product details on the left and live phone simulator on the right.
/// On native devices, renders the app directly full-screen.
class WebShowcaseShell extends StatelessWidget {
  final Widget child;

  const WebShowcaseShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return ColoredBox(
        color: AppColors.background,
        child: child,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 960) {
          // Mobile browser or compact window:
          // Show APK download & product landing page.
          return const _MobileWebLanding();
        }

        // Desktop / wide browser showcase experience.
        return ColoredBox(
          color: const Color(0xFFF5F5F7),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1360),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 48,
                  vertical: 32,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Left: Product presentation & features.
                    Expanded(
                      flex: 5,
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 48),
                          child: const _ShowcaseDetailsPanel(),
                        ),
                      ),
                    ),

                    // Right: Live phone preview.
                    Expanded(
                      flex: 4,
                      child: Center(
                        child: _PhoneMockupFrame(child: child),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ShowcaseDetailsPanel extends StatelessWidget {
  const _ShowcaseDetailsPanel();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // App header with icon.
        Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E24),
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1F000000),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  CupertinoIcons.mic_fill,
                  color: AppColors.record,
                  size: 26,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Study Recorder',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Revision by Self-Explanation',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 28),

        // Method Pill.
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFFCEBEA),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'FEYNMAN TECHNIQUE · 100% OFFLINE',
            style: TextStyle(
              color: AppColors.record,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              decoration: TextDecoration.none,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Hero headline.
        const Text(
          'Master any topic by explaining it in your own words.',
          style: TextStyle(
            color: AppColors.text,
            fontSize: 34,
            fontWeight: FontWeight.w700,
            height: 1.22,
            letterSpacing: -0.6,
            decoration: TextDecoration.none,
          ),
        ),

        const SizedBox(height: 14),

        // Body text.
        Text(
          'Record short 2-minute audio or video explanations while studying, '
          'organize them into flexible subject folders, and queue whole '
          'folders as playlists to revise before sleep.',
          style: TextStyle(
            color: AppColors.text.withValues(alpha: 0.72),
            fontSize: 16,
            height: 1.55,
            decoration: TextDecoration.none,
          ),
        ),

        const SizedBox(height: 20),

        // APK Download Action Button & Release link.
        const _ApkDownloadAction(),

        const SizedBox(height: 32),

        // 4 Feature Highlights Grid.
        Wrap(
          spacing: 20,
          runSpacing: 18,
          children: const [
            _FeatureCard(
              icon: CupertinoIcons.videocam_fill,
              title: 'Audio & Video Takes',
              description:
                  'Front or back camera video, or audio-only via microphone with instant review.',
            ),
            _FeatureCard(
              icon: CupertinoIcons.folder_fill,
              title: 'Subject Hierarchy',
              description:
                  'Flexible subfolders with drag-and-drop rearranging to match your study order.',
            ),
            _FeatureCard(
              icon: CupertinoIcons.music_note_list,
              title: 'Continuous Playback',
              description:
                  'Tap any take to queue the whole folder. Mini-player and full-screen controls.',
            ),
            _FeatureCard(
              icon: CupertinoIcons.lock_shield_fill,
              title: 'Private & Offline',
              description:
                  'Zero accounts, zero tracking. All files and databases stay in your browser.',
            ),
          ],
        ),

        const SizedBox(height: 36),

        // Interactive Callout.
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E2E6)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(
                  CupertinoIcons.hand_point_right_fill,
                  color: AppColors.record,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Try the live app in the simulator 👉',
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'The phone on the right is fully interactive. Create a subject folder, '
                      'record an audio take with your mic, and listen to the playlist!',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                        height: 1.4,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // APK Release Footer link.
        const _ApkReleaseFooter(),
      ],
    );
  }
}

class _ApkDownloadAction extends StatefulWidget {
  const _ApkDownloadAction();

  static const releaseUrl =
      'https://github.com/RanjanKiran707/study-media-recorder/releases/tag/v1.0.0';

  @override
  State<_ApkDownloadAction> createState() => _ApkDownloadActionState();
}

class _ApkDownloadActionState extends State<_ApkDownloadAction> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) => setState(() => _pressed = false),
            onTapCancel: () => setState(() => _pressed = false),
            onTap: () => openUrl(_ApkDownloadAction.releaseUrl),
            child: AnimatedScale(
              scale: _pressed ? 0.96 : (_hovered ? 1.02 : 1.0),
              duration: const Duration(milliseconds: 140),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: _hovered ? const Color(0xFF2C2C35) : const Color(0xFF1E1E24),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0x24000000),
                      blurRadius: _hovered ? 14 : 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      CupertinoIcons.arrow_down_circle_fill,
                      color: AppColors.record,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Download Android APK',
                      style: TextStyle(
                        color: AppColors.onDark,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2.5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF33333F),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'v1.0.0',
                        style: TextStyle(
                          color: Color(0xFFE2E2EA),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      CupertinoIcons.arrow_up_right,
                      color: Color(0xFF9E9EA8),
                      size: 13,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Text(
          'Android 8.0+ · GitHub Release',
          style: TextStyle(
            color: AppColors.muted,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            decoration: TextDecoration.none,
          ),
        ),
      ],
    );
  }
}

class _ApkReleaseFooter extends StatefulWidget {
  const _ApkReleaseFooter();

  @override
  State<_ApkReleaseFooter> createState() => _ApkReleaseFooterState();
}

class _ApkReleaseFooterState extends State<_ApkReleaseFooter> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => openUrl(_ApkDownloadAction.releaseUrl),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              CupertinoIcons.arrow_down_doc_fill,
              color: AppColors.muted,
              size: 15,
            ),
            const SizedBox(width: 8),
            Text(
              'Get the APK on GitHub: Releases/tag/v1.0.0',
              style: TextStyle(
                color: _hovered ? AppColors.text : AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                decoration: _hovered ? TextDecoration.underline : TextDecoration.none,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              CupertinoIcons.arrow_up_right,
              color: _hovered ? AppColors.text : AppColors.muted,
              size: 11,
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFEBEBEF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Icon(
                icon,
                color: AppColors.text,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    height: 1.35,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PhoneMockupFrame extends StatelessWidget {
  final Widget child;

  const _PhoneMockupFrame({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 385,
      height: 785,
      decoration: BoxDecoration(
        color: const Color(0xFF18181D),
        borderRadius: BorderRadius.circular(46),
        border: Border.all(
          color: const Color(0xFF2C2C35),
          width: 3.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 45,
            offset: Offset(0, 22),
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(36),
        child: Stack(
          children: [
            // The running Flutter application with simulated mobile safe areas!
            Positioned.fill(
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  padding: const EdgeInsets.only(top: 44, bottom: 24),
                  viewPadding: const EdgeInsets.only(top: 44, bottom: 24),
                ),
                child: ColoredBox(
                  color: AppColors.background,
                  child: child,
                ),
              ),
            ),

            // Top Status Bar: Clock on left, Dynamic Island in center, Battery/Wifi on right.
            Align(
              alignment: Alignment.topCenter,
              child: IgnorePointer(
                child: SizedBox(
                  height: 44,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Left: Clock Time
                        const Text(
                          '9:41',
                          style: TextStyle(
                            color: AppColors.text,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        const Spacer(),
                        // Center: Notch Pill
                        Container(
                          width: 112,
                          height: 25,
                          decoration: BoxDecoration(
                            color: const Color(0xFF18181D),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF2A2A35),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                width: 38,
                                height: 4.5,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2A2A35),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        // Right: Status icons (Cellular, Wifi, Battery)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              CupertinoIcons.bars,
                              color: AppColors.text,
                              size: 13,
                            ),
                            SizedBox(width: 5),
                            Icon(
                              CupertinoIcons.wifi,
                              color: AppColors.text,
                              size: 14,
                            ),
                            SizedBox(width: 5),
                            Icon(
                              CupertinoIcons.battery_100,
                              color: AppColors.text,
                              size: 17,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Bottom Home Indicator Bar
            Align(
              alignment: Alignment.bottomCenter,
              child: IgnorePointer(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    width: 134,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: const Color(0xFF18181D).withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileWebLanding extends StatefulWidget {
  const _MobileWebLanding();

  @override
  State<_MobileWebLanding> createState() => _MobileWebLandingState();
}

class _MobileWebLandingState extends State<_MobileWebLanding> {
  bool _btnHovered = false;
  bool _btnPressed = false;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFF5F5F7),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App header with icon and title.
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E24),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x1F000000),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            CupertinoIcons.mic_fill,
                            color: AppColors.record,
                            size: 26,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Study Recorder',
                              style: TextStyle(
                                color: AppColors.text,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.4,
                                decoration: TextDecoration.none,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Revision by Self-Explanation',
                              style: TextStyle(
                                color: AppColors.muted,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // Method Pill.
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCEBEA),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'FEYNMAN TECHNIQUE · 100% OFFLINE',
                      style: TextStyle(
                        color: AppColors.record,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Hero headline.
                  const Text(
                    'Master any topic by explaining it in your own words.',
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 27,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                      letterSpacing: -0.5,
                      decoration: TextDecoration.none,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Body text.
                  Text(
                    'Record short 2-minute audio or video explanations while studying, '
                    'organize them into flexible subject folders, and queue whole '
                    'folders as playlists to revise before sleep.',
                    style: TextStyle(
                      color: AppColors.text.withValues(alpha: 0.75),
                      fontSize: 15,
                      height: 1.5,
                      decoration: TextDecoration.none,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // APK Download Action Button for Mobile.
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    onEnter: (_) => setState(() => _btnHovered = true),
                    onExit: (_) => setState(() => _btnHovered = false),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (_) => setState(() => _btnPressed = true),
                      onTapUp: (_) => setState(() => _btnPressed = false),
                      onTapCancel: () => setState(() => _btnPressed = false),
                      onTap: () => openUrl(_ApkDownloadAction.releaseUrl),
                      child: AnimatedScale(
                        scale: _btnPressed ? 0.97 : (_btnHovered ? 1.01 : 1.0),
                        duration: const Duration(milliseconds: 140),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                          decoration: BoxDecoration(
                            color: _btnHovered ? const Color(0xFF2C2C35) : const Color(0xFF1E1E24),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x2E000000),
                                blurRadius: 16,
                                offset: Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.record.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: Icon(
                                    CupertinoIcons.arrow_down_circle_fill,
                                    color: AppColors.record,
                                    size: 26,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Flexible(
                                          child: Text(
                                            'Download Android APK',
                                            style: TextStyle(
                                              color: AppColors.onDark,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: -0.2,
                                              decoration: TextDecoration.none,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF33333F),
                                            borderRadius: BorderRadius.circular(5),
                                          ),
                                          child: const Text(
                                            'v1.0.0',
                                            style: TextStyle(
                                              color: Color(0xFFE2E2EA),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              decoration: TextDecoration.none,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    const Text(
                                      'Free · Android 8.0+ · GitHub Release',
                                      style: TextStyle(
                                        color: AppColors.muted,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w500,
                                        decoration: TextDecoration.none,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                CupertinoIcons.arrow_up_right,
                                color: Color(0xFF9E9EA8),
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Feature Cards Section.
                  const Text(
                    'Key Features',
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 14),

                  const _MobileFeatureCard(
                    icon: CupertinoIcons.videocam_fill,
                    title: 'Audio & Video Takes',
                    description:
                        'Front or back camera video, or audio-only via microphone with instant review.',
                  ),
                  const SizedBox(height: 12),
                  const _MobileFeatureCard(
                    icon: CupertinoIcons.folder_fill,
                    title: 'Subject Hierarchy',
                    description:
                        'Flexible subfolders with custom nesting to mirror your study syllabus.',
                  ),
                  const SizedBox(height: 12),
                  const _MobileFeatureCard(
                    icon: CupertinoIcons.music_note_list,
                    title: 'Continuous Playback',
                    description:
                        'Tap any take to queue the whole folder as an auto-advancing playlist.',
                  ),
                  const SizedBox(height: 12),
                  const _MobileFeatureCard(
                    icon: CupertinoIcons.lock_shield_fill,
                    title: 'Private & 100% Offline',
                    description:
                        'Zero accounts, zero tracking. All recordings and database stay securely on your device.',
                  ),

                  const SizedBox(height: 24),

                  // Native Android advantage note box.
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E2E6)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          CupertinoIcons.info_circle_fill,
                          color: AppColors.record,
                          size: 20,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Recommended for Mobile',
                                style: TextStyle(
                                  color: AppColors.text,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'The native Android APK offers background audio playback with screen locked, native hardware camera controls, and persistent storage without mobile browser limits.',
                                style: TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 12.5,
                                  height: 1.4,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // GitHub Release link.
                  Center(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => openUrl(_ApkDownloadAction.releaseUrl),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            CupertinoIcons.arrow_down_doc_fill,
                            color: AppColors.muted,
                            size: 14,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'View v1.0.0 Release Notes on GitHub',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileFeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _MobileFeatureCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8E8EC)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFEBEBEF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Icon(
                icon,
                color: AppColors.text,
                size: 19,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12.5,
                    height: 1.35,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
