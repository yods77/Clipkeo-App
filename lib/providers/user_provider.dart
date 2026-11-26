import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart'; // Pastikan path ini benar sesuai lokasi file config.dart kamu

class UserProvider extends ChangeNotifier {
  Map<String, dynamic>? _userData;
  bool _isLoading = false;

  Map<String, dynamic>? get userData => _userData;
  bool get isLoading => _isLoading;

  // --- FUNGSI AMBIL DATA DARI SERVER ---
  Future<void> fetchProfile() async {
    _isLoading = true;
    notifyListeners();

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/user'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        _userData = jsonDecode(response.body)['data'];
      }
    } catch (e) {
      print("❌ Error UserProvider (fetch): $e");
    } finally {
      _isLoading = false;
      notifyListeners(); // 🔥 Semua halaman yang pakai data ini otomatis update
    }
  }

  // --- FUNGSI UPDATE FOTO SECARA INSTAN ---
  // Kita panggil ini setelah upload foto ke server sukses
  void updateAvatar(String newUrl) {
    if (_userData != null) {
      _userData!['avatar_url'] = newUrl;
      notifyListeners(); // 🔥 Sekali panggil, foto di semua halaman berubah!
    }
  }

  // --- FUNGSI CLEAR DATA (SAAT LOGOUT) ---
  void logout() {
    _userData = null;
    notifyListeners();
  }
}