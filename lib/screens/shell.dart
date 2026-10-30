import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/logo.dart';
import 'exams_screen.dart';
import 'home_screen.dart';
import 'schedule_screen.dart';
import 'timer_screen.dart';

class _Dest {
  const _Dest(this.icon, this.selectedIcon, this.label);
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

const _dests = [
  _Dest(Icons.home_outlined, Icons.home, 'الرئيسية'),
  _Dest(Icons.calendar_month_outlined, Icons.calendar_month, 'الجدول'),
  _Dest(Icons.timer_outlined, Icons.timer, 'المؤقت'),
  _Dest(Icons.school_outlined, Icons.school, 'الاختبارات'),
];

/// الإطار العام: شريط سفلي على الهاتف، وشريط جانبي على الشاشات العريضة.
class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _i = 0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final wide = c.maxWidth >= 720;
      final extended = c.maxWidth >= 1000;
      final body = IndexedStack(
        index: _i,
        children: const [HomeScreen(), ScheduleScreen(), TimerScreen(), ExamsScreen()],
      );
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.cream,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          title: const Row(mainAxisSize: MainAxisSize.min, children: [
            LogoPlaceholder(size: 32),
            SizedBox(width: 10),
            Text('دراسي', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.grass)),
          ]),
        ),
        body: wide
            ? Row(children: [
                NavigationRail(
                  selectedIndex: _i,
                  onDestinationSelected: (i) => setState(() => _i = i),
                  extended: extended,
                  backgroundColor: AppColors.cream,
                  indicatorColor: AppColors.grassLight,
                  labelType: extended ? NavigationRailLabelType.none : NavigationRailLabelType.all,
                  destinations: [
                    for (final d in _dests)
                      NavigationRailDestination(
                        icon: Icon(d.icon),
                        selectedIcon: Icon(d.selectedIcon),
                        label: Text(d.label),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1, color: AppColors.line),
                Expanded(child: body),
              ])
            : body,
        bottomNavigationBar: wide
            ? null
            : NavigationBar(
                selectedIndex: _i,
                onDestinationSelected: (i) => setState(() => _i = i),
                backgroundColor: Colors.white,
                indicatorColor: AppColors.grassLight,
                destinations: [
                  for (final d in _dests)
                    NavigationDestination(
                      icon: Icon(d.icon),
                      selectedIcon: Icon(d.selectedIcon),
                      label: d.label,
                    ),
                ],
              ),
      );
    });
  }
}
