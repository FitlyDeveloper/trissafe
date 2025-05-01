import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Features/codia/codia_page.dart';
import 'dart:convert'; // For base64 decoding
import 'dart:typed_data'; // For Uint8List
import 'package:http/http.dart' as http; // For API calls to OpenAI

// Custom scroll physics optimized for mouse wheel
class SlowScrollPhysics extends ScrollPhysics {
  const SlowScrollPhysics({super.parent});

  @override
  SlowScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return SlowScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    // Only slow down mouse wheel scrolling, speed up touch scrolling
    if (offset.abs() < 10) {
      // Mouse wheel typically produces smaller offset values
      return offset * 0.3; // Slow down mouse wheel by 70%
    }
    return offset * 1.5; // Speed up touch scrolling by 50%
  }

  @override
  double get minFlingVelocity => super.minFlingVelocity;

  @override
  double get maxFlingVelocity =>
      super.maxFlingVelocity * 1.2; // Increased fling velocity by 20%
}

class FoodCardOpen extends StatefulWidget {
  final String? foodName;
  final String? healthScore;
  final String? calories;
  final String? protein;
  final String? fat;
  final String? carbs;
  final String? imageBase64; // Add parameter for base64 encoded image
  final List<Map<String, dynamic>>? ingredients; // Add ingredients parameter

  const FoodCardOpen({
    super.key,
    this.foodName,
    this.healthScore,
    this.calories,
    this.protein,
    this.fat,
    this.carbs,
    this.imageBase64, // Include in constructor
    this.ingredients, // Include in constructor
  });

  @override
  State<FoodCardOpen> createState() => _FoodCardOpenState();
}

