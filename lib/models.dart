import 'package:flutter/material.dart';
import 'utils.dart';

enum TaskType { study, lesson, exam }

extension TaskTypeInfo on TaskType {
  String get label => switch (this) {
        TaskType.study => 'مذاكرة',
        TaskType.lesson => 'حصة',
        TaskType.exam => 'اختبار',
      };

  IconData get icon => switch (this) {
        TaskType.study => Icons.menu_book_outlined,
        TaskType.lesson => Icons.class_outlined,
        TaskType.exam => Icons.quiz_outlined,
      };
}

class TaskItem {
  TaskItem({
    required this.id,
    required this.title,
    required this.subject,
    required this.date,
    this.minutes,
    this.type = TaskType.study,
    this.done = false,
  });

  final int id;
  String title;
  String subject;
  DateTime date;
  int? minutes; // الوقت بالدقائق من منتصف الليل (اختياري)
  TaskType type;
  bool done;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subject': subject,
        'date': dayKey(date),
        'minutes': minutes,
        'type': type.index,
        'done': done,
      };

  factory TaskItem.fromJson(Map<String, dynamic> j) => TaskItem(
        id: j['id'] as int,
        title: j['title'] as String,
        subject: j['subject'] as String,
        date: DateTime.parse(j['date'] as String),
        minutes: j['minutes'] as int?,
        type: TaskType.values[j['type'] as int],
        done: j['done'] as bool,
      );
}

class StudySession {
  StudySession({
    required this.subject,
    required this.date,
    required this.seconds,
    required this.mode,
  });

  final String subject;
  final DateTime date;
  final int seconds;
  final String mode;

  Map<String, dynamic> toJson() => {
        'subject': subject,
        'date': dayKey(date),
        'seconds': seconds,
        'mode': mode,
      };

  factory StudySession.fromJson(Map<String, dynamic> j) => StudySession(
        subject: j['subject'] as String,
        date: DateTime.parse(j['date'] as String),
        seconds: j['seconds'] as int,
        mode: j['mode'] as String,
      );
}

class ExamResult {
  ExamResult({
    required this.id,
    required this.subject,
    required this.date,
    required this.score,
    required this.max,
    this.imagePath,
  });

  final int id;
  final String subject;
  final DateTime date;
  final double score;
  final double max; // الدرجة العظمى: أي رقم، وليست مقفولة على 100
  final String? imagePath;

  double get percent => max <= 0 ? 0.0 : score / max * 100;

  Map<String, dynamic> toJson() => {
        'id': id,
        'subject': subject,
        'date': dayKey(date),
        'score': score,
        'max': max,
        'image': imagePath,
      };

  factory ExamResult.fromJson(Map<String, dynamic> j) => ExamResult(
        id: j['id'] as int,
        subject: j['subject'] as String,
        date: DateTime.parse(j['date'] as String),
        score: (j['score'] as num).toDouble(),
        max: (j['max'] as num).toDouble(),
        imagePath: j['image'] as String?,
      );
}
