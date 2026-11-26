import 'package:flutter/material.dart';
import '../auth_service.dart';
import 'dart:async';
import 'register_name_screen.dart'; // Import halaman input nama
import 'main_screen.dart'; // Panggil file induknya
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'welcome_screen.dart';
import 'ForgotPasswordScreen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  String? _passwordErrorMessage;

  // --- STATE VISIBILITAS PASSWORD ---
  // Default false artinya password tersembunyi (titik-titik) saat pertama buka
  bool _isPasswordVisible = false;

  // --- VARIABEL ANIMASI BACKGROUND ---
  late ScrollController _scrollController1;
  late ScrollController _scrollController2;
  late ScrollController _scrollController3;
  Timer? _autoScrollTimer;

  // Pakai cara paling simpel
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  @override
  /**
   * -- Init State --
   * Menyiapkan controller untuk 3 kolom gambar background dan memulai animasi auto-scroll.
   */
  void initState() {
    super.initState();
    _scrollController1 = ScrollController();
    _scrollController2 = ScrollController();
    _scrollController3 = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAutoScrolling();
    });
  }

  @override
  /**
   * -- Dispose State --
   * Membersihkan timer dan controller saat widget dihapus agar tidak boros memori.
   */
  void dispose() {
    _autoScrollTimer?.cancel();
    _scrollController1.dispose();
    _scrollController2.dispose();
    _scrollController3.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /**
   * -- Auto Scroll Animation --
   * Menggerakkan 3 kolom gambar background dengan kecepatan berbeda (Efek Parallax).
   */
  void _startAutoScrolling() {
    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 50), (
      timer,
    ) {
      if (_scrollController1.hasClients &&
          _scrollController2.hasClients &&
          _scrollController3.hasClients) {
        _scrollController1.animateTo(
          _scrollController1.offset + 1,
          duration: const Duration(milliseconds: 50),
          curve: Curves.linear,
        );
        _scrollController2.animateTo(
          _scrollController2.offset + 1.8,
          duration: const Duration(milliseconds: 50),
          curve: Curves.linear,
        );
        _scrollController3.animateTo(
          _scrollController3.offset + 1.3,
          duration: const Duration(milliseconds: 50),
          curve: Curves.linear,
        );
      }
    });
  }

  // --- FUNGSI PEMBANTU: SIMPAN SESSION ---
  Future<void> _performSaveSession(Map<String, dynamic> result) async {
    print("💾 [SAVE SESSION] Memulai proses simpan data...");
    print("📦 [DEBUG DATA] Data diterima: $result"); // Lihat isi data mentah

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userIdToSave;
      String? userNameToSave;
      String? tokenToSave; // Tambahan untuk token

      // 1. Coba ambil dari result['user'] (Format standar)
      if (result['user'] != null) {
        print("✅ [LOGIC] Menemukan format result['user']");
        userIdToSave = result['user']['id'].toString();
        userNameToSave = result['user']['name'].toString();
      }
      // 2. Coba ambil dari result['data']['user'] (Format nested)
      else if (result['data'] != null && result['data']['user'] != null) {
        print("✅ [LOGIC] Menemukan format result['data']['user']");
        userIdToSave = result['data']['user']['id'].toString();
        userNameToSave = result['data']['user']['name'].toString();
      }

      // 3. Cek Token juga sekalian
      if (result['token'] != null) {
        tokenToSave = result['token'];
      }

      // EKSEKUSI SIMPAN
      if (userIdToSave != null) {
        await prefs.setString('user_id', userIdToSave);
        print("💾 [SUCCESS] User ID ($userIdToSave) BERHASIL DISIMPAN!");

        if (userNameToSave != null) {
          await prefs.setString('user_name', userNameToSave);
        }

        if (tokenToSave != null) {
          await prefs.setString('token', tokenToSave);
          print("🔑 [SUCCESS] Token BERHASIL DISIMPAN!");
        }
      } else {
        print("⚠️ [WARNING] Gagal menemukan ID User di dalam JSON server.");
      }
    } catch (e) {
      print("❌ [ERROR CRITICAL] Gagal Simpan Session: $e");
    }
  }

  // --- FUNGSI PEMBANTU: NAVIGASI KE REGISTER ---
  void _navigateToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RegisterNameScreen(
          email: _emailController.text,
          password: _passwordController.text,
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(
          0xFFE60023,
        ), // Warna merah branding Clipkeo
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /*
  |--------------------------------------------------------------------------
  | HANDLE LOGIN (UPDATE: SAVE SESSION)
  |--------------------------------------------------------------------------
  | Menambahkan logika penyimpanan ID User ke SharedPreferences
  | agar bisa dipakai di halaman lain (seperti saat Submit Campaign).
  */
  // GANTI BAGIAN _handleLogin DENGAN INI:

  void _handleLogin() async {
    // 1. Reset State
    setState(() {
      _isLoading = true;
      _passwordErrorMessage = null;
    });

    // 2. Panggil Service Login
    // Debug Print untuk melihat respon asli di Console
    print("🚀 Melakukan Login ke: ${_authService.baseUrl}");

    Map<String, dynamic> result = await _authService.login(
      _emailController.text,
      _passwordController.text,
    );

    print("🕵️ HASIL RESULT: $result"); // <--- Cek ini di console nanti

    setState(() => _isLoading = false);

    // 3. LOGIKA PENENTUAN NASIB
    if (result['success'] == true) {
      // --- JIKA SUKSES ---
      await _performSaveSession(result);

      // Cek apakah benar-benar user baru (Namanya kosong)
      if (result['is_new_user'] == true) {
        print("⚠️ Terdeteksi User Baru (Nama Kosong) -> Ke Register");
        _navigateToRegister();
      } else {
        print("✅ User Lama -> Ke Dashboard");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
    } else {
      // --- JIKA GAGAL (ERROR) ---
      if (!mounted) return;
      String message =
          result['message']?.toString().toLowerCase() ?? "unknown error";
      print("❌ LOGIN GAGAL: $message");

      // Skenario 1: Password Salah
      if (message.contains("password") ||
          message.contains("credentials") ||
          message.contains("salah")) {
        setState(() {
          _passwordErrorMessage = "Password atau Email salah!";
        });
      }
      // Skenario 2: User Tidak Ditemukan (BARU BOLEH KE REGISTER)
      else if (message.contains("tidak ditemukan") ||
          message.contains("not found")) {
        _navigateToRegister();
      }
      // Skenario 3: ERROR LAIN (Koneksi, Server, IP Salah) -> JANGAN KE REGISTER!
      else {
        // Tampilkan Dialog Error biar kita tahu salahnya dimana
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Gagal Login"),
            content: Text(
              "Masalah Koneksi/Server:\n\n$message\n\n(Cek IP Address & Internet)",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _handleGoogleLogin() async {
    try {
      // 1. Pilih Akun Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return; // User batal pilih akun

      setState(() => _isLoading = true);

      // 2. Kirim ke Backend Laravel
      final result = await _authService.loginWithGoogle(
        email: googleUser.email,
        googleId: googleUser.id,
        name: googleUser.displayName ?? "User Clipkeo",
        photoUrl: googleUser.photoUrl,
      );

      setState(() => _isLoading = false);

      if (result['success'] == true) {
        // ✅ BERHASIL! Langsung lempar ke WelcomeScreen
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        );
      } else {
        // Tampilkan error jika gagal
        _showErrorSnackBar(result['message']);
      }
    } catch (error) {
      setState(() => _isLoading = false);
      _showErrorSnackBar("Terjadi kesalahan: $error");
    }
  }

  @override
  /**
   * -- Build UI --
   * Menyusun tampilan halaman Login dengan Logo KEO dan Input Field.
   */
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 0, 0, 0),
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // 1. Background Animasi
          Positioned.fill(
            child: Opacity(opacity: 0.6, child: _buildAnimatedImageGrid()),
          ),

          // 2. Overlay Gelap
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color.fromARGB(255, 0, 0, 0).withOpacity(0.4),
                    const Color.fromARGB(255, 0, 0, 0).withOpacity(0.9),
                    const Color.fromARGB(255, 0, 0, 0),
                  ],
                ),
              ),
            ),
          ),

          // 3. Form Utama
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 34.0,
                vertical: 30,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // --- UPDATE: GANTI LOGO DI SINI ---
                  // Mengganti Icon Petir dengan Logo KEO (logo-1.png)
                  Image.asset(
                    'assets/images/logo_full.png',
                    height: 200, // Ukuran disesuaikan agar proporsional
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 5),
                  // Input Email
                  _buildDarkInput(
                    controller: _emailController,
                    label: "Email",
                    icon: Icons.email_outlined,
                  ),
                  const SizedBox(height: 16),

                  // Input Password (Dengan Fitur Mata)
                  _buildDarkInput(
                    controller: _passwordController,
                    label: "Password",
                    icon: Icons.lock_outline,
                    isPassword: true, // Mengaktifkan mode password
                  ),
                  // Tampilkan teks merah hanya jika ada error
                  if (_passwordErrorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, left: 20),
                      child: Text(
                        _passwordErrorMessage!,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ForgotPasswordScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      "Lupa Password?",
                      style: TextStyle(
                        color: Color(0xFFC8FF00),
                        fontSize: 12,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                  ),
                  const SizedBox(height: 10),

                  // Tombol MASUK
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC8FF00),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                          side: const BorderSide(
                            color: Color.fromARGB(255, 107, 107, 107),
                          ),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "Masuk",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color.fromARGB(255, 0, 0, 0),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Divider "atau"
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: const Color.fromARGB(
                            255,
                            255,
                            255,
                            255,
                          ).withOpacity(0.3),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 15),
                        child: Text(
                          "atau",
                          style: TextStyle(
                            color: Color.fromARGB(255, 255, 255, 255),
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: const Color.fromARGB(
                            255,
                            255,
                            255,
                            255,
                          ).withOpacity(0.3),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Tombol Google
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : _handleGoogleLogin,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        splashFactory: InkRipple.splashFactory,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/google_logo.png',
                            height: 24,
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            "Lanjutkan dengan Google",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),

          // 4. Disclaimer Footer
          Positioned(
            bottom: 70,
            left: 20,
            right: 20,
            child: _buildDisclaimerCaption(),
          ),
        ],
      ),
    );
  }

  /**
   * -- Widget Helper: Caption Footer --
   * Menampilkan teks persetujuan layanan di bagian bawah layar.
   */
  Widget _buildDisclaimerCaption() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Text(
        "Dengan melanjutkan, berarti Anda menyetujui Persyaratan Layanan Clipsquad dan menyatakan bahwa Anda telah membaca Kebijakan Privasi kami. Pemberitahuan saat persetujuan diminta.",
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white.withOpacity(0.7),
          fontSize: 11,
          height: 1.2,
        ),
      ),
    );
  }

  /**
   * -- Widget Helper: Grid Gambar --
   * Membuat grid 3 kolom untuk animasi background parallax.
   */
  Widget _buildAnimatedImageGrid() {
    return Row(
      children: [
        _buildColumn(_scrollController1, [
          "assets/images/1_TikTok.jpg",
          "assets/images/2_Instagram.jpg",
        ]),
        const SizedBox(width: 8),
        _buildColumn(_scrollController2, [
          "assets/images/3_TikTok.jpg",
          "assets/images/4_Instagram.jpg",
        ]),
        const SizedBox(width: 8),
        _buildColumn(_scrollController3, [
          "assets/images/5_TikTok.jpg",
          "assets/images/6_Instagram.jpg",
        ]),
      ],
    );
  }

  /**
   * -- Widget Helper: Kolom Gambar --
   * Membuat satu kolom yang berisi daftar gambar yang bisa di-scroll.
   */
  Widget _buildColumn(ScrollController controller, List<String> urls) {
    return Expanded(
      child: ListView.builder(
        controller: controller,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) =>
            _imgTile(urls[index % urls.length], index % 2 == 0 ? 250 : 200),
      ),
    );
  }

  /**
   * -- Widget Helper: Kotak Gambar --
   * Merender satu kotak gambar dengan sudut membulat.
   */
  Widget _imgTile(String path, double height) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: DecorationImage(image: AssetImage(path), fit: BoxFit.cover),
      ),
    );
  }

  /**
   * -- Widget Helper: Input Field Gelap --
   * Membuat Text Field dengan tema gelap dan mendukung fitur Show/Hide Password.
   */
  Widget _buildDarkInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      // LOGIKA OBSCURE:
      // Jika isPassword=false (Email) -> obscureText = false (Teks terlihat)
      // Jika isPassword=true (Pass) -> obscureText ikut status _isPasswordVisible (Toggle)
      obscureText: isPassword ? !_isPasswordVisible : false,
      style: const TextStyle(color: Colors.white),
      cursorColor: const Color.fromARGB(255, 217, 255, 0),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
        filled: true,
        fillColor: const Color.fromARGB(204, 0, 0, 0),
        prefixIcon: Icon(icon, color: const Color.fromARGB(255, 255, 255, 255)),

        // Ikon Mata (Hanya muncul jika ini adalah field Password)
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: const Color.fromARGB(255, 255, 255, 255),
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(
            color: Color.fromARGB(255, 255, 255, 255),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(
            color: Color.fromARGB(
              255,
              187,
              255,
              0,
            ), // Tetap Putih (Bisa ganti warna lain misal Kuning/Cyan)
            width: 1.0, // Kita bikin agak tebal biar kelihatan lagi aktif
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 14,
        ),
      ),
    );
  }
}
