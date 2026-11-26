import 'package:flutter/material.dart';

class PageSwitcher extends StatelessWidget {
  final Widget child;
  final int index;

  const PageSwitcher({
    super.key,
    required this.child,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400), // Kecepatan animasi sesuai request
      transitionBuilder: (Widget child, Animation<double> animation) {
        // Gabungan Fade (Memudar) dan Slide (Bergeser)
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.05, 0), // Masuk sedikit dari kanan (5%)
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      // Menggunakan Container dengan ValueKey agar animasi terdeteksi oleh Flutter
      child: Container(
        key: ValueKey<int>(index), // 🔥 Kunci pemicu animasi
        child: child,
      ),
    );
  }
}