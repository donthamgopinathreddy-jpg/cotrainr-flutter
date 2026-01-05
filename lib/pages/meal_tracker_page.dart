import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'dart:ui';

class MealTrackerPage extends StatefulWidget {
  const MealTrackerPage({super.key});

  @override
  State<MealTrackerPage> createState() => _MealTrackerPageState();
}

class _MealTrackerPageState extends State<MealTrackerPage> with TickerProviderStateMixin {
  // Animation Controllers
  late AnimationController _ringController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  
  // Date
  DateTime _selectedDate = DateTime.now();
  
  // Daily Goals
  final int _caloriesGoal = 2000;
  final int _proteinGoal = 120;
  final int _carbsGoal = 250;
  final int _fatGoal = 65;
  
  // Daily Totals (calculated from meals)
  int _totalCalories = 0;
  int _totalProtein = 0;
  int _totalCarbs = 0;
  int _totalFat = 0;
  
  // Meals
  final List<Meal> _meals = [
    Meal(
      id: '1',
      name: 'Breakfast',
      time: '08:00',
      items: [],
      photos: [],
    ),
    Meal(
      id: '2',
      name: 'Lunch',
      time: '13:00',
      items: [],
      photos: [],
    ),
    Meal(
      id: '3',
      name: 'Snack',
      time: '16:00',
      items: [],
      photos: [],
    ),
    Meal(
      id: '4',
      name: 'Dinner',
      time: '19:00',
      items: [],
      photos: [],
    ),
  ];
  
