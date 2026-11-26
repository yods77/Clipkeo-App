class Campaign {
  final int id;
  final String title;
  final String category;
  final String? imageUrl;
  final int rewardAmount;
  final int remainingBudget;
  final List<String> platforms; // TikTok, IG, dll
  final String companyName;

  Campaign({
    required this.id,
    required this.title,
    required this.category,
    this.imageUrl,
    required this.rewardAmount,
    required this.remainingBudget,
    required this.platforms,
    required this.companyName,
  });

  // Factory: Ubah JSON dari API Laravel ke Object Dart
  factory Campaign.fromJson(Map<String, dynamic> json) {
    // Handle Platform jika null atau string biasa
    List<String> parsedPlatforms = [];
    if (json['platform'] != null) {
      if (json['platform'] is List) {
        parsedPlatforms = List<String>.from(json['platform']);
      }
    }

    return Campaign(
      id: json['id'],
      title: json['title'] ?? 'Tanpa Judul',
      category: json['category'] ?? 'Umum',
      imageUrl: json['image_url'], // Sesuai key di API Controller PHP tadi
      rewardAmount: json['reward_amount'] ?? 0,
      remainingBudget: json['remaining_budget'] ?? 0,
      platforms: parsedPlatforms,
      companyName: json['company_name'] ?? 'Brand Partner',
    );
  }
}