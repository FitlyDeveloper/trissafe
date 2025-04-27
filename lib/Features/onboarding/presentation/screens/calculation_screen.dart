import 'package:flutter/material.dart';
import 'package:fitness_app/Features/onboarding/presentation/screens/comfort_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CalculationScreen extends StatelessWidget {
  final bool isMetric;
  final int initialWeight;
  final int dreamWeight;
  final bool isGaining;
  final double speedValue;
  final String gender;
  final int heightInCm;
  final DateTime birthDate;
  final String gymGoal;
  int calculatedCalories = 0;
  int tdee = 0;
  int dailyDeficit = 0;
  int proteinGrams = 0;
  int fatGrams = 0;
  int carbGrams = 0;

  CalculationScreen({
    super.key,
    required this.isMetric,
    required this.initialWeight,
    required this.dreamWeight,
    required this.isGaining,
    required this.speedValue,
    required this.gender,
    required this.heightInCm,
    required this.birthDate,
    required this.gymGoal,
  }) {
    // Print debug values
    print('Initial values:');
    print('Weight: $initialWeight ${isMetric ? 'kg' : 'lbs'}');

    // CRITICAL: Use the correct height that is passed in cm
    // The height should already be in cm from the weight_height_screen.dart
    int actualHeightInCm = heightInCm;
    print('Height passed to calculation: $heightInCm cm');

    print('Speed: $speedValue ${isMetric ? 'kg' : 'lbs'}/week');
    print('Birth date: $birthDate');

    // Save all data to SharedPreferences for the main app to access
    _saveDataToPreferences(actualHeightInCm);

    // Calculate age correctly - matches codia_page.dart logic
    DateTime today = DateTime.now();
    int userAge = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      userAge--;
    }

    // Only check for maximum age (130)
    if (userAge > 130) {
      print(
          'WARNING: User appears to be over 130 years old (age: $userAge). Using maximum age of 130.');
      userAge = 130;
    }

    print('Calculated age: $userAge from birth date: $birthDate');

    // Convert measurements if using imperial units
    final weightInKg =
        isMetric ? initialWeight : (initialWeight * 0.453592).round();
    final dreamWeightInKg =
        isMetric ? dreamWeight : (dreamWeight * 0.453592).round();

    // Use converted height
    final heightConverted = actualHeightInCm;

    print('Converted values:');
    print('Weight in kg: $weightInKg');
    print('Height in cm: $heightConverted');

    // NORMALIZE GOAL SPEED to exact increments (match codia_page.dart)
    double normalizedSpeed = speedValue;
    if (speedValue > 0) {
      if (isMetric) {
        // Round to exactly 1 decimal place
        normalizedSpeed = (speedValue * 10).round() / 10.0;
        print(
            'Normalized goal speed from $speedValue to ${normalizedSpeed.toStringAsFixed(1)} kg/week');
      } else {
        // Round to exactly 1 decimal place for pounds
        normalizedSpeed = (speedValue * 10).round() / 10.0;
        print(
            'Normalized goal speed from $speedValue to ${normalizedSpeed.toStringAsFixed(1)} lb/week');
      }
    }

    // Round weightInKg to 1 decimal place (match codia_page.dart)
    double roundedWeightKg = (weightInKg * 10).round() / 10.0;
    double roundedDreamWeightKg = (dreamWeightInKg * 10).round() / 10.0;

    // Ensure height is a whole number (match codia_page.dart)
    int roundedHeight = heightConverted.round();

    // Calculate TDEE first using rounded values
    tdee = calculateTDEE(
      gender: gender,
      weightKg: roundedWeightKg.round(), // Use rounded weight
      heightCm: roundedHeight, // Use rounded height
      userAge: userAge, // Use the calculated age
    );

    print('TDEE calculated: $tdee');

    // Calculate daily deficit/surplus based on unit system with normalized speed
    if (isMetric) {
      // Metric: Use 7700 kcal per kg
      // Round to 1 decimal place for metric values
      normalizedSpeed = (normalizedSpeed * 10).round() / 10.0;
      // Do NOT round the deficit calculation to maintain precision for small values
      double exactMetricDeficit = normalizedSpeed * 7700 / 7;
      dailyDeficit =
          exactMetricDeficit.floor().toInt(); // Weekly kg to daily calories
      print(
          'Metric calculation: ${normalizedSpeed.toStringAsFixed(3)} kg/week × 7700 ÷ 7 = ${exactMetricDeficit.toStringAsFixed(3)} → $dailyDeficit calories/day');
    } else {
      // Imperial: Use 3500 kcal per lb
      // For imperial values, keep full precision during calculation
      // For display only, round to 1 decimal place
      double displaySpeed = (normalizedSpeed * 10).round() / 10.0;
      // Do NOT round the deficit calculation to maintain precision for small values
      double exactDeficit = normalizedSpeed * 3500 / 7;
      dailyDeficit =
          exactDeficit.floor().toInt(); // Weekly lbs to daily calories
      print(
          'Imperial calculation: ${displaySpeed.toStringAsFixed(1)} lb/week × 3500 ÷ 7 = ${exactDeficit.toStringAsFixed(3)} → $dailyDeficit calories/day');
    }

    print('Daily deficit calculated: $dailyDeficit');

    // Calculate final target calories
    double rawCalculatedCalories = isGaining
        ? tdee.toDouble() + dailyDeficit.toDouble()
        : tdee.toDouble() - dailyDeficit.toDouble();
    print('Raw calculated calories before flooring: $rawCalculatedCalories');

    // Ensure the calories match exactly with codia_page.dart by using floor instead of rounding
    calculatedCalories = rawCalculatedCalories.floorToDouble().toInt();

    print('Final target calories (floored): $calculatedCalories');

    // Define macro distribution based on gym goal - EXACT SAME AS IN codia_page.dart
    Map<String, Map<String, double>> macroTargets = {
      "Build Muscle": {
        "proteinPercent": 0.32,
        "carbPercent": 0.45,
        "fatPercent": 0.23,
      },
      "Gain Strength": {
        "proteinPercent": 0.28,
        "carbPercent": 0.42,
        "fatPercent": 0.30,
      },
      "Boost Endurance": {
        "proteinPercent": 0.18,
        "carbPercent": 0.60,
        "fatPercent": 0.22,
      },
      // Default balanced macros when no gym goal is selected
      "null": {
        "proteinPercent": 0.25,
        "carbPercent": 0.50,
        "fatPercent": 0.25,
      }
    };

    // Get the macro distribution for the selected gym goal (default to balanced macros if null or not found)
    print('Using gym goal for macros: "$gymGoal"');
    Map<String, double> selectedMacros =
        macroTargets["null"]!; // Default to balanced macros

    // Only try to use gymGoal if it's a valid key in the map - EXACTLY like in codia_page.dart
    String goalKey = gymGoal ?? "null";
    if (macroTargets.containsKey(goalKey)) {
      selectedMacros = macroTargets[goalKey]!;
      print('Using macro distribution for: "$goalKey"');
    } else {
      print(
          'No matching macro distribution for: "$goalKey", using balanced default');
    }

    // Calculate macronutrient targets based on calorie goal and gym goal
    double proteinPercent = selectedMacros["proteinPercent"]!;
    double carbPercent = selectedMacros["carbPercent"]!;
    double fatPercent = selectedMacros["fatPercent"]!;

    // Log the selected macro distribution exactly like codia_page.dart
    print('Using macro distribution for gym goal: "$gymGoal"');
    print('- Protein: ${(proteinPercent * 100).toStringAsFixed(1)}%');
    print('- Carbs: ${(carbPercent * 100).toStringAsFixed(1)}%');
    print('- Fat: ${(fatPercent * 100).toStringAsFixed(1)}%');

    // Calculate macro targets in grams - EXACTLY as in codia_page.dart
    proteinGrams = ((calculatedCalories * proteinPercent) / 4).round();
    fatGrams = ((calculatedCalories * fatPercent) / 9).round();
    carbGrams = ((calculatedCalories * carbPercent) / 4).round();

    // Log the calculations with the exact same format as codia_page.dart
    print('Calculated macro targets for $calculatedCalories calories:');
    print(
        '- Protein: ${proteinGrams}g (${(calculatedCalories * proteinPercent).round()} kcal)');
    print(
        '- Fat: ${fatGrams}g (${(calculatedCalories * fatPercent).round()} kcal)');
    print(
        '- Carbs: ${carbGrams}g (${(calculatedCalories * carbPercent).round()} kcal)');
    print(
        '- Total: ${((calculatedCalories * proteinPercent) + (calculatedCalories * fatPercent) + (calculatedCalories * carbPercent)).round()} kcal');
  }

  // Save all important calculation data to SharedPreferences
  Future<void> _saveDataToPreferences(int heightInCm) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Print existing height values for debugging
      print('\nHEIGHT VALUES BEFORE SAVING:');
      List<String> heightKeys = [
        'user_height_cm',
        'heightInCm',
        'height_cm',
        'height'
      ];
      for (String key in heightKeys) {
        try {
          if (prefs.containsKey(key)) {
            if (prefs.getInt(key) != null) {
              print('$key (Int): ${prefs.getInt(key)}');
            } else if (prefs.getDouble(key) != null) {
              print('$key (Double): ${prefs.getDouble(key)}');
            } else {
              print('$key: exists but type is not int or double');
            }
          } else {
            print('$key: does not exist');
          }
        } catch (e) {
          print('$key: Error reading - $e');
        }
      }

      // Save gender
      await prefs.setString('gender', gender);

      // Save weight - both in original and kg format if needed
      if (isMetric) {
        await prefs.setDouble('user_weight_kg', initialWeight.toDouble());
      } else {
        // Convert to kg for consistent storage
        double weightInKg = initialWeight * 0.453592;
        await prefs.setDouble('user_weight_kg', weightInKg);
        await prefs.setDouble('original_weight_lbs', initialWeight.toDouble());
      }

      // Save height in cm - CRITICAL: Store as both int and double using the CONVERTED height value
      print('\nSAVING HEIGHT VALUE:');
      print('Height value to save: $heightInCm cm (correctly converted)');
      await prefs.setInt('user_height_cm', heightInCm);
      await prefs.setDouble('heightInCm', heightInCm.toDouble());
      await prefs.setDouble('height_cm', heightInCm.toDouble());
      await prefs.setInt('height', heightInCm);

      // Also save original height in inches if using imperial
      if (!isMetric) {
        int originalHeightInches = this.heightInCm;
        await prefs.setInt('original_height_inches', originalHeightInches);
        print('Also saving original height: $originalHeightInches inches');
      }

      // Verify height was properly saved
      print('\nHEIGHT VALUES AFTER SAVING:');
      for (String key in heightKeys) {
        try {
          if (prefs.containsKey(key)) {
            if (prefs.getInt(key) != null) {
              print('$key (Int): ${prefs.getInt(key)}');
            } else if (prefs.getDouble(key) != null) {
              print('$key (Double): ${prefs.getDouble(key)}');
            } else {
              print('$key: exists but type is not int or double');
            }
          } else {
            print('$key: does not exist');
          }
        } catch (e) {
          print('$key: Error reading - $e');
        }
      }

      // Save birth date as string
      await prefs.setString('birth_date', birthDate.toIso8601String());

      // Save weight goal - Make sure these are consistent
      // If speedValue is 0, set goal to 'maintain' explicitly
      if (speedValue == 0) {
        await prefs.setString('goal', 'maintain');
        await prefs.setBool('isGaining', false); // Clear any previous value
        await prefs.setBool('isMaintaining', true); // Add a clear indicator
      } else {
        await prefs.setString('goal', isGaining ? 'gain' : 'lose');
        await prefs.setBool('isGaining', isGaining);
        await prefs.setBool('isMaintaining', false);
      }

      // Save goal speed - Be explicit about units and ensure consistency across all screens
      await prefs.setDouble('goal_speed', speedValue);

      // Also save the kg equivalent for cross-screen compatibility
      if (!isMetric && speedValue > 0) {
        double speedInKg = speedValue * 0.453592;
        await prefs.setDouble('goal_speed_kg_per_week', speedInKg);
      } else {
        await prefs.setDouble('goal_speed_kg_per_week', speedValue);
      }

      // Save gym goal if not null
      if (gymGoal != null && gymGoal.isNotEmpty) {
        await prefs.setString('gymGoal', gymGoal);
      }

      // Save metric/imperial preference
      await prefs.setBool('is_metric', isMetric);

      print('All calculation data saved to SharedPreferences');
    } catch (e) {
      print('Error saving calculation data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background gradient
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white,
                  Colors.grey[100]!.withOpacity(0.9),
                ],
              ),
            ),
          ),

          // Header content
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.07),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back,
                            color: Colors.black, size: 24),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 40),
                          child: const LinearProgressIndicator(
                            value: 11 / 13,
                            minHeight: 2,
                            backgroundColor: Color(0xFFE5E5EA),
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.black),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 21.2),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your Personalized\nNutrition Plan',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                          height: 1.21,
                          fontFamily: '.SF Pro Display',
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Just a glimpse of what\'s coming.',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w400,
                          height: 1.3,
                          fontFamily: '.SF Pro Display',
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Nutrition Plan Card
          Positioned(
            top: MediaQuery.of(context).size.height * 0.37,
            left: 32,
            right: 32,
            child: Container(
              height: 220,
              padding: EdgeInsets.fromLTRB(20, 15, 20, 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Calorie stats row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Deficit
                      Column(
                        children: [
                          Text(
                            '-$tdee',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              decoration: TextDecoration.none,
                            ),
                          ),
                          Text(
                            'Deficit',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.normal,
                              color: Colors.black,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ],
                      ),

                      // Circular progress
                      Container(
                        width: 130,
                        height: 130,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Circle image
                            Transform.translate(
                              offset: Offset(0, -3.9),
                              child: Image.asset(
                                'assets/images/circle.png',
                                width: 130,
                                height: 130,
                                fit: BoxFit.contain,
                              ),
                            ),

                            // Remaining calories text
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '$calculatedCalories',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                                Text(
                                  'Remaining',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.normal,
                                    color: Colors.black,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Burned
                      Column(
                        children: [
                          Text(
                            '0',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              decoration: TextDecoration.none,
                            ),
                          ),
                          Text(
                            'Burned',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.normal,
                              color: Colors.black,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  SizedBox(height: 5),

                  // Macronutrient progress bars
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Protein
                      Column(
                        children: [
                          Text(
                            'Protein',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black,
                              decoration: TextDecoration.none,
                            ),
                          ),
                          SizedBox(height: 4),
                          Container(
                            width: 80,
                            height: 8,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: Color(0xFFEEEEEE),
                            ),
                            child: FractionallySizedBox(
                              widthFactor: 0,
                              alignment: Alignment.centerLeft,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  color: Color(0xFFD7C1FF),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '0 / $proteinGrams g',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ],
                      ),

                      // Fat
                      Column(
                        children: [
                          Text(
                            'Fat',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black,
                              decoration: TextDecoration.none,
                            ),
                          ),
                          SizedBox(height: 4),
                          Container(
                            width: 80,
                            height: 8,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: Color(0xFFEEEEEE),
                            ),
                            child: FractionallySizedBox(
                              widthFactor: 0,
                              alignment: Alignment.centerLeft,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  color: Color(0xFFFFD8B1),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '0 / $fatGrams g',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ],
                      ),

                      // Carbs
                      Column(
                        children: [
                          Text(
                            'Carbs',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black,
                              decoration: TextDecoration.none,
                            ),
                          ),
                          SizedBox(height: 4),
                          Container(
                            width: 80,
                            height: 8,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: Color(0xFFEEEEEE),
                            ),
                            child: FractionallySizedBox(
                              widthFactor: 0,
                              alignment: Alignment.centerLeft,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  color: Color(0xFFB1EFD8),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '0 / $carbGrams g',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // White box at bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: MediaQuery.of(context).size.height * 0.153887,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.zero,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
            ),
          ),

          // Next button
          Positioned(
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).size.height * 0.06,
            child: Container(
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.0689,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(28),
              ),
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ComfortScreen(
                        isMetric: isMetric,
                        initialWeight: initialWeight,
                        dreamWeight: dreamWeight,
                        isGaining: isGaining,
                        speedValue: speedValue,
                        isMaintaining: speedValue == 0,
                      ),
                    ),
                  );
                },
                child: const Text(
                  'Continue',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    fontFamily: '.SF Pro Display',
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroBar(String label, int current, int total, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                fontFamily: '.SF Pro Display',
              ),
            ),
            Text(
              '$current/$total g',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontFamily: '.SF Pro Display',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: current / total,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Helper method for the numbers
  Widget _buildNumber(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            fontFamily: '.SF Pro Display',
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
            fontFamily: '.SF Pro Display',
          ),
        ),
      ],
    );
  }

  int calculateTDEE({
    required String gender,
    required int weightKg,
    required int heightCm,
    required int userAge, // Changed parameter from birthDate to userAge
  }) {
    // BMR using Mifflin-St Jeor Equation - EXACTLY as in codia_page.dart
    double bmr;
    if (gender == 'Female') {
      bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * userAge) - 161;
    } else if (gender == 'Male') {
      bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * userAge) + 5;
    } else {
      // Default to female formula for "Other"
      bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * userAge) - 161;
    }

    // Apply activity multiplier (1.2 for sedentary - little/no exercise)
    final tdee = bmr * 1.2;
    print('BMR calculated: $bmr, TDEE with multiplier: $tdee');

    return tdee.round();
  }
}

class CalorieArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height * 2);
    final paint = Paint()
      ..color = Colors.grey[200]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;

    canvas.drawArc(
      rect,
      -3.14,
      3.14,
      false,
      paint,
    );

    final progressPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;

    canvas.drawArc(
      rect,
      -3.14,
      2.1,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
