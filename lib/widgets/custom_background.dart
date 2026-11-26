import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomBackground extends StatelessWidget {
  final Widget child;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;

  const CustomBackground({
    super.key,
    required this.child,
    this.appBar,
    this.bottomNavigationBar,
  });

  @override
  Widget build(BuildContext context) {
    // Kunci Anti-Belang: Warna Scaffold WAJIB SAMA dengan warna akhir gradient
    const Color mainBackgroundColor = Color(0xFFB9B9B9);

    return Scaffold(
      backgroundColor: mainBackgroundColor, // 1. Warna Dasar (Menutup area bawah)
      resizeToAvoidBottomInset: false, // Mencegah keyboard merusak layout
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      body: Stack(
        children: [
          // 2. Lapisan Gradient (Hanya di bagian atas, menyatu ke warna dasar)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 350.h, // Tinggi gradient
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFFFFFFFF).withOpacity(0.4), // Putih transparan di atas
                    mainBackgroundColor, // HARUS SAMA dengan backgroundColor Scaffold
                  ],
                ),
              ),
            ),
          ),

          // 3. Konten Halaman (Safe Area agar tidak ketabrak poni HP)
          SafeArea(
            child: child,
          ),
        ],
      ),
    );
  }
}