import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/common.dart';
import '../widgets/task_tile.dart';

/// خزنة الاختبارات: المادة + الدرجة + الدرجة العظمى (أي رقم) + صورة الورقة.
class ExamsScreen extends StatefulWidget {
  const ExamsScreen({super.key});

  @override
  State<ExamsScreen> createState() => _ExamsScreenState();
}

class _ExamsScreenState extends State<ExamsScreen> {
  String? _subject;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final results = app.exams.where((e) => _subject == null || e.subject == _subject).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final upcoming = app.upcomingExams().where((t) => _subject == null || t.subject == _subject).toList();
    final double? avg = results.isEmpty
        ? null
        : results.map((e) => e.percent).reduce((a, b) => a + b) / results.length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => showAddExamSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('نتيجة اختبار'),
      ),
      body: PageBody(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          FilterChips(options: app.subjects, selected: _subject, onSelected: (s) => setState(() => _subject = s)),
          const SizedBox(height: 16),
          if (upcoming.isNotEmpty) ...[
            const SectionTitle('اختبارات قادمة'),
            for (final t in upcoming) TaskTile(task: t, showDate: true),
            const SizedBox(height: 16),
          ],
          SectionTitle(
            'خزنة الاختبارات',
            trailing: avg == null ? null : Text('المتوسط ${avg.toStringAsFixed(0)}%'),
          ),
          if (results.isEmpty)
            const EmptyNote('لم تضف أي نتيجة بعد.\nاضغط "نتيجة اختبار" لحفظ درجتك وصورة الورقة.')
          else
            for (final e in results) _ExamCard(exam: e),
        ]),
      ),
    );
  }
}

class _ExamCard extends StatelessWidget {
  const _ExamCard({required this.exam});
  final ExamResult exam;

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    final p = exam.percent;
    final color = p >= 85 ? AppColors.accent : (p >= 60 ? AppColors.warn : AppColors.danger);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          _thumb(context),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(exam.subject, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 2),
              Text(formatDate(exam.date), style: const TextStyle(fontSize: 12, color: AppColors.muted)),
              const SizedBox(height: 6),
              Row(children: [
                Text('${fmtNum(exam.score)} / ${fmtNum(exam.max)}', style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: color.withAlpha(30), borderRadius: BorderRadius.circular(12)),
                  child: Text('${p.toStringAsFixed(0)}%', style: TextStyle(color: color, fontWeight: FontWeight.w700)),
                ),
              ]),
            ]),
          ),
          IconButton(
            tooltip: 'حذف',
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              if (await confirm(context, 'حذف هذه النتيجة؟')) app.deleteExam(exam.id);
            },
          ),
        ]),
      ),
    );
  }

  Widget _thumb(BuildContext context) {
    final path = exam.imagePath;
    final box = BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      color: AppColors.cream,
      border: Border.all(color: AppColors.line),
    );
    if (path == null || !File(path).existsSync()) {
      return Container(
        width: 64,
        height: 64,
        decoration: box,
        child: const Icon(Icons.description_outlined, color: AppColors.muted),
      );
    }
    return GestureDetector(
      onTap: () => showDialog<void>(
        context: context,
        builder: (_) => Dialog(child: InteractiveViewer(child: Image.file(File(path)))),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.file(File(path), width: 64, height: 64, fit: BoxFit.cover),
      ),
    );
  }
}

/// ينسخ الصورة إلى مجلد التطبيق الدائم (مجلد الكاميرا المؤقت قد يُمسح).
Future<String> persistImage(String path) async {
  final dir = await getApplicationDocumentsDirectory();
  final dest = File('${dir.path}/exam_${DateTime.now().millisecondsSinceEpoch}.jpg');
  await File(path).copy(dest.path);
  return dest.path;
}

Future<void> showAddExamSheet(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.cream,
      constraints: const BoxConstraints(maxWidth: 560),
      builder: (_) => const _AddExamForm(),
    );

class _AddExamForm extends StatefulWidget {
  const _AddExamForm();

  @override
  State<_AddExamForm> createState() => _AddExamFormState();
}

class _AddExamFormState extends State<_AddExamForm> {
  final _score = TextEditingController();
  final _max = TextEditingController();
  String? _subject;
  DateTime _date = dateOnly(DateTime.now());
  String? _imagePath;
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _score.dispose();
    _max.dispose();
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

  Future<void> _pickImage(ImageSource source) async {
    try {
      final x = await ImagePicker().pickImage(source: source, imageQuality: 85, maxWidth: 1800);
      if (x != null && mounted) setState(() => _imagePath = x.path);
    } catch (_) {
      if (mounted) setState(() => _error = 'تعذّر فتح الصورة، تأكد من الأذونات.');
    }
  }

  Future<void> _save() async {
    final score = parseNum(_score.text);
    final max = parseNum(_max.text);
    if (_subject == null) {
      setState(() => _error = 'اختر المادة');
      return;
    }
    if (score == null || score < 0) {
      setState(() => _error = 'اكتب الدرجة المحصّلة بشكل صحيح');
      return;
    }
    if (max == null || max <= 0) {
      setState(() => _error = 'اكتب الدرجة العظمى (رقم أكبر من صفر)');
      return;
    }
    setState(() {
      _error = null;
      _saving = true;
    });
    final app = context.read<AppState>();
    String? saved = _imagePath;
    if (saved != null) {
      try {
        saved = await persistImage(saved);
      } catch (_) {
        // نكتفي بالمسار الأصلي إن فشل النسخ
      }
    }
    app.addExam(ExamResult(
      id: app.newId(),
      subject: _subject!,
      date: _date,
      score: score,
      max: max,
      imagePath: saved,
    ));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final img = _imagePath;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('نتيجة اختبار',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            const Text('المادة'),
            const SizedBox(height: 6),
            SubjectPicker(selected: _subject, onChanged: (s) => setState(() => _subject = s)),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _score,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: inputDeco('الدرجة المحصّلة'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _max,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: inputDeco('الدرجة العظمى', hint: 'مثال: 20 أو 50 أو 100'),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.event),
              label: Text(formatDate(_date)),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('تصوير الورقة'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('من المعرض'),
                ),
              ),
            ]),
            if (img != null) ...[
              const SizedBox(height: 12),
              Stack(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(File(img), height: 160, width: double.infinity, fit: BoxFit.cover),
                ),
                PositionedDirectional(
                  top: 4,
                  end: 4,
                  child: IconButton.filledTonal(
                    onPressed: () => setState(() => _imagePath = null),
                    icon: const Icon(Icons.close),
                  ),
                ),
              ]),
            ],
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_error!, style: const TextStyle(color: AppColors.danger)),
              ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'جارٍ الحفظ...' : 'حفظ'),
            ),
          ],
        ),
      ),
    );
  }
}
