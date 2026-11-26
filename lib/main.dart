import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'screens/video_splash_screen.dart';
import 'package:firebase_core/firebase_core.dart'; // 1. Import ini
import 'package:firebase_messaging/firebase_messaging.dart'; // 2. Import ini
import 'package:provider/provider.dart'; // 🔥 Import Provider
import 'providers/user_provider.dart'; // 🔥 Import UserProvider yang kita buat tadi

void main() async {
  // 1. Pastikan engine Flutter siap
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // --- TAMBAHAN BARU (Minta Izin) ---
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // 1. Minta izin notifikasi (Wajib buat Android 13+)
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  print('Izin User: ${settings.authorizationStatus}');

  // 2. Tampilkan notifikasi saat aplikasi dibuka (Foreground)
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  final fcmToken = await FirebaseMessaging.instance.getToken();
  print("🔥 TOKEN SAYA: $fcmToken");

  // 2. 🔥 WAJIB: Kunci Orientasi Layar ke Portrait (Berdiri)
  // Supaya desain tidak hancur saat HP dimiringkan
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        // Jika nanti ada provider lain (misal BountyProvider), tinggal tambah di sini
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Setup ScreenUtil
    return ScreenUtilInit(
      designSize: const Size(375, 812), // Ukuran desain acuan
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Clipkeo',

          // Tema Aplikasi
          theme: ThemeData(
            useMaterial3: true,
            // Pastikan kamu sudah add package google_fonts di pubspec.yaml
            textTheme: GoogleFonts.poppinsTextTheme(
              Theme.of(context).textTheme,
            ),
            primaryColor: const Color(0xFFFF6B6B),
            scaffoldBackgroundColor: const Color(0xFFF8F9FD),
          ),

          // Mulai dari Splash Screen Video
          home: const VideoSplashScreen(),
        );
      },
    );
  }
}

// ============================================================================
// BATAS SUCI - KODE DI BAWAH INI ADALAH KODE LAMA ANDA (TIDAK DIHAPUS)
// ============================================================================

/**
 * -- Class: DashboardScreen (Legacy/Backup) --
 * Tampilan Dashboard versi awal. 
 * Catatan: Jika Anda sudah menggunakan 'dashboard_screen.dart' yang terpisah,
 * class ini mungkin tidak terpakai, tapi saya biarkan sesuai permintaan.
 */
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  /**
   * -- Build UI --
   * Merender struktur halaman Dashboard (AppBar, Body, dan ScrollView).
   */
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      // -- AppBar Bagian Atas --
      appBar: AppBar(
        title: const Text(
          "Clipsquad Dashboard",
          style: TextStyle(color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.black87),
            onPressed: () {},
          ),
        ],
      ),

      // -- Body Scrollable --
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Halo, Clipper!",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 5),
            const Text(
              "Overview Harian",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // -- Komponen: Kartu Saldo Utama --
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2E3192), Color(0xFF1BFFFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Total Saldo",
                        style: TextStyle(color: Colors.white70),
                      ),
                      Chip(
                        label: const Text(
                          "GOLD TIER",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        backgroundColor: Colors.amber,
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Rp 25.450.000",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "CPM Aktif: Rp 12.500 (1.25x)",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // -- Komponen: Statistik Kecil (Row) --
            Row(
              children: [
                _buildStatCard(
                  "Views Hari Ini",
                  "12.5K",
                  Icons.remove_red_eye,
                  Colors.blue,
                ),
                const SizedBox(width: 15),
                _buildStatCard(
                  "Estimasi Cuan",
                  "Rp 150rb",
                  Icons.monetization_on,
                  Colors.green,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // -- Komponen: Progress Bar Tier --
            const Text(
              "Menuju Platinum Tier",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: 0.7,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.purple),
              minHeight: 8,
            ),
            const SizedBox(height: 5),
            Text(
              "Kurang 300K views lagi untuk naik level!",
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  /**
   * -- Widget Helper: Stat Card --
   * Membuat kartu statistik kecil secara modular untuk menghindari duplikasi kode.
   */
  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
