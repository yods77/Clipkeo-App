import 'package:flutter/material.dart';

class SmoothRoute extends PageRouteBuilder {
  final Widget page;

  SmoothRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 400), // Kecepatan pindah
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Gabungan Fade dan Scale
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.9, end: 1.0).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic, // Efek melambat di akhir
                  ),
                ),
                child: child,
              ),
            );
          },
        );
}