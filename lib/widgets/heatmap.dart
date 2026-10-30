import 'package:flutter/material.dart';
import '../theme.dart';
import '../utils.dart';

/// خريطة حرارية بنمط GitHub: أبيض (0 مهام) ← أخضر عشبي داكن (يوم مكثف).
/// تُبنى بالكامل من ودجتات Flutter بدون أي حزمة خارجية.
class Heatmap extends StatelessWidget {
  const Heatmap({super.key, required this.counts});

  /// المفتاح: yyyy-MM-dd ، القيمة: عدد المهام المنجزة.
  final Map<String, int> counts;

  static const double _cell = 14;
  static const double _gap = 3;
  static const double _labelW = 18;

  static Color colorFor(int c) {
    if (c <= 0) return Colors.white;
    final t = (c.clamp(1, 8) - 1) / 7;
    return Color.lerp(AppColors.grassLight, AppColors.grass, t)!;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final avail = c.maxWidth - _labelW;
      final weeks = (avail / (_cell + _gap)).floor().clamp(4, 53).toInt();
      final today = dateOnly(DateTime.now());
      final firstWeek = addDays(weekStart(today), -7 * (weeks - 1));

      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            width: _labelW,
            child: Column(children: [
              for (final l in dayInitials)
                SizedBox(
                  height: _cell + _gap,
                  child: Text(l, style: const TextStyle(fontSize: 10, color: AppColors.muted)),
                ),
            ]),
          ),
          for (var w = 0; w < weeks; w++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: _gap / 2),
              child: Column(children: [
                for (var d = 0; d < 7; d++) _buildCell(addDays(firstWeek, w * 7 + d), today),
              ]),
            ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          const Text('أقل', style: TextStyle(fontSize: 11, color: AppColors.muted)),
          const SizedBox(width: 6),
          for (final v in const [0, 1, 3, 5, 8])
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1.5),
              child: _box(colorFor(v), v == 0),
            ),
          const SizedBox(width: 6),
          const Text('أكثر', style: TextStyle(fontSize: 11, color: AppColors.muted)),
        ]),
      ]);
    });
  }

  Widget _buildCell(DateTime d, DateTime today) {
    if (d.isAfter(today)) {
      return const SizedBox(width: _cell, height: _cell + _gap);
    }
    final n = counts[dayKey(d)] ?? 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: _gap),
      child: Tooltip(
        message: '${formatDate(d)}: $n مهمة منجزة',
        child: _box(colorFor(n), n == 0),
      ),
    );
  }

  Widget _box(Color color, bool bordered) => Container(
        width: _cell,
        height: _cell,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: bordered ? AppColors.line : Colors.transparent),
        ),
      );
}