class _FoodCardOpenState extends State<FoodCardOpen>
    with TickerProviderStateMixin {
  bool _isLoading = false;
  bool _isLiked = false;
  bool _isBookmarked = false; // Track bookmark state
  int _counter = 1; // Counter for +/- buttons
  String _privacyStatus = 'Public'; // Default privacy status
  late AnimationController _bookmarkController;
  late Animation<double> _bookmarkScaleAnimation;
  late AnimationController _likeController;
  late Animation<double> _likeScaleAnimation;
  late String _foodName;
  late String _healthScore;
  late double _healthScoreValue;
  late String _calories;
  late String _protein;
  late String _fat;
  late String _carbs;
  Uint8List? _imageBytes; // Store decoded image bytes
  String?
      _storedImageBase64; // For storing retrieved image from SharedPreferences
  List<Map<String, dynamic>> _ingredients = []; // Store ingredients list

  @override
  void initState() {
    super.initState();
    // Initialize animation controllers
    _initAnimationControllers();

    // Initialize food data
    _initFoodData();

    // Process image if available
    _processImage();

    // Load saved data from SharedPreferences
    _loadSavedData();
  }

  // Debug method to print ingredient details
  void _debugPrintIngredients(String source) {
    print('\n========== INGREDIENTS DEBUG ($source) ==========');
    print('Food: $_foodName');
    print('Ingredient count: ${_ingredients.length}');

    for (int i = 0; i < _ingredients.length; i++) {
      var ingredient = _ingredients[i];
      String name = ingredient['name'] ?? 'NO NAME';
      String amount = ingredient['amount'] ?? 'NO AMOUNT';
      var calories = ingredient['calories'] ?? 'NO CALORIES';
      print('[$i] $name - $amount - $calories kcal (${calories.runtimeType})');
    }

    print('===========================================\n');
  }

  void _initAnimationControllers() {
    // Bookmark animations
    _bookmarkController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );

    _bookmarkScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(
      CurvedAnimation(
        parent: _bookmarkController,
        curve: Curves.easeOutBack,
      ),
    );

    // Like animations
    _likeController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );

    _likeScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(
      CurvedAnimation(
        parent: _likeController,
        curve: Curves.easeOutBack,
      ),
    );
  }

  void _initFoodData() {
    // Initialize food name with provided value or fallback
    _foodName = widget.foodName ?? 'Delicious Cake';

    // Initialize health score with provided value or fallback
    _healthScore = widget.healthScore ?? '8/10';

    // Initialize nutritional values with provided values or fallbacks
    _calories = _formatDecimalValue(widget.calories ?? '500');
    _protein = widget.protein ?? '30';
    _fat = widget.fat ?? '32';
    _carbs = widget.carbs ?? '125';

    // Initialize ingredients list with 14-character limit enforcement
    // Don't override _ingredients if it will be loaded from SharedPreferences in _loadSavedData
    if (widget.ingredients != null && widget.ingredients!.isNotEmpty) {
      _ingredients = [];

      // Process each ingredient and split if necessary
      for (var ingredient in widget.ingredients!) {
        // Ensure ingredient is a Map<String, dynamic>
        if (ingredient is! Map<String, dynamic>) {
          print('Skipping invalid ingredient: $ingredient (not a Map)');
          continue;
        }

        // Extract ingredient data with proper fallbacks
        String name = ingredient['name'] ?? '';
        String amount =
            ingredient['amount'] ?? '1 serving'; // Ensure we keep the amount

        // Handle different types of calories values properly
        dynamic calories = ingredient['calories'] ?? 0;
        // If calories is a string, try to parse it to a number
        if (calories is String) {
          try {
            calories = double.tryParse(calories) ?? 0;
          } catch (e) {
            calories = 0;
          }
        }

        // Skip ingredients containing "with"
        if (name.toLowerCase().contains(' with ')) {
          // Split at "with" instead of skipping
          List<String> parts = name.split(' with ');
          if (parts.length >= 2) {
            // Add first part with original amount and calories
            if (parts[0].isNotEmpty && parts[0].length <= 14) {
              _ingredients.add({
                'name': parts[0].trim(),
                'amount': amount, // Keep original amount
                'calories': calories, // Keep original calories
              });
            }

            // Add second part
            if (parts[1].isNotEmpty && parts[1].length <= 14) {
              _ingredients.add({
                'name': parts[1].trim(),
                'amount': amount, // Keep original amount
                'calories':
                    calories / 2, // Split calories between two ingredients
              });
            }
          }
          continue; // Skip the rest of the loop
        }

        // Check if name exceeds 14 characters
        if (name.length > 14) {
          // Split the name by spaces
          List<String> words = name.split(' ');
          String currentSegment = '';

          for (var word in words) {
            // If adding this word would exceed limit, create a new ingredient with current segment
            if (currentSegment.isNotEmpty &&
                (currentSegment.length + word.length + 1) > 14) {
              _ingredients.add({
                'name': currentSegment.trim(),
                'amount': amount, // Keep original amount
                'calories': calories, // Keep original calories
              });
              currentSegment = word;
            } else {
              // Add word to current segment
              if (currentSegment.isEmpty) {
                currentSegment = word;
              } else {
                currentSegment += ' $word';
              }
            }
          }

          // Add remaining segment as an ingredient
          if (currentSegment.isNotEmpty) {
            _ingredients.add({
              'name': currentSegment.trim(),
              'amount': amount, // Keep original amount
              'calories': calories, // Keep original calories
            });
          }
        } else {
          // Name is within limit, add as is with original values
          _ingredients
              .add({'name': name, 'amount': amount, 'calories': calories});
        }
      }

      // Sort ingredients by calories (highest to lowest)
      _ingredients.sort((a, b) {
        final caloriesA = a.containsKey('calories')
            ? double.tryParse(a['calories'].toString()) ?? 0
            : 0;
        final caloriesB = b.containsKey('calories')
            ? double.tryParse(b['calories'].toString()) ?? 0
            : 0;
        return caloriesB.compareTo(caloriesA);
      });

      // Debug print the processed ingredients
      _debugPrintIngredients('After processing widget ingredients');

      // We've processed widget.ingredients - immediately save them to SharedPreferences
      // to make sure they persist across screens
      _saveData();
    }
    // Note: We don't need the else clause here with default ingredients
    // It will only be used if no ingredients are loaded from SharedPreferences

    // Extract the numeric value from the health score (e.g., 8 from "8/10")
    _healthScoreValue = _extractHealthScoreValue(_healthScore);

    print(
        'Initialized food data: name=$_foodName, calories=$_calories, protein=$_protein, fat=$_fat, carbs=$_carbs, healthScore=$_healthScore');
  }

  void _processImage() {
    // Try to use image from parameters first
    if (widget.imageBase64 != null && widget.imageBase64!.isNotEmpty) {
      try {
        // Store the original image base64 to avoid any quality loss
        _storedImageBase64 = widget.imageBase64;

        // Decode base64 string to bytes
        _imageBytes = base64Decode(widget.imageBase64!);
        print(
            'Loaded image from passed parameter, size: ${_imageBytes!.length} bytes');

        // Call optimize method
        _optimizeImage();
      } catch (e) {
        print('Error decoding image from parameter: $e');
      }
    }
  }

  Future<void> _loadSavedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String foodId = _foodName.replaceAll(' ', '_').toLowerCase();

      // Before loading - check if we have any widget ingredients passed
      if (widget.ingredients != null && widget.ingredients!.isNotEmpty) {
        print(
            'Ingredients received from widget: ${widget.ingredients!.length}');
        for (var ingredient in widget.ingredients!) {
          if (ingredient is Map<String, dynamic>) {
            print(
                'Ingredient: ${ingredient['name']} - ${ingredient['amount']} - ${ingredient['calories']} kcal');
          } else {
            print(
                'Non-map ingredient: $ingredient (${ingredient.runtimeType})');
          }
        }
      }

      setState(() {
        // Load interaction data only (likes, bookmarks, counter)
        _isLiked = prefs.getBool('food_liked_$foodId') ?? false;
        _isBookmarked = prefs.getBool('food_bookmarked_$foodId') ?? false;
        _counter = prefs.getInt('food_counter_$foodId') ?? 1;
        // Load privacy status for this food item
        _privacyStatus = prefs.getString('food_privacy_$foodId') ?? 'Public';

        // Only load nutrition values if they weren't passed as parameters
        if (widget.calories == null || widget.calories!.isEmpty) {
          _calories = _formatDecimalValue(
              prefs.getString('food_calories_$foodId') ?? _calories);
        }

        if (widget.protein == null || widget.protein!.isEmpty) {
          _protein = prefs.getString('food_protein_$foodId') ?? _protein;
        }

        if (widget.fat == null || widget.fat!.isEmpty) {
          _fat = prefs.getString('food_fat_$foodId') ?? _fat;
        }

        if (widget.carbs == null || widget.carbs!.isEmpty) {
          _carbs = prefs.getString('food_carbs_$foodId') ?? _carbs;
        }

        if (widget.healthScore == null || widget.healthScore!.isEmpty) {
          _healthScore =
              prefs.getString('food_health_score_$foodId') ?? _healthScore;
          // Update health score value when loaded
          _healthScoreValue = _extractHealthScoreValue(_healthScore);
        }

        // Load ingredients if not provided as parameters or if ingredients list is empty
        if ((widget.ingredients == null || widget.ingredients!.isEmpty) &&
            _ingredients.isEmpty) {
          final String? ingredientsJson =
              prefs.getString('food_ingredients_$foodId');
          if (ingredientsJson != null && ingredientsJson.isNotEmpty) {
            try {
              final List<dynamic> decodedList = jsonDecode(ingredientsJson);
              // Explicitly validate each ingredient when loading
              _ingredients = [];
              for (var item in decodedList) {
                if (item is Map<String, dynamic>) {
                  // Ensure all required fields exist
                  Map<String, dynamic> validIngredient = {
                    'name': item['name'] ?? 'Ingredient',
                    'amount': item['amount'] ?? '1 serving',
                    'calories': item['calories'] ?? 0
                  };
                  _ingredients.add(validIngredient);
                }
              }
              print(
                  'Loaded and validated ${_ingredients.length} ingredients from SharedPreferences');
            } catch (e) {
              print('Error decoding ingredients JSON: $e');
              _ingredients = []; // Reset to empty on error
            }
          }

          // If no ingredients were loaded from SharedPreferences, use default fallback
          if (_ingredients.isEmpty) {
            _ingredients = [
              {'name': 'Cheesecake', 'amount': '100g', 'calories': 300},
              {'name': 'Berries', 'amount': '20g', 'calories': 10},
              {'name': 'Jam', 'amount': '10g', 'calories': 20}
            ];

            // Sort default ingredients by calories (highest to lowest)
            _ingredients.sort((a, b) {
              final caloriesA = a.containsKey('calories')
                  ? double.tryParse(a['calories'].toString()) ?? 0
                  : 0;
              final caloriesB = b.containsKey('calories')
                  ? double.tryParse(b['calories'].toString()) ?? 0
                  : 0;
              return caloriesB.compareTo(caloriesA);
            });

            print('Using default ingredients as fallback');
          }
        }

        // Load image from SharedPreferences if not already loaded from parameter
        if (_imageBytes == null) {
          _storedImageBase64 = prefs.getString('food_image_$foodId');
          if (_storedImageBase64 != null && _storedImageBase64!.isNotEmpty) {
            try {
              _imageBytes = base64Decode(_storedImageBase64!);
              print(
                  'Loaded image from SharedPreferences, size: ${_imageBytes!.length} bytes');

              // Call optimize method
              _optimizeImage();
            } catch (e) {
              print('Error decoding stored image: $e');
            }
          }
        }
      });

      // After loading - check what we have
      _debugPrintIngredients('After load');

      print(
          'Loaded interaction data for $foodId: liked=$_isLiked, bookmarked=$_isBookmarked, counter=$_counter');
      print(
          'Using nutrition data: calories=$_calories, protein=$_protein, fat=$_fat, carbs=$_carbs, healthScore=$_healthScore');
      if (_ingredients.isNotEmpty) {
        print('Loaded ${_ingredients.length} ingredients');
      }
    } catch (e) {
      print('Error loading saved food data: $e');
    }
  }

  Future<void> _saveData() async {
    // Debug output before saving
    _debugPrintIngredients('Before save');

    try {
      final prefs = await SharedPreferences.getInstance();
      final String foodId = _foodName.replaceAll(' ', '_').toLowerCase();

      await prefs.setBool('food_liked_$foodId', _isLiked);
      await prefs.setBool('food_bookmarked_$foodId', _isBookmarked);
      await prefs.setInt('food_counter_$foodId', _counter);
      await prefs.setString(
          'food_privacy_$foodId', _privacyStatus); // Save the privacy setting

      // Save all nutrition values
      await prefs.setString('food_calories_$foodId', _calories);
      await prefs.setString('food_protein_$foodId', _protein);
      await prefs.setString('food_fat_$foodId', _fat);
      await prefs.setString('food_carbs_$foodId', _carbs);
      await prefs.setString('food_health_score_$foodId', _healthScore);

      // Save ingredients list
      if (_ingredients.isNotEmpty) {
        try {
          // Validate that _ingredients contains valid Map objects before saving
          List<Map<String, dynamic>> validIngredients = [];
          for (var ingredient in _ingredients) {
            if (ingredient is Map<String, dynamic>) {
              // Make sure all required fields exist
              if (!ingredient.containsKey('name') ||
                  !ingredient.containsKey('amount') ||
                  !ingredient.containsKey('calories')) {
                // Add missing fields with defaults
                ingredient['name'] = ingredient['name'] ?? 'Ingredient';
                ingredient['amount'] = ingredient['amount'] ?? '1 serving';
                ingredient['calories'] = ingredient['calories'] ?? 0;
              }
              validIngredients.add(ingredient);
            }
          }

          final ingredientsJson = jsonEncode(validIngredients);
          await prefs.setString('food_ingredients_$foodId', ingredientsJson);
          print('Saved ${validIngredients.length} validated ingredients');

          // IMPORTANT: Also update the ingredients in the food_cards list
          // This ensures that when returning to FoodCardOpen, we have correct ingredients
          final List<String>? storedCards = prefs.getStringList('food_cards');
          if (storedCards != null && storedCards.isNotEmpty) {
            List<String> updatedCards = [];
            bool foundCard = false;

            // Find the correct card and update it
            for (String cardJson in storedCards) {
              try {
                Map<String, dynamic> cardData = jsonDecode(cardJson);
                String cardName = cardData['name'] ?? '';

                // If this is our card, update the ingredients
                if (cardName.toLowerCase() == _foodName.toLowerCase()) {
                  foundCard = true;

                  // Update with our valid ingredients
                  cardData['ingredients'] = validIngredients;

                  // Also create ingredient lookup maps for future use
                  Map<String, dynamic> ingredientAmounts = {};
                  Map<String, dynamic> ingredientCalories = {};

                  for (var ingredient in validIngredients) {
                    String name = ingredient['name'];
                    ingredientAmounts[name] = ingredient['amount'];
                    ingredientCalories[name] = ingredient['calories'];
                  }

                  cardData['ingredient_amounts'] = ingredientAmounts;
                  cardData['ingredient_calories'] = ingredientCalories;

                  // Update with our high quality image - preserve original quality
                  if (_storedImageBase64 != null &&
                      _storedImageBase64!.isNotEmpty) {
                    cardData['image'] = _storedImageBase64;
                    print(
                        'Using high-quality stored image data for food_cards: ${_storedImageBase64!.length} characters');
                  }

                  // Add the updated card to our list
                  updatedCards.add(jsonEncode(cardData));
                } else {
                  // Not our card, keep it as is
                  updatedCards.add(cardJson);
                }
              } catch (e) {
                print('Error updating food card ingredient data: $e');
                // If there was an error, keep the original card
                updatedCards.add(cardJson);
              }
            }

            // Save the updated cards list back to SharedPreferences
            if (foundCard) {
              await prefs.setStringList('food_cards', updatedCards);
              print('Updated ingredients in food_cards list for: $_foodName');
            }
          }
        } catch (e) {
          print('Error encoding ingredients for saving: $e');
        }
      }

      // Save image if available - ensure high quality
      if (_imageBytes != null || _storedImageBase64 != null) {
        // Prefer to use the stored base64 string directly if available
        // This prevents re-encoding which can reduce quality
        String imageData;
        if (_storedImageBase64 != null && _storedImageBase64!.isNotEmpty) {
          imageData = _storedImageBase64!;
          print(
              'Using original stored image data: ${imageData.length} characters');
        } else {
          // Only re-encode if we must
          imageData = base64Encode(_imageBytes!);
          print('Re-encoded image data: ${imageData.length} characters');
        }

        // Store the image
        await prefs.setString('food_image_$foodId', imageData);

        // Also update the image in the food_cards list to ensure high quality there too
        final List<String>? storedCards = prefs.getStringList('food_cards');
        if (storedCards != null && storedCards.isNotEmpty) {
          List<String> updatedCards = [];
          bool foundCard = false;

          // Find the correct card and update its image
          for (String cardJson in storedCards) {
            try {
              Map<String, dynamic> cardData = jsonDecode(cardJson);
              String cardName = cardData['name'] ?? '';

              // If this is our card, update the image
              if (cardName.toLowerCase() == _foodName.toLowerCase()) {
                foundCard = true;

                // Update with our high quality image
                cardData['image'] = imageData;

                // Add the updated card to our list
                updatedCards.add(jsonEncode(cardData));
              } else {
                // Not our card, keep it as is
                updatedCards.add(cardJson);
              }
            } catch (e) {
              print('Error updating food card image data: $e');
              // If there was an error, keep the original card
              updatedCards.add(cardJson);
            }
          }

          // Save the updated cards list back to SharedPreferences
          if (foundCard) {
            await prefs.setStringList('food_cards', updatedCards);
            print(
                'Updated high-quality image in food_cards list for: $_foodName');
          }
        }
      }

      print(
          'Saved data for $foodId: liked=$_isLiked, bookmarked=$_isBookmarked, counter=$_counter, calories=$_calories, protein=$_protein, fat=$_fat, carbs=$_carbs, healthScore=$_healthScore, ingredients=${_ingredients.length}');
    } catch (e) {
      print('Error saving food data: $e');
    }
  }

  @override
  void dispose() {
    // Save data when leaving the screen
    _saveData();

    _bookmarkController.dispose();
    _likeController.dispose();
    super.dispose();
  }

  void _handleBack() {
    // Save data before navigating back
    _saveData().then((_) => Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => CodiaPage()),
        ));
  }

  // Method to increment counter with maximum limit
  void _incrementCounter() {
    setState(() {
      if (_counter < 10) {
        _counter++;
        _saveData(); // Save immediately on value change
      }
    });
  }

  // Method to decrement counter with minimum limit
  void _decrementCounter() {
    setState(() {
      if (_counter > 1) {
        _counter--;
        _saveData(); // Save immediately on value change
      }
    });
  }

  // Method to toggle bookmark state with animation
  void _toggleBookmark() {
    setState(() {
      _isBookmarked = !_isBookmarked;
      _bookmarkController.reset();
      _bookmarkController.forward();
      _saveData(); // Save immediately on value change
    });
  }

  // Method to toggle like state with animation
  void _toggleLike() {
    setState(() {
      _isLiked = !_isLiked;
      _likeController.reset();
      _likeController.forward();
      _saveData(); // Save immediately on value change
    });
  }

  // Method to show privacy options in a bottom sheet
  void _showPrivacyOptions() {
    // Use the current privacy status instead of defaulting to Public
    String _selectedPrivacy = _privacyStatus;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      barrierColor: Colors.black.withOpacity(0.5),
      isScrollControlled: true, // Allow more height for additional options
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          width: MediaQuery.of(context).size.width, // Use full width
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPrivacyOption(
                  'Public', 'assets/images/globe.png', _selectedPrivacy,
                  (value) {
                // Update both the modal state and the parent state
                setModalState(() => _selectedPrivacy = value);
                setState(() {
                  _privacyStatus = value;
                  _saveData(); // Save the change immediately
                });
                Navigator.pop(context);
              }),
              _buildPrivacyOption('Friends Only',
                  'assets/images/socialicon.png', _selectedPrivacy, (value) {
                // Update both the modal state and the parent state
                setModalState(() => _selectedPrivacy = value);
                setState(() {
                  _privacyStatus = value;
                  _saveData(); // Save the change immediately
                });
                Navigator.pop(context);
              }),
              _buildPrivacyOption(
                  'Private', 'assets/images/Lock.png', _selectedPrivacy,
                  (value) {
                // Update both the modal state and the parent state
                setModalState(() => _selectedPrivacy = value);
                setState(() {
                  _privacyStatus = value;
                  _saveData(); // Save the change immediately
                });
                Navigator.pop(context);
              }),
              // Add Delete option with trashcan icon
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  // Show confirmation dialog for delete
                  showDialog(
                    context: context,
                    barrierColor:
                        Colors.black.withOpacity(0.5), // Add dark overlay
                    builder: (BuildContext context) {
                      return Dialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 0,
                        backgroundColor: Colors.white,
                        insetPadding: EdgeInsets.symmetric(horizontal: 32),
                        child: Container(
                          width: 326,
                          height: 182,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Title
                                Text(
                                  "Delete Meal?",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'SF Pro Display',
                                  ),
                                ),
                                SizedBox(height: 20),

                                // Delete button
                                Container(
                                  width: 267,
                                  height: 40,
                                  margin: EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        offset: Offset(0, 2),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Centered text
                                      Text(
                                        "Delete",
                                        style: TextStyle(
                                          color: Color(0xFFE97372),
                                          fontSize: 16,
                                          fontFamily: 'SF Pro Display',
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      // Icon positioned to the left with exact spacing
                                      Positioned(
                                        left:
                                            70, // Position for 28px from text (calculated based on button width)
                                        child: Image.asset(
                                          'assets/images/trashcan.png',
                                          width: 20,
                                          height: 20,
                                          color: Color(0xFFE97372),
                                        ),
                                      ),
                                      // Full-width button for tap area
                                      Positioned.fill(
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            onTap: () {
                                              // Delete the meal
                                              final prefs = SharedPreferences
                                                  .getInstance();
                                              prefs.then((prefs) {
                                                final String foodId = _foodName
                                                    .replaceAll(' ', '_')
                                                    .toLowerCase();

                                                // First: Delete all food-specific data
                                                prefs.remove(
                                                    'food_liked_$foodId');
                                                prefs.remove(
                                                    'food_bookmarked_$foodId');
                                                prefs.remove(
                                                    'food_counter_$foodId');
                                                prefs.remove(
                                                    'food_calories_$foodId');
                                                prefs.remove(
                                                    'food_protein_$foodId');
                                                prefs
                                                    .remove('food_fat_$foodId');
                                                prefs.remove(
                                                    'food_carbs_$foodId');
                                                prefs.remove(
                                                    'food_health_score_$foodId');
                                                prefs.remove(
                                                    'food_image_$foodId');

                                                print(
                                                    'Deleted all data for food: $foodId');

                                                // Second: Remove this meal from the food_cards list in SharedPreferences
                                                final List<String>?
                                                    storedCards =
                                                    prefs.getStringList(
                                                        'food_cards');
                                                if (storedCards != null &&
                                                    storedCards.isNotEmpty) {
                                                  List<Map<String, dynamic>>
                                                      cards = [];
                                                  List<String>
                                                      updatedCardsList = [];

                                                  // Parse all cards and filter out the one being deleted
                                                  for (String cardJson
                                                      in storedCards) {
                                                    try {
                                                      Map<String, dynamic>
                                                          cardData =
                                                          jsonDecode(cardJson);
                                                      String cardName =
                                                          cardData['name'] ??
                                                              '';

                                                      // Only keep cards with a different name
                                                      if (cardName
                                                              .toLowerCase() !=
                                                          _foodName
                                                              .toLowerCase()) {
                                                        updatedCardsList
                                                            .add(cardJson);
                                                      } else {
                                                        print(
                                                            'Removing card: $cardName from food_cards list');
                                                      }
                                                    } catch (e) {
                                                      print(
                                                          "Error parsing food card JSON: $e");
                                                      // Keep cards that can't be parsed (just in case)
                                                      updatedCardsList
                                                          .add(cardJson);
                                                    }
                                                  }

                                                  // Save the updated list back to SharedPreferences
                                                  prefs.setStringList(
                                                      'food_cards',
                                                      updatedCardsList);
                                                  print(
                                                      'Updated food_cards list, removed deleted meal');
                                                }

                                                // Navigate back to main screen
                                                Navigator.of(context).pop();
                                                Navigator.pushReplacement(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (context) =>
                                                          CodiaPage()),
                                                );
                                              });
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Cancel button
                                Container(
                                  width: 267,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        offset: Offset(0, 2),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Centered text
                                      Text(
                                        "Cancel",
                                        style: TextStyle(
                                          color: Colors.black54,
                                          fontSize: 16,
                                          fontFamily: 'SF Pro Display',
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      // Icon positioned to match the delete icon's position
                                      Positioned(
                                        left:
                                            70, // Same position as delete icon
                                        child: Image.asset(
                                          'assets/images/closeicon.png',
                                          width: 18, // 10% smaller than 20
                                          height: 18, // 10% smaller than 20
                                          color: Colors.black54,
                                        ),
                                      ),
                                      // Full-width button for tap area
                                      Positioned.fill(
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            onTap: () =>
                                                Navigator.of(context).pop(),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Image.asset(
                            'assets/images/trashcan.png',
                            width: 20,
                            height: 20,
                            color: Color(0xFFE97372),
                          ),
                          SizedBox(width: 12),
                          Text(
                            "Delete",
                            style: TextStyle(
                              color: Color(0xFFE97372),
                              fontSize: 16,
                              fontFamily: 'SF Pro Display',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget to build privacy option rows
  Widget _buildPrivacyOption(String title, String iconPath,
      String selectedPrivacy, Function(String) onSelect) {
    bool isSelected = selectedPrivacy == title;
    return InkWell(
      onTap: () => onSelect(title),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Image.asset(
                  iconPath,
                  width: 20,
                  height: 20,
                  color: isSelected ? Colors.black : Colors.grey,
                ),
                SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.grey,
                    fontSize: 16,
                    fontFamily: 'SF Pro Display',
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
            if (isSelected) Icon(Icons.check, color: Colors.black),
          ],
        ),
      ),
    );
  }

  // Helper method to extract numeric value from health score
  double _extractHealthScoreValue(String score) {
    final match = RegExp(r'(\d+)\/10').firstMatch(score);
    if (match != null && match.group(1) != null) {
      return double.parse(match.group(1)!) / 10;
    }
    return 0.8; // Default to 8/10 if parsing fails
  }

  // Helper method to format decimal values for consistent display
  String _formatDecimalValue(String input) {
    try {
      // Try to extract number with possible decimal point
      final match = RegExp(r'(\d+\.?\d*)').firstMatch(input);
      if (match != null && match.group(1) != null) {
        // Use original value with decimal places
        double value = double.tryParse(match.group(1)!) ?? 0.0;

        // Keep full precision for all calorie values
        return value.toString();
      }
    } catch (e) {
      print('Error formatting decimal value: $e');
    }
    return input; // Return original if parsing fails
  }

  // Helper method to optimize image quality
  void _optimizeImage() {
    if (_imageBytes != null) {
      try {
        print('Optimizing image quality for display...');
        // Create an optimized image storage if needed
        if (_storedImageBase64 == null || _storedImageBase64!.isEmpty) {
          _storedImageBase64 = base64Encode(_imageBytes!);
          print(
              'Created high-quality image storage: ${_storedImageBase64!.length} characters');
        }
      } catch (e) {
        print('Error optimizing image: $e');
      }
    }
  }

  // Helper method to format ingredient calories for display
  String _formatIngredientCalories(dynamic calories) {
    if (calories == null) return "0 kcal";

    // If it's already a string, ensure it has "kcal" suffix
    if (calories is String) {
      return calories.contains("kcal") ? calories : "$calories kcal";
    }

    // If it's a number, convert to string with full precision
    return "$calories kcal";
  }

  // Calculate nutrition using OpenAI API based on food name and serving size
  Future<Map<String, dynamic>> _calculateNutritionWithAI(
      String foodName, String servingSize) async {
    // No retry logic - just a direct call like in SnapFood.dart
    try {
      // Add debug print at start of method
      print('STARTING OpenAI calculation for: $foodName ($servingSize)');

      // Use the Render.com URL for OpenAI proxy
      final url = Uri.parse('https://snap-food.onrender.com/api/analyze-food');

      print('SENDING API REQUEST to ${url.toString()}');

      // Prepare the request with food details in proper format for the API
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'query':
                  'Calculate nutrition for $foodName, portion size: $servingSize',
              'type': 'nutrition'
            }),
          )
          .timeout(const Duration(seconds: 30)); // Longer timeout for API call

      print('RECEIVED API RESPONSE: Status ${response.statusCode}');
      print('RESPONSE BODY: ${response.body}');

      // Check if request was successful
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('PARSED Nutrition API response: $data');

        // Extract nutrition data from the response format
        var nutritionData = data;
        if (data.containsKey('data')) {
          nutritionData = data['data'];
        }

        // Return nutritional information in expected format
        return {
          'calories': _extractNutritionValue(nutritionData, 'calories'),
          'protein': _extractNutritionValue(nutritionData, 'protein'),
          'carbs': _extractNutritionValue(nutritionData, 'carbs'),
          'fat': _extractNutritionValue(nutritionData, 'fat'),
        };
      } else {
        print(
            'ERROR API call failed: Status ${response.statusCode}, Body: ${response.body}');
        // No fallback - throw error to trigger catch block
        throw Exception(
            'API call failed with status code ${response.statusCode}');
      }
    } catch (e) {
      print('CRITICAL ERROR calculating nutrition: $e');
      // No fallback - just rethrow the error
      rethrow;
    }
  }

  // Helper method to extract nutrition values from API response
  double _extractNutritionValue(Map<String, dynamic> data, String key) {
    try {
      // Try different possible paths where the value might be found
      if (data.containsKey(key)) {
        return double.tryParse(data[key].toString()) ?? 0.0;
      } else if (data.containsKey('nutrition') && data['nutrition'] is Map) {
        var nutrition = data['nutrition'];
        if (nutrition.containsKey(key)) {
          return double.tryParse(nutrition[key].toString()) ?? 0.0;
        }
      }
      return 0.0;
    } catch (e) {
      print('Error extracting $key: $e');
      return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).viewPadding.top;

    return Scaffold(
      backgroundColor: Color(0xFFDADADA),
      // Use a stack for better layout control
      body: WillPopScope(
        onWillPop: () async {
          // Save data before allowing pop
          await _saveData();
          // Navigate to CodiaPage instead of regular pop
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => CodiaPage()),
          );
          // Return false to prevent default pop behavior
          return false;
        },
        child: Stack(
          children: [
            // Scrollable content with extra slow physics for mouse wheel
            ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                dragDevices: {
                  PointerDeviceKind.touch,
                  PointerDeviceKind.mouse,
                  PointerDeviceKind.trackpad,
                },
              ),
              child: SingleChildScrollView(
                physics: SlowScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Gray image header with back button on it
                    Container(
                      height: MediaQuery.of(context).size.width,
                      color: Color(0xFFDADADA),
                      child: Stack(
                        children: [
                          // Meal image - show user image or fallback
                          _imageBytes != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.zero,
                                  child: Image.memory(
                                    _imageBytes!,
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.cover,
                                    alignment: Alignment.center,
                                    filterQuality: FilterQuality.high,
                                    cacheWidth: MediaQuery.of(context)
                                            .size
                                            .width
                                            .toInt() *
                                        2, // 2x display size for quality
                                    isAntiAlias: true,
                                  ),
                                )
                              : Center(
                                  child: Image.asset(
                                    'assets/images/meal1.png',
                                    width: 48,
                                    height: 48,
                                  ),
                                ),
                          // Back button inside the scrollable area
                          Positioned(
                            top: statusBarHeight + 16,
                            left: 16,
                            child: Container(
                              width: 40,
                              height: 40,
                              alignment: Alignment.center,
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.7),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.arrow_back,
                                      color: Colors.black, size: 24),
                                  onPressed: _handleBack,
                                  padding: EdgeInsets.zero,
                                  constraints: BoxConstraints(),
                                ),
                              ),
                            ),
                          ),
                          // Share and more buttons
                          Positioned(
                            top: statusBarHeight + 16,
                            right: 16,
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  alignment: Alignment.center,
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.7),
                                      shape: BoxShape.circle,
                                    ),
                                    child: IconButton(
                                      icon: Image.asset(
                                        'assets/images/share.png',
                                        width:
                                            21.6, // 10% smaller (24 * 0.9 = 21.6)
                                        height: 21.6, // 10% smaller
                                        color: Colors.black,
                                      ),
                                      onPressed: () {},
                                      padding: EdgeInsets.zero,
                                      constraints: BoxConstraints(),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8), // Add spacing between icons
                                Container(
                                  width: 40,
                                  height: 40,
                                  alignment: Alignment.center,
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.7),
                                      shape: BoxShape.circle,
                                    ),
                                    child: IconButton(
                                      icon: Image.asset(
                                        'assets/images/more2.png',
                                        width:
                                            21.6, // 10% smaller (24 * 0.9 = 21.6)
                                        height: 21.6, // 10% smaller
                                        color: Colors.black,
                                      ),
                                      onPressed: _showPrivacyOptions,
                                      padding: EdgeInsets.zero,
                                      constraints: BoxConstraints(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // White rounded container with gradient
                    Transform.translate(
                      offset: Offset(0, -40), // Move up to create overlap
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(40),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: [0, 0.4, 1],
                            colors: [
                              Color(0xFFFFFFFF),
                              Color(0xFFFFFFFF),
                              Color(0xFFEBEBEB),
                            ],
                          ),
                        ),
                        child: Column(
                          children: [
                            // Add 20px gap at top of white container
                            SizedBox(height: 20),

                            // Time and interaction buttons
                            Padding(
                              padding: const EdgeInsets.fromLTRB(29, 0, 29, 0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  // Left side: Bookmark and time
                                  Row(
                                    children: [
                                      // Bookmark button with enhanced animation
                                      GestureDetector(
                                        onTap: _toggleBookmark,
                                        child: AnimatedBuilder(
                                          animation: _bookmarkController,
                                          builder: (context, child) {
                                            return Transform.scale(
                                              scale:
                                                  _bookmarkScaleAnimation.value,
                                              child: Image.asset(
                                                _isBookmarked
                                                    ? 'assets/images/bookmarkfilled.png'
                                                    : 'assets/images/bookmark.png',
                                                width: 24,
                                                height: 24,
                                                color: _isBookmarked
                                                    ? Color(0xFFFFC300)
                                                    : Colors.black,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      SizedBox(width: 16),
                                      // Time
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Color(0xFFF2F2F2),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '12:07',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Right side: Counter with minus and plus buttons
                                  Row(
                                    children: [
                                      // Minus button
                                      GestureDetector(
                                        onTap: _decrementCounter,
                                        child: Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.white,
                                          ),
                                          child: Center(
                                            child: Image.asset(
                                              'assets/images/minus.png',
                                              width: 24,
                                              height: 24,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                      ),

                                      // Counter with smaller width
                                      Container(
                                        width:
                                            24, // Reduced from 40 to bring icons closer
                                        child: Center(
                                          child: Text(
                                            '$_counter',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),

                                      // Plus button
                                      GestureDetector(
                                        onTap: _incrementCounter,
                                        child: Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.white,
                                          ),
                                          child: Center(
                                            child: Image.asset(
                                              'assets/images/plus.png',
                                              width: 24,
                                              height: 24,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Title and description with adjusted padding
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title and subtitle area with 14px top spacing
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: 29, right: 29, top: 14, bottom: 0),
                                  child: Container(
                                    width: double.infinity,
                                    height: 70, // Fixed height for consistency
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _foodName,
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'SF Pro Display',
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Rusty Pelican is so good',
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Add 20px gap between subtitle and divider
                                SizedBox(height: 20),

                                // Only show social interaction area if not Private
                                if (_privacyStatus != 'Private') ...[
                                  // Divider with correct color and margins
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 29),
                                    child: Container(
                                      height: 0.5,
                                      color: Color(0xFFBDBDBD),
                                    ),
                                  ),

                                  // Social sharing buttons
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 48, vertical: 16),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        // Like button area (left section)
                                        Row(
                                          children: [
                                            GestureDetector(
                                              onTap: _toggleLike,
                                              child: AnimatedBuilder(
                                                animation: _likeController,
                                                builder: (context, child) {
                                                  return Transform.scale(
                                                    scale: _likeScaleAnimation
                                                        .value,
                                                    child: Image.asset(
                                                      _isLiked
                                                          ? 'assets/images/likefilled.png'
                                                          : 'assets/images/like.png',
                                                      width: 24,
                                                      height: 24,
                                                      color: Colors.black,
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              '2',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),

                                        // Comment button (center section)
                                        Row(
                                          children: [
                                            Image.asset(
                                              'assets/images/comment.png',
                                              width: 24,
                                              height: 24,
                                              color: Colors.black,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              '2',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),

                                        // Share button (right section)
                                        Image.asset(
                                          'assets/images/share.png',
                                          width: 24,
                                          height: 24,
                                          color: Colors.black,
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Divider with correct color and margins
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 29),
                                    child: Container(
                                      height: 0.5,
                                      color: Color(0xFFBDBDBD),
                                    ),
                                  ),
                                ] else
                                  // Empty container with exact same height as the social interaction area
                                  Container(
                                    height:
                                        33, // 0.5px divider + 16px vertical padding*2 + 0.5px divider
                                    padding: EdgeInsets.zero,
                                    margin: EdgeInsets.zero,
                                  ),
                              ],
                            ),

                            // Rest of the content
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Exact 20px gap between divider and calories
                                SizedBox(height: 20),

                                // Calories and macros card
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 29),
                                  child: Container(
                                    padding: EdgeInsets.all(20),
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
                                        // Calories circle
                                        Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            // Circle image instead of custom painted progress
                                            Transform.translate(
                                              offset: Offset(0, -3.9),
                                              child: ColorFiltered(
                                                colorFilter: ColorFilter.mode(
                                                  Colors.black,
                                                  BlendMode.srcIn,
                                                ),
                                                child: Image.asset(
                                                  'assets/images/circle.png',
                                                  width: 130,
                                                  height: 130,
                                                  fit: BoxFit.contain,
                                                ),
                                              ),
                                            ),
                                            // Calories text
                                            Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  _calories,
                                                  style: TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black,
                                                    decoration:
                                                        TextDecoration.none,
                                                  ),
                                                ),
                                                Text(
                                                  'Calories',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight:
                                                        FontWeight.normal,
                                                    color: Colors.black,
                                                    decoration:
                                                        TextDecoration.none,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 5),

                                        // Macros
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceAround,
                                          children: [
                                            _buildMacro(
                                                'Protein',
                                                '${_protein}g',
                                                Color(0xFFD7C1FF)),
                                            _buildMacro('Fat', '${_fat}g',
                                                Color(0xFFFFD8B1)),
                                            _buildMacro('Carbs', '${_carbs}g',
                                                Color(0xFFB1EFD8)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Gap between calorie box and health score - changed to 15px
                                SizedBox(height: 15),

                                // Health Score
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 29),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        vertical: 12, horizontal: 20),
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
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.only(
                                              left: 60, right: 12),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    'Health Score',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.normal,
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                  Spacer(),
                                                  Text(
                                                    _healthScore,
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.normal,
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: 8),
                                              Container(
                                                width: double.infinity,
                                                height: 8,
                                                decoration: BoxDecoration(
                                                  color: Color(0xFFDADADA),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                  child: Container(
                                                    width: double.infinity,
                                                    child: FractionallySizedBox(
                                                      alignment:
                                                          Alignment.centerLeft,
                                                      widthFactor:
                                                          _healthScoreValue,
                                                      child: Container(
                                                        decoration:
                                                            BoxDecoration(
                                                          color:
                                                              Color(0xFF75D377),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Positioned(
                                          left: -4,
                                          top: -5,
                                          bottom: -5,
                                          child: Image.asset(
                                            'assets/images/heartpink.png',
                                            width: 45,
                                            height: 45,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Gap between health score and ingredients label - set to 20px
                                SizedBox(height: 20),

                                // Ingredients
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 29),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Ingredients',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'SF Pro Display',
                                        ),
                                      ),
                                      // Gap between Ingredients label and boxes - set to 20px
                                      SizedBox(height: 20),
                                      // Display ingredient grid
                                      _buildIngredientGrid(),
                                    ],
                                  ),
                                ),

                                // Set exact 20px spacing between Ingredients section and More label
                                SizedBox(height: 20),

                                // More options
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 29),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'More',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'SF Pro Display',
                                        ),
                                      ),
                                      // Set exact 20px spacing between More label and buttons
                                      SizedBox(height: 20),
                                      _buildMoreOption('In-Depth Nutrition',
                                          'nutrition.png'),
                                      _buildMoreOption(
                                          'Fix Manually', 'pencilicon.png'),
                                      _buildMoreOption(
                                          'Fix with AI', 'bulb.png'),
                                    ],
                                  ),
                                ),

                                // Extra space at the bottom to account for the Save button
                                SizedBox(height: 120),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // White box at bottom - EXACTLY as in signin.dart
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: MediaQuery.of(context).size.height * 0.148887,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.zero,
                ),
              ),
            ),

            // Save button - EXACTLY as in signin.dart
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
                    // Save data and navigate to CodiaPage
                    _saveData().then((_) => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => CodiaPage()),
                        ));
                  },
                  style: ButtonStyle(
                    overlayColor: MaterialStateProperty.all(Colors.transparent),
                  ),
                  child: const Text(
                    'Save',
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
      ),
    );
  }

  Widget _buildMacro(String name, String amount, Color color) {
    return Column(
      children: [
        Text(name, style: TextStyle(fontSize: 12)),
        SizedBox(height: 4),
        Container(
          width: 80,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            widthFactor: 1.0, // Changed from 0.5 to 1.0 to fill entirely
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        SizedBox(height: 4),
        Text(amount,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildIngredient(String name, String amount, String calories) {
    final boxWidth = (MediaQuery.of(context).size.width - 78) / 2;
    return Container(
      width: boxWidth,
      height: 110,
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
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'SF Pro Display',
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              Text(
                amount,
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'SF Pro Display',
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              Text(
                calories,
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'SF Pro Display',
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoreOption(String title, String iconAsset) {
    // Base icon size for pencilicon.png
    double baseIconSize = 25.0;
    // Calculate 10% larger size for the other two icons
    double largerIconSize = baseIconSize * 1.1; // 27.5px

    // Determine the size for the current icon
    double iconSize = (iconAsset == 'nutrition.png' || iconAsset == 'bulb.png')
        ? largerIconSize
        : baseIconSize;

    return Container(
      margin: EdgeInsets.only(bottom: 15), // Set gap between boxes to 15px
      padding: EdgeInsets.symmetric(vertical: 0, horizontal: 20),
      width: double.infinity,
      height: 45,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Add 40px padding before the icon alignment container (35 + 5)
          SizedBox(width: 40),
          // Container to ensure icons align vertically and have space
          SizedBox(
            width: 40, // Keep this width consistent for alignment
            child: Align(
              alignment:
                  Alignment.centerLeft, // Align icon to the left of this box
              child: SizedBox(
                width: iconSize, // Use the calculated size
                height: iconSize, // Use the calculated size
                child: Image.asset(
                  'assets/images/$iconAsset',
                  width: iconSize, // Apply calculated width
                  height: iconSize, // Apply calculated height
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Center(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16, // Matches Health Score text size
                  fontWeight: FontWeight.normal,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
                softWrap: false, // Prevent text from wrapping to the next line
                overflow: TextOverflow
                    .visible, // Allow text to overflow container bounds
              ),
            ),
          ),
          // Adjust balance spacing for the added left padding
          SizedBox(width: 88), // (40 padding + 40 icon area + 8 gap)
        ],
      ),
    );
  }

  // Build a responsive grid of ingredient boxes
  Widget _buildIngredientGrid() {
    if (_ingredients.isEmpty) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: _showAddIngredientDialog, // Make the entire box clickable
            child: _buildIngredient('Add', '', ''),
          ),
          SizedBox(), // Empty spacer
        ],
      );
    }

    // Organize ingredients in rows of 2 columns
    List<Widget> rows = [];

    // Process actual ingredients (all except possibly the last one to leave room for Add button)
    for (int i = 0; i < _ingredients.length; i += 2) {
      // Check if we have a pair or a single ingredient left
      if (i + 1 < _ingredients.length) {
        // We have a pair of ingredients
        rows.add(
          Padding(
            padding: EdgeInsets.only(bottom: 15), // Gap between rows
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildIngredient(
                  _ingredients[i]['name'],
                  _ingredients[i]['amount'],
                  _formatIngredientCalories(_ingredients[i]['calories']),
                ),
                _buildIngredient(
                  _ingredients[i + 1]['name'],
                  _ingredients[i + 1]['amount'],
                  _formatIngredientCalories(_ingredients[i + 1]['calories']),
                ),
              ],
            ),
          ),
        );
      } else {
        // We have a single ingredient left, pair it with the Add button
        rows.add(
          Padding(
            padding: EdgeInsets.only(bottom: 15), // Gap between rows
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildIngredient(
                  _ingredients[i]['name'],
                  _ingredients[i]['amount'],
                  _formatIngredientCalories(_ingredients[i]['calories']),
                ),
                // Add button with clickable box
                GestureDetector(
                  onTap: _showAddIngredientDialog,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Add box
                      _buildIngredient('Add', '', ''),
                      // Add icon overlay
                      Padding(
                        padding: const EdgeInsets.only(top: 20.0),
                        child: Image.asset(
                          'assets/images/add.png',
                          width: 29.0,
                          height: 29.0,
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
    }

    // If we have an even number of ingredients, add a row with just the Add button
    if (_ingredients.length % 2 == 0) {
      rows.add(
        Padding(
          padding: EdgeInsets.only(bottom: 15), // Gap between rows
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Add button with clickable box
              GestureDetector(
                onTap: _showAddIngredientDialog,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Add box
                    _buildIngredient('Add', '', ''),
                    // Add icon overlay
                    Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: Image.asset(
                        'assets/images/add.png',
                        width: 29.0,
                        height: 29.0,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: (MediaQuery.of(context).size.width - 78) / 2,
              ), // Empty spacer with same width as ingredient box
            ],
          ),
        ),
      );
    }

    return Column(children: rows);
  }

  // Method to show add ingredient dialog
  void _showAddIngredientDialog() {
    // Create controllers for text fields
    TextEditingController foodController = TextEditingController();
    TextEditingController sizeController = TextEditingController();
    TextEditingController caloriesController = TextEditingController();

    // Track input validation
    bool isFormValid = false;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Check form validity
            void updateFormValidity() {
              bool foodValid = foodController.text.trim().isNotEmpty;
              bool sizeValid = sizeController.text.trim().isNotEmpty;
              setDialogState(() {
                isFormValid = foodValid && sizeValid;
              });
            }

            // Function to handle form submission with nutrition calculation
            void handleSubmit() async {
              if (!isFormValid) return;

              // Get values from text fields
              String foodName = foodController.text.trim();
              String size = sizeController.text.trim();
              String caloriesText = caloriesController.text.trim();

              // Apply proper case to food name
              if (foodName.isNotEmpty) {
                // Check if text is all uppercase
                bool isAllCaps = foodName == foodName.toUpperCase() &&
                    foodName != foodName.toLowerCase();

                // Convert all caps to lowercase before formatting
                if (isAllCaps) foodName = foodName.toLowerCase();

                // Apply title case formatting with improved handling
                List<String> words = foodName.split(' ');
                for (int i = 0; i < words.length; i++) {
                  if (words[i].isNotEmpty) {
                    words[i] = words[i][0].toUpperCase() +
                        (words[i].length > 1 ? words[i].substring(1) : '');
                  }
                }
                foodName = words.join(' ');
              }

              // Format size by removing spaces before 'g' and 'kg'
              if (size.isNotEmpty) {
                // Handle '150 g' format
                size = size.replaceAll(' g', 'g');
                // Handle '1.5 kg' format
                size = size.replaceAll(' kg', 'kg');
              }

              // Initialize nutritional values
              double calories = 0;
              String protein = "0";
              String fat = "0";
              String carbs = "0";

              // Close the ingredient dialog first
              Navigator.pop(context);

              // Handle empty calories field - calculate with AI
              if (caloriesText.isEmpty) {
                // Track loading dialog for proper cleanup
                bool isLoadingDialogShowing = false;
                late BuildContext loadingDialogContext;

                try {
                  print(
                      'INGREDIENT ADD: Started calculation for $foodName ($size)');

                  // Show loading indicator (fixed to avoid overflow)
                  isLoadingDialogShowing = true;
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (BuildContext context) {
                      loadingDialogContext = context;
                      return Dialog(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Container(
                          width: 110, // Slightly wider to avoid text wrapping
                          height: 110, // Slightly taller
                          padding: EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 32,
                                height: 32,
                                child: CircularProgressIndicator(
                                  color: Colors.black,
                                  strokeWidth: 3,
                                ),
                              ),
                              SizedBox(height: 16),
                              Text(
                                "Calculating...", // Added ellipsis for clarity
                                style: TextStyle(
                                  fontFamily: 'SF Pro Display',
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );

                  // Force a minimum delay to ensure the loading animation is visible
                  await Future.delayed(Duration(seconds: 2));

                  print('INGREDIENT ADD: Calling OpenAI API');

                  // Call OpenAI API to calculate nutrition
                  final nutritionData =
                      await _calculateNutritionWithAI(foodName, size);

                  print('INGREDIENT ADD: Got response from API');

                  // Extract values
                  calories = nutritionData['calories'];
                  protein = nutritionData['protein'].toString();
                  fat = nutritionData['fat'].toString();
                  carbs = nutritionData['carbs'].toString();

                  print(
                      'INGREDIENT ADD: Processed values - calories=$calories, protein=$protein, fat=$fat, carbs=$carbs');

                  // Close the loading dialog
                  if (isLoadingDialogShowing) {
                    try {
                      Navigator.of(loadingDialogContext).pop();
                      isLoadingDialogShowing = false;
                    } catch (dialogError) {
                      print('Error closing loading dialog: $dialogError');
                    }
                  }

                  // Only proceed if we got valid data
                  if (calories <= 0 &&
                      protein == "0" &&
                      fat == "0" &&
                      carbs == "0") {
                    throw Exception('Invalid nutrition data returned from API');
                  }

                  // Update main nutritional values
                  setState(() {
                    _calories = calories.toString();
                    _protein = protein;
                    _fat = fat;
                    _carbs = carbs;
                  });
                  print('INGREDIENT ADD: Updated main nutrition values');

                  // Create new ingredient and add to list
                  setState(() {
                    Map<String, dynamic> newIngredient = {
                      'name': foodName,
                      'amount': size,
                      'calories': calories
                    };

                    _ingredients.add(newIngredient);

                    // Sort ingredients by calories (highest to lowest)
                    _ingredients.sort((a, b) {
                      final caloriesA = a.containsKey('calories')
                          ? double.tryParse(a['calories'].toString()) ?? 0
                          : 0;
                      final caloriesB = b.containsKey('calories')
                          ? double.tryParse(b['calories'].toString()) ?? 0
                          : 0;
                      return caloriesB.compareTo(caloriesA);
                    });
                  });

                  // Save data to persist ingredients
                  _saveData();
                  print('INGREDIENT ADD: Successfully added ingredient');
                } catch (e) {
                  print('CRITICAL ERROR calculating nutrition: $e');

                  // Close the loading dialog if it's still showing
                  if (isLoadingDialogShowing) {
                    try {
                      Navigator.of(loadingDialogContext).pop();
                      isLoadingDialogShowing = false;
                    } catch (dialogError) {
                      print('Error closing loading dialog: $dialogError');
                    }
                  }

                  // Add small delay to ensure loading dialog is closed
                  await Future.delayed(Duration(milliseconds: 300));

                  // Show error dialog in the same style as delete meal confirmation
                  print('INGREDIENT ADD: Displaying error dialog');
                  await showDialog(
                    context: context,
                    barrierDismissible: false, // Force user to respond
                    barrierColor: Colors.black.withOpacity(0.5),
                    builder: (BuildContext context) {
                      return Dialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 0,
                        backgroundColor: Colors.white,
                        insetPadding: EdgeInsets.symmetric(horizontal: 32),
                        child: Container(
                          width: 326,
                          height: 182,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Title
                                Text(
                                  "Scan Failed",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'SF Pro Display',
                                  ),
                                ),
                                SizedBox(height: 20),

                                // OK button
                                Container(
                                  width: 267,
                                  height: 40,
                                  margin: EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        offset: Offset(0, 2),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(20),
                                      onTap: () => Navigator.of(context).pop(),
                                      child: Center(
                                        child: Text(
                                          "OK",
                                          style: TextStyle(
                                            color: Colors.black87,
                                            fontSize: 16,
                                            fontFamily: 'SF Pro Display',
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                // Try Again button
                                Container(
                                  width: 267,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        offset: Offset(0, 2),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(20),
                                      onTap: () => Navigator.of(context).pop(),
                                      child: Center(
                                        child: Text(
                                          "Try Again Later",
                                          style: TextStyle(
                                            color: Colors.black54,
                                            fontSize: 16,
                                            fontFamily: 'SF Pro Display',
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                  print('INGREDIENT ADD: Error dialog closed');

                  return; // Exit the method - don't add ingredient on error
                } finally {
                  // Close the loading dialog if it's still showing (belt and suspenders approach)
                  if (isLoadingDialogShowing) {
                    try {
                      Navigator.of(loadingDialogContext).pop();
                    } catch (dialogError) {
                      print(
                          'Error in finally block closing dialog: $dialogError');
                    }
                  }
                }
              } else {
                // Parse user-entered calories
                try {
                  final match = RegExp(r'(\d+\.?\d*)').firstMatch(caloriesText);
                  if (match != null && match.group(1) != null) {
                    calories = double.tryParse(match.group(1)!) ?? 0;
                  }
                } catch (e) {
                  print('Error parsing calories: $e');
                }

                // Create new ingredient and add to list
                setState(() {
                  Map<String, dynamic> newIngredient = {
                    'name': foodName,
                    'amount': size,
                    'calories': calories
                  };

                  _ingredients.add(newIngredient);

                  // Sort ingredients by calories (highest to lowest)
                  _ingredients.sort((a, b) {
                    final caloriesA = a.containsKey('calories')
                        ? double.tryParse(a['calories'].toString()) ?? 0
                        : 0;
                    final caloriesB = b.containsKey('calories')
                        ? double.tryParse(b['calories'].toString()) ?? 0
                        : 0;
                    return caloriesB.compareTo(caloriesA);
                  });
                });

                // Save data to persist ingredients
                _saveData();
              }
            }

            return Theme(
              data: Theme.of(context).copyWith(
                textSelectionTheme: TextSelectionThemeData(
                  selectionColor: Colors.grey.withOpacity(0.3),
                  cursorColor: Colors.black,
                  selectionHandleColor: Colors.black,
                ),
              ),
              child: Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
                backgroundColor: Colors.white,
                insetPadding: EdgeInsets.symmetric(horizontal: 32),
                child: Container(
                  width: 326,
                  height: 530,
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Title
                            SizedBox(height: 14),
                            Text(
                              "Add Ingredient",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'SF Pro Display',
                              ),
                            ),

                            // Plus icon
                            SizedBox(height: 29),
                            Image.asset(
                              'assets/images/add.png',
                              width: 45.0,
                              height: 45.0,
                            ),

                            // Food field
                            SizedBox(height: 25),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Food",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'SF Pro Display',
                                    ),
                                  ),
                                  SizedBox(height: 7),
                                  Container(
                                    width: 280,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(25),
                                      border:
                                          Border.all(color: Colors.grey[300]!),
                                    ),
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 15),
                                    child: TextField(
                                      controller: foodController,
                                      cursorColor: Colors.black,
                                      cursorWidth: 1.2,
                                      onChanged: (value) {
                                        updateFormValidity();
                                      },
                                      style: TextStyle(
                                        fontSize: 13.6,
                                        fontFamily: '.SF Pro Display',
                                        color: Colors.black,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: "Pasta, Tomato, etc",
                                        hintStyle: TextStyle(
                                          color: Colors.grey[600]!
                                              .withOpacity(0.7),
                                          fontSize: 13.6,
                                          fontFamily: '.SF Pro Display',
                                        ),
                                        border: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        contentPadding:
                                            EdgeInsets.symmetric(vertical: 15),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Size field
                            SizedBox(height: 10),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Size",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'SF Pro Display',
                                    ),
                                  ),
                                  SizedBox(height: 7),
                                  Container(
                                    width: 280,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(25),
                                      border:
                                          Border.all(color: Colors.grey[300]!),
                                    ),
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 15),
                                    child: TextField(
                                      controller: sizeController,
                                      cursorColor: Colors.black,
                                      cursorWidth: 1.2,
                                      onChanged: (value) {
                                        updateFormValidity();
                                      },
                                      style: TextStyle(
                                        fontSize: 13.6,
                                        fontFamily: '.SF Pro Display',
                                        color: Colors.black,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: "150g, 3/4 cup, etc",
                                        hintStyle: TextStyle(
                                          color: Colors.grey[600]!
                                              .withOpacity(0.7),
                                          fontSize: 13.6,
                                          fontFamily: '.SF Pro Display',
                                        ),
                                        border: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        contentPadding:
                                            EdgeInsets.symmetric(vertical: 15),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Calories field
                            SizedBox(height: 10),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        "Calories",
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w500,
                                          fontFamily: 'SF Pro Display',
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        "(optional)",
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.black.withOpacity(0.5),
                                          fontFamily: 'SF Pro Display',
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 7),
                                  Container(
                                    width: 280,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(25),
                                      border:
                                          Border.all(color: Colors.grey[300]!),
                                    ),
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 15),
                                    child: TextField(
                                      controller: caloriesController,
                                      cursorColor: Colors.black,
                                      cursorWidth: 1.2,
                                      style: TextStyle(
                                        fontSize: 13.6,
                                        fontFamily: '.SF Pro Display',
                                        color: Colors.black,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: "450 kcal",
                                        hintStyle: TextStyle(
                                          color: Colors.grey[600]!
                                              .withOpacity(0.7),
                                          fontSize: 13.6,
                                          fontFamily: '.SF Pro Display',
                                        ),
                                        border: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        contentPadding:
                                            EdgeInsets.symmetric(vertical: 15),
                                      ),
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Add button
                            SizedBox(height: 30),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Container(
                                width: 280,
                                height: 48,
                                margin: EdgeInsets.only(bottom: 24),
                                decoration: BoxDecoration(
                                  color: isFormValid
                                      ? Colors.black
                                      : Colors.grey[400],
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                child: TextButton(
                                  onPressed: isFormValid ? handleSubmit : null,
                                  style: ButtonStyle(
                                    overlayColor: MaterialStateProperty.all(
                                        Colors.transparent),
                                  ),
                                  child: const Text(
                                    'Add',
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
                      ),

                      // Close button
                      Positioned(
                        top: 19,
                        right: 22,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Image.asset(
                            'assets/images/closeicon.png',
                            width: 22,
                            height: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
