import 'package:flutter/material.dart';
import 'main_screen.dart';
import 'package:google_fonts/google_fonts.dart'; // 👈 Tambahkan ini

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      // Menggunakan warna dasar dashboard
      backgroundColor: const Color(0xFFF8F9FD),
      body: Stack(
        children: [
          // 🔥 1. GRADASI HIJAU NEON (KEMBALI HADIR) 🔥
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color.fromARGB(255, 0, 0, 0).withOpacity(0.2), // Hijau Neon Tipis di atas
                    const Color(
                      0xFFF8F9FD,
                    ).withOpacity(0.6), // Transisi ke warna dashboard
                    const Color(0xFFF8F9FD), // Solid warna dashboard di bawah
                  ],
                ),
              ),
            ),
          ),

          // 2. SENI UTAMA (LOGO & LINGKARAN)
          Positioned(
            top: size.height * 0.15,
            left: 0,
            right: 0,
            child: SizedBox(
              height: size.height * 0.4,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Lingkaran Besar Outline
                  Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color.fromARGB(
                          255,
                          0,
                          0,
                          0,
                        ).withOpacity(0.2),
                        width: 2,
                      ),
                    ),
                  ),

                  // Aksen Lingkaran Neon (Agar gradasi hijaunya makin kuat)
                  Positioned(
                    top: 40,
                    right: 60,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFC8FF00).withOpacity(0.4),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFC8FF00).withOpacity(0.2),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // LOGO KEO
                  Positioned(
                    child: Image.asset(
                      'assets/images/logo_full.png',
                      width: 200,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. BAGIAN TEKS & TOMBOL
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: EdgeInsets.only(
                left: 30,
                right: 30,
                top: 60,
                bottom: 30 + bottomPadding,
              ),
              width: double.infinity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Cuma Bikin Konten\nBisa Hasilin Uang",
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF1A1A1A),
                      fontSize: 32,
                      fontWeight: FontWeight.w700, // Super Bold / Black
                      letterSpacing: -1.5, // Huruf berdempet
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    "Bergabung dengan ribuan kreator Clipkeo. Selesaikan campaign, kumpulkan poin, dan tarik uang tunai kapan saja.",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Tombol 'Mulai Sekarang'
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MainScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFC8FF00),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 8,
                            shadowColor: const Color(
                              0xFFC8FF00,
                            ).withOpacity(0.4),
                          ),
                          child: const Text(
                            "Mulai Sekarang",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ]
              ),
            ),
          ),
        ],
      ),
    );
  }
}
