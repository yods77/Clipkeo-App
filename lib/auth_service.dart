import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';

class AuthService {
  // --- KONFIGURASI ---
  // Pastikan IP ini benar (Cek pakai ipconfig di cmd laptop)
  // Jika pakai Emulator Android Studio, ganti jadi "http://10.0.2.2:8000/api"
  final String baseUrl = AppConfig.baseUrl;

  /**
   * -- Fungsi Login (REVISI: STRICT MODE) --
   * Sekarang kita hanya fokus mengambil data dari key 'user'.
   * Tidak ada lagi tebak-tebakan 'data' atau 'root'.
   */
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/login'),
        body: {'email': email, 'password': password},
      );

      print("🕵️ STATUS CODE: ${response.statusCode}");
      print("🕵️ JSON SERVER: ${response.body}");

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        await _performSaveSession(data);

        // 1. SIMPAN TOKEN
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String token = data['access_token'] ?? data['token'] ?? '';
        await prefs.setString('token', token);

        // 2. AMBIL DATA USER (LOGIKA TEGAS)
        // Kita cari langsung di key 'user' sesuai janji Laravel
        Map<String, dynamic>? userData;

        if (data['user'] != null) {
          userData = Map<String, dynamic>.from(data['user']);
        }
        // Fallback: Jaga-jaga kalau Laravel lupa di-update, kita cek 'data'
        else if (data['data'] != null) {
          userData = Map<String, dynamic>.from(data['data']);
        }

        // 3. LOGIKA PENENTUAN "USER BARU"
        bool isNewUser = false;

        if (userData != null) {
          // Kita simpan Nama & Email ke HP biar loading profil cepet
          await prefs.setString('user_name', userData['name'] ?? '');
          await prefs.setString('user_email', userData['email'] ?? '');

          // Cek apakah namanya kosong?
          String nameCheck = userData['name'] ?? '';
          if (nameCheck.trim().isEmpty) {
            isNewUser = true; // Nama kosong -> Lempar ke Isi Nama
          }
        } else {
          // BAHAYA: Login sukses tapi data user gak kebaca
          // Jangan anggap user baru, tapi anggap Error biar kita sadar
          return {
            'success': false,
            'message': 'Gagal membaca data user dari server.',
          };
        }

        return {
          'success': true,
          'is_new_user': isNewUser,
          'message': 'Login Berhasil',
          'user': userData,
        };
      } else {
        // Handle Error Login (Password salah dll)
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'is_new_user': false,
          'message': errorData['message'] ?? 'Email atau Password salah',
        };
      }
    } catch (e) {
      print("Error Login: $e");
      return {
        'success': false,
        'is_new_user': false,
        'message': 'Error koneksi: $e',
      };
    }
  }

  /**
   * -- Fungsi Register --
   * Auto Login setelah daftar sukses.
   */
  Future<bool> register(
    String name,
    String email,
    String password,
    String phoneNumber,
  ) async {
    try {
      print("Mendaftarkan: $email...");
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        body: {
          'name': name,
          'email': email,
          'password': password,
          'phone_number': phoneNumber,
        },
      );

      print("Status Register: ${response.statusCode}");

      if (response.statusCode == 201 || response.statusCode == 200) {
        print("Register Sukses. Melakukan Auto-Login...");

        // Panggil login supaya Token tersimpan di SharedPreferences
        await login(email, password);

        return true;
      } else {
        print("❌ Register Gagal: ${response.body}");
        return false;
      }
    } catch (e) {
      print("❌ Error Register: $e");
      return false;
    }
  }

  Future<void> _performSaveSession(Map<String, dynamic> result) async {
    print("💾 [AUTH] Menyimpan sesi login...");
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      String? userIdToSave;
      String? userNameToSave;
      String? tokenToSave;

      // 1. Ambil Data User (Cek di root atau di dalam 'data')
      var userData = result['user'] ?? result['data']?['user'];
      if (userData != null) {
        userIdToSave = userData['id'].toString();
        userNameToSave = userData['name'].toString();
      }

      // 2. Ambil Token (PENTING: Laravel kamu pakai 'access_token')
      tokenToSave =
          result['access_token'] ?? result['token'] ?? result['data']?['token'];

      // 3. Eksekusi Simpan ke Memori HP
      if (userIdToSave != null) {
        await prefs.setString('user_id', userIdToSave);
        if (userNameToSave != null) {
          await prefs.setString('user_name', userNameToSave);
        }

        if (tokenToSave != null) {
          await prefs.setString('token', tokenToSave);
          print("✅ [AUTH] Token Berhasil Disimpan: $tokenToSave");
        } else {
          print("⚠️ [AUTH] Token tidak ditemukan dalam response server!");
        }

        print("✅ [AUTH] Sesi berhasil disimpan! ID: $userIdToSave");
      }
    } catch (e) {
      print("❌ [AUTH ERROR] Gagal simpan sesi: $e");
    }
  }

  // Fungsi Helper: Logout
  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Hapus semua data (Token, Nama, dll)
  }

  Future<Map<String, dynamic>> loginWithGoogle({
    required String email,
    required String googleId,
    required String name,
    String? photoUrl,
  }) async {
    try {
      print("DEBUG: Mengirim Foto -> $photoUrl");
      final response = await http.post(
        Uri.parse('$baseUrl/login-google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'google_id': googleId,
          'name': name,
          'avatar_url': photoUrl,
        }),
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);

        // 🔥 PENTING: Simpan Token dan Data User ke HP
        await _performSaveSession(data);

        return {'success': true, 'data': data};
      }
      return {'success': false, 'message': 'Gagal koneksi ke server'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // auth_service.dart

Future<Map<String, dynamic>> forgotPassword(String email) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/forgot-password'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'email': email}),
    );

    // 🕵️ KITA CEK DI SINI BRO
    print("🕵️ DETEKTIF: Status Code -> ${response.statusCode}");
    print("🕵️ DETEKTIF: Respon Server -> ${response.body}");

    return jsonDecode(response.body);
  } catch (e) {
    print("❌ DETEKTIF: Error Catch -> $e");
    return {'success': false, 'message': 'Kesalahan koneksi'};
  }
}

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/reset-password'),
      body: {
        'email': email,
        'otp': otp,
        'password': password,
        'password_confirmation': password,
      },
    );
    return jsonDecode(response.body);
  }
}
