import 'package:flutter/material.dart';
import '../auth_service.dart'; // Import service untuk koneksi ke server
import 'welcome_screen.dart'; // Import halaman animasi pembuka

class RegisterPhoneScreen extends StatefulWidget {
  // Variabel untuk menampung data akumulatif dari step sebelumnya
  final String name;
  final String email;
  final String password;

  const RegisterPhoneScreen({
    super.key, 
    required this.name,
    required this.email,
    required this.password,
  });

  @override
  State<RegisterPhoneScreen> createState() => _RegisterPhoneScreenState();
}

class _RegisterPhoneScreenState extends State<RegisterPhoneScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final AuthService _authService = AuthService(); // Instance Auth Service
  
  bool _isButtonDisabled = true; // Status tombol mati/hidup
  bool _isLoading = false;       // Status loading saat kirim data

  @override
  /**
   * -- Init State --
   * Menambahkan listener untuk memvalidasi panjang nomor HP secara realtime.
   * Tombol "Selesai" baru aktif jika nomor HP minimal 10 digit.
   */
  void initState() {
    super.initState();
    _phoneController.addListener(() {
      setState(() {
        _isButtonDisabled = _phoneController.text.trim().length < 10;
      });
    });
  }

  @override
  /**
   * -- Dispose --
   * Membersihkan controller saat halaman ditutup untuk mencegah kebocoran memori (memory leak).
   */
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  /**
   * -- Finish Registration --
   * Fungsi Final: Mengirim PAKET LENGKAP (Nama, Email, Password, No HP) ke Backend.
   * * Update:
   * - Menambahkan parameter '_phoneController.text' agar data No HP tersimpan di database.
   */
  
  void _finishRegistration() async {
    print(">>> TOMBOL DITEKAN! Nama: ${widget.name}, HP: ${_phoneController.text}");
    setState(() => _isLoading = true);

    // FIX: Mengirim 4 Parameter ke AuthService.register
    bool success = await _authService.register(
      widget.name, 
      widget.email, 
      widget.password,
      _phoneController.text // <--- UPDATE: Mengirim No HP yang diinput user
    );

    setState(() => _isLoading = false);

    if (success) {
      // Jika sukses, lanjut ke Halaman Animasi Welcome
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
      );
    } else {
      // Jika gagal, tampilkan pesan error
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Pendaftaran Gagal. Silakan coba email lain."),
          backgroundColor: Color(0xFFE60023),
        ),
      );
    }
  }

  @override
  /**
   * -- Build UI --
   * Menyusun tampilan input nomor HP dengan gaya konsisten (Black Theme & Pinterest Style).
   */
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        
        // Tombol Penyeimbang (Ghost Button) agar Title Dots presisi di tengah
        actions: [
          const Opacity(
            opacity: 0.0, 
            child: IconButton(
              icon: Icon(Icons.arrow_back_ios), 
              onPressed: null,
            ),
          ),
        ],

        // Indikator Progress (Titik-Titik)
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildDot(isActive: false), // Step 1 selesai (gelap)
            _buildDot(isActive: true),  // Step 2 aktif (terang)
            _buildDot(isActive: false),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 30),
              
              // Judul Halaman
              const Text(
                "Nomor WhatsApp?",
                style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              
              // Teks Sapaan Personal
              Text(
                "Halo ${widget.name}, kami butuh nomor untuk verifikasi.",
                style: TextStyle(color: Colors.grey.withOpacity(0.7), fontSize: 14),
              ),
              const SizedBox(height: 30),

              // Input Field Nomor HP
              TextField(
                controller: _phoneController,
                autofocus: true,
                keyboardType: TextInputType.phone, // Keyboard khusus Angka
                style: const TextStyle(color: Colors.white, fontSize: 18),
                decoration: InputDecoration(
                  hintText: "08xx xxxx xxxx",
                  hintStyle: TextStyle(color: Colors.grey.withOpacity(0.6)),
                  filled: true,
                  fillColor: Colors.transparent,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: Colors.white, width: 1.5),
                  ),
                  
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: Colors.white, width: 2),
                  ),
                ),
              ),

              const Spacer(), // Dorong tombol ke bawah

              // Tombol Selesai
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  // Matikan tombol jika input belum valid atau sedang loading
                  onPressed: (_isButtonDisabled || _isLoading) ? null : _finishRegistration,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC8FF00), // Merah Branding
                    disabledBackgroundColor: const Color(0xFF333333),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: _isLoading 
                    ? const SizedBox(
                        width: 20, 
                        height: 20, 
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      )
                    : Text(
                        "Selesai",
                        style: TextStyle(
                          color: _isButtonDisabled ? const Color.fromARGB(255, 212, 212, 212) : const Color.fromARGB(255, 5, 5, 5),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  /**
   * -- Dot Indicator Widget --
   * Widget kecil untuk membuat titik indikator langkah pendaftaran.
   */
  Widget _buildDot({required bool isActive}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.grey.withOpacity(0.3),
        shape: BoxShape.circle,
      ),
    );
  }
}