  // Food Database (comprehensive Indian foods)
  List<FoodItem> get _foodDatabase => [
    // South Indian Breakfast
    FoodItem(id: '1', name: 'Idli', category: FoodCategory.count, defaultUnit: 'pcs', unitsSupported: ['pcs', 'g'], gramsPerUnit: {'pcs': 50, 'g': 1}, macrosPer100g: Macros(protein: 3.5, carbs: 25.0, fat: 0.5, fiber: 1.2), caloriesPer100g: 106, microsPer100g: Micros(calcium: 20, iron: 1.2, potassium: 50), isVerified: true, tags: ['South Indian', 'Breakfast']),
    FoodItem(id: '2', name: 'Dosa', category: FoodCategory.count, defaultUnit: 'pcs', unitsSupported: ['pcs', 'g'], gramsPerUnit: {'pcs': 120, 'g': 1}, macrosPer100g: Macros(protein: 2.5, carbs: 30.0, fat: 5.0, fiber: 1.5), caloriesPer100g: 160, microsPer100g: Micros(calcium: 30, iron: 1.5, potassium: 100), isVerified: true, tags: ['South Indian', 'Breakfast']),
    FoodItem(id: '3', name: 'Vada', category: FoodCategory.count, defaultUnit: 'pcs', unitsSupported: ['pcs', 'g'], gramsPerUnit: {'pcs': 60, 'g': 1}, macrosPer100g: Macros(protein: 4.5, carbs: 35.0, fat: 8.0, fiber: 2.0), caloriesPer100g: 220, microsPer100g: Micros(calcium: 25, iron: 1.8, potassium: 120), isVerified: true, tags: ['South Indian', 'Breakfast', 'Snacks']),
    FoodItem(id: '4', name: 'Upma', category: FoodCategory.weight, defaultUnit: 'bowl', unitsSupported: ['bowl', 'g', 'cup'], gramsPerUnit: {'bowl': 200, 'g': 1, 'cup': 150}, macrosPer100g: Macros(protein: 3.0, carbs: 28.0, fat: 6.0, fiber: 1.8), caloriesPer100g: 180, microsPer100g: Micros(calcium: 15, iron: 1.2, potassium: 80), isVerified: true, tags: ['South Indian', 'Breakfast']),
    FoodItem(id: '5', name: 'Pongal', category: FoodCategory.weight, defaultUnit: 'bowl', unitsSupported: ['bowl', 'g'], gramsPerUnit: {'bowl': 250, 'g': 1}, macrosPer100g: Macros(protein: 4.0, carbs: 32.0, fat: 5.0, fiber: 2.0), caloriesPer100g: 190, microsPer100g: Micros(calcium: 30, iron: 1.5, potassium: 100), isVerified: true, tags: ['South Indian', 'Breakfast']),
    FoodItem(id: '6', name: 'Uttapam', category: FoodCategory.count, defaultUnit: 'pcs', unitsSupported: ['pcs', 'g'], gramsPerUnit: {'pcs': 150, 'g': 1}, macrosPer100g: Macros(protein: 3.5, carbs: 32.0, fat: 4.5, fiber: 2.0), caloriesPer100g: 170, microsPer100g: Micros(calcium: 35, iron: 1.6, potassium: 110), isVerified: true, tags: ['South Indian', 'Breakfast']),
    
    // North Indian Breads
    FoodItem(id: '7', name: 'Roti', category: FoodCategory.count, defaultUnit: 'pcs', unitsSupported: ['pcs', 'g'], gramsPerUnit: {'pcs': 35, 'g': 1}, macrosPer100g: Macros(protein: 9.0, carbs: 50.0, fat: 2.0, fiber: 2.5), caloriesPer100g: 260, microsPer100g: Micros(calcium: 20, iron: 2.5, potassium: 150), isVerified: true, tags: ['North Indian']),
    FoodItem(id: '8', name: 'Chapati', category: FoodCategory.count, defaultUnit: 'pcs', unitsSupported: ['pcs', 'g'], gramsPerUnit: {'pcs': 40, 'g': 1}, macrosPer100g: Macros(protein: 10.0, carbs: 48.0, fat: 2.5, fiber: 2.8), caloriesPer100g: 270, microsPer100g: Micros(calcium: 25, iron: 2.8, potassium: 160), isVerified: true, tags: ['North Indian']),
    FoodItem(id: '9', name: 'Naan', category: FoodCategory.count, defaultUnit: 'pcs', unitsSupported: ['pcs', 'g'], gramsPerUnit: {'pcs': 90, 'g': 1}, macrosPer100g: Macros(protein: 8.0, carbs: 52.0, fat: 6.0, fiber: 2.0), caloriesPer100g: 280, microsPer100g: Micros(calcium: 30, iron: 2.0, potassium: 140), isVerified: true, tags: ['North Indian']),
    FoodItem(id: '10', name: 'Paratha', category: FoodCategory.count, defaultUnit: 'pcs', unitsSupported: ['pcs', 'g'], gramsPerUnit: {'pcs': 80, 'g': 1}, macrosPer100g: Macros(protein: 7.5, carbs: 45.0, fat: 12.0, fiber: 2.2), caloriesPer100g: 320, microsPer100g: Micros(calcium: 28, iron: 2.2, potassium: 150), isVerified: true, tags: ['North Indian', 'Breakfast']),
    FoodItem(id: '11', name: 'Puri', category: FoodCategory.count, defaultUnit: 'pcs', unitsSupported: ['pcs', 'g'], gramsPerUnit: {'pcs': 25, 'g': 1}, macrosPer100g: Macros(protein: 6.0, carbs: 42.0, fat: 18.0, fiber: 1.5), caloriesPer100g: 350, microsPer100g: Micros(calcium: 15, iron: 1.8, potassium: 100), isVerified: true, tags: ['North Indian', 'Breakfast']),
    
    // Proteins
    FoodItem(id: '12', name: 'Paneer', category: FoodCategory.weight, defaultUnit: 'g', unitsSupported: ['g', 'kg', 'cup'], gramsPerUnit: {'g': 1, 'kg': 1000, 'cup': 226}, macrosPer100g: Macros(protein: 18.0, carbs: 2.0, fat: 20.0, fiber: 0.0), caloriesPer100g: 265, microsPer100g: Micros(calcium: 200, iron: 0.2, potassium: 50), isVerified: true, tags: ['North Indian', 'Protein']),
    FoodItem(id: '13', name: 'Egg', category: FoodCategory.count, defaultUnit: 'pcs', unitsSupported: ['pcs', 'g'], gramsPerUnit: {'pcs': 50, 'g': 1}, macrosPer100g: Macros(protein: 13.0, carbs: 1.1, fat: 11.0, fiber: 0.0), caloriesPer100g: 155, microsPer100g: Micros(calcium: 56, iron: 1.8, potassium: 138), isVerified: true, tags: ['Protein']),
    FoodItem(id: '14', name: 'Chicken Breast', category: FoodCategory.weight, defaultUnit: 'g', unitsSupported: ['g', 'kg'], gramsPerUnit: {'g': 1, 'kg': 1000}, macrosPer100g: Macros(protein: 31.0, carbs: 0.0, fat: 3.6, fiber: 0.0), caloriesPer100g: 165, microsPer100g: Micros(calcium: 15, iron: 0.9, potassium: 256), isVerified: true, tags: ['Protein']),
    FoodItem(id: '15', name: 'Chicken Curry', category: FoodCategory.weight, defaultUnit: 'bowl', unitsSupported: ['bowl', 'g', 'plate'], gramsPerUnit: {'bowl': 200, 'g': 1, 'plate': 250}, macrosPer100g: Macros(protein: 15.0, carbs: 8.0, fat: 12.0, fiber: 1.5), caloriesPer100g: 200, microsPer100g: Micros(calcium: 30, iron: 1.5, potassium: 200), isVerified: true, tags: ['North Indian', 'Protein', 'Lunch', 'Dinner']),
    FoodItem(id: '16', name: 'Paneer Butter Masala', category: FoodCategory.weight, defaultUnit: 'bowl', unitsSupported: ['bowl', 'g', 'plate'], gramsPerUnit: {'bowl': 200, 'g': 1, 'plate': 250}, macrosPer100g: Macros(protein: 12.0, carbs: 10.0, fat: 18.0, fiber: 1.0), caloriesPer100g: 250, microsPer100g: Micros(calcium: 150, iron: 0.8, potassium: 120), isVerified: true, tags: ['North Indian', 'Protein', 'Lunch', 'Dinner']),
    FoodItem(id: '17', name: 'Dal', category: FoodCategory.weight, defaultUnit: 'bowl', unitsSupported: ['bowl', 'g', 'cup'], gramsPerUnit: {'bowl': 150, 'g': 1, 'cup': 200}, macrosPer100g: Macros(protein: 7.0, carbs: 20.0, fat: 2.0, fiber: 5.0), caloriesPer100g: 120, microsPer100g: Micros(calcium: 40, iron: 2.5, potassium: 300), isVerified: true, tags: ['North Indian', 'Protein', 'Lunch', 'Dinner']),
    FoodItem(id: '18', name: 'Chana Masala', category: FoodCategory.weight, defaultUnit: 'bowl', unitsSupported: ['bowl', 'g'], gramsPerUnit: {'bowl': 200, 'g': 1}, macrosPer100g: Macros(protein: 9.0, carbs: 25.0, fat: 4.0, fiber: 6.0), caloriesPer100g: 160, microsPer100g: Micros(calcium: 60, iron: 3.0, potassium: 350), isVerified: true, tags: ['North Indian', 'Protein', 'Lunch', 'Dinner']),
    FoodItem(id: '19', name: 'Rajma', category: FoodCategory.weight, defaultUnit: 'bowl', unitsSupported: ['bowl', 'g'], gramsPerUnit: {'bowl': 200, 'g': 1}, macrosPer100g: Macros(protein: 8.5, carbs: 22.0, fat: 3.5, fiber: 5.5), caloriesPer100g: 150, microsPer100g: Micros(calcium: 50, iron: 2.8, potassium: 320), isVerified: true, tags: ['North Indian', 'Protein', 'Lunch', 'Dinner']),
    FoodItem(id: '20', name: 'Fish Curry', category: FoodCategory.weight, defaultUnit: 'bowl', unitsSupported: ['bowl', 'g'], gramsPerUnit: {'bowl': 200, 'g': 1}, macrosPer100g: Macros(protein: 18.0, carbs: 6.0, fat: 10.0, fiber: 1.0), caloriesPer100g: 180, microsPer100g: Micros(calcium: 80, iron: 1.2, potassium: 280), isVerified: true, tags: ['South Indian', 'Protein', 'Lunch', 'Dinner']),
    
    // Rice Dishes
    FoodItem(id: '21', name: 'Biryani', category: FoodCategory.weight, defaultUnit: 'bowl', unitsSupported: ['bowl', 'g', 'plate'], gramsPerUnit: {'bowl': 250, 'g': 1, 'plate': 300}, macrosPer100g: Macros(protein: 8.0, carbs: 45.0, fat: 12.0, fiber: 2.0), caloriesPer100g: 300, microsPer100g: Micros(calcium: 50, iron: 2.0, potassium: 200), isVerified: true, tags: ['North Indian', 'Lunch', 'Dinner']),
    FoodItem(id: '22', name: 'Fried Rice', category: FoodCategory.weight, defaultUnit: 'bowl', unitsSupported: ['bowl', 'g'], gramsPerUnit: {'bowl': 200, 'g': 1}, macrosPer100g: Macros(protein: 4.0, carbs: 38.0, fat: 8.0, fiber: 1.5), caloriesPer100g: 230, microsPer100g: Micros(calcium: 20, iron: 1.0, potassium: 100), isVerified: true, tags: ['Lunch', 'Dinner']),
    FoodItem(id: '23', name: 'Curd Rice', category: FoodCategory.weight, defaultUnit: 'bowl', unitsSupported: ['bowl', 'g'], gramsPerUnit: {'bowl': 200, 'g': 1}, macrosPer100g: Macros(protein: 3.5, carbs: 32.0, fat: 4.0, fiber: 1.0), caloriesPer100g: 170, microsPer100g: Micros(calcium: 120, iron: 0.5, potassium: 150), isVerified: true, tags: ['South Indian', 'Lunch', 'Dinner']),
    FoodItem(id: '24', name: 'Lemon Rice', category: FoodCategory.weight, defaultUnit: 'bowl', unitsSupported: ['bowl', 'g'], gramsPerUnit: {'bowl': 200, 'g': 1}, macrosPer100g: Macros(protein: 3.0, carbs: 35.0, fat: 6.0, fiber: 1.2), caloriesPer100g: 200, microsPer100g: Micros(calcium: 15, iron: 0.8, potassium: 80), isVerified: true, tags: ['South Indian', 'Lunch', 'Dinner']),
    FoodItem(id: '25', name: 'Plain Rice', category: FoodCategory.weight, defaultUnit: 'bowl', unitsSupported: ['bowl', 'g', 'cup'], gramsPerUnit: {'bowl': 150, 'g': 1, 'cup': 200}, macrosPer100g: Macros(protein: 2.7, carbs: 28.0, fat: 0.3, fiber: 0.4), caloriesPer100g: 130, microsPer100g: Micros(calcium: 10, iron: 0.8, potassium: 35), isVerified: true, tags: ['Lunch', 'Dinner']),
    
    // Vegetables
    FoodItem(id: '26', name: 'Aloo Gobi', category: FoodCategory.weight, defaultUnit: 'bowl', unitsSupported: ['bowl', 'g'], gramsPerUnit: {'bowl': 150, 'g': 1}, macrosPer100g: Macros(protein: 2.5, carbs: 15.0, fat: 6.0, fiber: 3.0), caloriesPer100g: 120, microsPer100g: Micros(calcium: 30, iron: 1.2, potassium: 250), isVerified: true, tags: ['North Indian', 'Vegetables', 'Lunch', 'Dinner']),
    FoodItem(id: '27', name: 'Baingan Bharta', category: FoodCategory.weight, defaultUnit: 'bowl', unitsSupported: ['bowl', 'g'], gramsPerUnit: {'bowl': 150, 'g': 1}, macrosPer100g: Macros(protein: 2.0, carbs: 12.0, fat: 8.0, fiber: 4.0), caloriesPer100g: 130, microsPer100g: Micros(calcium: 25, iron: 1.0, potassium: 280), isVerified: true, tags: ['North Indian', 'Vegetables', 'Lunch', 'Dinner']),
    FoodItem(id: '28', name: 'Bhindi Masala', category: FoodCategory.weight, defaultUnit: 'bowl', unitsSupported: ['bowl', 'g'], gramsPerUnit: {'bowl': 150, 'g': 1}, macrosPer100g: Macros(protein: 2.2, carbs: 10.0, fat: 7.0, fiber: 3.5), caloriesPer100g: 110, microsPer100g: Micros(calcium: 60, iron: 1.5, potassium: 200), isVerified: true, tags: ['North Indian', 'Vegetables', 'Lunch', 'Dinner']),
    FoodItem(id: '29', name: 'Mix Vegetable', category: FoodCategory.weight, defaultUnit: 'bowl', unitsSupported: ['bowl', 'g'], gramsPerUnit: {'bowl': 150, 'g': 1}, macrosPer100g: Macros(protein: 2.8, carbs: 14.0, fat: 5.0, fiber: 4.0), caloriesPer100g: 110, microsPer100g: Micros(calcium: 40, iron: 1.8, potassium: 300), isVerified: true, tags: ['North Indian', 'Vegetables', 'Lunch', 'Dinner']),
    
    // Snacks
    FoodItem(id: '30', name: 'Samosa', category: FoodCategory.count, defaultUnit: 'pcs', unitsSupported: ['pcs', 'g'], gramsPerUnit: {'pcs': 50, 'g': 1}, macrosPer100g: Macros(protein: 4.0, carbs: 35.0, fat: 15.0, fiber: 2.5), caloriesPer100g: 280, microsPer100g: Micros(calcium: 20, iron: 1.5, potassium: 150), isVerified: true, tags: ['Snacks']),
    FoodItem(id: '31', name: 'Pakora', category: FoodCategory.count, defaultUnit: 'pcs', unitsSupported: ['pcs', 'g'], gramsPerUnit: {'pcs': 30, 'g': 1}, macrosPer100g: Macros(protein: 5.0, carbs: 28.0, fat: 12.0, fiber: 2.0), caloriesPer100g: 240, microsPer100g: Micros(calcium: 30, iron: 1.8, potassium: 120), isVerified: true, tags: ['Snacks']),
    FoodItem(id: '32', name: 'Bhel Puri', category: FoodCategory.weight, defaultUnit: 'bowl', unitsSupported: ['bowl', 'g'], gramsPerUnit: {'bowl': 100, 'g': 1}, macrosPer100g: Macros(protein: 3.5, carbs: 40.0, fat: 8.0, fiber: 3.0), caloriesPer100g: 240, microsPer100g: Micros(calcium: 25, iron: 1.2, potassium: 180), isVerified: true, tags: ['Snacks']),
    FoodItem(id: '33', name: 'Pav Bhaji', category: FoodCategory.weight, defaultUnit: 'plate', unitsSupported: ['plate', 'bowl', 'g'], gramsPerUnit: {'plate': 300, 'bowl': 200, 'g': 1}, macrosPer100g: Macros(protein: 4.0, carbs: 32.0, fat: 10.0, fiber: 4.0), caloriesPer100g: 220, microsPer100g: Micros(calcium: 50, iron: 2.0, potassium: 250), isVerified: true, tags: ['Snacks', 'Lunch']),
    FoodItem(id: '34', name: 'Dhokla', category: FoodCategory.count, defaultUnit: 'pcs', unitsSupported: ['pcs', 'g'], gramsPerUnit: {'pcs': 40, 'g': 1}, macrosPer100g: Macros(protein: 4.5, carbs: 28.0, fat: 3.0, fiber: 2.5), caloriesPer100g: 160, microsPer100g: Micros(calcium: 35, iron: 1.5, potassium: 100), isVerified: true, tags: ['Snacks']),
    FoodItem(id: '35', name: 'Kachori', category: FoodCategory.count, defaultUnit: 'pcs', unitsSupported: ['pcs', 'g'], gramsPerUnit: {'pcs': 60, 'g': 1}, macrosPer100g: Macros(protein: 5.0, carbs: 38.0, fat: 14.0, fiber: 2.0), caloriesPer100g: 290, microsPer100g: Micros(calcium: 25, iron: 1.8, potassium: 140), isVerified: true, tags: ['Snacks']),
    
    // Sweets
    FoodItem(id: '36', name: 'Gulab Jamun', category: FoodCategory.count, defaultUnit: 'pcs', unitsSupported: ['pcs', 'g'], gramsPerUnit: {'pcs': 25, 'g': 1}, macrosPer100g: Macros(protein: 4.0, carbs: 45.0, fat: 15.0, fiber: 0.5), caloriesPer100g: 320, microsPer100g: Micros(calcium: 80, iron: 0.5, potassium: 50), isVerified: true, tags: ['Sweets']),
    FoodItem(id: '37', name: 'Jalebi', category: FoodCategory.weight, defaultUnit: 'g', unitsSupported: ['g', 'pcs'], gramsPerUnit: {'g': 1, 'pcs': 30}, macrosPer100g: Macros(protein: 2.0, carbs: 55.0, fat: 12.0, fiber: 0.3), caloriesPer100g: 320, microsPer100g: Micros(calcium: 15, iron: 0.3, potassium: 30), isVerified: true, tags: ['Sweets']),
    FoodItem(id: '38', name: 'Rasgulla', category: FoodCategory.count, defaultUnit: 'pcs', unitsSupported: ['pcs', 'g'], gramsPerUnit: {'pcs': 30, 'g': 1}, macrosPer100g: Macros(protein: 3.5, carbs: 38.0, fat: 1.0, fiber: 0.0), caloriesPer100g: 180, microsPer100g: Micros(calcium: 90, iron: 0.2, potassium: 40), isVerified: true, tags: ['Sweets']),
    FoodItem(id: '39', name: 'Kheer', category: FoodCategory.weight, defaultUnit: 'bowl', unitsSupported: ['bowl', 'g', 'cup'], gramsPerUnit: {'bowl': 150, 'g': 1, 'cup': 200}, macrosPer100g: Macros(protein: 3.0, carbs: 32.0, fat: 8.0, fiber: 0.5), caloriesPer100g: 220, microsPer100g: Micros(calcium: 100, iron: 0.5, potassium: 120), isVerified: true, tags: ['Sweets']),
    FoodItem(id: '40', name: 'Halwa', category: FoodCategory.weight, defaultUnit: 'bowl', unitsSupported: ['bowl', 'g'], gramsPerUnit: {'bowl': 100, 'g': 1}, macrosPer100g: Macros(protein: 2.5, carbs: 42.0, fat: 18.0, fiber: 1.0), caloriesPer100g: 350, microsPer100g: Micros(calcium: 20, iron: 0.8, potassium: 60), isVerified: true, tags: ['Sweets']),
    
    // Drinks
    FoodItem(id: '41', name: 'Milk', category: FoodCategory.volume, defaultUnit: 'ml', unitsSupported: ['ml', 'l', 'cup'], gramsPerUnit: {'ml': 1, 'l': 1000, 'cup': 240}, macrosPer100g: Macros(protein: 3.4, carbs: 5.0, fat: 3.3, fiber: 0.0), caloriesPer100g: 61, microsPer100g: Micros(calcium: 113, iron: 0.03, potassium: 150), isVerified: true, tags: ['Drinks']),
    FoodItem(id: '42', name: 'Lassi', category: FoodCategory.volume, defaultUnit: 'glass', unitsSupported: ['glass', 'ml', 'cup'], gramsPerUnit: {'glass': 250, 'ml': 1, 'cup': 240}, macrosPer100g: Macros(protein: 3.0, carbs: 8.0, fat: 3.0, fiber: 0.0), caloriesPer100g: 70, microsPer100g: Micros(calcium: 100, iron: 0.05, potassium: 140), isVerified: true, tags: ['Drinks']),
    FoodItem(id: '43', name: 'Buttermilk', category: FoodCategory.volume, defaultUnit: 'glass', unitsSupported: ['glass', 'ml'], gramsPerUnit: {'glass': 200, 'ml': 1}, macrosPer100g: Macros(protein: 1.0, carbs: 3.0, fat: 0.5, fiber: 0.0), caloriesPer100g: 20, microsPer100g: Micros(calcium: 50, iron: 0.02, potassium: 100), isVerified: true, tags: ['Drinks']),
    FoodItem(id: '44', name: 'Chai', category: FoodCategory.volume, defaultUnit: 'cup', unitsSupported: ['cup', 'ml'], gramsPerUnit: {'cup': 150, 'ml': 1}, macrosPer100g: Macros(protein: 0.5, carbs: 4.0, fat: 1.0, fiber: 0.0), caloriesPer100g: 25, microsPer100g: Micros(calcium: 20, iron: 0.1, potassium: 50), isVerified: true, tags: ['Drinks']),
    FoodItem(id: '45', name: 'Coffee', category: FoodCategory.volume, defaultUnit: 'cup', unitsSupported: ['cup', 'ml'], gramsPerUnit: {'cup': 150, 'ml': 1}, macrosPer100g: Macros(protein: 0.7, carbs: 0.0, fat: 0.0, fiber: 0.0), caloriesPer100g: 2, microsPer100g: Micros(calcium: 5, iron: 0.1, potassium: 50), isVerified: true, tags: ['Drinks']),
    
    // Fruits
    FoodItem(id: '46', name: 'Banana', category: FoodCategory.count, defaultUnit: 'pcs', unitsSupported: ['pcs', 'g'], gramsPerUnit: {'pcs': 120, 'g': 1}, macrosPer100g: Macros(protein: 1.1, carbs: 23.0, fat: 0.3, fiber: 2.6), caloriesPer100g: 89, microsPer100g: Micros(calcium: 5, iron: 0.26, potassium: 358), isVerified: true, tags: ['Fruits']),
    FoodItem(id: '47', name: 'Apple', category: FoodCategory.count, defaultUnit: 'pcs', unitsSupported: ['pcs', 'g'], gramsPerUnit: {'pcs': 150, 'g': 1}, macrosPer100g: Macros(protein: 0.3, carbs: 14.0, fat: 0.2, fiber: 2.4), caloriesPer100g: 52, microsPer100g: Micros(calcium: 6, iron: 0.12, potassium: 107), isVerified: true, tags: ['Fruits']),
    FoodItem(id: '48', name: 'Orange', category: FoodCategory.count, defaultUnit: 'pcs', unitsSupported: ['pcs', 'g'], gramsPerUnit: {'pcs': 130, 'g': 1}, macrosPer100g: Macros(protein: 0.9, carbs: 12.0, fat: 0.2, fiber: 2.4), caloriesPer100g: 47, microsPer100g: Micros(calcium: 40, iron: 0.1, potassium: 181), isVerified: true, tags: ['Fruits']),
    FoodItem(id: '49', name: 'Mango', category: FoodCategory.count, defaultUnit: 'pcs', unitsSupported: ['pcs', 'g'], gramsPerUnit: {'pcs': 200, 'g': 1}, macrosPer100g: Macros(protein: 0.8, carbs: 15.0, fat: 0.4, fiber: 1.6), caloriesPer100g: 60, microsPer100g: Micros(calcium: 11, iron: 0.16, potassium: 168), isVerified: true, tags: ['Fruits']),
    FoodItem(id: '50', name: 'Papaya', category: FoodCategory.weight, defaultUnit: 'g', unitsSupported: ['g', 'cup'], gramsPerUnit: {'g': 1, 'cup': 145}, macrosPer100g: Macros(protein: 0.5, carbs: 10.0, fat: 0.3, fiber: 1.7), caloriesPer100g: 43, microsPer100g: Micros(calcium: 20, iron: 0.25, potassium: 182), isVerified: true, tags: ['Fruits']),
    
    // Packaged Foods
    FoodItem(id: '51', name: 'Biscuit', category: FoodCategory.count, defaultUnit: 'pcs', unitsSupported: ['pcs', 'g'], gramsPerUnit: {'pcs': 10, 'g': 1}, macrosPer100g: Macros(protein: 5.0, carbs: 65.0, fat: 18.0, fiber: 2.0), caloriesPer100g: 420, microsPer100g: Micros(calcium: 50, iron: 2.0, potassium: 100), isVerified: false, tags: ['Packaged', 'Snacks']),
    FoodItem(id: '52', name: 'Bread', category: FoodCategory.count, defaultUnit: 'slice', unitsSupported: ['slice', 'g'], gramsPerUnit: {'slice': 25, 'g': 1}, macrosPer100g: Macros(protein: 9.0, carbs: 49.0, fat: 3.2, fiber: 2.7), caloriesPer100g: 265, microsPer100g: Micros(calcium: 100, iron: 3.6, potassium: 100), isVerified: false, tags: ['Packaged', 'Breakfast']),
    FoodItem(id: '53', name: 'Noodles', category: FoodCategory.weight, defaultUnit: 'pack', unitsSupported: ['pack', 'g'], gramsPerUnit: {'pack': 70, 'g': 1}, macrosPer100g: Macros(protein: 9.0, carbs: 52.0, fat: 14.0, fiber: 2.0), caloriesPer100g: 350, microsPer100g: Micros(calcium: 30, iron: 2.5, potassium: 150), isVerified: false, tags: ['Packaged', 'Lunch', 'Dinner']),
  ];
  
