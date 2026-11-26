import 'dart:async'; // 1. WAJIB: Tambah Import ini
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main_screen.dart';
import 'login_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class VideoSplashScreen extends StatefulWidget {
  const VideoSplashScreen({super.key});

  @override
  State<VideoSplashScreen> createState() => _VideoSplashScreenState();
}

class _VideoSplashScreenState extends State<VideoSplashScreen> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  // 2. WAJIB: Variabel untuk "memegang" listener notifikasi
  StreamSubscription<RemoteMessage>? _splashSubscription;

  @override
  void initState() {
    super.initState();
    
    // --- 🔥 TAMBAHAN: SETUP LISTENER DENGAN VARIABLE 🔥 ---
    // Kita masukkan ke variabel _splashSubscription supaya bisa dimatikan nanti
    _splashSubscription = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      
      // Safety Check: Kalau layar sudah tidak aktif, jangan jalankan apa-apa
      if (!mounted) return;

      debugPrint("Pesan Masuk di Splash: ${message.notification?.title}");

      if (message.notification != null) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(message.notification!.title ?? "Notifikasi Baru"),
            content: Text(message.notification!.body ?? "Isi pesan kosong"),
            actions: [
              TextButton(
                onPressed: () {
                   if (mounted) Navigator.pop(context);
                },
                child: const Text("Tutup"),
              ),
            ],
          ),
        );
      }
    });
    // --- 🔥 BATAS AKHIR KODE TAMBAHAN 🔥 ---

    _initializeVideo();
  }

  void _initializeVideo() {
    _controller = VideoPlayerController.asset("assets/videos/splash_video.mp4")
      ..initialize().then((_) {
        // Cek mounted dulu biar aman
        if (mounted) {
          setState(() { _isInitialized = true; });
          _controller.play();
        }
      }).catchError((error) {
        debugPrint("❌ Video Error: $error");
        _navigateToNext(); 
      });

    _controller.addListener(() {
      if (_controller.value.position >= _controller.value.duration) {
        _navigateToNext();
      }
    });
  }

  Future<void> _navigateToNext() async {
    // 3. WAJIB: Matikan Listener SEBELUM pindah halaman (Kunci Anti-Crash)
    await _splashSubscription?.cancel();

    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');

    // Gunakan pushReplacement agar user tidak bisa back ke splash
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => (token != null) ? const MainScreen() : const LoginScreen(),
      ),
    );
  }

  @override
  void dispose() {
    // 4. WAJIB: Pastikan listener mati total saat widget dihancurkan
    _splashSubscription?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: _isInitialized
            ? SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller.value.size.width,
                    height: _controller.value.size.height,
                    child: VideoPlayer(_controller),
                  ),
                ),
              )
            : const CircularProgressIndicator(color: Color(0xFFC8FF00)),
      ),
    );
  }
}