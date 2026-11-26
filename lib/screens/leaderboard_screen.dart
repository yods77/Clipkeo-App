import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:animate_do/animate_do.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:intl/intl.dart';
import '../config.dart';

class LeaderboardScreen extends StatefulWidget {
  final VoidCallback? onBack;

  // 🔥 UPDATE CONSTRUCTOR: Tambahkan {this.onBack}
  const LeaderboardScreen({super.key, this.onBack});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  // VARIABLES
  List<dynamic> leaderboardData = [];
  bool isLoading = true;

  // COLOR PALETTE (Sama dengan Dashboard)
  final Color cardWhite = Colors.white;
  final Color textDark = const Color(0xFF1D1D1D);
  final Color textGrey = const Color(0xFF9E9E9E);
  final Color neonGreen = const Color(0xFFC8FF00);
  final String baseUrl = AppConfig.rawBaseUrl;

  @override
  void initState() {
    super.initState();
    fetchLeaderboard();
  }

  // FUNCTION: FETCH DATA
  Future<void> fetchLeaderboard() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      // 🔥 FIX 1: Gunakan AppConfig.baseUrl (Bukan rawBaseUrl)
      // Pastikan AppConfig.baseUrl kamu sudah berakhiran '/api'
      final String url = "${AppConfig.baseUrl}/leaderboard";

