import 'dart:async'; // Untuk Debouncer
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:animate_do/animate_do.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'job_detail_screen.dart';
import '../config.dart';
import '../widgets/app_background_scaffold.dart';
import 'package:clipkeo/utils/route_animation.dart';

/*
|--------------------------------------------------------------------------
| CLASS: SearchCampaignScreen (DYNAMIC CATEGORY VERSION)
|--------------------------------------------------------------------------
| Fitur:
| 1. Search Real-time (Debounce 500ms)
| 2. Filter Kategori Dinamis (Ambil dari Database)
| 3. Tampilan Dark Elite Premium
*/
class SearchCampaignScreen extends StatefulWidget {
  final VoidCallback onBack;
  const SearchCampaignScreen({super.key, required this.onBack});

  @override
  State<SearchCampaignScreen> createState() => _SearchCampaignScreenState();
}

class _SearchCampaignScreenState extends State<SearchCampaignScreen> {
  // --- STATE VARIABLES ---
  List<dynamic> campaigns = [];
  List<String> categoryList = ['Semua']; // Default category
  bool isLoading = true;
  bool isCategoryLoading = true; // Loading khusus kategori

  // Controller Search
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  // Filter Aktif
  String _selectedCategory = "Semua";
  String _searchKeyword = "";

  // [PENTING] Ganti IP ini sesuai IP Laptop Bosku
  final String baseUrl = AppConfig.baseUrl;

