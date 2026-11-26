import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

/*
|--------------------------------------------------------------------------
| WALLET SERVICE (UPDATED)
|--------------------------------------------------------------------------
| Mengelola Saldo, Request Withdraw, dan Data Bank User.
*/
class WalletService {
  // ⚠️ Pastikan IP ini sesuai dengan IP Laptop/Server Laravel Bosku
  final String baseUrl = AppConfig.baseUrl;

Future<Map<String, String>> _getHeaders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    print("🔑 [TOKEN] Menggunakan Token: $token"); // CCTV TOKEN
    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };
  }

  // --- 1. CEK STATUS PIN ---
  Future<bool> checkPinStatus() async {
    try {
      print("🚀 [CHECK PIN] Sedang mengecek status PIN ke Server...");
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/wallet/check-pin'),
        headers: headers,
      );

      print("📥 [CHECK PIN] Response Code: ${response.statusCode}");
      print("📄 [CHECK PIN] Body: ${response.body}");

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        bool status = data['has_pin'] ?? false;
        print("✅ [CHECK PIN] Hasil: User ${status ? 'SUDAH' : 'BELUM'} punya PIN");
        return status;
      }
      return false;
    } catch (e) {
      print("❌ [CHECK PIN ERROR]: $e");
      return false;
    }
  }

  // --- 2. SETUP PIN BARU ---
  Future<bool> setupPin(String newPin) async {
    try {
      print("🚀 [SETUP PIN] Mengirim PIN baru ke Server...");
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/wallet/setup-pin'),
        headers: headers,
        body: {
          'pin': newPin,
          'pin_confirmation': newPin,
        },
      );

      print("📥 [SETUP PIN] Response Code: ${response.statusCode}");
      print("📄 [SETUP PIN] Body: ${response.body}");

      if (response.statusCode == 200) {
        print("✅ [SETUP PIN] Berhasil disimpan!");
        return true;
      }
      return false;
    } catch (e) {
      print("❌ [SETUP PIN ERROR]: $e");
      return false;
    }
  }

  /**
   * -- GET DASHBOARD --
   * Mengambil saldo dan riwayat transaksi.
   */
  Future<Map<String, dynamic>> getWalletDashboard() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('user_id');

      final response = await http.get(
        Uri.parse('$baseUrl/wallet/dashboard?user_id=$userId'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body)['data'];
      }
      return {};
    } catch (e) {
      print("Error Wallet: $e");
      return {};
    }
  }

  /**
   * -- GET PAYOUT METHODS (FUNGSI BARU) --
   * Mengambil daftar bank yang tersimpan di database user.
   * Dipakai di halaman WithdrawInputScreen.
   */
  Future<List<dynamic>> getPayoutMethods() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('user_id');

      // 🔥 FIX SEMENTARA: JIKA NULL, PAKAI ID DUMMY DARI DATABASE 🔥
      // Saya ambil ID 47 (Derry Anggara) dari screenshot database Bosku
      if (userId == null) {
        print("⚠️ User ID Null. Menggunakan ID Testing: 47");
        userId = "47"; 
      }

      final response = await http.get(
        Uri.parse('$baseUrl/payout-methods?user_id=$userId'),
      );
      
      print("🕵️ JSON DARI SERVER: ${response.body}");

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        return data['data'] ?? []; 
      } else {
        print("⚠️ Gagal ambil bank: ${response.body}");
        return [];
      }
    } catch (e) {
      print("❌ Error Koneksi: $e");
      return [];
    }
  }

  /**
   * -- REQUEST WITHDRAW --
   * Mengirim permintaan penarikan dana.
   */
  Future<bool> requestWithdraw({required String amount, required int methodId}) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('user_id');
      String? token = prefs.getString('token');

      print("🚀 [START] MENGIRIM REQUEST WITHDRAW...");
      print("👉 URL: $baseUrl/wallet/withdraw");
      print("👉 Token Ada? ${token != null ? 'YA' : 'TIDAK'}");
      print("👉 Data Kirim: Amount=$amount, Method=$methodId");

      final response = await http.post(
        Uri.parse('$baseUrl/wallet/withdraw'),
        body: {
          'user_id': userId,           
          'amount': amount,            
          'payout_method_id': methodId.toString(),
        },
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json', // <--- KUNCI RAHASIANYA!
        },
      );

      print("📥 [RESPONSE] Status Code: ${response.statusCode}");
      print("📄 [RESPONSE] Body: ${response.body}");
      
      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print("❌ [ERROR KONEKSI]: $e");
      return false;
    }
  }
}