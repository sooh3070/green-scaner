import 'package:flutter/material.dart';
import '../../../core/models/scan_result.dart';

const _verdictColors = <String, Color>{
  '일반쓰레기': Colors.grey,
  '플라스틱': Colors.orange,
  '종이류': Color(0xFF795548),
  '유리': Colors.lightBlue,
  '캔': Color(0xFF607D8B),
  '비닐': Color(0xFFFFEB3B),
  '스티로폼': Color(0xFFEEEEEE),
  '음식물': Colors.green,
  '특수폐기물': Colors.red,
};

class ResultCard extends StatelessWidget {
  const ResultCard({super.key, required this.result});

  final ScanResult result;

  @override
  Widget build(BuildContext context) {
    final color = _verdictColors[result.verdict] ?? Colors.grey;
    final isDark = ThemeData.estimateBrightnessForColor(color) == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: color,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              children: [
                Text(
                  result.verdict,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (result.condition != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    result.condition!,
                    style: TextStyle(color: textColor.withValues(alpha: 0.85), fontSize: 14),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(label: '처리 방법', value: result.action),
                const Divider(height: 24),
                _InfoRow(label: '판단 근거', value: result.reason),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 15)),
      ],
    );
  }
}
