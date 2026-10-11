import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:study_recorder/core/widgets/app_theme.dart';

/// A spinning ring, shown while something loads.
class AppSpinner extends StatefulWidget {
  final double size;
  const AppSpinner({super.key, this.size = 28});

  @override
  State<AppSpinner> createState() => _AppSpinnerState();
}

class _AppSpinnerState extends State<AppSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading',
      child: RotationTransition(
        turns: _controller,
        child: CustomPaint(
          size: Size.square(widget.size),
          painter: _RingPainter(),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.text
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Offset.zero & size, 0, math.pi * 1.4, false, paint);
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) => false;
}

/// A thin line that fills from the left. [value] is 0 to 1.
class AppProgressLine extends StatelessWidget {
  final double value;
  final double height;

  const AppProgressLine({super.key, required this.value, this.height = 2});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: value.clamp(0.0, 1.0),
        child: Container(height: height, color: AppColors.text),
      ),
    );
  }
}

/// A seek slider: a thin track, a dark filled part and a round thumb.
class AppSlider extends StatelessWidget {
  /// 0 to 1.
  final double value;
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onChangeEnd;

  /// The filled part and the thumb, and the rest of the track. Light colours
  /// are used over a video.
  final Color color;
  final Color trackColor;

  const AppSlider({
    super.key,
    required this.value,
    this.onChanged,
    this.onChangeEnd,
    this.color = AppColors.text,
    this.trackColor = AppColors.track,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        double fractionAt(double dx) =>
            width <= 0 ? 0 : (dx / width).clamp(0.0, 1.0);
        final v = value.clamp(0.0, 1.0);

        return Semantics(
          slider: true,
          value: '${(v * 100).round()}%',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) {
              final f = fractionAt(d.localPosition.dx);
              onChanged?.call(f);
              onChangeEnd?.call(f);
            },
            onHorizontalDragStart: (d) =>
                onChanged?.call(fractionAt(d.localPosition.dx)),
            onHorizontalDragUpdate: (d) =>
                onChanged?.call(fractionAt(d.localPosition.dx)),
            onHorizontalDragEnd: (_) => onChangeEnd?.call(v),
            child: SizedBox(
              height: 24,
              child: Stack(
                alignment: Alignment.centerLeft,
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: trackColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Container(
                    height: 3,
                    width: width * v,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Positioned(
                    left: (width * v - 7).clamp(0.0, math.max(0, width - 14)),
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Two or more tabs with an underline that slides to the selected one
/// (the Video / Audio switch).
class AppTabs extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int>? onChanged;

  const AppTabs({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Stack(
        children: [
          Row(
            children: [
              for (var i = 0; i < labels.length; i++)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: i == selected,
                    enabled: onChanged != null,
                    child: GestureDetector(
                      key: Key('tab-${labels[i]}'),
                      behavior: HitTestBehavior.opaque,
                      onTap: onChanged == null ? null : () => onChanged!(i),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Text(
                          labels[i],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            decoration: TextDecoration.none,
                            color: i == selected
                                ? AppColors.text
                                : AppColors.muted,
                            fontWeight: i == selected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Positioned.fill(
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              alignment: labels.length < 2
                  ? Alignment.bottomLeft
                  : Alignment(-1 + 2 * selected / (labels.length - 1), 1),
              child: FractionallySizedBox(
                widthFactor: 1 / labels.length,
                child: Container(height: 2, color: AppColors.text),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Seven bars that dance while [active] (the audio "stage" in the player).
class AppEqualizer extends StatefulWidget {
  final bool active;
  const AppEqualizer({super.key, required this.active});

  @override
  State<AppEqualizer> createState() => _AppEqualizerState();
}

class _AppEqualizerState extends State<AppEqualizer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  static const _phases = [0.0, 0.3, 0.7, 0.5, 0.9, 0.1, 0.6];

  @override
  void initState() {
    super.initState();
    if (widget.active) _controller.repeat();
  }

  @override
  void didUpdateWidget(AppEqualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.active && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => SizedBox(
        height: 56,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (var i = 0; i < _phases.length; i++)
              Container(
                width: 4,
                height: widget.active
                    ? 56 *
                          (0.15 +
                              0.85 *
                                  (0.5 +
                                      0.5 *
                                          math.sin(
                                            2 *
                                                math.pi *
                                                (_controller.value +
                                                    _phases[i]),
                                          )))
                    : 56 * 0.15,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: AppColors.text,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A small pill switch over a picture (Video / Audio on the Record screen).
/// The selected half is lit; [color] is the text colour and [indicator] the
/// colour of the lit half.
class AppPillTabs extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int>? onChanged;
  final Color color;
  final Color indicator;

  const AppPillTabs({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
    required this.color,
    required this.indicator,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 176,
      height: 36,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0x387F7F7F),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            alignment: labels.length < 2
                ? Alignment.centerLeft
                : Alignment(-1 + 2 * selected / (labels.length - 1), 0),
            child: FractionallySizedBox(
              widthFactor: 1 / labels.length,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: indicator,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (var i = 0; i < labels.length; i++)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: i == selected,
                    enabled: onChanged != null,
                    child: GestureDetector(
                      key: Key('tab-${labels[i]}'),
                      behavior: HitTestBehavior.opaque,
                      onTap: onChanged == null ? null : () => onChanged!(i),
                      child: Center(
                        child: Text(
                          labels[i],
                          style: TextStyle(
                            fontSize: 14,
                            decoration: TextDecoration.none,
                            color: color.withValues(
                              alpha: i == selected ? 1 : 0.7,
                            ),
                            fontWeight: i == selected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
