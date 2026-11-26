import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:animate_do/animate_do.dart';
import 'main_screen.dart'; 

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: Stack(
        children: [
          /** 1. AMBIENT GLOW BACKGROUND (FIXED) **/
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300.w,
              height: 300.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFC8FF00).withOpacity(0.15),
                // [FIX] Baris 'filter' dihapus karena menyebabkan error
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFC8FF00).withOpacity(0.2),
                    blurRadius: 100,
                    spreadRadius: 50,
                  )
                ],
              ),
            ),
          ),
          
          /** 2. CENTER CONTENT **/
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ZoomIn(
                  duration: const Duration(milliseconds: 800),
                  child: Container(
                    width: 100.w,
                    height: 100.w,
                    decoration: BoxDecoration(
                      color: const Color(0xFFC8FF00),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFC8FF00).withOpacity(0.6),
                          blurRadius: 40,
                          spreadRadius: 5,
                        )
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        SolarIconsBold.bolt,
                        size: 50.sp,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 30.h),

                FadeInUp(
                  delay: const Duration(milliseconds: 500),
                  child: Column(
                    children: [
                      Text(
                        "CLIPSQUAD",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28.sp,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3.0,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        "Monetize Your Creativity",
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12.sp,
                          letterSpacing: 1.0,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          /** 3. BOTTOM LOADER **/
          Positioned(
            bottom: 50.h,
            left: 0,
            right: 0,
            child: FadeIn(
              delay: const Duration(milliseconds: 1000),
              child: Center(
                child: SizedBox(
                  width: 25.w,
                  height: 25.w,
                  child: const CircularProgressIndicator(
                    color: Color(0xFFC8FF00),
                    strokeWidth: 2.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}