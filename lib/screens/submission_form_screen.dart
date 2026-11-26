import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Untuk Copy Paste
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:image_picker/image_picker.dart'; // Support Video juga
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import 'dart:convert';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'tutorial_page.dart';

class SubmissionFormScreen extends StatefulWidget {
  final int campaignId;
  final String campaignTitle;
  final String defaultCaption;
  final String mentions;
  final List<dynamic> platforms;

  const SubmissionFormScreen({
    super.key,
    required this.campaignId,
    required this.campaignTitle,
    this.defaultCaption = "",
    this.mentions = "",
    this.platforms = const [],
  });

  @override
  State<SubmissionFormScreen> createState() => _SubmissionFormScreenState();
}

class _SubmissionFormScreenState extends State<SubmissionFormScreen> {
  // -- STATE --
  int _currentStep = 1; // 1 = Rules, 2 = Form Upload
  bool isSubmitting = false;
  List<dynamic> _mySocialAccounts = [];
  String? _selectedAccountId; // ID akun yang dipilih user
  bool _isLoadingAccounts = true;

  // -- THEME COLORS (Dark Elite) --
  final Color _neonGreen = const Color(0xFFC8FF00);
  final Color _darkBgStart = const Color(0xFF171717);
  final Color _darkBgEnd = Colors.black;
  final Color _darkInputBg = const Color(0xFF1A1A1A);

  // -- FORM RULES (Checklist) --
  bool ruleOwnVideo = false;
  bool ruleNoAi = false;
  bool ruleOrganic = false;
  bool ruleTargetMet = false;
  bool rulePenalty = false;

  // -- FORM UPLOAD --
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _linkController = TextEditingController();
  final TextEditingController _viewsController = TextEditingController();
  final TextEditingController _captionController = TextEditingController();