  final ImagePicker _picker = ImagePicker();
  
  @override
  void initState() {
    super.initState();
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _ringController.forward();
    _fadeController.forward();
    _calculateTotals();
  }
  
  @override
  void dispose() {
    _ringController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }
  
  void _calculateTotals() {
    int calories = 0;
    int protein = 0;
    int carbs = 0;
    int fat = 0;
    
    for (var meal in _meals) {
      for (var item in meal.items) {
        calories += item.calories;
        protein += item.macros.protein.toInt();
        carbs += item.macros.carbs.toInt();
        fat += item.macros.fat.toInt();
      }
    }
    
    setState(() {
      _totalCalories = calories;
      _totalProtein = protein;
      _totalCarbs = carbs;
      _totalFat = fat;
    });
  }
  
  String _getDateString() {
    final now = DateTime.now();
    if (_selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day) {
      return 'Today';
    }
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${weekdays[_selectedDate.weekday - 1]}, ${_selectedDate.day} ${months[_selectedDate.month - 1]}';
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF111827) : const Color(0xFFFAFAFA),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Top App Bar
            SliverToBoxAdapter(
              child: _buildAppBar(isDark),
            ),
            
            // Daily Summary Strip
            SliverToBoxAdapter(
              child: _buildDailySummary(isDark),
            ),
            
