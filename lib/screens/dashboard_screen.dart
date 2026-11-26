import 'dart:convert';
import 'dart:ui'; // Wajib untuk ImageFilter (Blur)
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:animate_do/animate_do.dart';
import '../config.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback onShowLeaderboard;
  final VoidCallback onShowWithdraw;
  final VoidCallback onShowSearch;
  final VoidCallback onShowMission;
  final VoidCallback onShowNotification;
  const DashboardScreen({
    super.key,
    required this.onShowLeaderboard,
    required this.onShowWithdraw,
    required this.onShowSearch,
    required this.onShowMission,
    required this.onShowNotification,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String fixImageUrl(String? url) {
    return AppConfig.fixImageUrl(url);
  }

  String name = "Clipper";
  String? avatarUrl;
  int walletBalance = 0;

  // 🔥 DATA REAL DASHBOARD
  int completedCampaigns = 0;
  String currentLevel = "Newbie";
  String? currentLevelImage; // URL Gambar Badge
  int currentXp = 0;
  int levelProgress = 0;
  int unreadNotifCount = 0;

  List<dynamic> recentActivities = [];
  bool isActivityLoading = true;
  bool isLoading = true;

  // ---------------------------------------------------------------------------
  // VARIABLES: COLORS & STYLES
  // ---------------------------------------------------------------------------
  final Color primaryColor = const Color.fromARGB(255, 71, 71, 71);
  final Color cardWhite = Colors.white;
  final Color textDark = const Color(0xFF1D1D1D);
  final Color textGrey = const Color(0xFF9E9E9E);

  // Warna Khusus
  final Color purpleBg = const Color(0xFFF3F0FF);
  final Color purpleAccent = const Color(0xFF6C5DD3);
  final Color orangeBg = const Color(0xFFFFF8E1);
  final Color orangeAccent = const Color(0xFFFFA000);
  final Color blueBg = const Color(0xFFE3F2FD);
  final Color blueAccent = const Color(0xFF2196F3);
  final Color neonGreen = const Color(0xFFC8FF00);

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
    _fetchRecentActivities();
  }

  // ---------------------------------------------------------------------------
  // FUNCTION: FETCH DATA
  // ---------------------------------------------------------------------------
  Future<void> _fetchDashboardData() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) {
      _logout();
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/dashboard'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['status'] == true) {
          final data = json['data'];

          if (mounted) {
            setState(() {
              name = data['name'] ?? "Clipper";
              avatarUrl = data['avatar'];
              walletBalance =
                  double.tryParse(data['wallet_balance'].toString())?.toInt() ??
                  0;
              completedCampaigns =
                  int.tryParse(data['total_submission'].toString()) ?? 0;
              currentLevel = data['current_level'] ?? "Newbie";
              currentLevelImage = data['current_level_image'];
              currentXp = int.tryParse(data['current_xp'].toString()) ?? 0;
              levelProgress =
                  int.tryParse(data['level_progress_percent'].toString()) ?? 0;
              unreadNotifCount = data['unread_notifications_count'] ?? 0;
              print("------- DEBUG DASHBOARD -------");
              print("Respon Server: $data");
              print("Jumlah Notif Terbaca: $unreadNotifCount");
              isLoading = false;
            });
          }
        }
      } else if (response.statusCode == 401) {
        _logout();
      } else {
        if (mounted) setState(() => isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Sesi Habis. Silakan login ulang."),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  String formatRupiah(int amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp. ',
      decimalDigits: 0,
    ).format(amount);
  }

  Future<void> _fetchRecentActivities() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      // 🔥 Pastikan URL ini benar
      final url = "${AppConfig.baseUrl}/my-active-missions";

      print("🚀 [DASHBOARD] Fetching Activities: $url");

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print("📩 [DASHBOARD] Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        // --- LOGIC DETEKTIF ---
        List<dynamic> dataMentah = [];

        // 1. Cek apakah dibungkus 'data'?
        if (json is Map<String, dynamic> && json.containsKey('data')) {
          dataMentah = json['data'];
        } else if (json is List) {
          dataMentah = json;
        }

        // 2. TAMPILKAN CONTOH DATA DI CONSOLE
        if (dataMentah.isNotEmpty) {
          var sample = dataMentah[0];
          print("🔍 [DASHBOARD] CONTOH DATA AKTIVITAS:");
          print(sample); // <--- INI YANG KITA CARI
          print("🔑 [DASHBOARD] KEYS TERSEDIA: ${sample.keys.toList()}");

          // Cek detail daleman 'campaign' kalau ada
          if (sample['campaign'] != null) {
            print("📦 [DASHBOARD] Isi Campaign: ${sample['campaign']}");
          }
        } else {
          print("⚠️ [DASHBOARD] Data Aktivitas Kosong (Empty List)");
        }

        if (mounted) {
          setState(() {
            recentActivities = dataMentah.take(5).toList();
            isActivityLoading = false;
          });
        }
      } else {
        print("❌ [DASHBOARD] Error: ${response.body}");
        if (mounted) setState(() => isActivityLoading = false);
      }
    } catch (e) {
      print("❌ [DASHBOARD] Exception: $e");
      if (mounted) setState(() => isActivityLoading = false);
    }
  }

  // ---------------------------------------------------------------------------
  // MAIN UI
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB9B9B9),
      body: Stack(
        children: [
          // -----------------------------------------------------------
          // LAYER 1: BACKGROUND APP (Tetap Aman di Belakang)
          // -----------------------------------------------------------
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 350.h,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color.fromARGB(
                      255,
                      255,
                      255,
                      255,
                    ).withOpacity(1), // Neon Green
                    const Color.fromARGB(255, 255, 255, 255).withOpacity(0),
                  ],
                ),
              ),
            ),
          ),

          // -----------------------------------------------------------
          // LAYER 2: CONTENT (Dibungkus RefreshIndicator)
          // -----------------------------------------------------------
          SafeArea(
            child: RefreshIndicator(
              // 👇 FUNGSI UPDATE DATA
              onRefresh: _fetchDashboardData,
              color: const Color(0xFFC8FF00), // Warna Spinner Neon
              backgroundColor: const Color(
                0xFF1E1E1E,
              ), // Background Spinner Gelap

              child: SingleChildScrollView(
                // 👇 WAJIB: Agar bisa ditarik walau konten sedikit
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    SizedBox(height: 30.h),
                    _buildOverviewSection(),
                    SizedBox(height: 20.h),
                    _buildTotalIncomeCard(),
                    SizedBox(height: 20.h),
                    _buildFeaturedSection(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return FadeInDown(
      duration: const Duration(milliseconds: 900),
      delay: const Duration(milliseconds: 700),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Halo, $name",
                style: TextStyle(fontSize: 14.sp, color: textDark),
              ),
              Text(
                "Dashboard",
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w600,
                  color: textDark,
                ),
              ),
            ],
          ),
          // Bagian Header di dashboard_screen.dart
          Container(
            padding: EdgeInsets.all(
              3.w,
            ), // Memberikan jarak antara border dan foto
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // Tetap menggunakan border neonGreen agar terlihat premium
              border: Border.all(
                color: const Color.fromARGB(255, 146, 146, 146),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 20.r,
              backgroundColor: Colors.black,
              // 1. Gunakan fungsi fixImageUrl dari AppConfig
              // Fungsi ini otomatis handle:
              // - Kalau link Google (https://...) -> dikembalikan apa adanya.
              // - Kalau path Laravel (avatars/xx.jpg) -> ditambah domain & /storage/.
              backgroundImage: (avatarUrl != null && avatarUrl!.isNotEmpty)
                  ? NetworkImage(AppConfig.fixImageUrl(avatarUrl))
                  : null,

              // 2. Tampilan cadangan jika foto tidak ada (Inisial Nama)
              child: (avatarUrl == null || avatarUrl!.isEmpty)
                  ? Text(
                      name.isNotEmpty ? name[0].toUpperCase() : "C",
                      style: TextStyle(
                        color: const Color(0xFFC8FF00), // Warna neonGreen kamu
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                      ),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 🔥 OVERVIEW SECTION (UPDATED)
  // ---------------------------------------------------------------------------
  Widget _buildOverviewSection() {
    // Logic dummy untuk Progress Bar
    double campaignProgress = (completedCampaigns % 10) / 10.0;
    if (campaignProgress == 0 && completedCampaigns > 0) campaignProgress = 1.0;
    int nextMilestone = ((completedCampaigns ~/ 10) + 1) * 10;

    return FadeInDown(
      duration: const Duration(milliseconds: 800),
      delay: const Duration(
        milliseconds: 600,
      ), // Berikan delay lebih lama sedikit dari kartu pendapatan
      child: Column(
        children: [
          // ---------------------------------------------
          // 1. BAGIAN ATAS: CARD CAMPAIGN (FULL WIDTH)
          // ---------------------------------------------
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24.r),
              border: Border.all(color: Colors.white, width: 0.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 5,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  height: 50.w,
                  width: 50.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFF252525),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF929292),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 5,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Icon(
                    SolarIconsOutline.clipboardCheck,
                    color: const Color(0xFFC8FF00),
                    size: 24.sp,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Misi Selesai",
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "$completedCampaigns / $nextMilestone",
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.black,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 7,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10.r),
                          child: LinearProgressIndicator(
                            value: campaignProgress,
                            minHeight: 8.h,
                            backgroundColor: Colors.grey[200],
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFFC8FF00),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 16.h),
          _buildQuickActions(),
          SizedBox(height: 16.h),
          // ---------------------------------------------
          // 2. BAGIAN BAWAH: LEVEL & LEADERBOARD
          // ---------------------------------------------
          SizedBox(
            height: 150.h,
            child: Row(
              children: [
                // --- KARTU KIRI: MY LEVEL (SUDAH BERSIH TANPA GAMBAR BLUR) ---
                Expanded(
                  child: FadeInLeft(
                    // 🔥 Tambahkan ini agar meluncur dari kiri
                    duration: const Duration(milliseconds: 800),
                    delay: const Duration(milliseconds: 500),
                    child: Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24.r),
                        border: Border.all(color: Colors.white, width: 0.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 5,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      // 👇 DULU DISINI ADA STACK & POSITIONED, SEKARANG LANGSUNG COLUMN
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "My Level",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.sp,
                                  color: Colors.grey[800],
                                ),
                              ),
                              Icon(
                                SolarIconsOutline.crownStar,
                                color: Colors.orange,
                                size: 20.sp,
                              ),
                            ],
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            currentLevel,
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            "$currentXp XP",
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: Colors.orange,
                              fontWeight: FontWeight.w800,
                            ),
                          ),

                          Expanded(
                            child: SfRadialGauge(
                              axes: <RadialAxis>[
                                RadialAxis(
                                  minimum: 0,
                                  maximum: 100,
                                  showLabels: false,
                                  showTicks: false,
                                  startAngle: 180,
                                  endAngle: 0,
                                  radiusFactor: 1.1,
                                  axisLineStyle: const AxisLineStyle(
                                    thickness: 8,
                                    cornerStyle: CornerStyle.bothCurve,
                                    color: Color(0xFFF0F0F0),
                                  ),
                                  pointers: <GaugePointer>[
                                    RangePointer(
                                      value: levelProgress.toDouble(),
                                      cornerStyle: CornerStyle.bothCurve,
                                      width: 8,
                                      gradient: const SweepGradient(
                                        colors: <Color>[
                                          Color.fromARGB(255, 240, 255, 187),
                                          Color.fromARGB(255, 179, 255, 0),
                                        ],
                                      ),
                                    ),
                                  ],
                                  annotations: <GaugeAnnotation>[
                                    GaugeAnnotation(
                                      angle: 90,
                                      positionFactor: 0.1,
                                      widget: Text(
                                        '$levelProgress%',
                                        style: TextStyle(
                                          fontSize: 18.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                SizedBox(width: 16.w),

                // --- KARTU KANAN: LEADERBOARD ---
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      widget
                          .onShowLeaderboard(); // 🔥 Lapor ke MainScreen untuk ganti index
                    },
                    child: FadeInRight(
                      duration: const Duration(milliseconds: 800),
                      delay: const Duration(milliseconds: 500),
                      child: Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24.r),
                          border: Border.all(color: Colors.white, width: 0.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 5,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Top Rank",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.sp,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.grey,
                                  size: 12.sp,
                                ),
                              ],
                            ),
                            Center(
                              child: Container(
                                height: 60.w,
                                width: 60.w,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF252525),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF929292),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 5,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  SolarIconsOutline.ranking,
                                  size: 32.sp,
                                  color: const Color(0xFFC8FF00),
                                ),
                              ),
                            ),
                            Center(
                              child: Column(
                                children: [
                                  Text(
                                    "Leaderboard",
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  Text(
                                    "Lihat Peringkat",
                                    style: TextStyle(
                                      fontSize: 10.sp,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SISA WIDGET (TIDAK BERUBAH)
  // ---------------------------------------------------------------------------
  Widget _buildTotalIncomeCard() {
    return FadeInUp(
      duration: const Duration(milliseconds: 800),
      delay: const Duration(milliseconds: 600),
      child: GestureDetector(
        onTap: () {
          // Ganti Navigator.push dengan ini:
          widget.onShowWithdraw();
        },
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: const Color(0xFF252525),
            border: Border.all(color: Colors.white, width: 0.5),
            borderRadius: BorderRadius.circular(24.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 5,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Image.asset(
                'assets/images/ic_wallet_3d.png',
                width: 48.w,
                height: 48.w,
                errorBuilder: (c, e, s) =>
                    Icon(SolarIconsBold.wallet, color: neonGreen, size: 48.sp),
              ),
              SizedBox(width: 16.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Total Pendapatan",
                    style: TextStyle(
                      color: const Color.fromARGB(255, 255, 255, 255),
                      fontSize: 12.sp,
                    ),
                  ),
                  Text(
                    formatRupiah(walletBalance),
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFFFFFFF),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Icon(
                Icons.chevron_right,
                color: const Color.fromARGB(255, 0, 0, 0),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildActionItem(SolarIconsOutline.magnifier, "Cari Misi", () {
          widget.onShowSearch(); // 🔥 Panggil pemicu pindah ke Index 2
        }),
        _buildActionItem(SolarIconsOutline.clipboardList, "Laporan", () {
          widget.onShowMission(); // 🔥 Panggil pemicu pindah ke Index 2
        }),
        _buildActionItem(SolarIconsOutline.chatUnread, "Komunitas", () {}),
        _buildActionItem(SolarIconsOutline.bell, "Notifikasi", () {
          widget.onShowNotification();
        }, badgeCount: unreadNotifCount),
      ],
    );
  }

  // 1. Tambahkan parameter {int badgeCount = 0} di akhir
  // Tambahkan parameter {int badgeCount = 0}
  Widget _buildActionItem(
    IconData icon,
    String label,
    VoidCallback onTap, {
    int badgeCount = 0,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Stack(
            // 🔥 Wajib pakai Stack untuk menumpuk angka
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: const Color(0xFF252525),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF929292), width: 2),
                ),
                child: Icon(icon, size: 24.sp, color: neonGreen),
              ),

              // --- INI BADGE NYA ---
              if (badgeCount > 0)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: EdgeInsets.all(4.w),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: BoxConstraints(
                      minWidth: 16.w,
                      minHeight: 16.w,
                    ),
                    child: Text(
                      '$badgeCount',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8.sp,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              color: textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedSection() {
    return FadeInUp(
      duration: const Duration(milliseconds: 800),
      delay: const Duration(milliseconds: 600),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER SECTION
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Aktivitas Terakhir 🔔",
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
              ),
              GestureDetector(
                onTap: () {
                  // Navigasi ke halaman history
                },
                child: Text(
                  "Lihat Semua",
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // ISI KONTEN
          if (isActivityLoading)
            _buildLoadingSpinner()
          else if (recentActivities.isEmpty)
            _buildEmptyActivityState()
          else
            // --- UPDATE DISINI: HAPUS CONTAINER/DECORATION ---
            Column(
              children: recentActivities.asMap().entries.map((entry) {
                int idx = entry.key;
                var item = entry.value;
                bool isLast = idx == recentActivities.length - 1;

                return _buildActivityItem(item, isLast, idx);
              }).toList(),
            ),
        ],
      ),
    );
  }

  // --- WIDGET ITEM PER BARIS ---
  Widget _buildActivityItem(dynamic item, bool isLast, int index) {
    // --- 1. PREPARASI DATA ---
    final String title = item['campaign']?['title'] ?? "Misi Tanpa Judul";
    final String status = item['status'] ?? "pending";
    final String dateStr = item['created_at'] ?? "";

    // Format Tanggal
    String formattedDate = "-";
    if (dateStr.isNotEmpty) {
      try {
        final date = DateTime.parse(dateStr);
        formattedDate = DateFormat("d MMM, HH:mm", "id_ID").format(date);
      } catch (_) {
        formattedDate = dateStr;
      }
    }

    // Format Uang
    final double prizeAmount =
        double.tryParse(item['prize_amount']?.toString() ?? "0") ?? 0;
    final String formattedPrize = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(prizeAmount);

    // Ambil Config Warna dari Helper (yang ada di luar class)
    final statusStyle = _getStatusConfig(status);

    // --- 2. TAMPILAN KARTU (CARD STYLE) ---
    return FadeInUp(
      delay: Duration(milliseconds: 400 * index),
      duration: const Duration(milliseconds: 600),
      child: Container(
        // Margin bawah untuk memberi jarak antar kartu
        margin: EdgeInsets.only(bottom: 12.h),

        // Dekorasi Kartu: Background Putih & Border Radius
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r), // Sudut Melengkung
          border: Border.all(color: Colors.grey[200]!), // Garis tepi tipis
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03), // Bayangan sangat halus
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),

        // Padding di dalam kartu
        padding: EdgeInsets.all(16.w),

        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // A. ICON (Kiri)
            Container(
              width: 42.w,
              height: 42.w,
              decoration: BoxDecoration(
                color: statusStyle.badgeColor.withOpacity(
                  0.3,
                ), // Background icon agak transparan
                shape: BoxShape.circle,
              ),
              child: Icon(
                statusStyle.icon,
                color: statusStyle.iconColor, // Warna icon lebih gelap
                size: 20.sp,
              ),
            ),

            SizedBox(width: 12.w),

            // B. JUDUL & TANGGAL (Tengah)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Icon(
                        SolarIconsOutline.calendarMinimalistic,
                        size: 10.sp,
                        color: Colors.grey[400],
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // C. HARGA & STATUS (Kanan)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formattedPrize,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w800,
                    color: _getAmountColor(status), // Warna uang sesuai status
                  ),
                ),
                SizedBox(height: 6.h),

                // Badge Status Simple
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: statusStyle.badgeColor,
                    borderRadius: BorderRadius.circular(
                      8.r,
                    ), // Radius kecil untuk badge
                  ),
                  child: Text(
                    statusStyle.label,
                    style: TextStyle(
                      fontSize: 9.sp,
                      fontWeight: FontWeight.bold,
                      color: statusStyle.textColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getAmountColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'paid':
        return const Color(0xFF27AE60);
      case 'rejected':
        return const Color(0xFFEB5757);
      default:
        return const Color(0xFF2D3436);
    }
  }

  StatusStyle _getStatusConfig(String status) {
    // Palette Warna
    const neonBrand = Color(0xFFC8FF00);
    const darkGreen = Color(0xFF1B5E20);
    const softRed = Color(0xFFFFEBEE);
    const darkRed = Color(0xFFC62828);
    const softOrange = Color(0xFFFFF3E0);
    const darkOrange = Color(0xFFE65100);
    const softBlue = Color(0xFFE3F2FD);
    const darkBlue = Color(0xFF1565C0);

    switch (status.toLowerCase()) {
      case 'approved':
        return StatusStyle(
          icon: SolarIconsBold.checkCircle,
          iconColor: darkGreen,
          badgeColor: neonBrand,
          textColor: Colors.black,
          label: "Diterima",
        );
      case 'rejected':
        return StatusStyle(
          icon: SolarIconsBold.closeCircle,
          iconColor: darkRed,
          badgeColor: softRed,
          textColor: darkRed,
          label: "Ditolak",
        );
      case 'paid':
        return StatusStyle(
          icon: SolarIconsBold.wadOfMoney,
          iconColor: Colors.blue,
          badgeColor: softBlue,
          textColor: darkBlue,
          label: "Dibayar",
        );
      default: // Pending
        return StatusStyle(
          icon: SolarIconsBold.clockCircle,
          iconColor: Colors.orange,
          badgeColor: softOrange,
          textColor: darkOrange,
          label: "Proses",
        );
    }
  }

  // --- WIDGET HELPER LAIN ---
  Widget _buildLoadingSpinner() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20.h),
        child: CircularProgressIndicator(color: const Color(0xFFC8FF00)),
      ),
    );
  }

  Widget _buildEmptyActivityState() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(SolarIconsOutline.history, size: 40.sp, color: Colors.grey[300]),
          SizedBox(height: 8.h),
          Text(
            "Belum ada aktivitas",
            style: TextStyle(color: Colors.grey[500], fontSize: 12.sp),
          ),
        ],
      ),
    );
  }
}

class StatusStyle {
  final IconData icon;
  final Color iconColor;
  final Color badgeColor;
  final Color textColor;
  final String label;

  StatusStyle({
    required this.icon,
    required this.iconColor,
    required this.badgeColor,
    required this.textColor,
    required this.label,
  });
}
