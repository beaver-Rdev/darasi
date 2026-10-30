import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../notifications.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/logo.dart';
import 'shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    final app = context.read<AppState>();
    await Future.wait([
      app.load(),
      Notifier.instance.init(),
      Future.delayed(const Duration(milliseconds: 1400)),
    ]);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const Shell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const LogoPlaceholder(size: 112),
            const SizedBox(height: 20),
            Text('دراسي', style: t.headlineLarge?.copyWith(fontWeight: FontWeight.w800, color: AppColors.grass)),
            const SizedBox(height: 6),
            Text('تتبّع دراستك بوضوح', style: t.bodyLarge?.copyWith(color: AppColors.muted)),
            const SizedBox(height: 32),
            const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 3)),
          ],
        ),
      ),
    );
  }
}
