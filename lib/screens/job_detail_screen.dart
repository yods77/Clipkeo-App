import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config.dart'; //
import 'submission_form_screen.dart';


/*
|--------------------------------------------------------------------------
| CLASS: JobDetailScreen (SCROLLABLE TAB VERSION)
|--------------------------------------------------------------------------
| Fitur:
| - Tampilan Clean (No Overlay)
| - Tab Deskripsi BISA DI-SCROLL independen
| - Data Lengkap (Deskripsi + Info Tambahan)
*/
class JobDetailScreen extends StatefulWidget {
  final Map<String, dynamic> campaign;

  const JobDetailScreen({super.key, required this.campaign});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen>
    with SingleTickerProviderStateMixin {
  // --- STATE VARIABLES ---
  Map<String, dynamic>? fullDetail;
  bool isLoading = true;
  late TabController _tabController;

  // [PENTING] Pastikan IP ini benar
  final String baseUrl = AppConfig.rawBaseUrl;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    fetchCampaignDetail();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- API FETCH ---
  Future<void> fetchCampaignDetail() async {
    final id = widget.campaign['id'];
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/campaigns/$id'));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['status'] == 'success') {
          if (mounted) {
            setState(() {
              fullDetail = json['data'];
              isLoading = false;
            });
          }
        }
      } else {
        if (mounted) setState(() => isLoading = false);
      }
    } catch (e) {
      print("Error Fetch Detail: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  // --- HELPERS ---
  String formatRupiah(double amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  String fixImageUrl(String? url) {
    return AppConfig.fixImageUrl(url);
  }

  Future<void> _launchDownload(String? url) async {
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Link materi tidak tersedia.")),
      );
      return;
    }
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal membuka link: $url")));
    }
  }

  // --- BUILDER UTAMA ---
  @override
  Widget build(BuildContext context) {
    // 1. Gabungkan Data
    final data = fullDetail ?? widget.campaign;
    // 2. Logika URL Gambar (Anti-Null)
    String? finalImageUrl;
    if (data['image_url'] != null && data['image_url'].toString().isNotEmpty) {
      finalImageUrl = data['image_url'];
    } else if (data['image_path'] != null &&
        data['image_path'].toString().isNotEmpty) {
      finalImageUrl = "${AppConfig.baseUrl}/storage/${data['image_path']}";
    }

    // Fallback ke data halaman sebelumnya
    if (finalImageUrl == null || finalImageUrl.isEmpty) {
      finalImageUrl =
          widget.campaign['image_url'] ?? widget.campaign['thumbnail_url'];
    }

    // C. Hitung Budget & Progress (LOGIKA ANTI-ZERO)
    double remaining =
        double.tryParse(data['remaining_budget'].toString()) ?? 0;

    // 1. Cek dari Data Detail
    double total = double.tryParse(data['reward_amount'].toString()) ?? 0;

    // 2. Fallback: Jika 0, ambil dari Data Search (widget.campaign)
    if (total == 0 && widget.campaign['reward_amount'] != null) {
      total = double.tryParse(widget.campaign['reward_amount'].toString()) ?? 0;
    }

    // 3. Fallback Terakhir: Jika masih 0, minimal sama dengan Sisa Budget
    if (total == 0) {
      total = remaining > 0
          ? remaining
          : 1000000; // Default 1 Juta kalau error semua
    }

    // Hitung Progress
    double progress = (remaining / total).clamp(0.0, 1.0);

    // --- LOGIKA HITUNG MIN. VIEWS CERDAS ---
    String minViewsDisplay = "0";
    String strategy =
        data['distribution_strategy'] ??
        widget.campaign['distribution_strategy'] ??
        'performance_tiered';

    // KASUS 1: Jika Tiered -> Ambil target terkecil dari Rules
    if (strategy == 'performance_tiered' ||
        strategy == 'performance_tiered'.toUpperCase()) {
      try {
        List<dynamic> tiers = [];
        // Ambil rules dari detail atau search (backup)
        var rawRules = data['rules'] ?? widget.campaign['rules'];

        if (rawRules != null) {
          // Parsing JSON
          if (rawRules is String) rawRules = jsonDecode(rawRules);

          if (rawRules is Map && rawRules.containsKey('tiers')) {
            tiers = rawRules['tiers'];
          } else if (rawRules is List) {
            tiers = rawRules;
          }
        }

        // Cari angka terkecil
        if (tiers.isNotEmpty) {
          int minV = -1;
          for (var t in tiers) {
            int v = int.tryParse(t['target_views'].toString()) ?? 0;
            // Jika minV belum diisi (-1) atau ketemu angka yang lebih kecil, update minV
            if (minV == -1 || (v > 0 && v < minV)) {
              minV = v;
            }
          }
          // Format jadi angka ribuan (10.000)
          if (minV != -1) {
            minViewsDisplay = NumberFormat.decimalPattern('id').format(minV);
          }
        }
      } catch (e) {
        print("Error parsing min views tiered: $e");
      }
    }

    // KASUS 2: Jika CPM (atau Tiered gagal parsing) -> Ambil dari kolom database
    if (minViewsDisplay == "0") {
      int mv = int.tryParse(data['min_views'].toString()) ?? 0;
      if (mv == 0)
        mv = int.tryParse(widget.campaign['min_views'].toString()) ?? 0;
      minViewsDisplay = NumberFormat.decimalPattern('id').format(mv);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // --- 1. GAMBAR (NO OVERLAY) ---
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 350.h,
            child: Container(
              color: Colors.grey[900],
              child: Image.network(
                fixImageUrl(finalImageUrl),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image,
                          color: Colors.grey,
                          size: 40.sp,
                        ),
                        Text(
                          "Gagal Load Gambar",
                          style: TextStyle(color: Colors.grey, fontSize: 10.sp),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          // --- 2. KONTEN SCROLLABLE ---
          Positioned.fill(
            child: SingleChildScrollView(
              // Physics ini penting agar scroll halaman utama terasa natural
              physics: const ClampingScrollPhysics(),
              child: Column(
                children: [
                  SizedBox(height: 320.h),

                  // Container Konten Utama
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF000000),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(30.r),
                      ),
                      border: Border(
                        top: BorderSide(color: Colors.white.withOpacity(0.1)),
                      ),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: 24.w,
                      vertical: 24.h,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Kategori Badge
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 6.h,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFC8FF00),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            data['category'] ?? 'Campaign',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 12.sp,
                            ),
                          ),
                        ),
                        SizedBox(height: 12.h),

                        // Judul
                        Text(
                          data['title'] ?? 'Loading...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 8.h),

                        Builder(
                          builder: (context) {
                            // 1. Coba ambil dari data detail (API baru)
                            String? deadline = data['deadline_at'];

                            // 2. Jika di detail kosong/strip, ambil dari data search (API lama)
                            if (deadline == null ||
                                deadline == "-" ||
                                deadline == "null") {
                              deadline = widget.campaign['deadline_at'];
                            }

                            // 3. Tampilkan
                            return Row(
                              children: [
                                Icon(
                                  SolarIconsOutline.calendar,
                                  color: const Color(0xFFC8FF00),
                                  size: 16.sp,
                                ),
                                SizedBox(width: 6.w),
                                Text(
                                  (deadline != null &&
                                          deadline != "-" &&
                                          deadline != "null")
                                      ? "Berakhir: $deadline"
                                      : "Berakhir: Segera Habis",
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 13.sp,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        SizedBox(height: 30.h),

                        // --- STATS CARD (UPDATED) ---
                        Container(
                          padding: EdgeInsets.all(20.w),
                          decoration: BoxDecoration(
                            color: const Color(0xFF252525),
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  // 🔥 UPDATE 1: Tampilkan Total Budget (Bukan Sisa)
                                  // Pastikan variabel 'total' diambil dari 'reward_amount' di Area Dapur
                                  _buildStatItem(
                                    "Total Budget",
                                    formatRupiah(total),
                                    const Color(0xFFC8FF00),
                                  ),

                                  // Min Views (Logika Cerdas yang tadi)
                                  _buildStatItem(
                                    "Min. Views",
                                    minViewsDisplay,
                                    Colors.white,
                                  ),
                                ],
                              ),
                              SizedBox(height: 16.h),

                              // 🔥 UPDATE 2: Tambah Label Persentase agar informatif
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Ketersediaan Budget",
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 11.sp,
                                    ),
                                  ),
                                  // Menampilkan angka persen (misal: 80%)
                                  Text(
                                    "${(progress * 100).toInt()}%",
                                    style: TextStyle(
                                      color: const Color(0xFFC8FF00),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11.sp,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 6.h),

                              // Progress Bar (Visual Sisa Dana)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value:
                                      progress, // Rumus: Sisa / Total (Otomatis memendek jika dana terpakai)
                                  minHeight: 6.h,
                                  backgroundColor: Colors.grey[800],
                                  color: const Color(0xFFC8FF00),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 30.h),

                        // Tabs
                        TabBar(
                          controller: _tabController,
                          labelColor: const Color(0xFFC8FF00),
                          unselectedLabelColor: Colors.grey[600],
                          indicatorColor: const Color(0xFFC8FF00),
                          tabs: const [
                            Tab(text: "Deskripsi"),
                            Tab(text: "Syarat"),
                            Tab(text: "Reward"),
                          ],
                        ),
                        SizedBox(height: 20.h),

                        // --- ISI TABS (Area Scrollable Khusus) ---
                        SizedBox(
                          height: 300.h, // Tinggi area tab tetap segini
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              // 🔥 TAB 1: DESKRIPSI (Sekarang Bisa Scroll) 🔥
                              _buildDescriptionTab(data),

                              // Tab 2: Syarat
                              _buildRequirementsTab(data, minViewsDisplay),

                              // Tab 3: Cara
                              _buildHowToTab(data),
                            ],
                          ),
                        ),

                        SizedBox(height: 80.h), // Extra space di bawah
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- 3. TOMBOL KEMBALI ---
          Positioned(
            top: 40.h,
            left: 24.w,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_back, color: Colors.white, size: 24.sp),
              ),
            ),
          ),

          // --- 4. STICKY BOTTOM BUTTON ---
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                24.w,
                16.h,
                24.w,
                20.h + MediaQuery.of(context).padding.bottom,
              ),
              color: Colors.black,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => _launchDownload(fullDetail?['source_link']),
                    child: Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(15.r),
                      ),
                      child: Icon(
                        SolarIconsOutline.fileDownload,
                        color: Colors.white,
                        size: 24.sp,
                      ),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        List<dynamic> platformsToSend = [];
                        if (data['platform'] is List) {
                          platformsToSend = data['platform'];
                        } else if (widget.campaign['platform'] is List) {
                          platformsToSend = widget.campaign['platform'];
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SubmissionFormScreen(
                              campaignId: widget.campaign['id'],
                              campaignTitle: data['title'],
                              platforms: platformsToSend,
                              defaultCaption:
                                  fullDetail?['required_hashtags'] ??
                                  "#Clipsquad",
                              mentions:
                                  fullDetail?['required_mentions'] ??
                                  widget.campaign['required_mentions'] ??
                                  "-",
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC8FF00),
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(vertical: 18.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.r),
                        ),
                      ),
                      child: Text(
                        "Ambil Misi",
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16.sp,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /*
  |--------------------------------------------------------------------------
  | WIDGET: DESCRIPTION TAB (SCROLLABLE)
  |--------------------------------------------------------------------------
  | Menggunakan SingleChildScrollView agar teks panjang bisa digulir
  | di dalam area TabBarView yang terbatas (300.h).
  */
  Widget _buildDescriptionTab(Map<String, dynamic> data) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(), // Efek memantul saat mentok
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Teks Deskripsi Utama
          Text(
            data['description'] ?? "Tidak ada deskripsi detail.",
            style: TextStyle(
              color: Colors.grey[400],
              height: 1.6,
              fontSize: 14.sp,
            ),
          ),

          SizedBox(height: 20.h),

          // Jarak aman di bawah agar scroll tidak terlalu mepet
          SizedBox(height: 40.h),
        ],
      ),
    );
  }

  /*
  |--------------------------------------------------------------------------
  | WIDGET: REQUIREMENTS TAB (CUSTOM LAYOUT)
  |--------------------------------------------------------------------------
  */
  Widget _buildRequirementsTab(Map<String, dynamic> data, String minViews) {
    // 1. AMBIL DATA MENTIONS (MENTAH)
    String rawMentions = "-";
    if (data['required_mentions'] != null && data['required_mentions'] != "-") {
      rawMentions = data['required_mentions'];
    } else if (widget.campaign['required_mentions'] != null) {
      rawMentions = widget.campaign['required_mentions'];
    }

    // 2. FORMAT MENTIONS (@)
    // Contoh: "clipkeo, rispo" -> "@clipkeo @rispo"
    String displayMentions = rawMentions;
    if (rawMentions != "-") {
      displayMentions = rawMentions
          .split(',')
          .where((e) => e.trim().isNotEmpty)
          .map((e) {
            String s = e.trim();
            return s.startsWith('@') ? s : "@$s";
          })
          .join(" "); // Gabung dengan spasi
    }

    // 3. FORMAT HASHTAGS (#)
    // Contoh: "lucu, viral" -> "#lucu #viral"
    String rawHashtags = data['required_hashtags'] ?? "-";
    String displayHashtags = rawHashtags;
    if (rawHashtags != "-") {
      displayHashtags = rawHashtags
          .split(',')
          .where((e) => e.trim().isNotEmpty)
          .map((e) {
            String s = e.trim();
            return s.startsWith('#') ? s : "#$s";
          })
          .join(" ");
    }
    // Helper: Hilangkan kurung siku & underscore biar rapi
    // Contoh: [tiktok, youtube_shorts] -> TIKTOK, YOUTUBE SHORTS
    String platforms = (data['platform'] ?? [])
        .toString()
        .replaceAll('[', '')
        .replaceAll(']', '')
        .replaceAll('_', ' '); // Ganti underscore jadi spasi

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(bottom: 40.h), // Jarak bawah agar aman scroll
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // BAGIAN 1: Syarat Upload
          Text(
            "Video yang di upload harus wajib memiliki:",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14.sp,
            ),
          ),
          SizedBox(height: 12.h),

          _buildRequirementRow("Hashtag", displayHashtags),
          SizedBox(height: 8.h),
          _buildRequirementRow("Mentions", displayMentions),

          SizedBox(height: 24.h),

          // BAGIAN 2: Platform (BRANDED VERSION)
          Text(
            "Dan video harus berhasil di upload di platform:",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14.sp,
            ),
          ),
          SizedBox(height: 12.h),

          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(
                12.r,
              ), // Lebih melengkung biar modern
              border: Border.all(color: Colors.grey[900]!),
            ),
            child: Wrap(
              spacing: 16.w, // Jarak antar logo ke samping
              runSpacing: 12.h, // Jarak jika platform turun ke baris baru
              children: () {
                List<String> platformList = platforms
                    .split(',')
                    .map((e) => e.trim())
                    .toList();

                return platformList.map((p) => _buildPlatformLogo(p)).toList();
              }(),
            ),
          ),

          SizedBox(height: 24.h),

          // BAGIAN 3: Cara Claim Reward
          Text(
            "CARA CLAIM REWARD",
            style: TextStyle(
              color: const Color(0xFFC8FF00),
              fontWeight: FontWeight.w900,
              fontSize: 14.sp,
            ),
          ),
          SizedBox(height: 12.h),

          _buildStepItem(
            "1",
            Text.rich(
              TextSpan(
                // Style Default (Abu-abu)
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12.sp,
                  height: 1.5,
                ),
                children: [
                  const TextSpan(
                    text: "Pastikan views sudah mencapai target minimum ",
                  ),

                  // 🔥 BAGIAN INI JADI HIJAU & BOLD 🔥
                  TextSpan(
                    text: "$minViews views",
                    style: TextStyle(
                      color: const Color(0xFFC8FF00),
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const TextSpan(text: "."),
                ],
              ),
            ),
          ),
          _buildStepItem(
            "2",
            "Setelah konten nya di upload dan sudah menyentuh views yang diinginkan, submit konten nya dengan cara klik “Ambil Misi” di kampanye yang kamu ikuti. Dilarang “Ambil Misi” disaat views masih dibawah angka views minimum.",
          ),
        ],
      ),
    );
  }

  // Helper Row untuk Hashtag/Mention
  Widget _buildRequirementRow(String label, String value) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[500], fontSize: 11.sp),
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            style: TextStyle(
              color: const Color(0xFFC8FF00),
              fontWeight: FontWeight.bold,
              fontSize: 13.sp,
            ),
          ),
        ],
      ),
    );
  }

  // Helper Row untuk Langkah Claim
  Widget _buildStepItem(String number, dynamic content) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20.w,
            height: 20.w,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: TextStyle(
                color: Colors.white,
                fontSize: 10.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: content is String
                ? Text(
                    content,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12.sp,
                      height: 1.5,
                    ),
                  )
                : content,
          ),
        ],
      ),
    );
  }

  Widget _buildHowToTab(Map<String, dynamic> data) {
    // 🔥 PERBAIKAN UTAMA DISINI 🔥
    // Cek strategi di data detail. Kalau kosong? Ambil dari data Search (widget.campaign).
    // Kalau masih kosong juga? Baru default ke 'performance_tiered'.
    String strategy =
        data['distribution_strategy'] ??
        widget.campaign['distribution_strategy'] ??
        'performance_tiered';

    // Jaga-jaga kalau backend kirim huruf besar "CPM"
    strategy = strategy.toLowerCase();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(bottom: 40.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            "Skema Hadiah",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16.sp,
            ),
          ),
          SizedBox(height: 8.h),

          // Keterangan Dinamis
          Text(
            strategy == 'cpm'
                ? "Misi ini menggunakan sistem CPM (Pay Per View). Kamu akan dibayar untuk setiap 1 view yang kamu dapatkan secara akumulatif."
                : "Misi ini menggunakan sistem Performance Tiered. Reward dibayarkan bertahap saat videomu mencapai target views tertentu.",
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12.sp,
              height: 1.5,
            ),
          ),

          SizedBox(height: 20.h),

          // Logika Pemilihan Tampilan
          if (strategy == 'cpm')
            _buildCPMView(data) // Tampilan ID 42 & 43
          else
            _buildTieredView(data), // Tampilan ID 44 & 45

          SizedBox(height: 24.h),

          // Footer Catatan
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  SolarIconsOutline.infoCircle,
                  color: Colors.grey[500],
                  size: 20.sp,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Catatan:",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13.sp,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        "Payout final ditentukan berdasarkan jumlah views valid yang diverifikasi oleh sistem setelah submission disetujui.",
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12.sp,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCPMView(Map<String, dynamic> data) {
    // 1. Ambil Data Rate (Paksa jadi String dulu baru parse)
    String rawRate = "0";

    if (data['rate_per_view'] != null) {
      rawRate = data['rate_per_view'].toString();
    } else if (widget.campaign['rate_per_view'] != null) {
      rawRate = widget.campaign['rate_per_view'].toString();
    }

    double rate = double.tryParse(rawRate) ?? 0;

    // 2. Formatter Manual (Anti-Bug Locale)
    // 2.0 -> "2.00" -> "2,00"
    String formattedRate = rate.toStringAsFixed(2).replaceAll('.', ',');

    // 3. Ambil Min Claim
    int minClaim = 0;
    if (data['min_views'] != null) {
      minClaim = int.tryParse(data['min_views'].toString()) ?? 0;
    } else if (widget.campaign['min_views'] != null) {
      minClaim = int.tryParse(widget.campaign['min_views'].toString()) ?? 0;
    }

    // Formatter Views
    String formattedViews = NumberFormat.decimalPattern('id').format(minClaim);

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFC8FF00).withOpacity(0.15),
            const Color(0xFF111111),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFC8FF00).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          // Kolom 1: Rate Per View
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "RATE PER VIEW",
                  style: TextStyle(
                    color: const Color(0xFFC8FF00),
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8.h),
                // 🔥 UPDATE: Gunakan FittedBox agar teks tidak kepotong jika terlalu besar
                FittedBox(
                  alignment: Alignment.centerLeft,
                  fit: BoxFit.scaleDown,
                  child: Text(
                    "Rp $formattedRate",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  "Per 1 views",
                  style: TextStyle(color: Colors.grey[400], fontSize: 11.sp),
                ),
              ],
            ),
          ),

          Container(
            width: 1,
            height: 50.h,
            color: Colors.white.withOpacity(0.1),
          ),
          SizedBox(width: 20.w),

          // Kolom 2: Min Claim
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "MIN. CLAIM",
                  style: TextStyle(
                    color: const Color(0xFFC8FF00),
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  formattedViews,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  "Total Views Akumulasi",
                  style: TextStyle(color: Colors.grey[400], fontSize: 11.sp),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /*
  |--------------------------------------------------------------------------
  | FIXED: TIERED VIEW (SUPPORT "tiers" KEY)
  |--------------------------------------------------------------------------
  */
  Widget _buildTieredView(Map<String, dynamic> data) {
    List<dynamic> tiers = [];

    // Parsing Rules
    // Struktur JSON: "rules": { "tiers": [ ... ] }
    if (data['rules'] != null) {
      try {
        var rawRules = (data['rules'] is String)
            ? jsonDecode(data['rules'])
            : data['rules'];

        if (rawRules is Map && rawRules.containsKey('tiers')) {
          tiers = rawRules['tiers']; // Ambil array di dalam key 'tiers'
        } else if (rawRules is List) {
          tiers = rawRules; // Jaga-jaga kalau formatnya langsung array
        }
      } catch (e) {
        print("Error parsing tiers: $e");
      }
    }

    if (tiers.isEmpty) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: const Text(
          "Detail tier belum tersedia.",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          // Header Tabel
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "TARGET VIEWS",
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "HADIAH",
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Divider(color: Colors.white.withOpacity(0.05), height: 1),

          // Looping Tiers
          ...tiers.asMap().entries.map((entry) {
            int index = entry.key;
            var tier = entry.value;
            bool isLast = index == tiers.length - 1;

            if (tier is! Map) return const SizedBox.shrink();

            int views = int.tryParse(tier['target_views'].toString()) ?? 0;
            double reward = double.tryParse(tier['reward'].toString()) ?? 0;

            return Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              decoration: BoxDecoration(
                border: isLast
                    ? null
                    : Border(
                        bottom: BorderSide(
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24.w,
                    height: 24.w,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFC8FF00).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      "${index + 1}",
                      style: TextStyle(
                        color: const Color(0xFFC8FF00),
                        fontWeight: FontWeight.bold,
                        fontSize: 10.sp,
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    "${NumberFormat.decimalPattern('id').format(views)} Views",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13.sp,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    formatRupiah(reward),
                    style: TextStyle(
                      color: const Color(0xFFC8FF00),
                      fontWeight: FontWeight.w900,
                      fontSize: 13.sp,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  /*
  |--------------------------------------------------------------------------
  | FIXED: STAT ITEM (ANTI-ERROR & ROBUST)
  |--------------------------------------------------------------------------
  */
  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey[600], fontSize: 12.sp),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16.sp,
          ),
        ),
      ],
    );
  }

  Widget _buildPlatformLogo(String platform) {
    String assetPath = 'assets/icons/tiktok.png';
    String displayName = platform.trim().toLowerCase();

    if (displayName.contains('tiktok')) {
      assetPath = 'assets/icons/tiktok.png';
      displayName = "Tiktok";
    } else if (displayName.contains('youtube') || displayName.contains('yt')) {
      assetPath = 'assets/icons/youtube.png';
      displayName = "Youtube";
    } else if (displayName.contains('ig') ||
        displayName.contains('instagram')) {
      assetPath = 'assets/icons/instagram.png';
      displayName = "Instagram";
    } else {
      displayName = displayName.isNotEmpty
          ? displayName[0].toUpperCase() + displayName.substring(1)
          : "General";
    }

    return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      // --- LOGO YANG DIBUAT TUMPUL ---
      ClipRRect(
        borderRadius: BorderRadius.circular(8.r), // 🔥 Ini yang bikin LOGO-nya tumpul
        child: Image.asset(
          assetPath,
          width: 22.w, // Sedikit diperbesar agar detail tumpulnya kelihatan
          height: 22.w,
          fit: BoxFit.cover, // PENTING: Agar gambar memenuhi area tumpul
        ),
      ),
      SizedBox(width: 10.w),
      // Teks Nama Platform
      Text(
        displayName,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 13.sp,
        ),
      ),
    ],
  );
}
}
