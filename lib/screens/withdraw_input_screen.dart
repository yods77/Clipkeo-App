import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:solar_icons/solar_icons.dart';
import 'withdraw_success_screen.dart';
import 'package:intl/intl.dart';
import '../services/wallet_service.dart';
import 'package:animate_do/animate_do.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import 'setup_pin_screen.dart';
import '../widgets/app_background_scaffold.dart';

class WithdrawInputScreen extends StatefulWidget {
  final double maxBalance;
  // Kita biarkan ini ada agar file Dashboard tidak error, TAPI KITA ABAIKAN ISINYA.
  final List<dynamic> payoutMethods;
  final VoidCallback onBack;

  const WithdrawInputScreen({
    super.key,
    required this.maxBalance,
    required this.payoutMethods,
    required this.onBack,
  });

  @override
  State<WithdrawInputScreen> createState() => _WithdrawInputScreenState();
}

class _WithdrawInputScreenState extends State<WithdrawInputScreen> {
  // -- STATE VARIABLES --
  List<dynamic> payoutMethods = []; // 🔥 Deklarasikan ini
  bool _isSubmitting = false;
  final WalletService _walletService = WalletService();
  String inputAmount = "0";
  List<dynamic>? _localBankList;

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
    return ""; // Kosong jika tidak ada logo
  }

  // Kita simpan data bank di sini (lokal), bukan pakai widget.payoutMethods lagi
  int? selectedBankId;

  final currencyFormat = NumberFormat.currency(
    locale: 'id',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _fetchBankData();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      payoutMethods = widget.payoutMethods;
    });
  }

  void _validatePinAndWithdraw() async {
    print("👆 [UI] Memulai Validasi Withdraw...");

    // 1. VALIDASI DASAR (KODE LAMA KAMU)
    double amount =
        double.tryParse(inputAmount.replaceAll('.', '')) ??
        0; // Tambah replaceAll biar aman
    if (amount < 50000) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Minimal Rp 50.000")));
      return;
    }
    if (amount > widget.maxBalance) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Saldo tidak cukup")));
      return;
    }
    if (selectedBankId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Pilih rekening dulu")));
      return;
    }

    // 2. TAMPILKAN LOADING (Sambil Cek Status PIN)
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(
        child: CircularProgressIndicator(color: Color(0xFFC8FF00)),
      ),
    );

    // 3. PANGGIL API CEK PIN
    print("🚀 [LOGIC] Cek Status PIN ke Server...");
    bool hasPin = await _walletService.checkPinStatus();

    Navigator.pop(context); // Tutup Loading
    print("🏁 [LOGIC] Status PIN: $hasPin");

    // 4. TENTUKAN ARAH
    if (hasPin) {
      // A. JIKA SUDAH PUNYA PIN -> Tampilkan Popup Input PIN (KODE LAMA KAMU)
      print("➡️ [NAV] User punya PIN. Buka Dialog Input PIN.");
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => _PinInputDialog(
          onPinSuccess: () {
            // Kalau PIN Benar, Panggil fungsi withdraw ASLI
            print("✅ [UI] PIN Benar. Eksekusi Withdraw!");
            _handleWithdraw();
          },
        ),
      );
    } else {
      // B. JIKA BELUM PUNYA PIN -> Buka Layar Setup PIN (KODE BARU)
      print("➡️ [NAV] User BELUM punya PIN. Buka Setup PIN.");
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SetupPinScreen(
            onSuccess: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    "PIN Berhasil dibuat! Silakan klik Tarik Dana kembali.",
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            },
          ),
        ),
      );
    }
  }

  // Fungsi untuk mengambil data segar dari API
  void _fetchBankData() async {
    // 1. Set jadi null biar Skeleton muncul
    setState(() {
      _localBankList = null;
    });

    try {
      List<dynamic> freshData = await _walletService.getPayoutMethods();

      if (mounted) {
        setState(() {
          _localBankList = freshData; // Isi data (Skeleton hilang otomatis)

          if (freshData.isNotEmpty) {
            selectedBankId = int.tryParse(freshData[0]['id'].toString());
          }
        });
      }
    } catch (e) {
      print("❌ Error: $e");
      if (mounted) {
        // Kalau error, anggap list kosong biar muncul pesan error (atau handling lain)
        setState(() => _localBankList = []);
      }
    }
  }

  // Helper untuk mendapatkan objek bank yang dipilih
  Map<String, dynamic>? get selectedBank {
    if (selectedBankId == null) return null;
    try {
      return _localBankList!.firstWhere(
        (bank) => int.tryParse(bank['id'].toString()) == selectedBankId,
        orElse: () => null,
      );
    } catch (e) {
      return null;
    }
  }

  // -- LOGIC PERHITUNGAN --
  double get rawAmount => double.tryParse(inputAmount) ?? 0;
  double get fee => rawAmount * 0.10;
  double get finalAmount => rawAmount - fee;

  // -- INPUT KEYPAD --
  void onKeyTap(String value) {
    setState(() {
      if (inputAmount == "0" && value != ".")
        inputAmount = value;
      else if (inputAmount.length < 10)
        inputAmount += value;
    });
  }

  void onBackspace() {
    setState(() {
      if (inputAmount.length > 1)
        inputAmount = inputAmount.substring(0, inputAmount.length - 1);
      else
        inputAmount = "0";
    });
  }

  // -- HANDLE WITHDRAW --
  void _handleWithdraw() async {
    if (selectedBankId == null) {
      _showSnackBar("Pilih bank tujuan terlebih dahulu", Colors.orange);
      return;
    }
    if (rawAmount < 50000) {
      _showSnackBar("Minimal penarikan adalah Rp 50.000", Colors.orange);
      return;
    }
    if (rawAmount > widget.maxBalance) {
      _showSnackBar("Saldo Anda tidak mencukupi", Colors.red);
      return;
    }

    setState(() => _isSubmitting = true);
    final success = await _walletService.requestWithdraw(
      amount: inputAmount,
      methodId: selectedBankId!,
    );
    setState(() => _isSubmitting = false);

    if (success) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WithdrawSuccessScreen(
            amount: inputAmount,
            finalAmount: finalAmount.toString(),
            bankName: selectedBank?['bank_name'] ?? "Bank",
          ),
        ),
      );
    } else {
      _showSnackBar("Gagal memproses, coba lagi nanti", Colors.red);
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print("========================================");
    print("🕵️ DEBUG SCREEN: Nilai maxBalance diterima: ${widget.maxBalance}");
    print("🕵️ DEBUG SCREEN: Tipe data: ${widget.maxBalance.runtimeType}");
    print("========================================");
    return AppBackgroundScaffold(
      child: Column(
        children: [
          _buildPremiumHeader(),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                children: [
                  SizedBox(height: 10.h),
                  Text(
                    currencyFormat.format(rawAmount),
                    style: TextStyle(
                      fontSize: 44.sp,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -2,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    "Saldo Tersedia: ${currencyFormat.format(widget.maxBalance)}",
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color.fromARGB(255, 58, 58, 58),
                    ),
                  ),

                  SizedBox(height: 25.h),

                  /** -- DROPDOWN BANK (Dengan Loading State) -- **/
                  _localBankList == null
                      ? const Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(),
                        )
                      : _buildBankInfoCard(),

                  if (rawAmount >= 50000) _buildReceiptBreakdown(),
                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ),
          _buildCompactKeypad(),
        ],
      ),
    );
  }

  Widget _buildPremiumHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 20.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 1. Tombol Back (Masuk dari Kiri)
          FadeInLeft(
            duration: const Duration(milliseconds: 600),
            child: _buildCircleBtn(Icons.arrow_back, widget.onBack),
          ),

          // 2. Judul (Turun dari Atas dengan sedikit delay)
          FadeInDown(
            duration: const Duration(milliseconds: 500),
            delay: const Duration(milliseconds: 200),
            child: Text(
              "Konfirmasi Nominal",
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 17.sp,
                color: const Color.fromARGB(
                  255,
                  34,
                  34,
                  34,
                ), // Pastikan warna kontras dengan background
              ),
            ),
          ),

          // 3. Tombol Info (Masuk dari Kanan)
          FadeInRight(
            duration: const Duration(milliseconds: 600),
            child: _buildCircleBtn(
              SolarIconsOutline.infoCircle,
              () => _showWithdrawInfo(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleBtn(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
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
      child: Icon(icon, size: 20.sp),
    ),
  );

  /**
   * -- KARTU BANK DENGAN POPUP MENU --
   * Menggantikan DropdownButton agar menu muncul RAPI DI BAWAH kartu,
   * tidak menutupi kartu (floating center) seperti perilaku default.
   */
  Widget _buildBankInfoCard() {
    // -----------------------------------------------------------
    // 1. LOGIKA SKELETON: Kalau data masih NULL, tampilkan Skeleton
    // (Ini menggantikan Spinner yang lama)
    // -----------------------------------------------------------
    if (_localBankList == null) {
      return _buildSkeletonLoading();
    }

    // -----------------------------------------------------------
    // 2. Kalau List KOSONG (Tapi bukan null), baru tampilkan Error
    // -----------------------------------------------------------
    if (_localBankList!.isEmpty) {
      return Container(
        padding: EdgeInsets.all(15.w),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                "Data Bank Kosong.\nSilahkan isi data bank terlebih dahulu.",
                style: TextStyle(color: Colors.red, fontSize: 12.sp),
              ),
            ),
          ],
        ),
      );
    }

    // -----------------------------------------------------------
    // 3. Render Data Asli (Kalau data sudah ada)
    // -----------------------------------------------------------
    // -----------------------------------------------------------
    // 3. Render Data Asli (Kalau data sudah ada)
    // -----------------------------------------------------------
    Map<String, dynamic>? currentBank;
    try {
      // 🔥 PERBAIKAN: Tambahkan tanda seru (!) setelah _localBankList
      // Artinya: "Gue jamin list ini gak null, jalanin aja!"
      currentBank = _localBankList!.firstWhere(
        (bank) => int.tryParse(bank['id'].toString()) == selectedBankId,
        orElse: () => _localBankList![0],
      );
    } catch (e) {
      currentBank = _localBankList![0];
    }

    // Ambil Logo (Pastikan fungsi _getBankLogoPath kamu ada di file ini)
    String mainLogoPath = _getBankLogoPath(currentBank?['bank_name'] ?? "");

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 18.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Row(
        children: [
          // --- LOGO BANK ---
          Container(
            width: 50.w,
            height: 34.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: mainLogoPath.isNotEmpty
                ? Image.asset(mainLogoPath, fit: BoxFit.contain)
                : Icon(SolarIconsBold.wallet, color: Colors.grey, size: 24.sp),
          ),

          SizedBox(width: 14.w),

          // --- INFO TEXT ---
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  currentBank?['bank_name'] ?? "-",
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13.sp,
                  ),
                ),
                Text(
                  "${currentBank?['account_number']} - ${currentBank?['account_name']}",
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // --- ICON VERIFIED ---
          Icon(
            SolarIconsBold.verifiedCheck,
            color: const Color.fromARGB(255, 0, 81, 255),
            size: 24.sp,
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptBreakdown() {
    return FadeInDown(
      from: 10,
      duration: const Duration(milliseconds: 800),
      delay: const Duration(milliseconds: 300),
      child: Container(
        margin: EdgeInsets.only(top: 10.h),
        padding: EdgeInsets.all(18.w),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(28.r),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 15,
              offset: Offset(0, 8),
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
                  "Admin Fee (10%)",
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  currencyFormat.format(fee),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13.sp,
                  ),
                ),
              ],
            ),
            const Icon(
              SolarIconsOutline.arrowRight,
              color: Color(0xFFC8FF00),
              size: 18,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "Dana Diterima",
                  style: TextStyle(
                    color: const Color(0xFFC8FF00),
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  currencyFormat.format(finalAmount),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15.sp,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactKeypad() {
    double systemPadding = MediaQuery.of(context).padding.bottom;
    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      child: Container(
        padding: EdgeInsets.fromLTRB(40.w, 20.h, 40.w, systemPadding + 20.h),
        decoration: BoxDecoration(
          color: const Color(0xFFF9F9FB),
          borderRadius: BorderRadius.vertical(top: Radius.circular(40.r)),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 5,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _keyRow(["1", "2", "3"]),
            SizedBox(height: 12.h),
            _keyRow(["4", "5", "6"]),
            SizedBox(height: 12.h),
            _keyRow(["7", "8", "9"]),
            SizedBox(height: 12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _keyBtn(".", isText: true),
                _keyBtn("0", isText: true),
                GestureDetector(
                  onTap: onBackspace,
                  child: Container(
                    width: 70.w,
                    height: 42.h,
                    color: Colors.transparent,
                    child: Icon(SolarIconsOutline.backspace, size: 24.sp),
                  ),
                ),
              ],
            ),
            SizedBox(height: 25.h),
            _buildWithdrawActionBtn(),
          ],
        ),
      ),
    );
  }

  Widget _buildWithdrawActionBtn() => GestureDetector(
    onTap: _isSubmitting ? null : _validatePinAndWithdraw,
    child: Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 18.h),
      decoration: BoxDecoration(
        color: _isSubmitting ? Colors.grey[400] : const Color(0xFFC8FF00),
        borderRadius: BorderRadius.circular(28.r),
        boxShadow: _isSubmitting
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 5,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      child: Center(
        child: _isSubmitting
            ? SizedBox(
                height: 20.h,
                width: 20.h,
                child: const CircularProgressIndicator(
                  color: Colors.black,
                  strokeWidth: 3,
                ),
              )
            : Text(
                "WITHDRAWAL",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14.sp,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    ),
  );

  Widget _keyRow(List<String> keys) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: keys.map((k) => _keyBtn(k)).toList(),
  );
  Widget _keyBtn(String v, {bool isText = true}) => GestureDetector(
    onTap: () => onKeyTap(v),
    child: Container(
      width: 70.w,
      height: 42.h,
      color: Colors.transparent,
      child: Center(
        child: Text(
          v,
          style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.w800),
        ),
      ),
    ),
  );
}

