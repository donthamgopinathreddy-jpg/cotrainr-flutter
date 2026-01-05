class MealModel {
  final String id;
  final String name;
  final String mealType; // 'breakfast', 'lunch', 'snacks', 'dinner', 'custom'
  final DateTime date;
  final List<MealItemModel> items;
  final List<MealPhotoModel> photos;
  final double totalKcal;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final bool hasItems;

  MealModel({
    required this.id,
    required this.name,
    required this.mealType,
    required this.date,
    this.items = const [],
    this.photos = const [],
    this.totalKcal = 0,
    this.totalProtein = 0,
    this.totalCarbs = 0,
    this.totalFat = 0,
    this.hasItems = false,
  });

  factory MealModel.fromMap(Map<String, dynamic> map, List<MealItemModel> items, List<MealPhotoModel> photos) {
    double totalKcal = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;

    for (var item in items) {
      totalKcal += item.kcal;
      totalProtein += item.protein;
      totalCarbs += item.carbs;
      totalFat += item.fat;
    }

    return MealModel(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      mealType: map['meal_type'] as String? ?? '',
      date: DateTime.parse(map['date'] as String),
      items: items,
      photos: photos,
      totalKcal: totalKcal,
      totalProtein: totalProtein,
      totalCarbs: totalCarbs,
      totalFat: totalFat,
      hasItems: items.isNotEmpty,
    );
  }
}

class MealItemModel {
  final String id;
  final String foodId;
  final String foodName;
  final String mealType;
  final DateTime date;
  final double quantity;
  final String unit;
  final double kcal;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final double sugar;
  final double sodium;
  final double iron;
  final double calcium;
  final double potassium;

  MealItemModel({
    required this.id,
    required this.foodId,
    required this.foodName,
    required this.mealType,
    required this.date,
    required this.quantity,
    required this.unit,
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.fiber = 0,
    this.sugar = 0,
    this.sodium = 0,
    this.iron = 0,
    this.calcium = 0,
    this.potassium = 0,
  });

  factory MealItemModel.fromMap(Map<String, dynamic> map) {
    final food = map['foods_catalog'] as Map<String, dynamic>?;
    
    return MealItemModel(
      id: map['id'] as String,
      foodId: map['food_id'] as String,
      foodName: food?['name'] as String? ?? '',
      mealType: map['meal_type'] as String,
      date: DateTime.parse(map['date'] as String),
      quantity: (map['quantity'] as num).toDouble(),
      unit: map['unit'] as String,
      kcal: (map['kcal'] as num).toDouble(),
      protein: (map['protein'] as num?)?.toDouble() ?? 0,
      carbs: (map['carbs'] as num?)?.toDouble() ?? 0,
      fat: (map['fat'] as num?)?.toDouble() ?? 0,
      fiber: (map['fiber'] as num?)?.toDouble() ?? 0,
      sugar: (map['sugar'] as num?)?.toDouble() ?? 0,
      sodium: (map['sodium'] as num?)?.toDouble() ?? 0,
      iron: (map['iron'] as num?)?.toDouble() ?? 0,
      calcium: (map['calcium'] as num?)?.toDouble() ?? 0,
      potassium: (map['potassium'] as num?)?.toDouble() ?? 0,
    );
  }
}

class MealPhotoModel {
  final String id;
  final String storagePath;
  final String mealType;
  final DateTime date;
  final DateTime createdAt;
  final DateTime expiresAt;

  MealPhotoModel({
    required this.id,
    required this.storagePath,
    required this.mealType,
    required this.date,
    required this.createdAt,
    required this.expiresAt,
  });

  factory MealPhotoModel.fromMap(Map<String, dynamic> map) {
    return MealPhotoModel(
      id: map['id'] as String,
      storagePath: map['storage_path'] as String,
      mealType: map['meal_type'] as String,
      date: DateTime.parse(map['date'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      expiresAt: DateTime.parse(map['expires_at'] as String),
    );
  }

  String getPublicUrl(String baseUrl) {
    return '$baseUrl/storage/v1/object/public/meal_photos/$storagePath';
  }
}