            // Meals Timeline
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index == _meals.length) {
                    return _buildAddMealTile(isDark);
                  }
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.1),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: _slideController,
                      curve: Interval(index * 0.1, 1.0, curve: Curves.easeOut),
                    )),
                    child: FadeTransition(
                      opacity: _fadeController,
                      child: _buildMealCard(_meals[index], isDark),
                    ),
                  );
                },
                childCount: _meals.length + 1,
              ),
            ),
            
            // Bottom spacing
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAppBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back_rounded,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Meal Tracker',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _getDateString(),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.calendar_today_rounded,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
            ),
            onPressed: () => _showDatePicker(isDark),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDailySummary(bool isDark) {
    final caloriesLeft = (_caloriesGoal - _totalCalories).clamp(0, _caloriesGoal);
    final calorieProgress = (_totalCalories / _caloriesGoal).clamp(0.0, 1.0);
    
    return FadeTransition(
      opacity: _fadeController,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Progress Ring
            GestureDetector(
              onTap: () => _showMacroDashboard(isDark),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: AnimatedBuilder(
                      animation: _ringController,
                      builder: (context, child) {
                        return CircularProgressIndicator(
                          value: calorieProgress * _ringController.value,
                          strokeWidth: 6,
                          backgroundColor: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                          valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF14B8A6)),
                        );
                      },
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$caloriesLeft',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF1F2937),
                        ),
                      ),
                      Text(
                        'left',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Macro Chips
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMacroChip('Protein', '$_totalProtein g', _proteinGoal, isDark, const Color(0xFF3B82F6)),
                _buildMacroChip('Carbs', '$_totalCarbs g', _carbsGoal, isDark, const Color(0xFF10B981)),
                _buildMacroChip('Fat', '$_totalFat g', _fatGoal, isDark, const Color(0xFFFF9800)),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMacroChip(String label, String value, int goal, bool isDark, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 10,
            color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }
  
  
  Widget _buildMealCard(Meal meal, bool isDark) {
    final mealCalories = meal.items.fold<int>(0, (sum, item) => sum + item.calories);
    final hasPhoto = meal.photos.isNotEmpty;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: hasPhoto ? Border(
          top: BorderSide(
            color: const Color(0xFF14B8A6).withValues(alpha: 0.3),
            width: 2,
          ),
        ) : null,
      ),
      child: Column(
        children: [
          // Header Row
          _buildMealHeader(meal, mealCalories, isDark),
          
          // Meal Photo Row
          if (meal.photos.isNotEmpty) _buildMealPhotos(meal, isDark),
          
          // Food Items List
          if (meal.items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: meal.items.map((item) => _buildFoodItemRow(item, meal, isDark)).toList(),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No items added yet',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildMealHeader(Meal meal, int calories, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal.name,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  meal.time,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$calories kcal',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF14B8A6) : const Color(0xFF14B8A6),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _showAddFoodSheet(meal, isDark),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF14B8A6).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.add_rounded,
                size: 20,
                color: Color(0xFF14B8A6),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMealPhotos(Meal meal, bool isDark) {
    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: meal.photos.length + 1, // +1 for add photo
        itemBuilder: (context, index) {
          if (index == meal.photos.length) {
            return _buildAddPhotoTile(meal, isDark);
          }
          return _buildPhotoThumbnail(meal.photos[index], meal, index, isDark);
        },
      ),
    );
  }
  
  Widget _buildAddPhotoTile(Meal meal, bool isDark) {
    return GestureDetector(
      onTap: () => _showPhotoPicker(meal, isDark),
      child: Container(
        width: 80,
        height: 80,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(12),
        ),
        child: CustomPaint(
          painter: DashedBorderPainter(
            color: isDark ? const Color(0xFF4B5563) : const Color(0xFFD1D5DB),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_photo_alternate_rounded,
                color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                'Add Photo',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildPhotoThumbnail(File photo, Meal meal, int index, bool isDark) {
    return GestureDetector(
      onTap: () => _showPhotoGallery(meal, index, isDark),
      child: Container(
        width: 80,
        height: 80,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          image: DecorationImage(
            image: FileImage(photo),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => _deletePhoto(meal, index),
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFoodItemRow(FoodEntry item, Meal meal, bool isDark) {
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      secondaryBackground: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF6366F1),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(Icons.edit_rounded, color: Colors.white),
      ),
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          _deleteFoodItem(meal, item);
        } else {
          _editFoodItem(meal, item, isDark);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF111827) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${item.foodName}, ${item.quantity.toStringAsFixed(item.quantity % 1 == 0 ? 0 : 1)} ${item.unit}, P ${item.macros.protein.toInt()} C ${item.macros.carbs.toInt()} F ${item.macros.fat.toInt()}, ${item.calories} kcal',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : const Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAddMealTile(bool isDark) {
    return GestureDetector(
      onTap: () => _showAddMealDialog(isDark),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
            style: BorderStyle.solid,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_rounded,
              color: isDark ? const Color(0xFF14B8A6) : const Color(0xFF14B8A6),
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Add Meal',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF14B8A6) : const Color(0xFF14B8A6),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Date Picker
  void _showDatePicker(bool isDark) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: const Color(0xFF14B8A6),
              onPrimary: Colors.white,
              surface: isDark ? const Color(0xFF1F2937) : Colors.white,
              onSurface: isDark ? Colors.white : const Color(0xFF1F2937),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }
  
  // Macro Dashboard
  void _showMacroDashboard(bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Text(
                    'Macro & Micro Dashboard',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1F2937),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: isDark ? Colors.white : const Color(0xFF1F2937),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _buildMacroProgress('Protein', _totalProtein, _proteinGoal, isDark, const Color(0xFF3B82F6)),
                    const SizedBox(height: 16),
                    _buildMacroProgress('Carbs', _totalCarbs, _carbsGoal, isDark, const Color(0xFF10B981)),
                    const SizedBox(height: 16),
                    _buildMacroProgress('Fat', _totalFat, _fatGoal, isDark, const Color(0xFFFF9800)),
                    const SizedBox(height: 16),
                    _buildMacroProgress('Fiber', 15, 30, isDark, const Color(0xFF8B5CF6)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMacroProgress(String label, int current, int goal, bool isDark, Color color) {
    final progress = (current / goal).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1F2937),
                ),
              ),
              Text(
                '$current / $goal g',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
  
  // Add Food Sheet
  void _showAddFoodSheet(Meal meal, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddFoodSheet(
        meal: meal,
        isDark: isDark,
        foodDatabase: _foodDatabase,
        onFoodAdded: (foodEntry) {
          setState(() {
            meal.items.add(foodEntry);
            _calculateTotals();
          });
          Navigator.pop(context);
          _showSuccessToast('Added to ${meal.name}');
        },
      ),
    );
  }
  
  // Photo Picker
  void _showPhotoPicker(Meal meal, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded),
                title: const Text('Take Photo'),
                onTap: () async {
                  Navigator.pop(context);
                  final image = await _picker.pickImage(source: ImageSource.camera);
                  if (image != null) {
                    setState(() {
                      meal.photos.add(File(image.path));
                    });
                    // Trigger glow animation
                    Future.delayed(const Duration(milliseconds: 100), () {
                      setState(() {});
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: const Text('Choose from Gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  final image = await _picker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    setState(() {
                      meal.photos.add(File(image.path));
                    });
                    // Trigger glow animation
                    Future.delayed(const Duration(milliseconds: 100), () {
                      setState(() {});
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showPhotoGallery(Meal meal, int index, bool isDark) {
    // Full screen photo gallery with pinch zoom
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _PhotoGalleryPage(photos: meal.photos, initialIndex: index),
      ),
    );
  }
  
  void _deletePhoto(Meal meal, int index) {
    setState(() {
      meal.photos.removeAt(index);
    });
  }
  
  void _deleteFoodItem(Meal meal, FoodEntry item) {
    setState(() {
      meal.items.remove(item);
      _calculateTotals();
    });
    _showSuccessToast('Removed from ${meal.name}');
  }
  
  void _editFoodItem(Meal meal, FoodEntry item, bool isDark) {
    // Reopen add food sheet with pre-filled data
    _showAddFoodSheet(meal, isDark);
  }
  
  void _showAddMealDialog(bool isDark) {
    final nameController = TextEditingController();
    final timeController = TextEditingController(text: '12:00');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1F2937) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Create Custom Meal',
          style: TextStyle(
            fontFamily: 'Poppins',
            color: isDark ? Colors.white : const Color(0xFF1F2937),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Meal name',
                labelStyle: TextStyle(
                  color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF111827) : const Color(0xFFF3F4F6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1F2937)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: timeController,
              decoration: InputDecoration(
                labelText: 'Time (optional)',
                labelStyle: TextStyle(
                  color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF111827) : const Color(0xFFF3F4F6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1F2937)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                setState(() {
                  _meals.add(Meal(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameController.text,
                    time: timeController.text,
                    items: [],
                    photos: [],
                  ));
                });
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF14B8A6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
  
  void _showSuccessToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                // Undo logic here
              },
              child: const Text('UNDO'),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF14B8A6),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// Add Food Sheet Widget
class _AddFoodSheet extends StatefulWidget {
  final Meal meal;
  final bool isDark;
  final List<FoodItem> foodDatabase;
  final Function(FoodEntry) onFoodAdded;
  
  const _AddFoodSheet({
    required this.meal,
    required this.isDark,
    required this.foodDatabase,
    required this.onFoodAdded,
  });
  
  @override
  State<_AddFoodSheet> createState() => _AddFoodSheetState();
}

class _AddFoodSheetState extends State<_AddFoodSheet> {
  int _selectedTab = 0; // 0: Recent, 1: Favorites, 2: Indian, 3: Packaged, 4: Recipes
  String _searchQuery = '';
  String? _selectedCategory;
  FoodItem? _selectedFood;
  
  List<FoodItem> get _filteredFoods {
    var foods = widget.foodDatabase;
    
    // Filter by search
    if (_searchQuery.isNotEmpty) {
      foods = foods.where((f) => 
        f.name.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    
    // Filter by category
    if (_selectedCategory != null) {
      foods = foods.where((f) => f.tags.contains(_selectedCategory!)).toList();
    }
    
    return foods;
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: widget.isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Type food name, e.g., idli, paneer, egg',
                      hintStyle: TextStyle(
                        color: widget.isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                      ),
                      filled: true,
                      fillColor: widget.isDark ? const Color(0xFF111827) : const Color(0xFFF3F4F6),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.search_rounded),
                    ),
                    style: TextStyle(color: widget.isDark ? Colors.white : const Color(0xFF1F2937)),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  onPressed: () {
                    // Barcode scanner
                  },
                ),
              ],
            ),
          ),
          // Quick Tabs
          _buildQuickTabs(),
          
          // Indian Food Category Chips
          if (_selectedTab == 2) _buildCategoryChips(),
          
          // Food Results
          Expanded(
            child: _selectedFood == null
                ? _buildFoodList()
                : _buildQuantitySelector(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildQuickTabs() {
    final tabs = ['Recent', 'Favorites', 'Indian', 'Packaged', 'Recipes'];
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: tabs.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedTab == index;
          return GestureDetector(
            onTap: () => setState(() {
              _selectedTab = index;
              _selectedCategory = null;
            }),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF14B8A6)
                    : (widget.isDark ? const Color(0xFF111827) : const Color(0xFFF3F4F6)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  tabs[index],
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : (widget.isDark ? Colors.white : const Color(0xFF1F2937)),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildCategoryChips() {
    final categories = ['South Indian', 'North Indian', 'Snacks', 'Sweets', 'Drinks'];
    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedCategory == categories[index];
          return GestureDetector(
            onTap: () => setState(() {
              _selectedCategory = isSelected ? null : categories[index];
            }),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF14B8A6).withValues(alpha: 0.2)
                    : (widget.isDark ? const Color(0xFF111827) : const Color(0xFFF3F4F6)),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF14B8A6)
                      : (widget.isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
                ),
              ),
              child: Center(
                child: Text(
                  categories[index],
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? const Color(0xFF14B8A6)
                        : (widget.isDark ? Colors.white : const Color(0xFF1F2937)),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildFoodList() {
    final foods = _filteredFoods;
    
    if (foods.isEmpty) {
      return Center(
        child: Text(
          'No foods found',
          style: TextStyle(
            fontFamily: 'Poppins',
            color: widget.isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
          ),
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: foods.length,
      itemBuilder: (context, index) {
        final food = foods[index];
        return _buildFoodCard(food);
      },
    );
  }
  
  Widget _buildFoodCard(FoodItem food) {
    return GestureDetector(
      onTap: () => setState(() => _selectedFood = food),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: widget.isDark ? const Color(0xFF111827) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    food.name,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: widget.isDark ? Colors.white : const Color(0xFF1F2937),
                    ),
                  ),
                ),
                if (food.isVerified)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF14B8A6).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '✓ Verified',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF14B8A6),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${food.defaultUnit == 'pcs' ? '1 ${food.defaultUnit}' : '100 ${food.defaultUnit}'}, '
              'Protein ${food.macrosPer100g.protein}g, '
              '${food.microsPer100g.calcium > 100 ? 'Calcium high' : 'Carbs ${food.macrosPer100g.carbs}g'}',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: widget.isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildQuantitySelector() {
    return _QuantitySelector(
      food: _selectedFood!,
      meal: widget.meal,
      isDark: widget.isDark,
      onAdded: (entry) {
        widget.onFoodAdded(entry);
        Navigator.pop(context);
      },
      onBack: () => setState(() => _selectedFood = null),
    );
  }
}

// Quantity Selector Widget
class _QuantitySelector extends StatefulWidget {
  final FoodItem food;
  final Meal meal;
  final bool isDark;
  final Function(FoodEntry) onAdded;
  final VoidCallback onBack;
  
  const _QuantitySelector({
    required this.food,
    required this.meal,
    required this.isDark,
    required this.onAdded,
    required this.onBack,
  });
  
  @override
  State<_QuantitySelector> createState() => _QuantitySelectorState();
}

class _QuantitySelectorState extends State<_QuantitySelector> with SingleTickerProviderStateMixin {
  late double _quantity;
  late String _selectedUnit;
  late AnimationController _numberController;
  
  @override
  void initState() {
    super.initState();
    _selectedUnit = widget.food.defaultUnit;
    // Auto-detect default quantity
    if (widget.food.category == FoodCategory.count) {
      _quantity = 2.0; // Default 2 pieces for count foods
    } else if (widget.food.category == FoodCategory.weight) {
      _quantity = 100.0; // Default 100g for weight foods
    } else {
      _quantity = 250.0; // Default 250ml for volume foods
    }
    _numberController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _numberController.forward();
  }
  
  @override
  void dispose() {
    _numberController.dispose();
    super.dispose();
  }
  
  void _updateQuantity(double delta) {
    setState(() {
      _quantity = (_quantity + delta).clamp(0.1, 10000);
      _numberController.reset();
      _numberController.forward();
    });
  }
  
  void _changeUnit(String newUnit) {
    // Convert quantity when unit changes
    final oldGrams = _quantity * (widget.food.gramsPerUnit[_selectedUnit] ?? 1);
    final newQuantity = oldGrams / (widget.food.gramsPerUnit[newUnit] ?? 1);
    
    setState(() {
      _selectedUnit = newUnit;
      _quantity = newQuantity;
    });
  }
  
  Macros _calculateMacros() {
    final grams = _quantity * (widget.food.gramsPerUnit[_selectedUnit] ?? 1);
    final multiplier = grams / 100.0;
    return Macros(
      protein: widget.food.macrosPer100g.protein * multiplier,
      carbs: widget.food.macrosPer100g.carbs * multiplier,
      fat: widget.food.macrosPer100g.fat * multiplier,
      fiber: widget.food.macrosPer100g.fiber * multiplier,
    );
  }
  
  int _calculateCalories() {
    final grams = _quantity * (widget.food.gramsPerUnit[_selectedUnit] ?? 1);
    final multiplier = grams / 100.0;
    return (widget.food.caloriesPer100g * multiplier).round();
  }
  
  @override
  Widget build(BuildContext context) {
    final macros = _calculateMacros();
    final calories = _calculateCalories();
    
    return Column(
      children: [
        // Back button
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: widget.onBack,
                color: widget.isDark ? Colors.white : const Color(0xFF1F2937),
              ),
              Expanded(
                child: Text(
                  widget.food.name,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: widget.isDark ? Colors.white : const Color(0xFF1F2937),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Quantity Selector
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => _updateQuantity(-1),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: widget.isDark ? const Color(0xFF111827) : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.remove_rounded),
                ),
              ),
              Expanded(
                child: Center(
                  child: AnimatedBuilder(
                    animation: _numberController,
                    builder: (context, child) {
                      return Text(
                        _quantity.toStringAsFixed(_quantity % 1 == 0 ? 0 : 1),
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: widget.isDark ? Colors.white : const Color(0xFF1F2937),
                        ),
                      );
                    },
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _updateQuantity(1),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: widget.isDark ? const Color(0xFF111827) : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.add_rounded),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Unit Selector
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Wrap(
            spacing: 8,
            children: widget.food.unitsSupported.map((unit) {
              final isSelected = _selectedUnit == unit;
              return GestureDetector(
                onTap: () => _changeUnit(unit),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF14B8A6)
                        : (widget.isDark ? const Color(0xFF111827) : const Color(0xFFF3F4F6)),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF14B8A6)
                          : (widget.isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
                    ),
                  ),
                  child: Text(
                    unit,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : (widget.isDark ? Colors.white : const Color(0xFF1F2937)),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Quick Picker
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Wrap(
            spacing: 8,
            children: (widget.food.category == FoodCategory.count
                ? [1, 2, 3, 4, 5]
                : [25, 50, 100, 150, 200]).map((value) {
              return GestureDetector(
                onTap: () => setState(() => _quantity = value.toDouble()),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: widget.isDark ? const Color(0xFF111827) : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    value.toString(),
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: widget.isDark ? Colors.white : const Color(0xFF1F2937),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Macros Display
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.isDark ? const Color(0xFF111827) : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMacroPill('Protein', macros.protein, widget.isDark, const Color(0xFF3B82F6)),
                    _buildMacroPill('Carbs', macros.carbs, widget.isDark, const Color(0xFF10B981)),
                    _buildMacroPill('Fat', macros.fat, widget.isDark, const Color(0xFFFF9800)),
                    _buildMacroPill('Fiber', macros.fiber, widget.isDark, const Color(0xFF8B5CF6)),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '$calories kcal',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: widget.isDark ? Colors.white : const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 16),
                _buildMicrosSection(macros, calories),
              ],
            ),
          ),
        ),
        
        const Spacer(),
        
        // Add Button
        Padding(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                widget.onAdded(FoodEntry(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  foodName: widget.food.name,
                  quantity: _quantity,
                  unit: _selectedUnit,
                  macros: macros,
                  calories: calories,
                ));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF14B8A6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Add to ${widget.meal.name}',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Micros _calculateMicros() {
    final grams = _quantity * (widget.food.gramsPerUnit[_selectedUnit] ?? 1);
    final multiplier = grams / 100.0;
    return Micros(
      calcium: widget.food.microsPer100g.calcium * multiplier,
      iron: widget.food.microsPer100g.iron * multiplier,
      potassium: widget.food.microsPer100g.potassium * multiplier,
    );
  }
  
  Widget _buildMicrosSection(Macros macros, int calories) {
    final micros = _calculateMicros();
    final allMicros = [
      {'name': 'Calcium', 'value': micros.calcium, 'unit': 'mg', 'daily': 1000.0, 'color': const Color(0xFF3B82F6)},
      {'name': 'Iron', 'value': micros.iron, 'unit': 'mg', 'daily': 18.0, 'color': const Color(0xFFEF4444)},
      {'name': 'Potassium', 'value': micros.potassium, 'unit': 'mg', 'daily': 3500.0, 'color': const Color(0xFF10B981)},
      {'name': 'Sodium', 'value': 0.0, 'unit': 'mg', 'daily': 2300.0, 'color': const Color(0xFF6366F1)},
      {'name': 'Vitamin A', 'value': 0.0, 'unit': 'IU', 'daily': 5000.0, 'color': const Color(0xFFFF9800)},
      {'name': 'Vitamin B12', 'value': 0.0, 'unit': 'mcg', 'daily': 2.4, 'color': const Color(0xFF8B5CF6)},
      {'name': 'Vitamin C', 'value': 0.0, 'unit': 'mg', 'daily': 90.0, 'color': const Color(0xFF14B8A6)},
    ];
    
    // Filter out zero values and sort by value
    final nonZeroMicros = allMicros.where((m) => m['value'] as double > 0).toList();
    nonZeroMicros.sort((a, b) => (b['value'] as double).compareTo(a['value'] as double));
    
    return _MicrosCollapsibleSection(
      micros: nonZeroMicros,
      isDark: widget.isDark,
    );
  }
  
  Widget _buildMacroPill(String label, double value, bool isDark, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${value.toStringAsFixed(1)}g',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 10,
            color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }
}

// Micros Collapsible Section
class _MicrosCollapsibleSection extends StatefulWidget {
  final List<Map<String, dynamic>> micros;
  final bool isDark;
  
  const _MicrosCollapsibleSection({
    required this.micros,
    required this.isDark,
  });
  
  @override
  State<_MicrosCollapsibleSection> createState() => _MicrosCollapsibleSectionState();
}

class _MicrosCollapsibleSectionState extends State<_MicrosCollapsibleSection> {
  bool _isExpanded = false;
  
  @override
  Widget build(BuildContext context) {
    if (widget.micros.isEmpty) return const SizedBox.shrink();
    
    final top3 = widget.micros.take(3).toList();
    final remaining = widget.micros.skip(3).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Row(
            children: [
              Text(
                'Micros',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: widget.isDark ? Colors.white : const Color(0xFF1F2937),
                ),
              ),
              const Spacer(),
              Text(
                _isExpanded ? 'Less' : 'More',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: const Color(0xFF14B8A6),
                ),
              ),
              Icon(
                _isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                color: const Color(0xFF14B8A6),
                size: 20,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...top3.map((m) => _buildMicroItem(m, widget.isDark)),
        if (_isExpanded) ...remaining.map((m) => _buildMicroItem(m, widget.isDark)),
      ],
    );
  }
  
  Widget _buildMicroItem(Map<String, dynamic> micro, bool isDark) {
    final name = micro['name'] as String;
    final value = micro['value'] as double;
    final unit = micro['unit'] as String;
    final daily = micro['daily'] as double;
    final color = micro['color'] as Color;
    final percent = (value / daily * 100).clamp(0.0, 100.0);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
              ),
            ),
          ),
          Text(
            '${value.toStringAsFixed(1)} $unit',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color.withValues(alpha: percent > 50 ? 1.0 : 0.7),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 60,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percent / 100,
                minHeight: 4,
                backgroundColor: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Dashed Border Painter
class DashedBorderPainter extends CustomPainter {
  final Color color;
  
  DashedBorderPainter({required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    
    const dashWidth = 5.0;
    const dashSpace = 3.0;
    double startX = 0;
    
    // Top
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
    
    // Right
    double startY = 0;
    while (startY < size.height) {
      canvas.drawLine(
        Offset(size.width, startY),
        Offset(size.width, startY + dashWidth),
        paint,
      );
      startY += dashWidth + dashSpace;
    }
    
    // Bottom
    startX = 0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height),
        Offset(startX + dashWidth, size.height),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
    
    // Left
    startY = 0;
    while (startY < size.height) {
      canvas.drawLine(
        Offset(0, startY),
        Offset(0, startY + dashWidth),
        paint,
      );
      startY += dashWidth + dashSpace;
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Photo Gallery Page
class _PhotoGalleryPage extends StatelessWidget {
  final List<File> photos;
  final int initialIndex;
  
  const _PhotoGalleryPage({
    required this.photos,
    required this.initialIndex,
  });
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: PageController(initialPage: initialIndex),
        itemCount: photos.length,
        itemBuilder: (context, index) {
          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 3.0,
            child: Center(
              child: Image.file(photos[index], fit: BoxFit.contain),
            ),
          );
        },
      ),
    );
  }
}

// Data Models
class Meal {
  String id;
  String name;
  String time;
  List<FoodEntry> items;
  List<File> photos;
  
  Meal({
    required this.id,
    required this.name,
    required this.time,
    required this.items,
    required this.photos,
  });
}

class FoodEntry {
  String id;
  String foodName;
  double quantity;
  String unit;
  Macros macros;
  int calories;
  
  FoodEntry({
    required this.id,
    required this.foodName,
    required this.quantity,
    required this.unit,
    required this.macros,
    required this.calories,
  });
}

class FoodItem {
  String id;
  String name;
  FoodCategory category;
  String defaultUnit;
  List<String> unitsSupported;
  Map<String, double> gramsPerUnit;
  Macros macrosPer100g;
  int caloriesPer100g;
  Micros microsPer100g;
  bool isVerified;
  List<String> tags;
  
  FoodItem({
    required this.id,
    required this.name,
    required this.category,
    required this.defaultUnit,
    required this.unitsSupported,
    required this.gramsPerUnit,
    required this.macrosPer100g,
    required this.caloriesPer100g,
    required this.microsPer100g,
    required this.isVerified,
    required this.tags,
  });
}

enum FoodCategory {
  count,
  weight,
  volume,
}

class Macros {
  double protein;
  double carbs;
  double fat;
  double fiber;
  
  Macros({
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
  });
}

class Micros {
  double calcium;
  double iron;
  double potassium;
  
  Micros({
    required this.calcium,
    required this.iron,
    required this.potassium,
  });
}