// --- TARUH DI PALING BAWAH FILE (DI LUAR CLASS UTAMA) ---

class _PinInputDialog extends StatefulWidget {
  final VoidCallback onPinSuccess;
  const _PinInputDialog({required this.onPinSuccess});

  @override
  State<_PinInputDialog> createState() => _PinInputDialogState();
}

class _PinInputDialogState extends State<_PinInputDialog> {
  final TextEditingController _pinController = TextEditingController();
  bool isChecking = false;
  String? errorText;
  String _currentPin = ""; // Untuk update UI kotak-kotak

  Future<void> _validatePin() async {
    if (_pinController.text.length < 6) return;

    setState(() {
      isChecking = true;
      errorText = null;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      // Validasi ke Server
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/wallet/validate-pin'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
        body: {'pin': _pinController.text},
      );

      if (response.statusCode == 200) {
        if (mounted) {
          Navigator.pop(context); // Tutup Popup
          widget.onPinSuccess(); // Lanjut Withdraw
        }
      } else {
        setState(() {
          errorText = "PIN Salah! Coba lagi.";
          _pinController.clear(); // Clear input biar user ngetik ulang
          _currentPin = "";
        });
      }
    } catch (e) {
      setState(() => errorText = "Gagal koneksi server.");
    } finally {
      if (mounted) setState(() => isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Gunakan Dialog transparan agar kita bisa custom bentuknya
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(20.w),
      child: ZoomIn(
        // 🔥 ANIMASI MUNCUL
        duration: const Duration(milliseconds: 300),
        child: Container(
          padding: EdgeInsets.all(25.w),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFC8FF00).withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- ICON GEMBOK ---
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFC8FF00).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  SolarIconsOutline.lockPassword,
                  color: const Color(0xFFC8FF00),
                  size: 28.sp,
                ),
              ),
              SizedBox(height: 16.h),

              // --- TITLE ---
              Text(
                "Verifikasi PIN",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18.sp,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                "Demi keamanan, masukkan 6 digit PIN kamu.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[500], fontSize: 12.sp),
              ),
              SizedBox(height: 24.h),

              // --- PIN INPUT AREA (STACK TRICK) ---
              Stack(
                alignment: Alignment.center,
                children: [
                  // 1. Invisible TextField (Buat nangkep keyboard)
                  TextField(
                    controller: _pinController,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    style: const TextStyle(color: Colors.transparent),
                    decoration: const InputDecoration(
                      counterText: "",
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                    showCursor: false,
                    enableSuggestions: false,
                    autocorrect: false,
                    onChanged: (val) {
                      setState(() {
                        _currentPin = val;
                        // Hapus error kalau user mulai ngetik lagi
                        if (val.isNotEmpty) errorText = null;
                      });
                      if (val.length == 6) _validatePin();
                    },
                  ),

                  // 2. Visual Boxes (Tampilan Keren)
                  // Kita abaikan sentuhan di sini biar tembus ke TextField
                  IgnorePointer(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(6, (index) {
                        bool isFilled = index < _currentPin.length;
                        bool isFocused = index == _currentPin.length;

                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 42.w,
                          height: 50.h,
                          decoration: BoxDecoration(
                            color: isFilled
                                ? const Color(0xFFC8FF00) // Warna Box Terisi
                                : Colors.black, // Warna Box Kosong
                            borderRadius: BorderRadius.circular(10.r),
                            border: Border.all(
                              // Logic Border: Kalau fokus nyala neon, kalau isi hijau, kalau kosong abu
                              color: isFocused
                                  ? const Color(0xFFC8FF00)
                                  : (isFilled
                                        ? const Color(0xFFC8FF00)
                                        : Colors.grey[800]!),
                              width: isFocused ? 2 : 1,
                            ),
                            boxShadow: isFocused
                                ? [
                                    BoxShadow(
                                      color: const Color(
                                        0xFFC8FF00,
                                      ).withOpacity(0.4),
                                      blurRadius: 8,
                                    ),
                                  ]
                                : [],
                          ),
                          child: Center(
                            child: isFilled
                                ? Container(
                                    // Titik Hitam di tengah
                                    width: 10.w,
                                    height: 10.w,
                                    decoration: const BoxDecoration(
                                      color: Colors.black,
                                      shape: BoxShape.circle,
                                    ),
                                  )
                                : null,
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),

              // --- ERROR TEXT ---
              if (errorText != null) ...[
                SizedBox(height: 16.h),
                FadeInUp(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    errorText!,
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],

              SizedBox(height: 24.h),

              // --- LOADING / CANCEL ---
              if (isChecking)
                const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Color(0xFFC8FF00),
                  ),
                )
              else
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(foregroundColor: Colors.grey),
                  child: const Text("Batalkan"),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- MODAL INFO PENARIKAN ---
void _showWithdrawInfo(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF1E1E1E), // Warna Gelap Premium
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
    ),
    builder: (context) {
      return FadeInUp(
        duration: const Duration(milliseconds: 600), // Durasi animasi
        child: Padding(
          padding: EdgeInsets.all(30.w),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Tinggi menyesuaikan isi
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Modal
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: 20.h),

              Row(
                children: [
                  Icon(
                    SolarIconsOutline.infoCircle,
                    color: const Color(0xFFC8FF00),
                    size: 28.sp,
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    "Info Penarikan",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              Divider(color: Colors.grey[800]),
              SizedBox(height: 20.h),

              // Poin-poin Informasi
              _buildInfoItem("1", "Minimal penarikan saldo adalah Rp 50.000."),
              _buildInfoItem("2", "Pastikan Nama & Nomor Rekening sesuai."),
              _buildInfoItem(
                "3",
                "Proses transfer biasanya instan (Realtime).",
              ),
              _buildInfoItem(
                "4",
                "Jika gagal, saldo akan otomatis dikembalikan.",
              ),

              SizedBox(height: 30.h),

              // Tombol Tutup
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC8FF00),
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    "Saya Mengerti",
                    style: TextStyle(
                      color: const Color.fromARGB(255, 43, 43, 43),
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                    ),
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

// Helper kecil untuk item info
Widget _buildInfoItem(String number, String text) {
  return Padding(
    padding: EdgeInsets.only(bottom: 12.h),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(6.w),
          decoration: BoxDecoration(
            color: const Color(0xFFC8FF00).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: TextStyle(
              color: const Color(0xFFC8FF00),
              fontWeight: FontWeight.bold,
              fontSize: 10.sp,
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 13.sp,
              height: 1.4,
            ),
          ),
        ),
      ],
    ),
  );
}

// 🔥 WIDGET BARU: SKELETON LOADING (Pulse Effect)
Widget _buildSkeletonLoading() {
  return Pulse(
    infinite: true, // Berdenyut terus
    duration: const Duration(milliseconds: 1000),
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 18.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05), // Agak transparan
        borderRadius: BorderRadius.circular(28.r),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          // Kotak Logo Abu-abu
          Container(
            width: 50.w,
            height: 34.h,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Baris Text Panjang (Judul)
                Container(
                  width: 100.w,
                  height: 12.h,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
                SizedBox(height: 8.h),
                // Baris Text Pendek (Sub-judul)
                Container(
                  width: 150.w,
                  height: 10.h,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(4.r),
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
