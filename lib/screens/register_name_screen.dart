import 'package:flutter/material.dart';
import 'register_phone_screen.dart';

class RegisterNameScreen extends StatefulWidget {
  // Variabel penampung data dari halaman Login
  final String email;
  final String password;

  const RegisterNameScreen({
    super.key, 
    required this.email, 
    required this.password
  });

  @override
  State<RegisterNameScreen> createState() => _RegisterNameScreenState();
}

class _RegisterNameScreenState extends State<RegisterNameScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _isButtonDisabled = true;

  @override
  /**
   * -- Init State --
   * Menambahkan listener pada controller input nama.
   * Jika kolom nama kosong, tombol "Berikutnya" akan dimatikan (disabled).
   */
  void initState() {
    super.initState();
    _nameController.addListener(() {
      setState(() {
        _isButtonDisabled = _nameController.text.trim().isEmpty;
      });
    });
  }

  @override
  /**
   * -- Dispose --
   * Membersihkan controller saat halaman ditutup untuk mencegah kebocoran memori.
   */
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /**
   * -- Go To Next Step --
   * Fungsi navigasi ke halaman input Nomor HP (Step 2).
   * Membawa serta Email & Password (dari Login) dan Nama (Inputan User).
   */
  void _goToNextStep() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RegisterPhoneScreen(
          email: widget.email,      // Oper data email dari Login
          password: widget.password, // Oper data password dari Login
          name: _nameController.text, // Oper nama yang barusan diisi
        ),
      ),
    );
  }

  @override
  /**
   * -- Build UI --
   * Menyusun tampilan utama halaman input nama dengan gaya Pinterest (Black Theme).
   */
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Background Hitam Premium
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        
        // Tombol Hantu (Ghost Action) untuk menyeimbangkan posisi Title (Dots) agar presisi di tengah
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
          mainAxisSize: MainAxisSize.min, // Agar Row rapat ke tengah
          children: [
            _buildDot(isActive: true),  // Step 1 Aktif
            _buildDot(isActive: false),
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
              
              // Judul Pertanyaan Utama
              const Text(
                "Siapa nama Anda?",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 30),

              // Input Field Nama (Style Outline Putih Pinterest)
              TextField(
                controller: _nameController,
                autofocus: true, // Keyboard otomatis muncul
                style: const TextStyle(color: Colors.white, fontSize: 18),
                decoration: InputDecoration(
                  hintText: "Nama lengkap",
                  hintStyle: TextStyle(color: Colors.grey.withOpacity(0.6)),
                  filled: true,
                  fillColor: Colors.transparent,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  
                  // Border saat diam (Putih Tipis)
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: Colors.white, width: 1.5),
                  ),
                  
                  // Border saat diketik (Putih Tebal)
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: Colors.white, width: 2),
                  ),
                ),
              ),

              const Spacer(), // Mendorong tombol ke bawah layar

              // Tombol "Berikutnya"
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isButtonDisabled ? null : _goToNextStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC8FF00), // Abu gelap saat mati
                    disabledBackgroundColor: const Color(0xFF222222),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    "Berikutnya",
                    style: TextStyle(
                      color: _isButtonDisabled ? const Color.fromARGB(255, 219, 219, 219) : const Color.fromARGB(255, 19, 19, 19),
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
   * Widget kecil untuk membuat titik indikator progress di AppBar.
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