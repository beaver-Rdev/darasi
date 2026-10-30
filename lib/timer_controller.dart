import 'dart:async';
import 'package:flutter/foundation.dart';
import 'models.dart';
import 'notifications.dart';
import 'state.dart';
import 'utils.dart';

enum TimerMode { pomodoro, stopwatch }

enum Phase { focus, rest }

/// مؤقت يعتمد على الوقت الحقيقي (لا يتأثر لو توقف التطبيق في الخلفية)،
/// ويسجّل وقت كل جلسة على المادة المختارة.
class TimerController extends ChangeNotifier {
  TimerController(this._app);

  final AppState _app;

  TimerMode mode = TimerMode.pomodoro;
  Phase phase = Phase.focus;
  int focusMin = 25;
  int restMin = 5;
  String? subject;
  bool running = false;

  DateTime? _startedAt;
  int _accumulated = 0; // ثواني مضت قبل آخر "إيقاف مؤقت"
  Timer? _ticker;

  int get elapsed =>
      _accumulated + (running && _startedAt != null ? DateTime.now().difference(_startedAt!).inSeconds : 0);

  int get target => mode == TimerMode.pomodoro ? (phase == Phase.focus ? focusMin : restMin) * 60 : 0;

  int get remaining {
    final r = target - elapsed;
    return r < 0 ? 0 : r;
  }

  void setMode(TimerMode m) {
    if (running || elapsed > 0) return;
    mode = m;
    notifyListeners();
  }

  void setFocus(int minutes) {
    if (running || elapsed > 0) return;
    focusMin = minutes;
    notifyListeners();
  }

  void setSubject(String s) {
    if (running || elapsed > 0) return;
    subject = s;
    notifyListeners();
  }

  void start() {
    if (running) return;
    if (phase == Phase.focus && subject == null) return;
    running = true;
    _startedAt = DateTime.now();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    if (mode == TimerMode.pomodoro) {
      final left = target - _accumulated;
      Notifier.instance.schedule(
        timerNotifId,
        phase == Phase.focus ? 'انتهت جلسة التركيز' : 'انتهت الاستراحة',
        phase == Phase.focus ? 'أحسنت! خذ استراحة قصيرة.' : 'هيا نكمل المذاكرة.',
        DateTime.now().add(Duration(seconds: left)),
      );
    }
    notifyListeners();
  }

  void pause() {
    if (!running) return;
    _accumulated = elapsed;
    running = false;
    _startedAt = null;
    _ticker?.cancel();
    Notifier.instance.cancel(timerNotifId);
    notifyListeners();
  }

  /// إنهاء يدوي: يحفظ الوقت المنجز (إن كان 10 ثوانٍ فأكثر) ثم يعيد الضبط.
  void finish() {
    _ticker?.cancel();
    final secs = elapsed;
    if (phase == Phase.focus && secs >= 10 && subject != null) {
      _app.addSession(StudySession(
        subject: subject!,
        date: dateOnly(DateTime.now()),
        seconds: secs,
        mode: mode == TimerMode.pomodoro ? 'بومودورو' : 'ساعة إيقاف',
      ));
    }
    _reset();
  }

  void _reset() {
    running = false;
    _startedAt = null;
    _accumulated = 0;
    phase = Phase.focus;
    Notifier.instance.cancel(timerNotifId);
    notifyListeners();
  }

  void _tick() {
    if (mode == TimerMode.pomodoro && elapsed >= target) {
      _complete();
    } else {
      notifyListeners();
    }
  }

  void _complete() {
    _ticker?.cancel();
    if (phase == Phase.focus && subject != null) {
      _app.addSession(StudySession(
        subject: subject!,
        date: dateOnly(DateTime.now()),
        seconds: target,
        mode: 'بومودورو',
      ));
      phase = Phase.rest;
    } else {
      phase = Phase.focus;
    }
    running = false;
    _startedAt = null;
    _accumulated = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
