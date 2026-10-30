import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../utils.dart';
import 'common.dart';

/// بطاقة مهمة مع Checkbox تفاعلي: التأشير يحدّث الخريطة الحرارية فوراً.
class TaskTile extends StatelessWidget {
  const TaskTile({super.key, required this.task, this.showDate = false});
  final TaskItem task;
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    final meta = [
      task.subject,
      task.type.label,
      if (showDate) formatShort(task.date),
      if (task.minutes != null) formatMinutesOfDay(task.minutes!),
    ].join(' • ');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: CheckboxListTile(
        value: task.done,
        onChanged: (_) => app.toggleTask(task.id),
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: AppColors.accent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.done ? TextDecoration.lineThrough : null,
            color: task.done ? AppColors.muted : AppColors.text,
          ),
        ),
        subtitle: Text(meta, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
        secondary: IconButton(
          tooltip: 'حذف',
          icon: const Icon(Icons.delete_outline, size: 20),
          onPressed: () async {
            if (await confirm(context, 'حذف "${task.title}"؟')) app.deleteTask(task.id);
          },
        ),
      ),
    );
  }
}
