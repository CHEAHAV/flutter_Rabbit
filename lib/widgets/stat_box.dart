import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StatBox extends StatelessWidget {
  final String value;
  final String label;
  final Color? valueColor;

  const StatBox({super.key, required this.value, required this.label, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: valueColor ?? AppColors.ink),
          ),
          const SizedBox(height: 3),
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.slate), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
