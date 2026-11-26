import 'package:animate_do/animate_do.dart'; // Untuk animasi masuk
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:solar_icons/solar_icons.dart';
import 'main_screen.dart'; // Pastikan import MainScreen untuk tombol "Go to Home"
import 'package:intl/intl.dart';
import '../widgets/app_background_scaffold.dart';

class WithdrawSuccessScreen extends StatelessWidget {
  final String amount;
  final String finalAmount; // [FIX] Definisi variabel baru
  final String bankName;    // [FIX] Definisi variabel baru

  const WithdrawSuccessScreen({
    super.key, 
    required this.amount, 
    required this.finalAmount, 
    required this.bankName
  });

  @override
  Widget build(BuildContext context) {
    return AppBackgroundScaffold(
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Spacer(),

              // --- 1. ILUSTRASI SUKSES (ANIMATED) ---
              ZoomIn(
                duration: const Duration(milliseconds: 500),
                child: Container(
                  width: 120.w,
                  height: 120.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC8FF00).withValues(alpha: 0.2), // Lime Transparan
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Container(
                      width: 80.w,
                      height: 80.w,
                      decoration: const BoxDecoration(
                        color: Color(0xFFC8FF00), // Lime Solid
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 20,
                            offset: Offset(0, 10),
                          )
                        ],
                      ),
                      child: Icon(
                        SolarIconsBold.checkCircle,
                        size: 40.sp,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 40.h),

              // --- 2. TEKS KETERANGAN ---
              FadeInUp(
                delay: const Duration(milliseconds: 300),
                child: Column(
                  children: [
                    Text(
                      "Withdrawal Berhasil",
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      "Penarikan sebesar ${NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(double.parse(finalAmount.toString()))} \nsedang diproses. Dana akan segera dikirim.", 
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14.sp, color: const Color.fromARGB(255, 41, 41, 41)),
                    ),
                  ],
                ),
              ),

              Spacer(),

              // --- 3. TOMBOL GO TO HOME ---
              FadeInUp(
                delay: const Duration(milliseconds: 600),
                child: GestureDetector(
                  onTap: () {
                    // Kembali ke Main Screen dan hapus semua history halaman sebelumnya
                    // Agar user tidak bisa tekan "Back" ke halaman sukses lagi
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const MainScreen()),
                      (route) => false,
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 18.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC8FF00), // Lime Green
                      borderRadius: BorderRadius.circular(30.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 5,
                          offset: const Offset(0, 5),
                        )
                      ],
                    ),
                    child: Center(
                      child: Text(
                        "Kembali ke Beranda",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 16.sp,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              SizedBox(height: 40.h),
            ],
          ),
        ),
      ),
    );
  }
}