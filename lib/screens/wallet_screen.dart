import 'dart:convert'; // Tambahan untuk decode JSON
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Untuk SystemUiOverlay
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:animate_do/animate_do.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http; // Tambahan untuk request ke API User
import 'package:shared_preferences/shared_preferences.dart'; // Tambahan untuk Token
import '../config.dart'; // Pastikan path config benar
import '../services/wallet_service.dart';
import '../widgets/app_background_scaffold.dart';

class WalletScreen extends StatefulWidget {
  final VoidCallback onShowWithdraw; // 🔥 Tambahkan ini
  const WalletScreen({super.key, required this.onShowWithdraw});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final WalletService _walletService = WalletService();
  final currencyFormat = NumberFormat.currency(
    locale: 'id',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  // --- STATE VARIABLES ---
  Map<String, dynamic> _walletData = {};
  bool _isLoading = true;

  // Data User untuk Kartu Saldo (Default Value)
  String _displayName = "Clipkeo Member";
  String _bankName = "BANK";
  String _accountNumber = "---- ---- ----";

  @override
  void initState() {
    super.initState();
    // Ambil data dompet & data profil secara bersamaan
    _fetchAllData();
  }

  Future<void> _fetchAllData() async {
    await Future.wait([_fetchWalletData(), _fetchUserProfile()]);
    if (mounted) setState(() => _isLoading = false);
  }

  // 1. Ambil Data Saldo & Transaksi
  Future<void> _fetchWalletData() async {
    try {
      final data = await _walletService.getWalletDashboard();
      if (mounted) setState(() => _walletData = data);
    } catch (e) {
      print("Error Wallet: $e");
    }
  }

  // 2. Ambil Data User (Nama & Bank)
  Future<void> _fetchUserProfile() async {
    print("🕵️‍♂️ [DETEKTIF] Memulai Penyelidikan Data User...");
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      print(
        "🔑 [DETEKTIF] Token ditemukan: ${token != null ? "YA (Ada isinya)" : "TIDAK (Null)"}",
      );

      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/user'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print("📡 [DETEKTIF] Status Server: ${response.statusCode}");
      print("📦 [DETEKTIF] Data Mentah (Body): ${response.body}");

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final user = json['data'] ?? json;

        print("🧐 [DETEKTIF] Menganalisa Data User:");
        print("    - Name di JSON: ${user['name']}");
        print("    - Bank (Key: bank_name): ${user['bank_name']}");
        print("    - Bank (Key: bank): ${user['bank']}");
        print(
          "    - Rekening (Key: account_number): ${user['account_number']}",
        );
        print("    - Rekening (Key: bank_number): ${user['bank_number']}");

        if (mounted) {
          setState(() {
            // Logika Pengambilan Nama
            _displayName = user['name'] ?? "Clipkeo Member";

            // Logika Pengambilan Bank (Cari di semua kemungkinan key)
            String? bank = user['bank_name'] ?? user['bank'];

            // Logika Pengambilan Rekening
            String? rek = user['account_number'] ?? user['bank_number'];

            if (bank != null && bank.isNotEmpty) {
              _bankName = bank;
              print("✅ [DETEKTIF] Bank berhasil diset ke: $_bankName");
            } else {
              print("⚠️ [DETEKTIF] Bank kosong/null dari server");
            }

            if (rek != null && rek.isNotEmpty) {
              _accountNumber = rek;
              print("✅ [DETEKTIF] Rekening berhasil diset ke: $_accountNumber");
            } else {
              print("⚠️ [DETEKTIF] Rekening kosong/null dari server");
            }
          });
        }
      } else {
        print("❌ [DETEKTIF] Gagal ambil data. Kode error server.");
      }
    } catch (e) {
      print("❌ [DETEKTIF] ERROR CRASH: $e");
    }
  }

  // Helper untuk Logo Bank
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

  @override
  Widget build(BuildContext context) {
    final num balance = _walletData['balance'] ?? 0;
    final List transactions = _walletData['transactions'] as List? ?? [];

    return AppBackgroundScaffold(
      child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFC8FF00)),
            )
          : RefreshIndicator(
              onRefresh: _fetchAllData, // Refresh semua data saat ditarik
              color: const Color(0xFFC8FF00),
              child: Stack(
                children: [
                  SafeArea(
                    child: Column(
                      children: [
                        _buildTopBar(context),
                        Expanded(
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.fromLTRB(
                              24.w,
                              10.h,
                              24.w,
                              40.h,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildBalanceCard(balance),
                                SizedBox(height: 40.h),
                                FadeInUp(
                                  duration: const Duration(milliseconds: 600),
                                  delay: const Duration(
                                    milliseconds: 100,
                                  ), // Muncul setelah kartu saldo turun
                                  child: Text(
                                    "Riwayat Transaksi",
                                    style: TextStyle(
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.w800,
                                      color: const Color.fromARGB(
                                        255,
                                        22,
                                        22,
                                        22,
                                      ), // Pastikan warna sesuai tema gelapmu
                                    ),
                                  ),
                                ),
                                SizedBox(height: 20.h),
                                transactions.isEmpty
                                    ? _buildEmptyState()
                                    : _buildTransactionItems(transactions),
                              ],
                            ),
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

  // --- HEADER & TOP BAR ---
  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 10.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(width: 45.w),
          Text(
            "Dompet Digital",
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w800),
          ),
          SizedBox(width: 45.w),
        ],
      ),
    );
  }

  // --- KARTU SALDO UTAMA (UPDATED: REAL USER DATA) ---
  Widget _buildBalanceCard(num balance) {
    const Color accentColor = Color(0xFFC8FF00);

    // Ambil Logo Bank berdasarkan nama bank user
    String logoPath = _getBankLogoPath(_bankName);

    return FadeInDown(
      duration: const Duration(milliseconds: 800),
      delay: const Duration(milliseconds: 200),
      child: AspectRatio(
        aspectRatio: 1.58,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A1A1A), Color(0xFF252525)],
            ),
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(color: accentColor.withOpacity(0.15), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 25,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // --- HEADER KARTU ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // KIRI: Label & Nama User
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Saldo Utama",
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          // NAMA USER ASLI
                          SizedBox(
                            width:
                                150.w, // Batasi lebar agar tidak menabrak logo
                            child: Text(
                              _displayName.toUpperCase(),
                              style: TextStyle(
                                color: accentColor.withOpacity(0.9),
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w800,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // KANAN: Logo Bank (Menggantikan Icon Wifi)
                      Container(
                        width: 60.w,
                        height: 38.h,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: logoPath.isNotEmpty
                            ? Image.asset(logoPath, fit: BoxFit.contain)
                            : Center(
                                child: Text(
                                  "BANK",
                                  style: TextStyle(
                                    fontSize: 8.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),

                  // --- SALDO UTAMA ---
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 5.h),
                    child: Text(
                      currencyFormat.format(balance),
                      style: TextStyle(
                        fontSize: 30.sp,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),

                  // --- FOOTER KARTU ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // INFO REKENING
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _bankName.toUpperCase(),
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 9.sp,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                          SizedBox(height: 2.h),

                          // 🔥 UPDATE DI SINI: MASKING NOMOR 🔥
                          Text(
                            _maskAccountNumber(
                              _accountNumber,
                            ), // <-- Pakai fungsi helper tadi
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              letterSpacing:
                                  2.0, // Spasi agak lebar biar bintangnya rapi
                            ),
                          ),
                        ],
                      ),

                      // Tombol Tarik Saldo
                      Material(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(50),
                        child: InkWell(
                          onTap: () {
                            _showWithdrawModal(context, balance);
                          },
                          borderRadius: BorderRadius.circular(50),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 8.h,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(50),
                              boxShadow: [
                                BoxShadow(
                                  color: accentColor.withOpacity(0.4),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  SolarIconsBold.cardTransfer,
                                  size: 16.sp,
                                  color: Colors.black,
                                ),
                                SizedBox(width: 6.w),
                                Text(
                                  "Tarik Saldo",
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- RIWAYAT TRANSAKSI (STYLE PREMIUM) ---
  Widget _buildTransactionItems(List transactions) {
    return Column(
      children: transactions.asMap().entries.map((entry) {
        int index = entry.key; // Index urutan (0, 1, 2...)
        var trx = entry.value; // Data transaksi asli
        bool isWithdraw = trx['type'] != 'reward';
        return FadeInUp(
          // 🔥 2. Bungkus dengan FadeInUp
          // 🔥 3. Atur delay berdasarkan index (makin ke bawah makin lambat munculnya)
          delay: Duration(milliseconds: 400 * index),
          duration: const Duration(milliseconds: 600),
          child: Container(
            height: 90.h,
            margin: EdgeInsets.only(bottom: 18.h),
            padding: EdgeInsets.symmetric(horizontal: 18.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 6,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildPremiumIcon(isWithdraw),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trx['description'] ?? 'Transaksi',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13.sp,
                          color: Colors.black,
                          letterSpacing: -0.3,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        DateFormat(
                          'dd MMM yyyy, HH:mm',
                        ).format(DateTime.parse(trx['created_at'])),
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  isWithdraw
                      ? "- ${currencyFormat.format(double.tryParse(trx['amount'].toString()) ?? 0)}"
                      : "+ ${currencyFormat.format(double.tryParse(trx['amount'].toString()) ?? 0)}",
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 12.sp,
                    color: isWithdraw ? Colors.red[700] : Colors.green[700],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPremiumIcon(bool isWithdraw) {
    Color baseColor = isWithdraw ? Colors.red[600]! : Colors.green[600]!;

    return Container(
      width: 56.w,
      height: 56.w,
      decoration: BoxDecoration(
        color: baseColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(SolarIconsBold.wallet, color: baseColor, size: 28.sp),
          Positioned(
            right: 8.w,
            top: 10.h,
            child: Container(
              padding: EdgeInsets.all(2.w),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isWithdraw
                    ? SolarIconsBold.arrowRightUp
                    : SolarIconsBold.arrowLeftDown,
                color: baseColor,
                size: 14.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() => Center(
    child: Padding(
      padding: EdgeInsets.only(top: 40.h),
      child: const Text(
        "Belum ada riwayat transaksi.",
        style: TextStyle(color: Colors.grey),
      ),
    ),
  );

  void _showWithdrawModal(BuildContext context, num balance) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111111),
      isScrollControlled: true,
      transitionAnimationController: AnimationController(
        vsync: Navigator.of(context),
        duration: const Duration(milliseconds: 500),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
      ),
      builder: (context) {
        final double bottomPadding = MediaQuery.of(context).viewPadding.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 40.h + bottomPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FadeInDown(
                duration: const Duration(milliseconds: 400),
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              Container(
                padding: EdgeInsets.all(15.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFC8FF00).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  SolarIconsBold.cardTransfer,
                  color: const Color(0xFFC8FF00),
                  size: 30.sp,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                "Tarik Saldo",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                "Pastikan data rekening Anda sudah benar\nsebelum melanjutkan.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[500], fontSize: 12.sp),
              ),
              SizedBox(height: 30.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // 1. Tutup Dialog atau BottomSheet-nya dulu
                    Navigator.pop(context);

                    // 2. Pindah ke halaman Withdraw via MainScreen (Index 6)
                    // Pastikan widget ini sudah menerima parameter onShowWithdraw
                    widget.onShowWithdraw();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC8FF00),
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.r),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    "Lanjut ke Penarikan",
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

String _maskAccountNumber(String number) {
  // 1. Bersihkan input (hapus spasi/strip jika ada) biar aman
  String cleanNum = number.replaceAll(RegExp(r'[^0-9]'), '');

  // 2. Kalau nomornya kependekan (misal error), tampilkan apa adanya
  if (cleanNum.length <= 4) return number;

  // 3. Ambil 4 digit terakhir
  String last4 = cleanNum.substring(cleanNum.length - 4);

  // 4. Gabungkan dengan bintang-bintang estetik
  return "**** **** $last4";
}
