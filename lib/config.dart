class AppConfig {
  // 🔥 GANTI IP DI SINI SAJA (JIKA GANTI WIFI/MODEM) 🔥
  static const String ipAddress = "192.168.1.102"; 

  // URL Video Tutorial
  static const String videoTutorialUrl = "https://res.cloudinary.com/daopl1ji6/video/upload/v1770652956/tutorial_analytics_ifwcu9.mp4";
  
  // Jika API kamu juga di dalam folder yang sama, pastikan base API-nya juga benar
  static const String apiBaseUrl = "$baseUrl/clipsquad/public/api";
  
  // Port Laravel (Jangan diubah kecuali pakai port lain)
  static const String port = "8000";

  // URL untuk API (Login, Register, Data)
  static const String baseUrl = "http://$ipAddress:$port/api";
  
  // URL untuk Gambar/Storage (Tanpa /api)
  static const String rawBaseUrl = "http://$ipAddress:$port";

  // --- FUNGSI PINTAR PERBAIKI GAMBAR ---
  // Fungsi ini otomatis mengubah localhost/127.0.0.1 menjadi IP Laptop
  static String fixImageUrl(String? url) {
    if (url == null || url.isEmpty) return "";
    
    // Jika URL sudah mengandung http
    if (url.startsWith("http")) {
      return url
          .replaceAll("localhost", ipAddress)
          .replaceAll("127.0.0.1", ipAddress)
          // Jaga-jaga kalau ada sisa IP lama
          .replaceAll("192.168.1.110", ipAddress); 
    }
    
    // Jika URL dari database cuma path (misal: "avatars/foto.jpg")
    return "$rawBaseUrl/storage/$url";
  }
}