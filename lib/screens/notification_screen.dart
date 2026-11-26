import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:animate_do/animate_do.dart'; // 🔥 Tambahkan ini
import '../config.dart';

class NotificationScreen extends StatefulWidget {
  final VoidCallback onBack;
  const NotificationScreen({super.key, required this.onBack});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  // 🔥 Trik PageSwitcher: Ganti bool _isLoading jadi Nullable List
  // null = Sedang Loading (Tampilkan Skeleton)
  // [] = Data Kosong (Tampilkan Pesan Kosong)
  List<dynamic>? _notifications; 

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  // --- 1. AMBIL DATA DARI API ---
  Future<void> _fetchNotifications() async {
    // Paksa jadi null setiap kali fungsi dipanggil biar Skeleton muncul (Anti-Malas)
    if (mounted) setState(() => _notifications = null);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/notifications'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _notifications = json['data'];
          });
        }
      } else {
        if (mounted) setState(() => _notifications = []);
      }
    } catch (e) {
      print("Error fetch notif: $e");
      if (mounted) setState(() => _notifications = []);
    }
  }

  // --- 2. TANDAI SUDAH DIBACA ---
  Future<void> _markAsRead(String id, int index) async {
    if (_notifications == null) return;
    
    if (!_notifications![index]['is_read']) {
      setState(() {
        _notifications![index]['is_read'] = true;
      });

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      try {
        await http.post(
          Uri.parse('${AppConfig.baseUrl}/notifications/$id/read'),
          headers: {'Authorization': 'Bearer $token'},
        );
      } catch (e) {
        print("Gagal mark read: $e");
      }
    }
  }

  // --- 3. HELPER IKON & WARNA (Tetap pakai punya lo) ---
  Widget _buildIcon(String type) {
    IconData iconData;
    Color color;

    if (type.contains('deposit') || type.contains('money')) {
      iconData = SolarIconsBold.walletMoney;
      color = Colors.green;
    } else if (type.contains('withdraw')) {
      iconData = SolarIconsBold.wallet2;
      color = Colors.orange;
    } else if (type.contains('approved') || type.contains('accepted')) {
      iconData = SolarIconsBold.checkCircle;
      color = Colors.blue;
    } else if (type.contains('rejected')) {
      iconData = SolarIconsBold.closeCircle;
      color = Colors.red;
    } else {
      iconData = SolarIconsBold.bell;
      color = Colors.purple;
    }

    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, color: color, size: 24.sp),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Notifikasi",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(SolarIconsOutline.checkCircle, color: Color.fromARGB(255, 0, 47, 255)),
            onPressed: () {
              if (_notifications != null) {
                setState(() {
                  for (var n in _notifications!) n['is_read'] = true;
                });
              }
            },
          )
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // 1. KONDISI LOADING (SKELETON)
    if (_notifications == null) {
      return ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
        itemCount: 6,
        itemBuilder: (context, index) => _buildSkeletonItem(),
      );
    }

    // 2. KONDISI KOSONG
    if (_notifications!.isEmpty) {
      return Center(
        child: FadeInUp(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(SolarIconsOutline.bell, size: 64.sp, color: Colors.grey[300]),
              SizedBox(height: 10.h),
              const Text("Belum ada notifikasi", style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    // 3. KONDISI DATA ADA
    return RefreshIndicator(
      onRefresh: _fetchNotifications,
      color: const Color(0xFFC8FF00),
      child: ListView.builder(
        itemCount: _notifications!.length,
        itemBuilder: (context, index) {
          final notif = _notifications![index];
          final isRead = notif['is_read'];

          return FadeInLeft( // 🔥 Efek transisinya di sini
            duration: const Duration(milliseconds: 300),
            delay: Duration(milliseconds: index * 50),
            child: InkWell(
              onTap: () => _markAsRead(notif['id'].toString(), index),
              child: Container(
                color: isRead ? Colors.white : const Color(0xFFC8FF00).withOpacity(0.05),
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildIcon(notif['type'].toString()),
                    SizedBox(width: 15.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  notif['title'],
                                  style: TextStyle(
                                    fontWeight: isRead ? FontWeight.w600 : FontWeight.w900,
                                    fontSize: 14.sp,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                notif['created_at'],
                                style: TextStyle(color: Colors.grey[500], fontSize: 10.sp),
                              ),
                            ],
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            notif['message'],
                            style: TextStyle(color: Colors.grey[600], fontSize: 12.sp, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                    if (!isRead)
                      Container(
                        margin: EdgeInsets.only(left: 10.w, top: 5.h),
                        width: 8.w, height: 8.w,
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      )
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // 🔥 WIDGET SKELETON (Modern Pulse)
  Widget _buildSkeletonItem() {
    return Pulse(
      infinite: true,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        child: Row(
          children: [
            Container(
              width: 44.w, height: 44.w,
              decoration: BoxDecoration(color: Colors.grey[200], shape: BoxShape.circle),
            ),
            SizedBox(width: 15.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 150.w, height: 12.h, color: Colors.grey[200]),
                  SizedBox(height: 8.h),
                  Container(width: double.infinity, height: 10.h, color: Colors.grey[200]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}