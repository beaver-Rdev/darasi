import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/add_task_sheet.dart';
import '../widgets/common.dart';
import '../widgets/heatmap.dart';
import '../widgets/task_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _subject;
  int _status = 0; // 0 الكل، 1 المتبقية، 2 المنجزة

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final today = dateOnly(DateTime.now());
    final all = app.tasksOn(today);
    final done = all.where((t) => t.done).length;
    final progress = all.isEmpty ? 0.0 : done / all.length;
    final list = all.where((t) {
      final okSubject = _subject == null || t.subject == _subject;
      final okStatus = _status == 0 || (_status == 1 ? !t.done : t.done);
      return okSubject && okStatus;
    }).toList();

    final summary = AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SectionTitle('اليوم، ${formatDate(today)}'),
        Row(children: [
          Expanded(child: _Stat(icon: Icons.check_circle_outline, value: '$done / ${all.length}', label: 'مهام منجزة')),
          Expanded(child: _Stat(icon: Icons.local_fire_department_outlined, value: '${app.streak()}', label: 'أيام متتالية')),
          Expanded(child: _Stat(icon: Icons.timelapse, value: formatDuration(app.secondsOn(today)), label: 'وقت المذاكرة')),
        ]),
        const SizedBox(height: 14),
        LinearProgressIndicator(
          value: progress,
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
          color: AppColors.accent,
          backgroundColor: AppColors.line,
        ),
      ]),
    );

    final heat = AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionTitle('نشاطك الدراسي'),
        Heatmap(counts: app.doneCounts()),
      ]),
    );

    final tasks = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SectionTitle('مهام اليوم'),
      FilterChips(options: app.subjects, selected: _subject, onSelected: (s) => setState(() => _subject = s)),
      const SizedBox(height: 8),
      SegmentedButton<int>(
        showSelectedIcon: false,
        segments: const [
          ButtonSegment<int>(value: 0, label: Text('الكل')),
          ButtonSegment<int>(value: 1, label: Text('المتبقية')),
          ButtonSegment<int>(value: 2, label: Text('المنجزة')),
        ],
        selected: {_status},
        onSelectionChanged: (Set<int> s) => setState(() => _status = s.first),
      ),
      const SizedBox(height: 12),
      if (all.isEmpty)
        const EmptyNote('لا توجد مهام اليوم.\nاضغط "مهمة جديدة" لإضافة أول مهمة.')
      else if (list.isEmpty)
        const EmptyNote('لا توجد مهام مطابقة للفلتر.')
      else
        for (final t in list) TaskTile(task: t),
    ]);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => showAddTaskSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('مهمة جديدة'),
      ),
      body: LayoutBuilder(builder: (context, c) {
        final wide = c.maxWidth >= 900;
        return PageBody(
          maxWidth: 1100,
          child: wide
              ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                    flex: 3,
                    child: Column(children: [summary, const SizedBox(height: 16), heat]),
                  ),
                  const SizedBox(width: 16),
                  Expanded(flex: 2, child: tasks),
                ])
              : Column(children: [summary, const SizedBox(height: 16), heat, const SizedBox(height: 16), tasks]),
        );
      }),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.value, required this.label});
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(children: [
        Icon(icon, color: AppColors.accent),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
      ]);
}
