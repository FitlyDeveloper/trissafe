import 'package:flutter/material.dart';

class FoodHelperMethods {
  static String formatCalories(int calories) {
    return '$calories kcal';
  }

  static String formatMacros(double value) {
    return '${value.toStringAsFixed(1)}g';
  }

  static Color getCalorieColor(int calories) {
    if (calories < 300) return Colors.green;
    if (calories < 600) return Colors.orange;
    return Colors.red;
  }

  static String getMealType(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return 'Breakfast';
      case 'lunch':
        return 'Lunch';
      case 'dinner':
        return 'Dinner';
      case 'snack':
        return 'Snack';
      default:
        return 'Meal';
    }
  }
} 