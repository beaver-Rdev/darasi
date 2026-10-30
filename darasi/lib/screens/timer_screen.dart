import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state.dart';
import '../theme.dart';
import '../timer_controller.dart';
import '../utils.dart';
import '../widgets/common.dart';

/// المؤقت: بومودورو أو ساعة إيقاف، ويسجّل الوقت على المادة المختارة.
class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  static const _periods = ['اليوم', 'هذا الأسبوع', 'الكل'];
  int _period = 0;

  @override
  Widget build(BuildContext context) {
    final t = context.watch<TimerController>();
    final app = context.watch<AppState>();
    final elapsed = t.elapsed;
    final locked = t.running || elapsed > 0;
    final pomodoro = t.mode == TimerMode.pomodoro;
    final canStart = t.phase == Phase.rest || t.subject != null;
    final shown = pomodoro ? t.remaining : elapsed;
    double progress = pomodoro ? elapsed / t.target : (elapsed % 60) / 60;
    if (progress > 1) progress = 1;

    final label = pomodoro
        ? (t.phase == Phase.focus ? 'وقت التركيز' : 'استراحة')
        : (t.subject ?? 'ساعة إيقاف');

    return PageBody(
      maxWidth: 640,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SegmentedButton<TimerMode>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment<TimerMode>(
              value: TimerMode.pomodoro,
              label: Text('بومودورو'),
              icon: Icon(Icons.local_fire_department_outlined),
            ),
            ButtonSegment<TimerMode>(
              value: TimerMode.stopwatch,
              label: Text('ساعة إيقاف'),
              icon: Icon(Icons.timer_outlined),
            ),
          ],
          selected: {t.mode},
          onSelectionChanged: locked ? null : (Set<TimerMode> s) => t.setMode(s.first),
        ),
        const SizedBox(height: 16),
        const Text('المادة'),
        const SizedBox(height: 6),
        SubjectPicker(selected: t.subject, enabled: !locked, onChanged: t.setSubject),
        if (pomodoro) ...[
          const SizedBox(height: 12),
          Wrap(spacing: 8, children: [
            for (final m in const [15, 25, 45, 60])
              ChoiceChip(
                label: Text('$m د'),
                selected: t.focusMin == m,
                onSelected: locked ? null : (bool _) => t.setFocus(m),
              ),
          ]),
        ],
        const SizedBox(height: 16),
        Center(
          child: SizedBox(
            width: 240,
            height: 240,
            child: Stack(alignment: Alignment.center, children: [
              Positioned.fill(
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 10,
                  color: t.phase == Phase.rest ? AppColors.warn : AppColors.accent,
                  backgroundColor: AppColors.line,
                ),
              ),
              Column(mainAxisSize: MainAxisSize.min, children: [
                Text(label, style: const TextStyle(color: AppColors.muted)),
                Text(
                  formatClock(shown),
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                ),
              ]),
            ]),
          ),
        ),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: canStart ? (t.running ? t.pause : t.start) : null,
              icon: Icon(t.running ? Icons.pause : Icons.play_arrow),
              label: Text(t.running ? 'إيقاف مؤقت' : (elapsed > 0 ? 'متابعة' : 'ابدأ')),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: (elapsed > 0 || t.phase == Phase.rest) ? t.finish : null,
              icon: const Icon(Icons.stop_circle_outlined),
              label: const Text('إنهاء وحفظ'),
            ),
          ),
        ]),
        if (!canStart)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('اختر المادة أولاً لتبدأ.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted)),
          ),
        const SizedBox(height: 24),
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SectionTitle('وقت المذاكرة حسب المادة'),
            Wrap(spacing: 8, children: [
              for (var i = 0; i < _periods.length; i++)
                ChoiceChip(
                  label: Text(_periods[i]),
                  selected: _period == i,
                  onSelected: (_) => setState(() => _period = i),
                ),
            ]),
            const SizedBox(height: 8),
            ..._subjectBars(app),
          ]),
        ),
      ]),
    );
  }

  List<Widget> _subjectBars(AppState app) {
    final today = dateOnly(DateTime.now());
    final DateTime? since = _period == 0 ? today : (_period == 1 ? weekStart(today) : null);
    final data = app.secondsBySubject(since).entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (data.isEmpty) return const [EmptyNote('لا توجد جلسات في هذه الفترة.')];
    final maxV = data.first.value;
    final total = data.fold<int>(0, (a, e) => a + e.value);
    return [
      Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text('المجموع: ${formatDuration(total)}', style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      for (final e in data)
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Expanded(child: Text(e.key)),
              Text(formatDuration(e.value), style: const TextStyle(color: AppColors.muted)),
            ]),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: e.value / maxV,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
              color: AppColors.accent,
              backgroundColor: AppColors.line,
            ),
          ]),
        ),
    ];
  }
}
