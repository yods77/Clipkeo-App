import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppBackgroundScaffold extends StatelessWidget {
  final Widget child; // Isi halaman (konten)
  final PreferredSizeWidget? appBar; // Opsional: Kalau halaman butuh AppBar
  final Widget? bottomNavigationBar; // Opsional: Kalau butuh Nav Bar bawah

  const AppBackgroundScaffold({
    super.key,
    required this.child,
    this.appBar,
    this.bottomNavigationBar,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB9B9B9), // 1. Warna Dasar Abu Silver
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      extendBodyBehindAppBar: true, // Agar gradient nyambung ke atas
      body: Stack(
        children: [
          // 2. Lapisan Gradient (Sama Persis Dashboard)
          Positioned(
            top: 0, left: 0, right: 0, height: 350.h, // Tinggi gradient
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFFFFFFFF), // Putih Transparan
                    const Color(0xFFB9B9B9), // Abu Silver
                  ],
                ),
              ),
            ),
          ),

          // 3. Konten Halaman (Isi codingan kamu masuk sini)
          SafeArea(
            child: child,
          ),
        ],
      ),
    );
  }
}