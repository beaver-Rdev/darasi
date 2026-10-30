import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../utils.dart';
import 'common.dart';

Future<void> showAddTaskSheet(BuildContext context, {DateTime? initialDate}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.cream,
    constraints: const BoxConstraints(maxWidth: 560),
    builder: (_) => AddTaskForm(initialDate: initialDate ?? DateTime.now()),
  );
}

class AddTaskForm extends StatefulWidget {
  const AddTaskForm({super.key, required this.initialDate});
  final DateTime initialDate;

  @override
  State<AddTaskForm> createState() => _AddTaskFormState();
}

class _AddTaskFormState extends State<AddTaskForm> {
  final _title = TextEditingController();
  late DateTime _date = dateOnly(widget.initialDate);
  String? _subject;
  TimeOfDay? _time;
  TaskType _type = TaskType.study;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (d != null && mounted) setState(() => _date = dateOnly(d));
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: _time ?? TimeOfDay.now());
    if (t != null && mounted) setState(() => _time = t);
  }

  void _save() {
    final title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'اكتب عنوان المهمة');
      return;
    }
    if (_subject == null) {
      setState(() => _error = 'اختر المادة');
      return;
    }
    final app = context.read<AppState>();
    final time = _time;
    app.addTask(TaskItem(
      id: app.newId(),
      title: title,
      subject: _subject!,
      date: _date,
      minutes: time == null ? null : time.hour * 60 + time.minute,
      type: _type,
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('مهمة جديدة',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextField(controller: _title, decoration: inputDeco('عنوان المهمة', hint: 'مثال: حل تمارين الفصل 3')),
            const SizedBox(height: 16),
            SegmentedButton<TaskType>(
              showSelectedIcon: false,
              segments: [
                for (final t in TaskType.values) ButtonSegment<TaskType>(value: t, label: Text(t.label)),
              ],
              selected: {_type},
              onSelectionChanged: (Set<TaskType> s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: 16),
            const Text('المادة'),
            const SizedBox(height: 6),
            SubjectPicker(selected: _subject, onChanged: (s) => setState(() => _subject = s)),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.event),
                  label: Text(formatDate(_date)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickTime,
                  icon: const Icon(Icons.schedule),
                  label: Text(_time == null ? 'بدون وقت' : _time!.format(context)),
                ),
              ),
              if (_time != null)
                IconButton(onPressed: () => setState(() => _time = null), icon: const Icon(Icons.close)),
            ]),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_error!, style: const TextStyle(color: AppColors.danger)),
              ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _save, child: const Text('حفظ')),
          ],
        ),
      ),
    );
  }
}