      print("🚀 Fetching Leaderboard: $url"); // Cek URL di Console

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print("📩 Response Status: ${response.statusCode}");
      print("📩 Response Body: ${response.body}"); // Cek isi data di Console

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        if (mounted) {
          setState(() {
            // 🔥 FIX 2: Pastikan mengambil key yang benar ('data')
            // Kalau API kamu membungkusnya dalam 'data', ini benar.
            // Kalau langsung list, ganti jadi: leaderboardData = json;
            leaderboardData = json['data'] ?? [];
            isLoading = false;
          });
        }
      } else {
        print("❌ Gagal ambil data: ${response.statusCode}");
        if (mounted) setState(() => isLoading = false);
      }
    } catch (e) {
      print("❌ Error Exception: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  // HELPER: WARNA TIER (Disesuaikan dengan Tema Green/Clean)
  Color _getTierColor(String tier) {
    switch (tier.toLowerCase()) {
      case 'legend':
        return const Color(0xFFE0F7FA); // Cyan pudar
      case 'master':
        return const Color(0xFFF3F0FF); // Ungu pudar
      case 'star':
        return const Color(0xFFF5F5F5); // Abu pudar
      default: // Newbie
        return neonGreen.withOpacity(0.2); // Hijau Neon pudar
    }
  }

  Color _getTierTextColor(String tier) {
    switch (tier.toLowerCase()) {
      case 'legend':
        return const Color(0xFF006064);
      case 'master':
        return const Color(0xFF6C5DD3);
      case 'star':
        return const Color(0xFF424242);
      default:
        return const Color(0xFF556B2F); // Dark Olive Green
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB9B9B9),
      body: AnimatedSwitcher(
        // 🔥 Biar pas 'isLoading' jadi 'false' transisinya smooth
        duration: const Duration(milliseconds: 400),
        // 🔥 TIDAK PAKAI APPBAR BIASA, TAPI CUSTOM BODY
        child: isLoading
            ? _buildLoadingSpinner()
            : Stack(
                children: [
                  // 🔥 1. BACKGROUND GRADASI (SAMA PERSIS DASHBOARD)
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
                            ).withOpacity(0.6),
                            const Color(0xFFB9B9B9).withOpacity(0),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 🔥 2. KONTEN UTAMA
                  SafeArea(
                    child: Column(
                      children: [
                        // CUSTOM HEADER (Back Button + Title)
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 24.w,
                            vertical: 10.h,
                          ),
                          child: Row(
                            children: [
                              // 1. Tombol Back (FadeInDown + Delay pendek)
                              FadeInLeft(
                                duration: const Duration(milliseconds: 800),
                                delay: const Duration(milliseconds: 200),
                                child: GestureDetector(
                                  onTap: () {
                                    if (widget.onBack != null) {
                                      widget
                                          .onBack!(); // 🔥 Jalankan fungsi dari MainScreen (pindah index)
                                    } else {
                                      Navigator.pop(
                                        context,
                                      ); // Normal push jika dipanggil manual
                                    }
                                  },
                                  child: Container(
                                    padding: EdgeInsets.all(10.w),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 5,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.arrow_back,
                                      size: 20.sp,
                                      color: textDark,
                                    ),
                                  ),
                                ),
                              ),

                              SizedBox(width: 16.w),

                              // 2. Teks Title (FadeInDown + Delay sedikit lebih lama agar muncul berurutan)
                              Expanded(
                                child: FadeInDown(
                                  duration: const Duration(milliseconds: 800),
                                  delay: const Duration(milliseconds: 200),
                                  child: Center(
                                    // Membuat teks tepat di tengah sisa ruang
                                    child: Text(
                                      "Hall of Fame",
                                      style: TextStyle(
                                        fontSize: 20.sp,
                                        fontWeight: FontWeight.bold,
                                        color: textDark,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 40.w),
                            ],
                          ),
                        ),

                        SizedBox(height: 20.h),

                        // HEADER BANNER (Top Clippers) - Desain Web tapi disesuaikan warna App
                        // 🔥 Bungkus dengan FadeInUp
                        FadeInDown(
                          duration: const Duration(milliseconds: 600),
                          delay: const Duration(
                            milliseconds: 400,
                          ), // Muncul setelah Header selesai
                          child: Container(
                            width: double.infinity,
                            margin: EdgeInsets.symmetric(horizontal: 24.w),
                            padding: EdgeInsets.all(20.w),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomLeft,
                                end: Alignment.topRight,
                                colors: [
                                  Colors.white,
                                  const Color.fromARGB(
                                    255,
                                    255,
                                    255,
                                    255,
                                  ).withOpacity(0.4),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(24.r),
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "TOP CLIPPERS",
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      "Leaderboard",
                                      style: TextStyle(
                                        fontSize: 24.sp,
                                        fontWeight: FontWeight.bold,
                                        color: textDark,
                                      ),
                                    ),
                                  ],
                                ),
                                // 🔥 Tambahkan sedikit animasi tambahan pada Icon agar lebih hidup
                                Icon(
                                  SolarIconsBold.ranking,
                                  size: 48.sp,
                                  color: const Color.fromARGB(255, 208, 255, 0),
                                  shadows: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: 20.h),

                        // LIST USER
                        Expanded(
                          child: ListView.builder(
                            padding: EdgeInsets.symmetric(
                              horizontal: 24.w,
                              vertical: 20
                                  .h, // Tambahin dikit biar gak nempel kartu atas
                            ),
                            itemCount: leaderboardData.length,
                            itemBuilder: (context, index) {
                              final user = leaderboardData[index];

                              // 🔥 BUNGKUS DENGAN FADEINUP
                              return FadeInUp(
                                duration: const Duration(milliseconds: 500),
                                // Delay: Mulai di 600ms (setelah kartu utama muncul),
                                // lalu nambah 100ms setiap barisnya
                                delay: Duration(
                                  milliseconds: 600 + (index * 100),
                                ),
                                child: _buildUserTile(user),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // WIDGET: ITEM USER (TILE)
  Widget _buildUserTile(dynamic user) {
    int rank = user['rank'];
    bool isTop3 = rank <= 3;
    bool isMe = user['is_me'] ?? false;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: isMe
            ? neonGreen.withOpacity(0.1)
            : Colors.white, // Highlight Hijau Tipis kalau user sendiri
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          // Border Hijau kalau sendiri, Putih kalau orang lain
          color: isMe ? neonGreen : Colors.transparent,
          width: isMe ? 1.5 : 0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // 1. RANKING NUMBER / ICON
          SizedBox(
            width: 30.w,
            child: isTop3
                ? Icon(
                    SolarIconsBold.ranking,
                    color: rank == 1
                        ? const Color(0xFFFFD700) // Emas
                        : rank == 2
                        ? const Color(0xFFC0C0C0) // Perak
                        : const Color(0xFFCD7F32), // Perunggu
                    size: 28.sp,
                  )
                : Text(
                    "#$rank",
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: textGrey,
                    ),
                    textAlign: TextAlign.center,
                  ),
          ),

          SizedBox(width: 12.w),

          // 2. AVATAR DENGAN BADGE (STACK)
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                ),
                child: CircleAvatar(
                  radius: 22.r,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: user['avatar_url'] != null
                      ? NetworkImage(user['avatar_url'])
                      : null,
                  child: user['avatar_url'] == null
                      ? Icon(SolarIconsBold.user, color: textGrey)
                      : null,
                ),
              ),
              // Badge Level Kecil di Pojok
              if (user['badge_url'] != null)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Image.network(
                    user['badge_url'],
                    width: 18.w,
                    height: 18.w,
                    errorBuilder: (c, e, s) => const SizedBox.shrink(),
                  ),
                ),
            ],
          ),

          SizedBox(width: 12.w),

          // 3. NAMA & TIER
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user['name'] ?? "User",
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: textDark,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isMe) ...[
                      SizedBox(width: 6.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "YOU",
                          style: TextStyle(
                            fontSize: 9.sp,
                            color: neonGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 4.h),
                // Tier Badge (Warna-warni)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: _getTierColor(user['tier_name'] ?? "Newbie"),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    user['tier_name'] ?? "Newbie",
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: _getTierTextColor(user['tier_name'] ?? "Newbie"),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 4. TOTAL XP
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                NumberFormat.compact().format(user['xp']), // Format 1.2K
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
              ),
              Text(
                "XP",
                style: TextStyle(
                  fontSize: 10.sp,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSpinner() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: neonGreen, // Pakai warna neon green Clipsquad lo
            strokeWidth: 3,
          ),
          SizedBox(height: 16.h),
          Text(
            "Memuat peringkat...",
            style: TextStyle(
              color: textGrey,
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
