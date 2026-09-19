import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Pops a brief, non-blocking "correct answer" celebration (checkmark card
/// + particle burst) above the current screen. Safe to call repeatedly —
/// each call inserts a fresh overlay entry, so the animation always
/// replays from the start.
void showCelebrationOverlay(BuildContext context) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _CelebrationBurst(onDone: () => entry.remove()),
  );
  overlay.insert(entry);
}

class _CelebrationBurst extends StatefulWidget {
  final VoidCallback onDone;
  const _CelebrationBurst({required this.onDone});

  @override
  State<_CelebrationBurst> createState() => _CelebrationBurstState();
}

class _CelebrationBurstState extends State<_CelebrationBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    final rand = Random(7);
    final colors = [
      AppColors.emerald,
      AppColors.gold,
      AppColors.amber,
      AppColors.emeraldLight,
    ];
    _particles = List.generate(18, (i) {
      final angle = (i / 18) * 2 * pi + rand.nextDouble() * 0.3;
      return _Particle(
        angle: angle,
        speed: 60 + rand.nextDouble() * 50,
        color: colors[i % colors.length],
        size: 5 + rand.nextDouble() * 4,
      );
    });
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onDone();
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value;
            final burstT = (t / 0.55).clamp(0.0, 1.0);
            final fade = t < 0.7
                ? 1.0
                : (1.0 - ((t - 0.7) / 0.3)).clamp(0.0, 1.0);
            final scale = t < 0.22
                ? Curves.elasticOut.transform((t / 0.22).clamp(0.0, 1.0))
                : 1.0;
            return Stack(
              children: [
                Align(
                  alignment: const Alignment(0, -0.32),
                  child: CustomPaint(
                    size: const Size(220, 220),
                    painter: _ParticlePainter(
                      particles: _particles,
                      progress: burstT,
                      fade: fade,
                    ),
                  ),
                ),
                Align(
                  alignment: const Alignment(0, -0.32),
                  child: Opacity(
                    opacity: fade,
                    child: Transform.scale(
                      scale: scale,
                      child: const _CelebrationCard(),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CelebrationCard extends StatelessWidget {
  const _CelebrationCard();

  @override
  Widget build(BuildContext context) {
    // Overlay entries sit outside any Scaffold/Material, so Text would fall
    // back to the yellow double-underline debug style without this.
    return Material(
      type: MaterialType.transparency,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: AppColors.emerald.withValues(alpha: 0.25),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(color: AppColors.mint, width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: AppColors.emerald,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'ត្រឹមត្រូវ!',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.emerald,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'ធ្វើបានល្អ បន្តទៅមុខទៀត',
              style: TextStyle(fontSize: 11.5, color: AppColors.slate),
            ),
          ],
        ),
      ),
    );
  }
}

class _Particle {
  final double angle;
  final double speed;
  final Color color;
  final double size;
  _Particle({
    required this.angle,
    required this.speed,
    required this.color,
    required this.size,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final double fade;
  _ParticlePainter({
    required this.particles,
    required this.progress,
    required this.fade,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    for (final p in particles) {
      final dist = p.speed * progress;
      final pos = center + Offset(cos(p.angle) * dist, sin(p.angle) * dist);
      final paint = Paint()..color = p.color.withValues(alpha: fade);
      canvas.drawCircle(pos, p.size * (1 - progress * 0.3), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.fade != fade;
}
