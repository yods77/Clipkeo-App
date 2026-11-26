import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class VideoTutorialPlayer extends StatefulWidget {
  final String videoUrl;

  const VideoTutorialPlayer({super.key, required this.videoUrl});

  @override
  State<VideoTutorialPlayer> createState() => _VideoTutorialPlayerState();
}

class _VideoTutorialPlayerState extends State<VideoTutorialPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
void initState() {
  super.initState();
  
  print("🔍 DETEKTIF: Memulai inisialisasi video...");
  print("🔗 DETEKTIF: Mencoba akses URL: ${widget.videoUrl}");

  try {
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        print("✅ DETEKTIF: Video Berhasil di-load!");
        setState(() {
          _isInitialized = true;
        });
      }).catchError((error) {
        // Ini akan menangkap jika URL salah atau server mati
        print("❌ DETEKTIF: Gagal load video! Error: $error");
      });
  } catch (e) {
    // Ini menangkap jika kodingannya sendiri yang bikin crash
    print("🚨 DETEKTIF: Terjadi Crash di Kodingan! Pesan: $e");
  }
}

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(color: const Color(0xFFC8FF00).withOpacity(0.5)),
      ),
      child: Column(
        children: [
          // Bagian Video
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(15.r)),
            child: AspectRatio(
              aspectRatio: _controller.value.aspectRatio > 0 ? _controller.value.aspectRatio : 9 / 14,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  _isInitialized
                      ? VideoPlayer(_controller)
                      : const Center(child: CircularProgressIndicator(color: Color(0xFFC8FF00))),
                  
                  // Tombol Play/Pause Melayang
                  Center(
                    child: IconButton(
                      icon: Icon(
                        _controller.value.isPlaying ? Icons.pause_circle : Icons.play_circle,
                        color: const Color(0xFFC8FF00).withOpacity(0.8),
                        size: 50.sp,
                      ),
                      onPressed: () {
                        setState(() {
                          _controller.value.isPlaying ? _controller.pause() : _controller.play();
                        });
                      },
                    ),
                  ),
                  
                  // Progress Bar Tipis di bawah
                  VideoProgressIndicator(_controller, allowScrubbing: true, colors: const VideoProgressColors(playedColor: Color(0xFFC8FF00))),
                ],
              ),
            ),
          ),
          // Judul Tutorial di Bawah Video
          Container(
            padding: EdgeInsets.all(10.w),
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15.r), 
            ),
            child: Text(
              "🎥 TUTORIAL SCREEN RECORD ANALYTICS",
              style: TextStyle(color: Colors.white, fontSize: 10.sp, fontWeight: FontWeight.bold, letterSpacing: 1),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}