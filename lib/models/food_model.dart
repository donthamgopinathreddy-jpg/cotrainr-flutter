class FoodModel {
  final String id;
  final String name;
  final String defaultUnit;
  final double perUnitGrams;
  final double kcalPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;
  final double fiberPer100g;
  final double sugarPer100g;
  final double sodiumPer100g;
  final double ironPer100g;
  final double calciumPer100g;
  final double potassiumPer100g;
  final List<String> tags;
  final bool isIndian;
  final bool isVerified;

  FoodModel({
    required this.id,
    required this.name,
    required this.defaultUnit,
    required this.perUnitGrams,
    required this.kcalPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
    this.fiberPer100g = 0,
    this.sugarPer100g = 0,
    this.sodiumPer100g = 0,
    this.ironPer100g = 0,
    this.calciumPer100g = 0,
    this.potassiumPer100g = 0,
    this.tags = const [],
    this.isIndian = true,
    this.isVerified = false,
  });

  factory FoodModel.fromMap(Map<String, dynamic> map) {
    return FoodModel(
      id: map['id'] as String,
      name: map['name'] as String,
      defaultUnit: map['default_unit'] as String,
      perUnitGrams: (map['per_unit_grams'] as num).toDouble(),
      kcalPer100g: (map['kcal_per_100g'] as num).toDouble(),
      proteinPer100g: (map['protein_per_100g'] as num?)?.toDouble() ?? 0,
      carbsPer100g: (map['carbs_per_100g'] as num?)?.toDouble() ?? 0,
      fatPer100g: (map['fat_per_100g'] as num?)?.toDouble() ?? 0,
      fiberPer100g: (map['fiber_per_100g'] as num?)?.toDouble() ?? 0,
      sugarPer100g: (map['sugar_per_100g'] as num?)?.toDouble() ?? 0,
      sodiumPer100g: (map['sodium_per_100g'] as num?)?.toDouble() ?? 0,
      ironPer100g: (map['iron_per_100g'] as num?)?.toDouble() ?? 0,
      calciumPer100g: (map['calcium_per_100g'] as num?)?.toDouble() ?? 0,
      potassiumPer100g: (map['potassium_per_100g'] as num?)?.toDouble() ?? 0,
      tags: List<String>.from(map['tags'] as List? ?? []),
      isIndian: map['is_indian'] as bool? ?? true,
      isVerified: map['is_verified'] as bool? ?? false,
    );
  }

  /// Calculate nutrition for a given quantity and unit
  NutritionInfo calculateNutrition(double quantity, String unit) {
    // Convert quantity to grams
    double totalGrams = quantity * perUnitGrams;
    double multiplier = totalGrams / 100.0;

    return NutritionInfo(
      kcal: kcalPer100g * multiplier,
      protein: proteinPer100g * multiplier,
      carbs: carbsPer100g * multiplier,
      fat: fatPer100g * multiplier,
      fiber: fiberPer100g * multiplier,
      sugar: sugarPer100g * multiplier,
      sodium: sodiumPer100g * multiplier,
      iron: ironPer100g * multiplier,
      calcium: calciumPer100g * multiplier,
      potassium: potassiumPer100g * multiplier,
    );
  }

  /// Get supported units based on food category
  List<String> getSupportedUnits() {
    // Default units based on default_unit
    switch (defaultUnit) {
      case 'pcs':
        return ['pcs', 'g'];
      case 'g':
        return ['g', 'kg'];
      case 'ml':
        return ['ml', 'l'];
      case 'bowl':
        return ['bowl', 'g', 'cup'];
      case 'cup':
        return ['cup', 'ml', 'g'];
      default:
        return [defaultUnit, 'g'];
    }
  }
}

class NutritionInfo {
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

  NutritionInfo({
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
}



