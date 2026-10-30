import 'package:flutter/material.dart';
import '../theme.dart';

/// مكان مخصص للشعار (الهيدر + شاشة البداية).
/// لاستبداله: ضع شعارك في assets/images/logo.png بنفس الاسم.
class LogoPlaceholder extends StatelessWidget {
  const LogoPlaceholder({super.key, this.size = 40});
  final double size;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.24),
        child: Image.asset(
          'assets/images/logo.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: size,
            height: size,
            color: AppColors.grass,
            alignment: Alignment.center,
            child: Icon(Icons.menu_book_rounded, color: Colors.white, size: size * 0.55),
          ),
        ),
      );
}
