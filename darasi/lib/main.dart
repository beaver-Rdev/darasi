import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'screens/splash_screen.dart';
import 'state.dart';
import 'theme.dart';
import 'timer_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final app = AppState();
  runApp(DarasiApp(app: app, timer: TimerController(app)));
}

class DarasiApp extends StatelessWidget {
  const DarasiApp({super.key, required this.app, required this.timer});
  final AppState app;
  final TimerController timer;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppState>.value(value: app),
        ChangeNotifierProvider<TimerController>.value(value: timer),
      ],
      child: MaterialApp(
        title: 'دراسي',
        debugShowCheckedModeBanner: false,
        // ── RTL كامل: اللغة العربية فقط تفرض الاتجاه من اليمين لليسار على كل الواجهات ──
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: buildTheme(),
        home: const SplashScreen(),
      ),
    );
  }
}
