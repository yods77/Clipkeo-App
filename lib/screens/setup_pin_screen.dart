import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:solar_icons/solar_icons.dart';
import '../../services/wallet_service.dart';

class SetupPinScreen extends StatefulWidget {
  final VoidCallback onSuccess;

  const SetupPinScreen({Key? key, required this.onSuccess}) : super(key: key);

  @override
  State<SetupPinScreen> createState() => _SetupPinScreenState();
}

class _SetupPinScreenState extends State<SetupPinScreen> {
  final TextEditingController _pinController = TextEditingController();
  final WalletService _walletService = WalletService();
  bool _isLoading = false;
  String? _errorMessage;

  void _submitSetup() async {
    String pin = _pinController.text;

    print("👆 [UI] Tombol Simpan PIN ditekan. Input: $pin");

    if (pin.length != 6) {
      print("⚠️ [UI] Validasi Gagal: PIN bukan 6 digit");
      setState(() => _errorMessage = "PIN harus 6 digit angka");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Panggil Service
    bool success = await _walletService.setupPin(pin);

    setState(() => _isLoading = false);

    if (success) {
      widget.onSuccess();
      Navigator.pop(context);
    } else {
      setState(() => _errorMessage = "Gagal membuat PIN. Coba lagi.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(SolarIconsOutline.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Buat PIN Baru",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 20.h),
              const Icon(
                SolarIconsBold.shieldKeyhole,
                color: Color(0xFFC8FF00),
                size: 64,
              ),
              SizedBox(height: 20.h),
              Text(
                "Amankan Saldo Anda",
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 10.h),
              Text(
                "Buat 6 digit PIN keamanan untuk penarikan dana.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[400]),
              ),
              SizedBox(height: 40.h),

              TextField(
                controller: _pinController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                obscureText: true,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFFC8FF00),
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 12,
                ),
                decoration: InputDecoration(
                  counterText: "",
                  filled: true,
                  fillColor: const Color(0xFF1E1E1E),
                  hintText: "••••••",
                  hintStyle: TextStyle(
                    color: Colors.grey[700],
                    letterSpacing: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              if (_errorMessage != null) ...[
                SizedBox(height: 15.h),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ],

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitSetup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC8FF00),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          "Simpan PIN",
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }
}