  @override
  void initState() {
    super.initState();
    fetchCategories(); // 1. Ambil Kategori Dulu
    fetchCampaigns(); // 2. Ambil Data Campaign
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  /*
  |--------------------------------------------------------------------------
  | API 1: AMBIL KATEGORI (FIXED VERSION)
  |--------------------------------------------------------------------------
  */
  Future<void> fetchCategories() async {
    try {
      // 1. Request ke Server
      final url = Uri.parse('${AppConfig.baseUrl}/categories');
      print("🚀 REQUEST CATEGORIES: $url"); // Cek URL

      final response = await http.get(url);

      print("📦 CAT STATUS: ${response.statusCode}");
      print("📦 CAT BODY: ${response.body}"); // Cek isi datanya

      if (response.statusCode == 200) {
        final dynamic decoded = json.decode(response.body);
        List<dynamic> rawList = [];

        // --- LOGIKA PARSING PINTAR ---
        // Cek apakah formatnya List [...] atau Map { "data": [...] }
        if (decoded is List) {
          rawList = decoded;
        } else if (decoded is Map<String, dynamic>) {
          if (decoded.containsKey('data') && decoded['data'] is List) {
            rawList = decoded['data'];
          } else {
            // Kadang Laravel kirim { "0": {...}, "1": {...} } (Object bukan List)
            // Kita paksa ubah jadi List values
            rawList = decoded.values.toList();
          }
        }

        // Ambil field 'name' dari setiap item
        List<String> loadedCategories = [];

        for (var item in rawList) {
          // Pastikan item punya key 'name' dan tidak null
          if (item is Map && item['name'] != null) {
            loadedCategories.add(item['name'].toString());
          }
          // Jaga-jaga kalau isinya langsung String ["Teknologi", "Masak"]
          else if (item is String) {
            loadedCategories.add(item);
          }
        }

        if (mounted) {
          setState(() {
            List<String> tempCategories = ['Semua', ...loadedCategories];

            // 2. 🔥 JURUS ANTI DUPLIKAT 🔥
            // .toSet() akan membuang kata yang sama persis
            // .toList() mengembalikan lagi jadi List
            categoryList = tempCategories.toSet().toList();

            isCategoryLoading = false;
          });
        }
      } else {
        print("❌ Gagal ambil kategori: ${response.statusCode}");
        if (mounted) setState(() => isCategoryLoading = false);
      }
    } catch (e) {
      print("❌ Error Kategori: $e");
      if (mounted) setState(() => isCategoryLoading = false);
    }
  }

  /*
  |--------------------------------------------------------------------------
  | API 2: AMBIL CAMPAIGNS (PERBAIKAN: URL & PARSING)
  |--------------------------------------------------------------------------
  */
  Future<void> fetchCampaigns() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      // Bangun Query Parameter
      String queryParams = "?category=$_selectedCategory";
      if (_searchKeyword.isNotEmpty) {
        queryParams += "&search=$_searchKeyword";
      }

      // 🔥 FIX 1: HAPUS '/api' KARENA BASEURL SUDAH ADA '/api'
      // Dari: '$baseUrl/api/campaigns' -> Jadi: '$baseUrl/campaigns'
      final url = Uri.parse('$baseUrl/campaigns$queryParams');

      print("🚀 REQUEST URL: $url"); // Cek Console untuk lihat URL benar

      final response = await http.get(
        url,
        headers: {"Accept": "application/json"},
      );

      print("📦 STATUS: ${response.statusCode}");
      print("📦 BODY: ${response.body}");

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        List<dynamic> resultList = [];

        // 🔥 FIX 2: LOGIKA PARSING PINTAR (ANTI-MACET)
        // Kita cek berbagai kemungkinan format dari Laravel
        if (decoded is Map<String, dynamic>) {
          if (decoded.containsKey('data') && decoded['data'] is List) {
            resultList = decoded['data']; // Format: { "data": [...] }
          } else if (decoded['status'] == 'success' &&
              decoded.containsKey('data')) {
            resultList =
                decoded['data']; // Format: { "status": "success", "data": ... }
          }
        } else if (decoded is List) {
          resultList = decoded; // Format: [ ... ] (Langsung List)
        }

        if (mounted) {
          setState(() {
            campaigns = resultList;
            isLoading = false;
          });
        }
      } else {
        print("❌ API Error: ${response.statusCode}");
        if (mounted) setState(() => isLoading = false);
      }
    } catch (e) {
      print("❌ Connection Error: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  // --- LOGIKA SEARCH INPUT (DEBOUNCER) ---
  void _onSearchChanged(String query) {
    // Batalkan timer sebelumnya jika user masih mengetik
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // Tunggu 500ms setelah user berhenti mengetik
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchKeyword = query; // Simpan kata kunci
      });
      fetchCampaigns(); // Panggil API
    });
  }

  // --- LOGIKA GANTI KATEGORI ---
  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
    });
    fetchCampaigns(); // Reload data sesuai kategori baru
  }

  // --- HELPERS ---
  String fixImageUrl(String? url) {
    return AppConfig.fixImageUrl(url);
  }

  String formatRupiah(double amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return AppBackgroundScaffold(
      child: Stack(
        children: [
          // Background Gradient
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 300.h,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFFFFFFFF).withOpacity(0.3),
                    const Color(0xFFB9B9B9).withOpacity(0),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // HEADER
                FadeInDown(
                  duration: const Duration(milliseconds: 600),
                  delay: const Duration(milliseconds: 200),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      24.w,
                      20.h,
                      24.w,
                      10.h,
                    ), // Jarak standar wallet
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Spacer kiri agar teks tepat di tengah
                        SizedBox(width: 45.w),

                        Text(
                          "Cari Campaign",
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        // Spacer kanan sebagai penyeimbang
                        SizedBox(width: 45.w),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 10.h),

                // SEARCH BAR
                FadeInDown(
                  duration: const Duration(milliseconds: 600),
                  delay: const Duration(
                    milliseconds: 200,
                  ), // Muncul setelah header
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 5,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged:
                            _onSearchChanged, // 🔥 INPUT BERFUNGSI DISINI
                        decoration: InputDecoration(
                          hintText: "Cari brand atau misi...",
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14.sp,
                          ),
                          border: InputBorder.none,
                          icon: Icon(
                            SolarIconsOutline.magnifier,
                            color: Colors.black,
                          ),
                          suffixIcon: _searchKeyword.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.close,
                                    size: 18.sp,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    _onSearchChanged('');
                                  },
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 20.h),

                // --- KATEGORI DINAMIS (UPDATED HERE) ---
                FadeInDown(
                  duration: const Duration(milliseconds: 600),
                  delay: const Duration(
                    milliseconds: 200,
                  ), // Muncul setelah search bar
                  child: SizedBox(
                    height: 45.h,
                    child: isCategoryLoading
                        ? Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: const Color(0xFF000000),
                              ),
                            ),
                          )
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: EdgeInsets.symmetric(horizontal: 24.w),
                            itemCount: categoryList.length,
                            itemBuilder: (context, index) {
                              return _buildFilterChip(categoryList[index]);
                            },
                          ),
                  ),
                ),
                SizedBox(height: 20.h),
                Expanded(
                  child: isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: const Color(0xFFC8FF00),
                          ),
                        )
                      : campaigns.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: EdgeInsets.symmetric(
                            horizontal: 24.w,
                            vertical: 10.h,
                          ),
                          itemCount: campaigns.length,
                          itemBuilder: (context, index) {
                            return FadeInUp(
                              duration: const Duration(milliseconds: 600),
                              delay: Duration(milliseconds: 500 * index),
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    SmoothRoute(
                                      page: JobDetailScreen(
                                        campaign: campaigns[index],
                                      ),
                                    ),
                                  );
                                },
                                child: _buildDarkEliteCard(campaigns[index]),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    bool isSelected = _selectedCategory == label;
    return GestureDetector(
      onTap: () => _onCategorySelected(label),
      child: Container(
        margin: EdgeInsets.only(right: 10.w),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF252525) : Colors.white,
          borderRadius: BorderRadius.circular(30.r),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey[300]!,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFC8FF00).withOpacity(0.4),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: isSelected ? const Color(0xFFC8FF00) : Colors.black54,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDarkEliteCard(Map<String, dynamic> item) {
    // --- 1. Fungsi Helper untuk Icon & Format Nama ---
    Widget _buildPlatformBadge(String platform) {
      String assetPath = 'assets/icons/tiktok.png';
      String displayName = platform.toLowerCase();

      // Logika Ikon & Format Nama
      if (displayName.contains('tiktok')) {
        assetPath = 'assets/icons/tiktok.png';
        displayName = "Tiktok";
      } else if (displayName.contains('youtube') ||
          displayName.contains('yt')) {
        assetPath =
            'assets/icons/youtube.png'; // Sesuaikan dengan nama file kamu
        displayName = "Youtube";
      } else if (displayName.contains('ig') ||
          displayName.contains('instagram')) {
        assetPath = 'assets/icons/instagram.png';
        displayName = "Instagram";
      } else {
        // Fallback jika ada platform lain, kapitalisasi huruf pertama
        displayName = displayName[0].toUpperCase() + displayName.substring(1);
      }

      return Container(
        margin: EdgeInsets.only(right: 12.w), // Jarak antar platform
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(
                20.r,
              ), // Atur kehalusan sudut di sini
              child: Container(
                padding: EdgeInsets.all(1.w), // Beri sedikit ruang napas
                color: Colors.white.withOpacity(
                  0.05,
                ), // Background tipis agar radius terlihat
                child: Image.asset(
                  assetPath,
                  width: 12.w,
                  height: 12.w,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            SizedBox(width: 4.w),
            Text(
              displayName,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 11.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    // --- 2. Perhitungan Progress ---
    double total = double.tryParse(item['reward_amount'].toString()) ?? 1;
    double remaining =
        double.tryParse(item['remaining_budget'].toString()) ?? 0;
    double progress = (remaining / total).clamp(0.0, 1.0);

    // Ambil data platform
    List<String> platforms = [];
    if (item['platform'] != null) {
      if (item['platform'] is List) {
        platforms = List<String>.from(item['platform']);
      } else {
        platforms = [item['platform'].toString()];
      }
    }

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFF252525),
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              Container(
                width: 60.w,
                height: 60.w,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.r),
                  color: Colors.grey[800],
                  image: item['image_url'] != null
                      ? DecorationImage(
                          image: NetworkImage(
                            AppConfig.fixImageUrl(item['image_url']),
                          ),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: item['image_url'] == null
                    ? Icon(Icons.image, color: Colors.grey)
                    : null,
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category Tag
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFC8FF00).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        item['category'] ?? "General",
                        style: TextStyle(
                          color: const Color(0xFFC8FF00),
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 6.h),
                    // Title
                    Text(
                      item['title'],
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 6.h), // Jarak ke platform
                    // --- PLATFORM AREA (BERJAJAR DI BAWAH JUDUL) ---
                    Wrap(
                      spacing:
                          0, // Jarak dikelola di margin _buildPlatformBadge
                      runSpacing: 4.h,
                      children: platforms
                          .map((p) => _buildPlatformBadge(p))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Divider(color: Colors.white.withOpacity(0.1), height: 1),
          SizedBox(height: 12.h),

          // --- Progress & Budget Area (Tetap Sama) ---
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Sisa Budget",
                    style: TextStyle(color: Colors.grey[500], fontSize: 11.sp),
                  ),
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
              SizedBox(height: 8.h),
              Stack(
                children: [
                  Container(
                    height: 6.h,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(
                      height: 6.h,
                      decoration: BoxDecoration(
                        color: const Color(0xFFC8FF00),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Total Budget:",
                    style: TextStyle(color: Colors.grey[400], fontSize: 12.sp),
                  ),
                  Text(
                    formatRupiah(total),
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 14.sp,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(SolarIconsOutline.box, size: 60.sp, color: Colors.grey[300]),
          SizedBox(height: 10.h),
          Text(
            "Misi tidak ditemukan",
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
