import 'dart:async';
import 'dart:convert'; // 1. Tambahan: Buat encode JSON
import 'package:http/http.dart' as http; // 2. Tambahan: Buat Tembak API
import 'package:shared_preferences/shared_preferences.dart'; // 3. Tambahan: Ambil Token Login
import '../utils/page_switcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dashboard_screen.dart';
import 'wallet_screen.dart';
import 'notification_screen.dart';
import 'profile_screen.dart';
import 'withdraw_input_screen.dart'; // 🔥 Pastikan jalurnya benar sesuai folder lo
import 'leaderboard_screen.dart';
import 'search_campaign_screen.dart';
import 'mission_screen.dart';
import '../config.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // Index halaman yang sedang aktif
  int _selectedIndex = 0;
  double walletBalance = 0;

  // Variabel untuk menyimpan 'Kuping' Notifikasi
  StreamSubscription<RemoteMessage>? _notifSubscription;

  // Daftar halaman

  @override
  void initState() {
    super.initState();

    _setupNotificationListener();
    _syncBalance();
    _syncFcmTokenToLaravel();
   
  }

  Future<void> _syncBalance() async {
  final prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('token');

  // Debugging: Pastikan token ada
  if (token == null) {
    print("⚠️ TOKEN KOSONG: Tidak bisa tarik saldo.");
    return;
  }

  try {
    // Tembak API Profile
    final response = await http.get(
      Uri.parse("${AppConfig.baseUrl}/user"), // Pastikan AppConfig benar
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      final data = jsonResponse['data'];

      // 🔥 KUNCI KEMENANGAN:
      // Ambil 'wallet_balance'. Jika null/error, ambil 0.
      double saldoServer = double.tryParse(data['wallet_balance'].toString()) ?? 0.0;

      print("✅ SALDO ASLI DARI SERVER: Rp $saldoServer");

      if (mounted) {
        setState(() {
          walletBalance = saldoServer;
        });
      }

      // Simpan ke memori HP biar pas buka lagi gak 0
      await prefs.setDouble('user_balance', saldoServer);
    } else {
      print("❌ GAGAL TARIK SALDO. Status: ${response.statusCode}");
    }
  } catch (e) {
    print("❌ ERROR KONEKSI SALDO: $e");
  }
}

  // --- 🔥 FUNGSI BARU: KIRIM TOKEN KE LARAVEL ---
  Future<void> _syncFcmTokenToLaravel() async {
    try {
      // A. Ambil FCM Token dari Firebase
      String? fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null) return;

      // B. Ambil Token Login (Bearer) dari Memory HP
      final prefs = await SharedPreferences.getInstance();
      final String? authToken = prefs.getString('token');

      if (authToken == null) {
        debugPrint("❌ User belum login, batal setor token.");
        return;
      }

      // C. Tembak API Laravel
      // ⚠️ GANTI IP INI DENGAN IP LAPTOP/SERVER KAMU YANG BENAR
      final url = Uri.parse('${AppConfig.baseUrl}/update-fcm-token');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken', // Auth Sanctum
        },
        body: jsonEncode({'fcm_token': fcmToken}),
      );

      if (response.statusCode == 200) {
        debugPrint("✅ SUKSES: FCM Token tersimpan di Database Laravel!");
      } else {
        debugPrint("❌ GAGAL SYNC: ${response.body}");
      }
    } catch (e) {
      debugPrint("❌ ERROR KONEKSI: $e");
    }
  }

  // --- LOGIKA LISTENER NOTIFIKASI (TIDAK BERUBAH) ---
  void _setupNotificationListener() {
    _notifSubscription?.cancel();

    _notifSubscription = FirebaseMessaging.onMessage.listen((
      RemoteMessage message,
    ) {
      if (!mounted) return;

      if (message.notification != null) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
              side: const BorderSide(color: Color(0xFF333333)),
            ),
            title: Row(
              children: [
                Icon(
                  SolarIconsBold.bell,
                  color: const Color(0xFFC8FF00),
                  size: 24.sp,
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    message.notification!.title ?? "Notifikasi",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            content: Text(
              message.notification!.body ?? "Ada pesan baru masuk.",
              style: TextStyle(color: Colors.grey[300], fontSize: 14.sp),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  if (mounted) Navigator.pop(context);
                },
                child: Text(
                  "Tutup",
                  style: TextStyle(
                    color: const Color(0xFFC8FF00),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _notifSubscription?.cancel();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 1 || index == 6) {
      _syncBalance();
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      DashboardScreen(
        onShowLeaderboard: () => _onItemTapped(5),
        onShowWithdraw: () => _onItemTapped(6),
        onShowSearch: () => _onItemTapped(2),
        onShowMission: () => _onItemTapped(3),
        onShowNotification: () => _onItemTapped(7),
      ), // Index 0
      WalletScreen(onShowWithdraw: () => _onItemTapped(6)),
      SearchCampaignScreen(onBack: () => _onItemTapped(0)),
      MissionScreen(onBack: () => _onItemTapped(0)),
      const ProfileScreen(), // Index 4
      LeaderboardScreen(onBack: () => _onItemTapped(0)),
      WithdrawInputScreen(
        maxBalance: walletBalance, // Ambil variabel saldo lo
        payoutMethods: const [], // Data bank lo
        onBack: () => _onItemTapped(1), // Balik ke Dompet (Index 1)
      ),
      NotificationScreen(onBack: () => _onItemTapped(0)),
    ];
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),

      // --- BODY UTAMA ---
      // --- BODY UTAMA DENGAN ANIMASI ---
      body: PageSwitcher(
        index: _selectedIndex,
        child: _pages[_selectedIndex],
      ),
      // --- TOMBOL TENGAH (PREMIUM SEARCH FAB) ---
      floatingActionButton: Container(
        height: 50.w,
        width: 50.w,
        margin: EdgeInsets.only(top: 10.h),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color.fromARGB(255, 208, 255, 0).withOpacity(0.4),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(255, 36, 36, 36).withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => _onItemTapped(2),
          backgroundColor: const Color(0xFF111111),
          elevation: 0,
          shape: const CircleBorder(),
          child: Icon(
            SolarIconsOutline.magnifier,
            size: 22.sp,
            color: const Color(0xFFC8FF00),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // --- NAVBAR BAWAH (SOLAR ICONS) ---
      bottomNavigationBar: Container(
        height: 75.h,
        decoration: BoxDecoration(
          color: const Color.fromARGB(0, 255, 255, 255),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 8.0,
          color: const Color(0xFF111111),
          elevation: 0,
          surfaceTintColor: Colors.white,
          padding: EdgeInsets.zero,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // --- KIRI ---
                Row(
                  children: [
                    _buildNavItem(
                      0,
                      "Beranda",
                      SolarIconsOutline.home2,
                      SolarIconsBold.home2,
                    ),
                    SizedBox(width: 10.w),
                    _buildNavItem(
                      1,
                      "Dompet",
                      SolarIconsOutline.walletMoney,
                      SolarIconsBold.walletMoney,
                    ),
                  ],
                ),

                // --- SPASI TENGAH ---
                SizedBox(width: 40.w),

                // --- KANAN ---
                Row(
                  children: [
                    _buildNavItem(
                      3,
                      "Submissions",
                      SolarIconsOutline.clipboardList,
                      SolarIconsBold.clipboardList,
                    ),
                    SizedBox(width: 10.w),
                    _buildNavItem(
                      4,
                      "Profil",
                      SolarIconsOutline.user,
                      SolarIconsBold.user,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- HELPER FUNCTION ---
  Widget _buildNavItem(
    int index,
    String label,
    IconData iconOutline,
    IconData iconBold,
  ) {
    bool isActive = _selectedIndex == index;
    if (_selectedIndex == 5 && index == 0) isActive = false;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 70.w,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? iconBold : iconOutline,
              color: isActive ? const Color(0xFFC8FF00) : Colors.grey[400],
              size: 26.sp,
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: TextStyle(
                color: isActive ? const Color(0xFFC8FF00) : Colors.grey[400],
                fontSize: 10.sp,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
