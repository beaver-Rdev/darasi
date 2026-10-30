import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';
import 'notifications.dart';
import 'utils.dart';

const defaultSubjects = ['رياضيات', 'فيزياء', 'كيمياء', 'أحياء', 'لغة عربية', 'لغة إنجليزية'];

/// حالة التطبيق الكاملة + الحفظ المحلي (shared_preferences).
class AppState extends ChangeNotifier {
  final List<TaskItem> tasks = [];
  final List<StudySession> sessions = [];
  final List<ExamResult> exams = [];
  final List<String> subjects = [...defaultSubjects];
  int _nextId = 1;
  bool loaded = false;

  int newId() => _nextId++;

  // ───────────── التحميل والحفظ ─────────────
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('darasi_data');
      if (raw != null) {
        final m = jsonDecode(raw) as Map<String, dynamic>;
        _nextId = (m['nextId'] as int?) ?? 1;
        subjects
          ..clear()
          ..addAll(((m['subjects'] as List?) ?? defaultSubjects).cast<String>());
        tasks
          ..clear()
          ..addAll(((m['tasks'] as List?) ?? []).map((e) => TaskItem.fromJson(e as Map<String, dynamic>)));
        sessions
          ..clear()
          ..addAll(((m['sessions'] as List?) ?? []).map((e) => StudySession.fromJson(e as Map<String, dynamic>)));
        exams
          ..clear()
          ..addAll(((m['exams'] as List?) ?? []).map((e) => ExamResult.fromJson(e as Map<String, dynamic>)));
      }
    } catch (e) {
      debugPrint('AppState.load failed: $e');
    }
    loaded = true;
    notifyListeners();
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'darasi_data',
        jsonEncode({
          'nextId': _nextId,
          'subjects': subjects,
          'tasks': tasks.map((e) => e.toJson()).toList(),
          'sessions': sessions.map((e) => e.toJson()).toList(),
          'exams': exams.map((e) => e.toJson()).toList(),
        }),
      );
    } catch (e) {
      debugPrint('AppState.save failed: $e');
    }
  }

  void _commit() {
    notifyListeners();
    _save();
  }

  // ───────────── المهام ─────────────
  void addTask(TaskItem t) {
    tasks.add(t);
    _scheduleFor(t);
    _commit();
  }

  void toggleTask(int id) {
    final i = tasks.indexWhere((t) => t.id == id);
    if (i < 0) return;
    tasks[i].done = !tasks[i].done;
    _scheduleFor(tasks[i]);
    _commit();
  }

  void deleteTask(int id) {
    final i = tasks.indexWhere((t) => t.id == id);
    if (i < 0) return;
    Notifier.instance.cancel(id * 2);
    Notifier.instance.cancel(id * 2 + 1);
    tasks.removeAt(i);
    _commit();
  }

  /// تذكير قبل الموعد بـ 10 دقائق، وللاختبارات تذكير إضافي قبلها بيوم.
  void _scheduleFor(TaskItem t) {
    final n = Notifier.instance;
    n.cancel(t.id * 2);
    n.cancel(t.id * 2 + 1);
    if (t.done) return;
    final isExam = t.type == TaskType.exam;
    if (t.minutes == null && !isExam) return;
    final mins = t.minutes ?? 8 * 60;
    final start = DateTime(t.date.year, t.date.month, t.date.day, mins ~/ 60, mins % 60);
    final what = isExam ? 'اختبار' : (t.type == TaskType.lesson ? 'حصة' : 'مذاكرة');
    n.schedule(
      t.id * 2,
      'تذكير: $what ${t.subject}',
      '${t.title} بعد 10 دقائق',
      start.subtract(const Duration(minutes: 10)),
    );
    if (isExam) {
      n.schedule(
        t.id * 2 + 1,
        'اختبار غدًا',
        'اختبار ${t.subject}: ${t.title}',
        start.subtract(const Duration(days: 1)),
      );
    }
  }

  // ───────────── المواد والجلسات والاختبارات ─────────────
  void addSubject(String name) {
    final s = name.trim();
    if (s.isEmpty || subjects.contains(s)) return;
    subjects.add(s);
    _commit();
  }

  void addSession(StudySession s) {
    sessions.add(s);
    _commit();
  }

  void addExam(ExamResult e) {
    exams.add(e);
    _commit();
  }

  void deleteExam(int id) {
    exams.removeWhere((e) => e.id == id);
    _commit();
  }

  // ───────────── الاستعلامات ─────────────
  List<TaskItem> tasksOn(DateTime d) {
    final l = tasks.where((t) => sameDay(t.date, d)).toList();
    l.sort((a, b) => (a.minutes ?? 1440).compareTo(b.minutes ?? 1440));
    return l;
  }

  List<TaskItem> upcomingExams() {
    final today = dateOnly(DateTime.now());
    return tasks
        .where((t) => t.type == TaskType.exam && !t.done && !t.date.isBefore(today))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  /// عدد المهام المنجزة لكل يوم (يغذي الخريطة الحرارية).
  Map<String, int> doneCounts() {
    final m = <String, int>{};
    for (final t in tasks) {
      if (t.done) {
        final k = dayKey(t.date);
        m[k] = (m[k] ?? 0) + 1;
      }
    }
    return m;
  }

  int streak() {
    final counts = doneCounts();
    var d = dateOnly(DateTime.now());
    if ((counts[dayKey(d)] ?? 0) == 0) d = addDays(d, -1);
    var n = 0;
    while ((counts[dayKey(d)] ?? 0) > 0) {
      n++;
      d = addDays(d, -1);
    }
    return n;
  }

  Map<String, int> secondsBySubject(DateTime? since) {
    final m = <String, int>{};
    for (final s in sessions) {
      if (since != null && s.date.isBefore(since)) continue;
      m[s.subject] = (m[s.subject] ?? 0) + s.seconds;
    }
    return m;
  }

  int secondsOn(DateTime d) =>
      sessions.where((s) => sameDay(s.date, d)).fold(0, (a, s) => a + s.seconds);
}
