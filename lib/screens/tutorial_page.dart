import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:solar_icons/solar_icons.dart';
import '../widgets/video_tutorial_player.dart';
import '../config.dart';

class TutorialPage extends StatelessWidget {
  const TutorialPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(SolarIconsOutline.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Video Tutorial",
          style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold),
        ),
      ),
      // 🔥 BODY DIBUNGKUS SingleChildScrollView AGAR BISA DI-SCROLL
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Cara Screen Record Analytics",
                style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10.h),
              Text(
                "Tonton video ini sampai habis untuk memastikan submission kamu diterima oleh admin.",
                style: TextStyle(color: Colors.grey, fontSize: 13.sp),
              ),
              SizedBox(height: 20.h),
              
              // Widget Video Player (Kotak Video)
              const VideoTutorialPlayer(
                videoUrl: AppConfig.videoTutorialUrl,
              ),
              
              SizedBox(height: 30.h),
              
              // Bagian teks langkah-langkah yang bikin panjang
              _buildStepItem("1", "Buka aplikasi TikTok/Instagram/YouTube kamu."),
              _buildStepItem("2", "Masuk ke menu Insight/Analytics pada video terkait."),
              _buildStepItem("3", "Mulai Screen Record dan scroll perlahan pada bagian Views & Watch Time."),
              _buildStepItem("4", "Pastikan ID Akun dan Judul Video terlihat jelas dalam rekaman."),
              
              // Beri ruang ekstra di paling bawah agar item terakhir tidak mepet
              SizedBox(height: 40.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepItem(String number, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12.r,
            backgroundColor: const Color(0xFFC8FF00),
            child: Text(number, style: TextStyle(color: Colors.black, fontSize: 12.sp, fontWeight: FontWeight.bold)),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              text, 
              style: TextStyle(color: Colors.grey[300], fontSize: 13.sp, height: 1.4)
            ),
          ),
        ],
      ),
    );
  }
}