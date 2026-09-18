import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/khmer_numerals.dart';

class ReadinessGauge extends StatelessWidget {
  final double value; // 0..100
  final double size;

  const ReadinessGauge({super.key, required this.value, this.size = 154});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: 12,
              color: const Color(0xFFE5ECE8),
            ),
          ),
          SizedBox(
            width: size,
            height: size,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: (value / 100).clamp(0, 1)),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => CircularProgressIndicator(
                value: v,
                strokeWidth: 12,
                strokeCap: StrokeCap.round,
                backgroundColor: Colors.transparent,
                color: AppColors.emerald,
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${kh(value.round())}%',
                style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w800, color: AppColors.emerald),
              ),
              const Text('ត្រៀមខ្លួន', style: TextStyle(fontSize: 10.5, color: AppColors.slate)),
            ],
          ),
        ],
      ),
    );
  }
}
