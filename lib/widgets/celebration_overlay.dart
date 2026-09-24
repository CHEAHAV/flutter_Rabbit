import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:lottie/lottie.dart';

import '../theme/app_theme.dart';

/// The trophy-and-confetti animation played on a correct answer.
const celebrationLottieAsset = 'assets/lotties/congratulation.json';

Future<LottieComposition?>? _composition;

/// The parsed animation once [precacheCelebration] has finished, so a card
/// can start with it on its very first frame rather than flashing the
/// fallback checkmark for one frame while a future resolves.
LottieComposition? _loaded;

/// Loads and parses the celebration animation once, so the first correct
/// answer plays it immediately instead of waiting on the asset. Called at app
/// start; later calls reuse the same future. Resolves to null if the asset
/// cannot be read, and the card then shows its plain checkmark instead.
Future<LottieComposition?> precacheCelebration() =>
    _composition ??= _loadComposition();

Future<LottieComposition?> _loadComposition() async {
  try {
    final data = await rootBundle.load(celebrationLottieAsset);
    return _loaded = await LottieComposition.fromByteData(data);
  } catch (_) {
    return null;
  }
}

/// Forgets the loaded animation. Tests only.
@visibleForTesting
void resetCelebrationForTesting() {
  _composition = null;
  _loaded = null;
}

OverlayEntry? _active;

/// Pops a brief, non-blocking "correct answer" celebration (trophy animation
/// + message card) above the current screen. Only one is ever on screen: a
/// new call replaces the previous one, so the animation always replays from
/// the start even when the user answers faster than it runs.
void showCelebrationOverlay(BuildContext context) {
  dismissCelebrationOverlay();
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _CelebrationBurst(
      onDone: () {
        if (_active == entry) _active = null;
        if (entry.mounted) entry.remove();
      },
    ),
  );
  _active = entry;
  overlay.insert(entry);
}

/// Removes the celebration currently on screen, if any - for when the screen
/// that showed it goes away, so it does not linger over the next one.
void dismissCelebrationOverlay() {
  final entry = _active;
  _active = null;
  if (entry != null && entry.mounted) entry.remove();
}

class _CelebrationBurst extends StatefulWidget {
  final VoidCallback onDone;
  const _CelebrationBurst({required this.onDone});

  @override
  State<_CelebrationBurst> createState() => _CelebrationBurstState();
}

class _CelebrationBurstState extends State<_CelebrationBurst>
    with TickerProviderStateMixin {
  /// How long the card stays up. It matches the animation's own length, and
  /// runs on its own clock so the card always leaves on time, whether or not
  /// the animation has loaded.
  static const _lifetime = Duration(milliseconds: 2500);

  late final AnimationController _life;
  late final AnimationController _lottie;
  LottieComposition? _comp;

  @override
  void initState() {
    super.initState();
    _life = AnimationController(vsync: this, duration: _lifetime)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) widget.onDone();
      })
      ..forward();
    _lottie = AnimationController(vsync: this);
    final ready = _loaded;
    if (ready != null) {
      _play(ready);
    } else {
      precacheCelebration().then((comp) {
        if (mounted && comp != null) setState(() => _play(comp));
      });
    }
  }

  void _play(LottieComposition comp) {
    _comp = comp;
    _lottie.duration = comp.duration;
    if (_lottie.value < 1) _lottie.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reduce-motion users get the finished frame, not the confetti burst.
    if (MediaQuery.of(context).disableAnimations) _lottie.value = 1;
  }

  @override
  void dispose() {
    _life.dispose();
    _lottie.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _life,
          builder: (context, child) {
            final t = _life.value;
            // Pop in over the first ~350ms, hold, fade out over the last 30%.
            final fade = t < 0.7
                ? 1.0
                : (1.0 - ((t - 0.7) / 0.3)).clamp(0.0, 1.0);
            final scale = reduceMotion || t >= 0.14
                ? 1.0
                : Curves.easeOutBack.transform(t / 0.14) * 0.25 + 0.75;
            return Align(
              alignment: const Alignment(0, -0.32),
              child: Opacity(
                opacity: Curves.easeIn.transform(fade),
                child: Transform.scale(scale: scale, child: child),
              ),
            );
          },
          // Not `const`: the card reads the mutable AppColors palette.
          child: _CelebrationCard(composition: _comp, controller: _lottie),
        ),
      ),
    );
  }
}

class _CelebrationCard extends StatelessWidget {
  final LottieComposition? composition;
  final Animation<double> controller;

  const _CelebrationCard({required this.composition, required this.controller});

  /// The trophy is drawn larger than the card is tall at the top and rises
  /// [_artRise] above the card's edge, so its confetti bursts out over the
  /// screen instead of being boxed in by the card.
  static const _artSize = 150.0;
  static const _artRise = 62.0;

  @override
  Widget build(BuildContext context) {
    final comp = composition;
    // Overlay entries sit outside any Scaffold/Material, so Text would fall
    // back to the yellow double-underline debug style without this.
    return Material(
      type: MaterialType.transparency,
      child: Padding(
        padding: const EdgeInsets.only(top: _artRise),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Container(
              width: 220,
              padding: EdgeInsets.fromLTRB(20, _artSize - _artRise + 4, 20, 16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.emerald.withValues(alpha: 0.22),
                    blurRadius: 30,
                    offset: const Offset(0, 12),
                  ),
                ],
                border: Border.all(color: AppColors.mint, width: 1.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'ត្រឹមត្រូវ!',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: AppColors.emerald,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'ធ្វើបានល្អ បន្តទៅមុខទៀត',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: AppColors.slate),
                  ),
                ],
              ),
            ),
            Positioned(
              top: -_artRise,
              child: SizedBox.square(
                dimension: _artSize,
                child: comp != null
                    ? Lottie(
                        composition: comp,
                        controller: controller,
                        frameRate: FrameRate.max,
                        fit: BoxFit.contain,
                      )
                    : Center(child: _Checkmark()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown in place of the trophy until (or if ever) the animation is loaded.
class _Checkmark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.emerald,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.check_rounded, color: Colors.white, size: 38),
    );
  }
}
