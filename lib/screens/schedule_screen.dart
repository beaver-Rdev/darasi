import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/add_task_sheet.dart';
import '../widgets/common.dart';
import '../widgets/task_tile.dart';

/// الجدول الأسبوعي: الأسبوع يبدأ السبت، مع فلترة بالمادة والنوع.
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  DateTime _selected = dateOnly(DateTime.now());
  String? _subject;
  String? _typeLabel;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final start = weekStart(_selected);
    final end = addDays(start, 6);
    final today = dateOnly(DateTime.now());

    final dayTasks = app.tasksOn(_selected).where((t) {
      return (_subject == null || t.subject == _subject) &&
          (_typeLabel == null || t.type.label == _typeLabel);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => showAddTaskSheet(context, initialDate: _selected),
        icon: const Icon(Icons.add),
        label: const Text('إضافة للجدول'),
      ),
      body: PageBody(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            IconButton(
              tooltip: 'الأسبوع السابق',
              icon: const Icon(Icons.chevron_left),
              onPressed: () => setState(() => _selected = addDays(_selected, -7)),
            ),
            Expanded(
              child: Text(
                '${formatShort(start)} – ${formatShort(end)}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            IconButton(
              tooltip: 'الأسبوع التالي',
              icon: const Icon(Icons.chevron_right),
              onPressed: () => setState(() => _selected = addDays(_selected, 7)),
            ),
            IconButton(
              tooltip: 'اليوم',
              icon: const Icon(Icons.today),
              onPressed: () => setState(() => _selected = today),
            ),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: _DayChip(
                  date: addDays(start, i),
                  index: i,
                  selected: sameDay(addDays(start, i), _selected),
                  isToday: sameDay(addDays(start, i), today),
                  tasks: app.tasksOn(addDays(start, i)),
                  onTap: () => setState(() => _selected = addDays(start, i)),
                ),
              ),
          ]),
          const SizedBox(height: 16),
          FilterChips(options: app.subjects, selected: _subject, onSelected: (s) => setState(() => _subject = s)),
          const SizedBox(height: 8),
          FilterChips(
            options: [for (final t in TaskType.values) t.label],
            selected: _typeLabel,
            onSelected: (s) => setState(() => _typeLabel = s),
          ),
          const SizedBox(height: 16),
          SectionTitle('${arabicDays[satIndex(_selected)]}، ${formatDate(_selected)}'),
          if (dayTasks.isEmpty)
            const EmptyNote('لا توجد عناصر في هذا اليوم.')
          else
            for (final t in dayTasks) TaskTile(task: t),
        ]),
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.date,
    required this.index,
    required this.selected,
    required this.isToday,
    required this.tasks,
    required this.onTap,
  });

  final DateTime date;
  final int index;
  final bool selected;
  final bool isToday;
  final List<TaskItem> tasks;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final allDone = tasks.isNotEmpty && tasks.every((t) => t.done);
    final fg = selected ? Colors.white : AppColors.text;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.accent : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isToday ? AppColors.accent : AppColors.line, width: isToday ? 1.6 : 1),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(arabicDays[index], style: TextStyle(fontSize: 11, color: fg)),
            ),
            const SizedBox(height: 2),
            Text('${date.day}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: fg)),
            const SizedBox(height: 4),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: tasks.isEmpty
                    ? Colors.transparent
                    : (allDone ? (selected ? Colors.white : AppColors.accent) : AppColors.warn),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