  // VIDEO FILE
  File? _videoFile;
  String? _videoName; // Nama file untuk ditampilkan
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchSocialAccounts();
  }

  // --- LOGIC: PILIH VIDEO ---
  Future<void> _pickVideo() async {
    final XFile? pickedFile = await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 5),
    );

    if (pickedFile != null) {
      int sizeInBytes = await pickedFile.length();
      double sizeInMb = sizeInBytes / (1024 * 1024);

      if (sizeInMb > 55) {
        _showSnack("Ukuran video terlalu besar! Maks 50MB.", Colors.red);
        return;
      }

      setState(() {
        _videoFile = File(pickedFile.path);
        _videoName = pickedFile.name;
      });
    }
  }

  /*
  |--------------------------------------------------------------------------
  | SUBMIT WORK (API TETAP UTUH)
  |--------------------------------------------------------------------------
  */
  Future<void> _submitWork() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedAccountId == null) {
      _showSnack("Wajib pilih akun sosmed!", Colors.red);
      return;
    }
    if (_videoFile == null) {
      _showSnack("Wajib upload Screen Record Analytics!", Colors.red);
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedUserId = prefs.getString('user_id');

    if (storedUserId == null) {
      _showSnack("Sesi habis. Silakan login ulang aplikasi.", Colors.red);
      return;
    }

    setState(() => isSubmitting = true);

    try {
      var uri = Uri.parse(
        "${AppConfig.baseUrl}/campaigns/${widget.campaignId}/submit",
      );
      var request = http.MultipartRequest('POST', uri);

      request.fields['user_id'] = storedUserId;
      request.fields['linked_account_id'] = _selectedAccountId!;
      request.fields['video_link'] = _linkController.text;
      request.fields['current_views'] = _viewsController.text;
      request.fields['caption_content'] = _captionController.text;

      request.files.add(
        await http.MultipartFile.fromPath('analytics_file', _videoFile!.path),
      );

      final streamedResponse = await request.send().timeout(
        const Duration(minutes: 5),
        onTimeout: () {
          throw Exception("Waktu habis! Koneksi lambat.");
        },
      );

      final response = await http.Response.fromStream(streamedResponse);

      // --- START: UPDATE LOGIKA DI SINI BRO ---
      final responseData = json.decode(response.body);
      final String serverMessage =
          responseData['message'] ?? 'Terjadi kesalahan';

      if (response.statusCode == 200 || response.statusCode == 201) {
        // ✅ BERHASIL
        if (mounted) {
          _showFinishDialog(
            title: "Submit Berhasil!",
            message: serverMessage,
            isError: false,
          );
        }
      } else if (response.statusCode == 403) {
        // 🛡️ ANTI-TIKUNG TERTANGKAP
        if (mounted) {
          _showFinishDialog(
            title: "Submit Ditolak!",
            message: serverMessage,
            isError: true,
          );
        }
      } else {
        // ❌ ERROR LAINNYA
        if (mounted) {
          _showFinishDialog(
            title: "Ops, Gagal!",
            message: serverMessage,
            isError: true,
          );
        }
      }
      // --- END: UPDATE LOGIKA ---
    } catch (e) {
      print("Error System: $e");
      _showSnack("Koneksi Error: $e", Colors.red);
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  void _showFinishDialog({
    required String title,
    required String message,
    required bool isError,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false, // User wajib klik tombol
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // --- IKON ---
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: isError
                        ? Colors.red.withOpacity(0.1)
                        : _neonGreen.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isError
                        ? SolarIconsOutline.danger
                        : SolarIconsOutline.checkCircle,
                    color: isError ? Colors.redAccent : _neonGreen,
                    size: 50.sp,
                  ),
                ),
                SizedBox(height: 20.h),

                // --- TITLE ---
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12.h),

                // --- MESSAGE ---
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[400], fontSize: 14.sp),
                ),
                SizedBox(height: 24.h),

                // --- TOMBOL ---
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Tutup Dialog
                      if (!isError) {
                        Navigator.pop(
                          this.context,
                          true,
                        ); // Keluar dari Form jika sukses
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isError ? Colors.grey[800] : _neonGreen,
                      foregroundColor: isError ? Colors.white : Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.r),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                    ),
                    child: Text(
                      isError ? "Saya Mengerti" : "Oke, Selesai!",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == _neonGreen
                  ? Icons.check_circle
                  : Icons.warning_amber_rounded,
              color: color == _neonGreen ? Colors.black : Colors.white,
              size: 20.sp,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                msg,
                style: TextStyle(
                  color: color == _neonGreen ? Colors.black : Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating, // Biar melayang lebih modern
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
        ),
      ),
    );
  }

  // --- LOAD SOSMED USER ---
  Future<void> _fetchSocialAccounts() async {
    // 1. Pastikan status loading nyala
    setState(() => _isLoadingAccounts = true);

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      print("🚀 [SOSMED] Mengambil data akun sosmed...");
      print("🔗 URL: ${AppConfig.baseUrl}/api/my-social-accounts");

      final response = await http.get(
        Uri.parse("${AppConfig.baseUrl}/my-social-accounts"),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print("📥 [SOSMED] Status Code: ${response.statusCode}");
      print("📄 [SOSMED] Body: ${response.body}");

      if (response.statusCode == 200) {
        var json = jsonDecode(response.body);
        print("📦 [DATA MENTAH]: ${json['data']}");
        if (mounted) {
          setState(() {
            _mySocialAccounts = json['data'];
            _isLoadingAccounts = false; // ✅ MATIKAN LOADING (Sukses)

            // Auto select
            if (_mySocialAccounts.length == 1) {
              _selectedAccountId = _mySocialAccounts[0]['id'].toString();
            }
          });
        }
      } else {
        // ⚠️ JIKA SERVER ERROR (404, 500, 401)
        print("⚠️ [SOSMED] Gagal ambil data. Server error.");
        if (mounted)
          setState(
            () => _isLoadingAccounts = false,
          ); // ✅ MATIKAN LOADING (Gagal)
      }
    } catch (e) {
      // ❌ JIKA KONEKSI PUTUS/ERROR KODING
      print("❌ [SOSMED ERROR] $e");
      if (mounted)
        setState(() => _isLoadingAccounts = false); // ✅ MATIKAN LOADING (Error)
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // BACKGROUND DARK GRADIENT
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_darkBgStart, _darkBgEnd],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // CUSTOM APP BAR
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (_currentStep == 2) {
                          setState(() => _currentStep = 1);
                        } else {
                          Navigator.pop(context);
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          SolarIconsOutline.arrowLeft,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          _currentStep == 1
                              ? "Pernyataan & Persetujuan"
                              : "Upload Bukti Tayang",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 40.w), // Dummy spacer biar title center
                  ],
                ),
              ),

              // INDICATOR STEP
              LinearProgressIndicator(
                value: _currentStep == 1 ? 0.5 : 1.0,
                backgroundColor: Colors.grey[800],
                color: _neonGreen,
                minHeight: 4.h,
              ),

              Expanded(
                child: _currentStep == 1
                    ? _buildRulesView()
                    : _buildUploadView(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- VIEW 1: RULES (DARK MODE) ---
  Widget _buildRulesView() {
    bool allChecked =
        ruleOwnVideo && ruleNoAi && ruleOrganic && ruleTargetMet && rulePenalty;

    return SingleChildScrollView(
      padding: EdgeInsets.all(24.w),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Konfirmasi Sebelum Submit",
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            "Mohon centang semua poin untuk melanjutkan.",
            style: TextStyle(color: Colors.grey[400]),
          ),
          SizedBox(height: 20.h),

          _buildCheckbox(
            "Link video adalah milik sendiri.",
            ruleOwnVideo,
            (v) => setState(() => ruleOwnVideo = v!),
          ),
          _buildCheckbox(
            "Tidak menggunakan AI Generator instan.",
            ruleNoAi,
            (v) => setState(() => ruleNoAi = v!),
          ),
          _buildCheckbox(
            "Views 100% ORGANIK (No Bot/Panel).",
            ruleOrganic,
            (v) => setState(() => ruleOrganic = v!),
          ),
          _buildCheckbox(
            "View Count sudah menyentuh target.",
            ruleTargetMet,
            (v) => setState(() => ruleTargetMet = v!),
          ),
          _buildCheckbox(
            "Siap BANNED PERMANEN jika curang.",
            rulePenalty,
            (v) => setState(() => rulePenalty = v!),
            isRed: true,
          ),

          SizedBox(height: 40.h),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: allChecked
                  ? () => setState(() => _currentStep = 2)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: allChecked ? _neonGreen : Colors.grey[800],
                padding: EdgeInsets.symmetric(vertical: 18.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28.r),
                ),
              ),
              child: Text(
                "Lengkapi Persyaratan & Lanjut ->",
                style: TextStyle(
                  color: allChecked ? Colors.black : Colors.grey[500],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET BARU: PLATFORM INFO ---
  Widget _buildPlatformSection() {
    if (widget.platforms.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "PLATFORM CAMPAIGN",
          style: TextStyle(
            fontSize: 10.sp,
            fontWeight: FontWeight.bold,
            color: Colors.grey[500],
          ),
        ),
        SizedBox(height: 8.h),

        // List Chips Platform
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: widget.platforms
              .map(
                (p) => Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: _darkInputBg, // Menggunakan warna input gelap
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        p.toString().replaceAll('_', ' ').toUpperCase(),
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11.sp,
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Icon(
                        SolarIconsBold.checkCircle,
                        color: _neonGreen,
                        size: 14.sp,
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),

        SizedBox(height: 16.h),

        // Warning Box Akun Sosmed
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: const Color(0xFF2C2410), // Aksen Gelap Kekuningan
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: Colors.orange.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(
                SolarIconsOutline.dangerTriangle,
                color: Colors.orange,
                size: 20.sp,
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Pastikan akun sosmed sudah terhubung!",
                      style: TextStyle(
                        color: Colors.orange[200],
                        fontWeight: FontWeight.bold,
                        fontSize: 12.sp,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      "Cek Profil Saya →",
                      style: TextStyle(
                        color: Colors.orange[300],
                        decoration: TextDecoration.underline,
                        fontSize: 11.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 24.h),
      ],
    );
  }

  // --- VIEW 2: UPLOAD FORM (DARK MODE) ---
  Widget _buildUploadView() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24.w),
      physics: const BouncingScrollPhysics(),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // COPY CAPTION BOX
            _buildPlatformSection(),
            // --- LOGIKA COPY CAPTION (AUTO GABUNG) ---
            Builder(
              builder: (context) {
                // 1. FORMAT MENTIONS (@)
                // Contoh: "clipkeo, rispo" -> "@clipkeo @rispo"
                String rawMentions = widget.mentions != "-"
                    ? widget.mentions
                    : "";

                String formattedMentions = rawMentions
                    .split(',')
                    .where((e) => e.trim().isNotEmpty)
                    .map((e) {
                      String s = e.trim();
                      // Cek apakah sudah ada @, kalau belum tambahkan
                      return s.startsWith('@') ? s : "@$s";
                    })
                    .join(" "); // Gabung pakai spasi

                // 2. FORMAT HASHTAGS (#)
                // Contoh: "lucu, viral" -> "#lucu #viral"
                String rawHashtags = widget.defaultCaption;

                String formattedHashtags = rawHashtags
                    .split(',')
                    .where((e) => e.trim().isNotEmpty)
                    .map((e) {
                      String s = e.trim();
                      // Cek apakah sudah ada #, kalau belum tambahkan
                      return s.startsWith('#') ? s : "#$s";
                    })
                    .join(" "); // Gabung pakai spasi

                // 3. Gabungkan: Mentions di atas, Hashtags di bawah
                String fullContent = "$formattedMentions\n$formattedHashtags"
                    .trim();

                // Fallback kalau kosong
                if (fullContent.isEmpty) fullContent = "#Clipsquad";

                return Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: _darkInputBg,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // HEADER KECIL
                      Padding(
                        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
                        child: Row(
                          children: [
                            Icon(
                              SolarIconsBold.documentText,
                              size: 14.sp,
                              color: Colors.grey[500],
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              "COPY MENTION & HASHTAG (WAJIB)",
                              style: TextStyle(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),

                      Divider(color: Colors.white.withOpacity(0.05), height: 1),

                      // ISI TEKS GABUNGAN
                      Padding(
                        padding: EdgeInsets.all(16.w),
                        child: Text(
                          fullContent,
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[300],
                            height: 1.5,
                            fontFamily:
                                'Monospace', // Font ala koding biar jelas
                          ),
                        ),
                      ),

                      // TOMBOL COPY DI BAWAH (FULL WIDTH)
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: fullContent));
                          // Panggil snackbar manual atau pakai helper yang ada
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Caption lengkap berhasil disalin!",
                                style: TextStyle(color: Colors.black),
                              ),
                              backgroundColor: Color(0xFFC8FF00),
                            ),
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          decoration: BoxDecoration(
                            color: const Color(0xFFC8FF00).withOpacity(0.1),
                            borderRadius: BorderRadius.vertical(
                              bottom: Radius.circular(16.r),
                            ),
                            border: Border(
                              top: BorderSide(
                                color: const Color(0xFFC8FF00).withOpacity(0.2),
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                SolarIconsBold.copy,
                                size: 16.sp,
                                color: const Color(0xFFC8FF00),
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                "COPY SEMUA UNTUK CAPTION",
                                style: TextStyle(
                                  color: const Color(0xFFC8FF00),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            SizedBox(height: 24.h),

            _buildAccountDropdown(),

            // FORM INPUTS
            _buildLabel("Video URL (TikTok/Reels/Shorts)"),
            TextFormField(
              controller: _linkController,
              style: TextStyle(color: Colors.white),
              decoration: _inputDecoration("https://..."),
              validator: (val) => val!.isEmpty ? "Link wajib diisi" : null,
            ),
            SizedBox(height: 16.h),

            _buildLabel("Caption Video Anda"),
            TextFormField(
              controller: _captionController,
              maxLines: 2,
              style: TextStyle(color: Colors.white),
              decoration: _inputDecoration("Paste caption..."),
              validator: (val) => val!.isEmpty ? "Caption wajib diisi" : null,
            ),
            SizedBox(height: 16.h),

            _buildLabel("Jumlah Views Saat Ini"),
            TextFormField(
              controller: _viewsController,
              keyboardType: TextInputType.number,
              style: TextStyle(color: Colors.white),
              decoration: _inputDecoration("0"),
              validator: (val) => val!.isEmpty ? "Views wajib diisi" : null,
            ),
            SizedBox(height: 24.h),

            // 🔥 LINK TUTORIAL
      GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TutorialPage()),
          );
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10.h),
          child: Row(
            children: [
              Icon(SolarIconsOutline.playCircle, color: const Color(0xFFC8FF00), size: 22.sp),
              SizedBox(width: 10.w),
              Text(
                "Bingung cara screen record? Lihat Tutorial Disini",
                style: TextStyle(
                  color: const Color(0xFFC8FF00),
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
        ),
      ),
      
      SizedBox(height: 15.h),

            // VIDEO UPLOAD BOX (DARK)
            _buildLabel("Upload Screen Record Analytics (Max 20MB)"),
            GestureDetector(
              onTap: _pickVideo,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 30.h, horizontal: 20.w),
                decoration: BoxDecoration(
                  color: _darkInputBg,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: _videoFile != null
                        ? _neonGreen
                        : Colors.white.withOpacity(0.1),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      _videoFile == null
                          ? SolarIconsOutline.clapperboardOpenPlay
                          : SolarIconsBold.fileCheck,
                      size: 40.sp,
                      color: _videoFile == null ? Colors.grey : _neonGreen,
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      _videoName ?? "Klik untuk Pilih Video (MP4/MOV)",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _videoFile == null
                            ? Colors.grey[500]
                            : Colors.white,
                        fontWeight: _videoFile == null
                            ? FontWeight.normal
                            : FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 30.h),

            _buildBeforeSubmittingInfo(),
            SizedBox(height: 30.h),

            // SUBMIT BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSubmitting ? null : _submitWork,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _neonGreen,
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(vertical: 18.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28.r),
                  ),
                ),
                child: isSubmitting
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : Text(
                        "KIRIM SUBMISSION",
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
    );
  }

  // --- HELPER WIDGETS (DARK THEME) ---
  Widget _buildCheckbox(
    String text,
    bool value,
    Function(bool?) onChanged, {
    bool isRed = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Theme(
        data: ThemeData(
          unselectedWidgetColor: Colors.grey[600],
        ), // Border checkbox normal
        child: CheckboxListTile(
          value: value,
          onChanged: onChanged,
          title: Text(
            text,
            style: TextStyle(
              fontSize: 13.sp,
              color: isRed ? Colors.redAccent : Colors.white,
              fontWeight: isRed ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: _neonGreen,
          checkColor: Colors.black,
          tileColor: Colors.transparent,
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.bold,
          color: Colors.grey[400],
        ),
      ),
    );
  }

  // --- WIDGET BARU: INFO BEFORE SUBMITTING ---
  Widget _buildBeforeSubmittingInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "BEFORE SUBMITTING:",
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.w900,
            color: Colors.grey[600],
            letterSpacing: 1.5, // Biar terlihat tegas
          ),
        ),
        SizedBox(height: 12.h),

        _buildInfoCheckItem("Pastikan Video sudah mencapai minimal views"),
        _buildInfoCheckItem(
          "Pastikan Video sudah menggunakan hashtag yang diminta",
        ),
        _buildInfoCheckItem("Pastikan Video sudah mention akun yang diminta"),
        _buildInfoCheckItem("Video sudah di-publish dan bisa diakses publik"),
      ],
    );
  }

  Widget _buildInfoCheckItem(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(SolarIconsBold.checkCircle, color: _neonGreen, size: 16.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12.sp,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: _darkInputBg,
      hintStyle: TextStyle(color: Colors.grey[600]),
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.r),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.r),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.r),
        borderSide: BorderSide(color: _neonGreen, width: 1.5),
      ),
    );
  }

  Widget _buildAccountDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel("Pilih Akun Sosmed Yang Digunakan"),

        if (_isLoadingAccounts)
          const Padding(
            padding: EdgeInsets.all(10),
            child: LinearProgressIndicator(color: Color(0xFFC8FF00)),
          )
        else if (_mySocialAccounts.isEmpty)
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.red.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                Icon(
                  SolarIconsBold.dangerTriangle,
                  color: Colors.red,
                  size: 20.sp,
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    "Anda belum menghubungkan akun sosmed. Silakan ke menu Profil dulu.",
                    style: TextStyle(color: Colors.red[200], fontSize: 12.sp),
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            decoration: BoxDecoration(
              color: _darkInputBg,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: _selectedAccountId != null
                    ? _neonGreen
                    : Colors.white.withOpacity(0.05),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedAccountId,
                hint: Text(
                  "Pilih akun...",
                  style: TextStyle(color: Colors.grey[600]),
                ),
                dropdownColor: const Color(0xFF1E1E1E),
                icon: const Icon(
                  SolarIconsOutline.altArrowDown,
                  color: Colors.white,
                ),
                isExpanded: true,
                items: _mySocialAccounts.map((item) {
                  return DropdownMenuItem<String>(
                    value: item['id'].toString(),
                    child: Row(
                      children: [
                        _getSocialIcon(item['provider_name']?.toString() ?? ''),
                        SizedBox(width: 10.w),
                        Text(
                          "${item['username']} (${item['provider_name']})",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.sp,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() => _selectedAccountId = val);
                },
              ),
            ),
          ),
        SizedBox(height: 16.h),
      ],
    );
  }

  Widget _getSocialIcon(String provider) {
    String p = provider.toLowerCase();

    print("🔍 Cek Logo untuk Provider: '$p'");

    if (p.contains('tiktok')) {
      return const FaIcon(
        FontAwesomeIcons.tiktok,
        color: Colors.white,
        size: 18,
      );
    } else if (p.contains('instagram')) {
      return const FaIcon(
        FontAwesomeIcons.instagram,
        color: Color(0xFFE1306C),
        size: 18,
      ); // Pink IG
    } else if (p.contains('youtube')) {
      return const FaIcon(
        FontAwesomeIcons.youtube,
        color: Color(0xFFFF0000),
        size: 18,
      ); // Merah YT
    } else if (p.contains('facebook')) {
      return const FaIcon(
        FontAwesomeIcons.facebook,
        color: Color(0xFF1877F2),
        size: 18,
      ); // Biru FB
    }

    // Default kalau tidak dikenali
    return const Icon(SolarIconsBold.global, color: Colors.grey, size: 18);
  }
}
