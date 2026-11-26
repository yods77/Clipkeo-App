import 'dart:convert';
import 'dart:ui'; // Wajib untuk ImageFilter
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:animate_do/animate_do.dart';
import 'login_screen.dart';
import '../config.dart';
import '../widgets/app_background_scaffold.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // --- VARIABLES ---
  // 🔥 FIX 1: Hapus variabel ganda. Kita pakai _isLoading saja.
  bool _isLoading = true;

  // Controllers
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  final TextEditingController _tiktokController = TextEditingController();
  final TextEditingController _instaController = TextEditingController();
  final TextEditingController _youtubeController = TextEditingController();

  final TextEditingController _bankNumController = TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();
  final List<String> _bankList = [
    "BCA", "BRI", "Mandiri", "BNI", "BSI", "CIMB Niaga",
    "Permata", "Danamon", "Bank Jago", "SeaBank",
    "Dana", "OVO", "GoPay", "ShopeePay", // Tambah E-Wallet jika perlu
  ];
  String _selectedBank = "BCA"; // Default awal

  String _getBankLogoPath(String bankName) {
    String name = bankName.toLowerCase();

    if (name.contains("bca")) return "assets/banks/bca.png";
    if (name.contains("bri")) return "assets/banks/bri.png";
    if (name.contains("mandiri")) return "assets/banks/mandiri.png";
    if (name.contains("bni")) return "assets/banks/bni.png";
    if (name.contains("cimb")) return "assets/banks/cimb.png";
    if (name.contains("bsi")) return "assets/banks/bsi.png";
    if (name.contains("danamon")) return "assets/banks/danamon.png";
    if (name.contains("permata")) return "assets/banks/permata.png";
    if (name.contains("jago")) return "assets/banks/jago.png";
    if (name.contains("sea")) return "assets/banks/seabank.png";
    if (name.contains("dana")) return "assets/banks/dana.png";
    if (name.contains("ovo")) return "assets/banks/ovo.png";
    if (name.contains("gopay")) return "assets/banks/gopay.png";
    if (name.contains("shopee")) return "assets/banks/shopeepay.png";

    return "";
  }

  // Data Display
  String displayName = "";
  String displayUsername = "";
  String displayEmail = "";
  String? avatarUrl;
  String role = "Clipper";

  // Colors
  final Color neonGreen = const Color(0xFFC8FF00);
  final Color surfaceWhite = Colors.white;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    fetchProfileData();
  }

  // --- FUNGSI AMBIL DATA PROFILE (SUDAH DIPERBAIKI) ---
  Future<void> fetchProfileData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final url = Uri.parse('${AppConfig.baseUrl}/user');
      print("🚀 REQUEST PROFILE: $url");

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print("📦 RESPONSE PROFILE: ${response.body}");

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final user = json['data'] ?? json;

        if (mounted) {
          setState(() {
            // 1. DATA UTAMA
            displayName = user['name'] ?? "No Name";
            displayUsername = user['username'] ?? "@username";
            displayEmail = user['email'] ?? "-";
            role = user['role'] ?? "Clipper";

            // 2. 🔥 FOTO PROFIL (FIX: Tambahkan 'avatar_url')
            // JSON Bosku pakai 'avatar_url', jadi kita prioritas ambil itu
            String? rawPhoto =
                user['avatar_url'] ??
                user['avatar'] ??
                user['profile_photo_url'] ??
                user['image'];

            // Perbaiki URL Foto (Tambah http://... jika cuma path)
            avatarUrl = AppConfig.fixImageUrl(rawPhoto);
            print("📸 AVATAR FINAL: $avatarUrl");

            // 3. FILL FORM DATA PRIBADI
            _nameController.text = user['name'] ?? "";
            _usernameController.text = user['username'] ?? "";
            _emailController.text = user['email'] ?? "";
            _phoneController.text = user['phone_number'] ?? user['phone'] ?? "";

            // 4. SOSMED (Tetap kita pasang jaring, jaga-jaga kalau Backend diperbaiki)
            _tiktokController.text =
                user['tiktok'] ??
                user['social_tiktok'] ??
                user['tiktok_id'] ??
                "";
            _instaController.text =
                user['instagram'] ??
                user['social_instagram'] ??
                user['instagram_id'] ??
                "";
            _youtubeController.text =
                user['youtube'] ??
                user['social_youtube'] ??
                user['youtube_id'] ??
                "";

            // 5. BANK INFO
            String? bankDb =
                user['bank_name'] ?? user['bank']; // Ambil dari API

            if (bankDb != null && _bankList.contains(bankDb)) {
              _selectedBank = bankDb; // Jika ada di list, pakai itu
            } else {
              // FALBACK PENTING:
              // Kalau bank di DB aneh-aneh (misal "Bank BCA" padahal list kita cuma "BCA"),
              // Atau kalau user belum punya bank,
              // KITA PAKSA PILIH YANG PERTAMA DI LIST (Default BCA) AGAR TIDAK CRASH.
              _selectedBank = _bankList.first;
            }
            _bankNameController.text =
                user['account_name'] ?? user['bank_account_name'] ?? "";
            _bankNumController.text =
                user['account_number'] ?? user['bank_number'] ?? "";

            _isLoading = false;
          });
        }
      } else {
        print("❌ Gagal ambil profile: ${response.statusCode}");
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      print("❌ Error Profile: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });

      // 🔥 PANGGIL FUNGSI UPLOAD DI SINI
      _uploadProfilePicture();
    }
  }

  Future<void> _uploadProfilePicture() async {
    if (_imageFile == null) return;

    setState(() => _isLoading = true);

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      // 1. Siapkan Request Multipart
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConfig.baseUrl}/profile/update-avatar'),
      );

      // 2. Tambahkan Header Authorization
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      // 3. Tambahkan File (Key 'avatar' harus sama dengan di Laravel)
      request.files.add(
        await http.MultipartFile.fromPath('avatar', _imageFile!.path),
      );

      // 4. Kirim Request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print("📤 UPLOAD RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        setState(() {
          // Update avatarUrl dengan URL baru dari server agar UI berubah permanen
          avatarUrl = AppConfig.fixImageUrl(json['avatar_url']);
          _imageFile = null; // Bersihkan temporary file
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Foto profil berhasil diperbarui!")),
        );
      } else {
        throw Exception("Gagal upload: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error Upload: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal mengunggah foto: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    try {
      final response = await http.post(
        Uri.parse(
          '${AppConfig.baseUrl}/profile/update',
        ), // Pastikan route update benar
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
        body: {
          'name': _nameController.text,
          'username': _usernameController.text,
          'email': _emailController.text,
          'phone_number': _phoneController.text,
          'social_tiktok': _tiktokController.text,
          'social_instagram': _instaController.text,
          'social_youtube': _youtubeController.text,
          'bank_name': _selectedBank,
          'account_number': _bankNumController.text,
          'account_name': _bankNameController.text,
        },
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profil Berhasil Disimpan!")),
        );
        fetchProfileData();
      }
    } catch (e) {
      print("Error update: $e");
    }
  }

  // --- FUNGSI LOGOUT AMAN (SERVER + LOCAL) ---
  Future<void> _doLogout(BuildContext context) async {
    // 1. Tampilkan Loading (Opsional, biar user tau sedang proses)
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      // 2. TEMBAK API LOGOUT KE LARAVEL
      // Kita lakukan ini SEBELUM menghapus data di HP
      if (token != null) {
        final url = Uri.parse('${AppConfig.baseUrl}/logout');

        // Kita pakai try-catch di dalam sini,
        // supaya kalau internet mati, user TETAP BISA logout lokal (Force Logout)
        try {
          await http.post(
            url,
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          );
          print("✅ Sukses Logout dari Server (FCM Hangus)");
        } catch (serverError) {
          print("⚠️ Gagal connect server saat logout (Abaikan): $serverError");
        }
      }

      // 3. HAPUS DATA LOKAL (BERSIH TOTAL)
      await prefs.clear();
      // Atau kalau mau spesifik:
      // await prefs.remove('token');
      // await prefs.remove('user');

      // 4. PINDAH KE LOGIN SCREEN
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false, // Hapus semua history halaman sebelumnya
        );
      }
    } catch (e) {
      print("❌ Error Logout Fatal: $e");
      // Safety Net: Kalau error parah, tetap paksa pindah ke login
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  // --- MAIN UI ---
  @override
  // --- MAIN UI (BERSIH & RAPIS) ---
  @override
  Widget build(BuildContext context) {
    final double spacerWidth = 45.w;

    // 🔥 PAKAI WADAH AJAIB (Background Silver Otomatis)
    return AppBackgroundScaffold(
      child: _isLoading
          ? Center(child: CircularProgressIndicator(color: neonGreen))
          : SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 40.h),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // HEADER NAV
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(width: spacerWidth), // Spacer kiri
                        Text(
                          "Profil Clipper",
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w900,
                            color: Colors.black, // Judul Hitam
                          ),
                        ),
                        SizedBox(width: spacerWidth), // Spacer kanan
                      ],
                    ),

                    SizedBox(height: 20.h),

                    // 🔥 A. DIGITAL ID CARD (Tetap Dark sebagai Kartu Member)
                    FadeInDown(
                      duration: const Duration(milliseconds: 600),
                      child: _buildDigitalIDCard(),
                    ),

                    SizedBox(height: 25.h),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Judul Pengaturan (Muncul Duluan)
                        FadeInUp(
                          duration: const Duration(milliseconds: 500),
                          delay: const Duration(milliseconds: 200),
                          child: Padding(
                            padding: EdgeInsets.only(left: 8.w, bottom: 10.h),
                            child: Text(
                              "PENGATURAN AKUN",
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w900,
                                color: const Color.fromARGB(255, 54, 54, 54),
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ),

                        // 2. Menu Data Pribadi
                        FadeInUp(
                          duration: const Duration(milliseconds: 500),
                          delay: const Duration(
                            milliseconds: 300,
                          ), // Delay nambah 100ms
                          child: _buildModularMenu(
                            title: "Data Pribadi",
                            subtitle: "Nama, Email, No. HP",
                            icon: SolarIconsOutline.user,
                            color: Colors.black,
                            onTap: () => _showEditBasicInfo(context),
                          ),
                        ),
                        SizedBox(height: 12.h),

                        // 3. Menu Akun Terhubung
                        FadeInUp(
                          duration: const Duration(milliseconds: 500),
                          delay: const Duration(
                            milliseconds: 400,
                          ), // Delay nambah lagi
                          child: _buildModularMenu(
                            title: "Akun Terhubung",
                            subtitle: "TikTok, Instagram, YouTube",
                            icon: SolarIconsBold.link,
                            color: Colors.black,
                            onTap: () => _showEditSosmed(context),
                          ),
                        ),
                        SizedBox(height: 12.h),

                        // 4. Menu Metode Pembayaran
                        FadeInUp(
                          duration: const Duration(milliseconds: 500),
                          delay: const Duration(
                            milliseconds: 500,
                          ), // Delay nambah lagi
                          child: _buildModularMenu(
                            title: "Metode Pembayaran",
                            subtitle: "Informasi Bank & Penarikan",
                            icon: SolarIconsOutline.card,
                            color: Colors.black,
                            onTap: () => _showEditBank(context),
                          ),
                        ),
                        SizedBox(height: 12.h),

                        // 5. Menu Keluar
                        FadeInUp(
                          duration: const Duration(milliseconds: 500),
                          delay: const Duration(
                            milliseconds: 600,
                          ), // Paling terakhir muncul
                          child: _buildModularMenu(
                            title: "Keluar",
                            subtitle: "Keluar dari perangkat",
                            icon: SolarIconsOutline.logout,
                            color: Colors.redAccent,
                            isDanger: true,
                            onTap: () => _doLogout(context),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 50.h),
                  ],
                ),
              ),
            ),
    );
  }

  // --- WIDGETS ---
  // --- DIGITAL ID CARD (UPDATED: EMAIL & VERTICAL SOSMED) ---
  Widget _buildDigitalIDCard() {
    return Container(
      width: double.infinity,
      height: 205.h, // 🔥 Tinggi kita lebihkan sedikit biar aman
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30.r),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2D2D2D), Color(0xFF252525)],
        ),
        boxShadow: [
          // 🔥 FIX DI SINI: GANTI SHADOW NEON JADI SHADOW HITAM NATURAL 🔥
          BoxShadow(
            color: Colors.black.withOpacity(0.25), // Shadow hitam, bukan neon
            blurRadius: 5,
            offset: const Offset(0, 5),
            spreadRadius: 0,
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
      ),
      child: Stack(
        children: [
          // DEKORASI
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 150.w,
              height: 150.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: surfaceWhite.withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -20,
            right: -10,
            child: Opacity(
              opacity: 0.1,
              child: Icon(
                SolarIconsBold.user,
                size: 180.sp,
                color: Colors.white,
              ),
            ),
          ),
          Positioned(
            top: 24.h,
            right: 24.w,
            child: Opacity(
              opacity: 0.6,
              child: Icon(
                SolarIconsOutline.userId,
                color: neonGreen,
                size: 28.sp,
              ),
            ),
          ),

          // KONTEN UTAMA
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. ATAS: PROFIL
                Row(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        // 🔥 Tambahkan Stack agar bisa menumpuk icon kamera
                        children: [
                          Container(
                            padding: EdgeInsets.all(2.w),
                            child: Container(
                              padding: EdgeInsets.all(3.w),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: neonGreen, width: 2),
                              ),
                              child: CircleAvatar(
                                radius: 26.r,
                                backgroundColor: Colors.grey[900],
                                backgroundImage: _imageFile != null
                                    ? FileImage(_imageFile!)
                                    : (avatarUrl != null &&
                                          avatarUrl!.isNotEmpty)
                                    ? NetworkImage(avatarUrl!)
                                    : null,
                                child:
                                    (_imageFile == null &&
                                        (avatarUrl == null ||
                                            avatarUrl!.isEmpty))
                                    ? Text(
                                        displayName.isNotEmpty
                                            ? displayName[0]
                                            : "U",
                                        style: TextStyle(
                                          color: neonGreen,
                                          fontSize: 24.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                          ),

                          // --- INI ICON KAMERA KECILNYA ---
                          Positioned(
                            bottom: 4.h,
                            right: 4.w,
                            child: Container(
                              padding: EdgeInsets.all(4.w),
                              decoration: BoxDecoration(
                                color:
                                    neonGreen, // Warna background icon kamera
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF252525),
                                  width: 2,
                                ), // Biar ada jarak dari foto
                              ),
                              child: Icon(
                                Icons.camera_alt,
                                size: 10
                                    .sp, // Ukuran mungil biar gak nutupin muka
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName.toUpperCase(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4.h),
                          Row(
                            children: [
                              Icon(
                                SolarIconsOutline.letter,
                                color: Colors.grey[400],
                                size: 10.sp,
                              ),
                              SizedBox(width: 4.w),
                              Expanded(
                                child: Text(
                                  displayEmail.isNotEmpty
                                      ? displayEmail
                                      : "No Email",
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 6.h),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 2.h,
                            ),
                            decoration: BoxDecoration(
                              color: neonGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: neonGreen.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              role.toUpperCase(),
                              style: TextStyle(
                                color: neonGreen,
                                fontSize: 8.sp,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Pendorong ke bawah
                SizedBox(height: 10.h),
                // 2. BAWAH: SOSMED & QR
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end, // Rata Bawah
                  children: [
                    // --- 🔥 FIX UTAMA: Bungkus Kolom Kiri dengan EXPANDED 🔥 ---
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "LINKED ACCOUNTS",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 8.sp,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          SizedBox(height: 6.h),

                          if (_tiktokController.text.isEmpty &&
                              _instaController.text.isEmpty &&
                              _youtubeController.text.isEmpty)
                            Text(
                              "- Empty -",
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 10.sp,
                                fontStyle: FontStyle.italic,
                              ),
                            ),

                          if (_tiktokController.text.isNotEmpty)
                            _buildCompactSocialRow(
                              'assets/icons/tiktok.png',
                              _tiktokController.text,
                            ),
                          if (_instaController.text.isNotEmpty)
                            _buildCompactSocialRow(
                              'assets/icons/instagram.png',
                              _instaController.text,
                            ),
                          if (_youtubeController.text.isNotEmpty)
                            _buildCompactSocialRow(
                              'assets/icons/youtube.png',
                              _youtubeController.text,
                            ),
                        ],
                      ),
                    ),

                    SizedBox(width: 10.w), // Jarak antara Sosmed dan QR
                    // --- KANAN: QR CODE (Ukurannya Fixed, jadi aman) ---
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          width: 45.w,
                          height: 45.w,
                          padding: EdgeInsets.all(4.w),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Center(
                            child: Icon(
                              SolarIconsBold.qrCode,
                              color: Colors.black,
                              size: 36.sp,
                            ),
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          "SCAN TO CONNECT",
                          style: TextStyle(
                            color: neonGreen,
                            fontSize: 7.sp,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          "SINCE 2026",
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 7.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- HELPER BARU: ROW SOSMED KECIL ---
  Widget _buildCompactSocialRow(String iconPath, String username) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h), // Jarak antar baris
      child: Row(
        children: [
          // 🔥 UPDATE: Bungkus Image dengan ClipRRect untuk Border Radius
          ClipRRect(
            borderRadius: BorderRadius.circular(
              50.r,
            ), // 50.r = Bulat Penuh, 4.r = Kotak Tumpul
            child: Image.asset(
              iconPath,
              width: 16.w,
              height: 16.h,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              username,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 10.sp,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniSocialIcon(String assetPath) {
    return Padding(
      padding: EdgeInsets.only(right: 12.w),
      child: ClipRRect(
        // 1. Tentukan radius di sini (misal 8 agar tidak terlalu bulat)
        borderRadius: BorderRadius.circular(8.r),
        child: Image.asset(
          assetPath,
          width: 26.w,
          height: 26.w,
          fit: BoxFit.cover, // Pastikan dicover agar pemotongan radius rapi
          errorBuilder: (context, error, stackTrace) =>
              Icon(Icons.broken_image, size: 18.sp, color: Colors.white24),
        ),
      ),
    );
  }

  // 3. MODULAR MENU ITEM
  // --- MODULAR MENU WIDGET (VERSI BLACK & NEON) ---
  Widget _buildModularMenu({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color
    color, // Parameter ini kita abaikan untuk mode normal, kita paksa jadi hijau
    required VoidCallback onTap,
    bool isDanger = false, // Untuk tombol Logout
  }) {
    // TENTUKAN WARNA
    // Jika tombol Logout (Danger), tetap Merah. Jika Menu biasa, jadi Hitam-Hijau.
    Color boxColor = isDanger
        ? const Color(0xFFFEF2F2)
        : const Color(0xFF252525); // Hitam Elegan
    Color iconColor = isDanger ? Colors.white : neonGreen; // Ikon Hijau Neon
    Color titleColor = isDanger ? Colors.red : Colors.white; // Teks Putih
    Color subtitleColor = isDanger
        ? Colors.red.withOpacity(0.6)
        : Colors.grey[500]!;
    Color borderColor = isDanger
        ? Colors.red.withOpacity(0.2)
        : Colors.white.withOpacity(0.1);

    return Material(
      color: const Color(0x00000000),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: boxColor,
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(
              color: borderColor,
              width: 1,
            ), // Border tipis biar rapi
            boxShadow: isDanger
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 5,
                      offset: const Offset(0, 5),
                    ),
                  ],
          ),
          child: Row(
            children: [
              // --- ICON BOX (KIRI) ---
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: isDanger
                      ? Colors.red
                      : const Color(0xFF252525), // Background Ikon
                  shape: BoxShape.circle,
                  // Kasih border hijau tipis di sekeliling ikon biar menyala
                  border: Border.all(
                    color: isDanger
                        ? Colors.transparent
                        : neonGreen.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Icon(icon, color: iconColor, size: 22.sp),
              ),

              SizedBox(width: 16.w),

              // --- TEXT (TENGAH) ---
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: titleColor, // Putih
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: subtitleColor, // Abu-abu
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // --- ARROW (KANAN) ---
              // Panah kecil biar user tau ini bisa diklik
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16.sp,
                color: isDanger
                    ? Colors.red.withOpacity(0.4)
                    : const Color.fromARGB(255, 255, 255, 255),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- POP UP FORMS ---

  // --- MODAL DATA PRIBADI (STYLE BARU) ---
  void _showEditBasicInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: FadeInUp(
            duration: const Duration(milliseconds: 500),
            delay: const Duration(milliseconds: 200),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
              ),
              child: FadeInUp(
                duration: const Duration(milliseconds: 400),
                delay: const Duration(milliseconds: 200),
                child: Column(
                  children: [
                    // HEADER
                    SizedBox(height: 16.h),
                    Center(
                      child: Container(
                        width: 40.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      "Data Pribadi",
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Divider(color: Colors.grey[200]),

                    // CONTENT
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(
                          horizontal: 24.w,
                          vertical: 10.h,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Nama Lengkap",
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            _buildTextField(
                              "Nama Kamu",
                              _nameController,
                              prefix: Icon(
                                SolarIconsBold.user,
                                size: 20.sp,
                                color: const Color(0xFF1F1F1F),
                              ),
                            ),

                            SizedBox(height: 20.h),

                            // EMAIL (READ ONLY)
                            Text(
                              "Email Address",
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Opacity(
                              opacity: 0.8,
                              child: _buildTextField(
                                "email@kamu.com",
                                _emailController,
                                prefix: Icon(
                                  SolarIconsBold.letter,
                                  size: 20.sp,
                                  color: const Color(0xFF1F1F1F),
                                ),
                                isEnabled: false,
                              ),
                            ),
                            SizedBox(height: 6.h),
                            Text(
                              "Hubungi admin jika ingin mengubah email.",
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: Colors.grey,
                              ),
                            ),

                            SizedBox(height: 20.h),

                            Text(
                              "Nomor WhatsApp",
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            _buildTextField(
                              "08xxxxxxxx",
                              _phoneController,
                              prefix: Icon(
                                SolarIconsBold.phone,
                                size: 20.sp,
                                color: const Color(0xFF1F1F1F),
                              ),
                              isNumber: true,
                            ),

                            SizedBox(height: 50.h),
                          ],
                        ),
                      ),
                    ),

                    // FOOTER BUTTON
                    Container(
                      padding: EdgeInsets.all(24.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          top: BorderSide(color: Colors.grey[100]!),
                        ),
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _updateProfile();
                            // Update UI lokal biar langsung berubah
                            setState(() {
                              displayName = _nameController.text;
                              displayEmail = _emailController.text;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: neonGreen,
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          child: Text(
                            "Simpan Perubahan",
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w800,
                              fontSize: 16.sp,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // --- MODAL AKUN SOSMED (STYLE BARU) ---
  void _showEditSosmed(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: FadeInUp(
            duration: const Duration(milliseconds: 400),
            delay: const Duration(milliseconds: 200),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
              ),
              child: FadeInUp(
                duration: const Duration(milliseconds: 400),
                delay: const Duration(milliseconds: 200),
                child: Column(
                  children: [
                    // HEADER
                    SizedBox(height: 16.h),
                    Center(
                      child: Container(
                        width: 40.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      "Hubungkan Akun",
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Divider(color: Colors.grey[200]),

                    // CONTENT
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(
                          horizontal: 24.w,
                          vertical: 10.h,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Username TikTok",
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            _buildTextField(
                              "@username",
                              _tiktokController,
                              prefix: _buildMiniSocialIcon(
                                'assets/icons/tiktok.png',
                              ),
                            ),

                            SizedBox(height: 20.h),

                            Text(
                              "Username Instagram",
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            _buildTextField(
                              "@username",
                              _instaController,
                              prefix: _buildMiniSocialIcon(
                                'assets/icons/instagram.png',
                              ),
                            ),

                            SizedBox(height: 20.h),

                            Text(
                              "Link / ID YouTube",
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            _buildTextField(
                              "Channel ID",
                              _youtubeController,
                              prefix: _buildMiniSocialIcon(
                                'assets/icons/youtube.png',
                              ),
                            ),

                            SizedBox(height: 50.h),
                          ],
                        ),
                      ),
                    ),

                    // FOOTER BUTTON
                    Container(
                      padding: EdgeInsets.all(24.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          top: BorderSide(color: Colors.grey[100]!),
                        ),
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _updateProfile();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: neonGreen,
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          child: Text(
                            "Simpan Sosmed",
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w800,
                              fontSize: 16.sp,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // --- MODAL EDIT BANK (VERSI HYBRID: BCA GAMBAR, SISANYA ICON) ---
  void _showEditBank(BuildContext context) {
    // ... (Bagian Logic Safe Guard tetap sama) ...
    String safeValue = _selectedBank;
    if (!_bankList.contains(safeValue)) safeValue = _bankList.first;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: FadeInUp(
            duration: const Duration(milliseconds: 400),
            delay: const Duration(milliseconds: 200),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
              ),
              child: FadeInUp(
                duration: const Duration(milliseconds: 400),
                delay: const Duration(milliseconds: 200),
                child: Column(
                  children: [
                    SizedBox(height: 16.h),
                    Center(
                      child: Container(
                        width: 40.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      "Metode Pembayaran",
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Divider(color: Colors.grey[200]),

                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(
                          horizontal: 24.w,
                          vertical: 10.h,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Nama Bank / E-Wallet",
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 8.h),

                            // --- 🔥 GANTI DROPDOWN DENGAN INI (SELECTOR) 🔥 ---
                            // Ini bentuknya kayak tombol, tapi desainnya mirip input form
                            // --- 1. Bungkus InkWell dengan FadeInUp ---
                            FadeInUp(
                              duration: const Duration(milliseconds: 500),
                              delay: const Duration(
                                milliseconds: 200,
                              ), // Muncul setelah input di atasnya
                              child: InkWell(
                                onTap: () {
                                  // Saat diklik, buka list bank baru
                                  _showBankListModal(context);
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16.w,
                                    vertical: 14.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF9FAFB),
                                    borderRadius: BorderRadius.circular(12.r),
                                    border: Border.all(
                                      color: Colors.transparent,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      // --- 2. LOGO BANK (Bisa dikasih animasi Pulse biar makin elite) ---
                                      FadeIn(
                                        duration: const Duration(
                                          milliseconds: 500,
                                        ),
                                        child: Container(
                                          width: 45.w,
                                          height: 30.h,
                                          margin: EdgeInsets.only(right: 12.w),
                                          child:
                                              _getBankLogoPath(
                                                safeValue,
                                              ).isNotEmpty
                                              ? Image.asset(
                                                  _getBankLogoPath(safeValue),
                                                  fit: BoxFit.contain,
                                                )
                                              : Icon(
                                                  Icons.account_balance_wallet,
                                                  color: Colors.blueGrey,
                                                  size: 20.sp,
                                                ),
                                        ),
                                      ),

                                      // NAMA BANK
                                      Expanded(
                                        child: Text(
                                          safeValue,
                                          style: TextStyle(
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),

                                      // ICON PANAH KE BAWAH
                                      Icon(
                                        Icons.keyboard_arrow_down,
                                        color: Colors.grey,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // --------------------------------------------------
                            SizedBox(height: 20.h),

                            // FIELD LAINNYA (TETAP SAMA)
                            Text(
                              "Nomor Rekening",
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            _buildTextField(
                              "Contoh: 1234567890",
                              _bankNumController,
                              prefix: Icon(
                                SolarIconsBold.pen,
                                size: 20.sp,
                                color: const Color(0xFF1F1F1F),
                              ),
                              isNumber: true,
                            ),

                            SizedBox(height: 20.h),

                            Text(
                              "Atas Nama Pemilik",
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            _buildTextField(
                              "Contoh: Nama Kamu",
                              _bankNameController,
                              prefix: Icon(
                                SolarIconsBold.textField,
                                size: 20.sp,
                                color: const Color(0xFF1F1F1F),
                              ),
                            ),

                            SizedBox(height: 50.h),
                          ],
                        ),
                      ),
                    ),

                    // TOMBOL SIMPAN
                    Container(
                      padding: EdgeInsets.all(24.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          top: BorderSide(color: Colors.grey[100]!),
                        ),
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _updateProfile();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: neonGreen,
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          child: Text(
                            "Simpan Data Bank",
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w800,
                              fontSize: 16.sp,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // --- FUNGSI PILIH BANK (MODEL LIST BIASA - ANTI CRASH) ---
  void _showBankListModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.symmetric(vertical: 20.h),
          height: 500.h, // Tinggi list
          child: Column(
            children: [
              Text(
                "Pilih Bank / E-Wallet",
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10.h),
              Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: _bankList.length,
                  itemBuilder: (context, index) {
                    String bank = _bankList[index];
                    String logoPath = _getBankLogoPath(bank);
                    bool isSelected = _selectedBank == bank;

                    return ListTile(
                      onTap: () {
                        setState(() {
                          _selectedBank = bank; // Update pilihan
                        });
                        Navigator.pop(context); // Tutup list

                        // Trik: Refresh modal utama agar tampilan berubah
                        Navigator.pop(context); // Tutup modal edit lama
                        _showEditBank(context); // Buka lagi (Refresh UI)
                      },
                      leading: Container(
                        width: 50.w,
                        height: 35.h,
                        padding: EdgeInsets.all(4.r),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        // DISINI GAMBAR AKAN TAMPIL DENGAN AMAN
                        child: logoPath.isNotEmpty
                            ? Image.asset(logoPath, fit: BoxFit.contain)
                            : Icon(
                                Icons.account_balance_wallet,
                                color: Colors.blueGrey,
                                size: 20.sp,
                              ),
                      ),
                      title: Text(
                        bank,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14.sp,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check_circle, color: neonGreen)
                          : null,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- HELPER TEXT FIELD (UPDATED) ---
  Widget _buildTextField(
    String hint,
    TextEditingController controller, {
    Widget? prefix,
    bool isNumber = false,
    bool isEnabled = true, // Tambah isEnabled
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      enabled: isEnabled, // <-- Logic Read Only
      style: TextStyle(
        color: isEnabled
            ? Colors.black
            : Colors.grey[600], // Text abu jika disabled
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14.sp),
        prefixIcon: prefix != null
            ? Padding(padding: EdgeInsets.all(12.w), child: prefix)
            : null,
        filled: true,
        // Warna background beda dikit kalau disabled biar user paham
        fillColor: isEnabled ? const Color(0xFFF9FAFB) : Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      ),
    );
  }
}
