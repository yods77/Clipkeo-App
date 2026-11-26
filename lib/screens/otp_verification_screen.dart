import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../auth_service.dart';
import 'login_screen.dart';


class OtpVerificationScreen extends StatefulWidget {
  final String email; // Terima email dari halaman sebelumnya

  const OtpVerificationScreen({super.key, required this.email});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  void _handleResetPassword() async {
    if (_otpController.text.length < 6) {
      _showSnackBar("Masukkan 6 digit kode OTP");
      return;
    }
    if (_passwordController.text.length < 8) {
      _showSnackBar("Password minimal 8 karakter");
      return;
    }

    setState(() => _isLoading = true);
    
    final result = await _authService.resetPassword(
      email: widget.email,
      otp: _otpController.text,
      password: _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      _showSnackBar("Password berhasil diubah! Silakan login.");
      if (!mounted) return;
      // Balik ke halaman login dan hapus tumpukan halaman sebelumnya
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    } else {
      _showSnackBar(result['message'] ?? "Gagal mereset password");
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(25.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Verifikasi Kode 🛡️", 
              style: TextStyle(color: Colors.white, fontSize: 26.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 10.h),
            Text("Kami telah mengirimkan kode 6-digit ke ${widget.email}", 
              style: TextStyle(color: Colors.grey, fontSize: 14.sp)),
            
            SizedBox(height: 40.h),

            // Input Kode OTP
            _buildLabel("Kode OTP"),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              style: const TextStyle(color: Colors.white, letterSpacing: 10, fontSize: 20),
              textAlign: TextAlign.center,
              decoration: _inputStyle("000000"),
            ),

            SizedBox(height: 20.h),

            // Input Password Baru
            _buildLabel("Password Baru"),
            TextField(
              controller: _passwordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: _inputStyle("Masukkan password baru").copyWith(
                prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFFC8FF00)),
              ),
            ),

            SizedBox(height: 40.h),

            // Tombol Selesai
            SizedBox(
              width: double.infinity,
              height: 55.h,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleResetPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC8FF00),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.black)
                  : const Text("Reset Password", 
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Text(text, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14.sp)),
    );
  }

  InputDecoration _inputStyle(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      counterText: "",
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
    );
  }
}