import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_image_compress/flutter_image_compress.dart'
    as flutter_compress;
// Remove permission_handler temporarily
// import 'package:permission_handler/permission_handler.dart';

// Conditionally import dart:io only on non-web
import 'dart:io' if (dart.library.html) 'package:fitness_app/web_io_stub.dart';

// Import our web handling code
import 'web_impl.dart' if (dart.library.io) 'web_impl_stub.dart';

// Additional imports for mobile platforms
import 'web_image_compress_stub.dart' as img_compress;

// Conditionally import the image compress library
// We need to use a different approach to avoid conflicts
import 'image_compress.dart';

// Add import for our secure API service
import '../services/food_analyzer_api.dart';

// Import FoodCardOpen for navigation after analysis
import 'FoodCardOpen.dart';

class SnapFood extends StatefulWidget {
  const SnapFood({super.key});

  @override
  State<StatefulWidget> createState() => _SnapFoodState();
}

class _SnapFoodState extends State<SnapFood> {
  // Track the active button
  String _activeButton = 'Scan Food'; // Default active button
  bool _permissionsRequested = false;
  bool _isAnalyzing = false; // Track if analysis is in progress

  // Food analysis result
  Map<String, dynamic>? _analysisResult;
  String? _formattedAnalysisResult;

  // Image related variables
  File? _imageFile;
  String? _webImagePath;
  Uint8List? _webImageBytes; // Add storage for web image bytes
  final ImagePicker _picker = ImagePicker();
  XFile? imageFile;
  XFile? _mostRecentImage;
  bool _pendingAnalysis = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      // Simplified permission check - no permission_handler
      _checkPermissionsSimple();
    }
    print("SnapFood screen initialized");
  }

  // Simplified permission check method that doesn't use permission_handler
  Future<void> _checkPermissionsSimple() async {
    if (kIsWeb) return; // Skip permission checks on web

    // For simplicity, we'll just try to use the image picker which will trigger permission prompts
    try {
      await _picker.pickImage(source: ImageSource.camera).then((_) => null);
    } catch (e) {
      print("Camera permission might be needed: $e");
      if (mounted) {
        _showPermissionsDialog();
      }
    }
  }

  void _showPermissionsDialog() {
    _showCustomDialog("Permission Required",
        "Camera permission is needed to take pictures. Please grant permission in your device settings.");
  }

  Future<void> _requestCameraPermission() async {
    // This will trigger the actual iOS system permission dialog for camera
    try {
      // Just check availability, don't actually pick
      await _picker
          .pickImage(source: ImageSource.camera)
          .then((_) => _requestPhotoLibraryPermission());
    } catch (e) {
      print("Camera permission denied or error occurred: $e");
      _requestPhotoLibraryPermission();
    }
  }

  Future<void> _requestPhotoLibraryPermission() async {
    // This will trigger the actual iOS system permission dialog for photo library
    try {
      // Just check availability, don't actually pick
      await _picker.pickImage(source: ImageSource.gallery);
    } catch (e) {
      print("Photo library permission denied or error occurred: $e");
    }
  }

  // Local fallback for image analysis when Firebase isn't working
  Future<Map<String, dynamic>> _analyzeImageLocally(
      Uint8List imageBytes) async {
    // This is a local fallback that doesn't require any Firebase connection
    // It returns mock data similar to what the real function would return

    print("Using local fallback for image analysis");

    // Simulate a processing delay
    await Future.delayed(Duration(seconds: 1));

    // Return mock food analysis data
    return {
      "success": true,
      "meal": [
        {
          "dish": "Local Analysis Result",
          "calories": 450,
          "macronutrients": {"protein": 25, "carbohydrates": 45, "fat": 18},
          "ingredients": [
            "This is a local analysis",
            "Firebase functions deployment had issues",
            "This is a fallback implementation",
            "Image size: ${imageBytes.length} bytes"
          ]
        }
      ]
    };
  }

  // Modify the _analyzeImage method to keep isAnalyzing true until redirection
  Future<void> _analyzeImage(XFile? image) async {
    if (_isAnalyzing || image == null) return;

    setState(() {
      _isAnalyzing = true;
    });

    try {
      print("Processing image ${image.path}");
      Uint8List imageBytes;

      // Get bytes from the image
      if (kIsWeb && _webImageBytes != null) {
        // For web, use the bytes we already have
        imageBytes = _webImageBytes!;
        print("Using web image bytes: ${imageBytes.length} bytes");
      } else {
        // Read as bytes from the file
        imageBytes = await image.readAsBytes();
        print("Read image bytes (${imageBytes.length} bytes)");
      }

      // Process image if needed (e.g., compress large images)
      Uint8List processedBytes = imageBytes;
      // Get image size in MB for logging
      final double originalSizeMB = imageBytes.length / (1024 * 1024);
      print("Original image size: ${originalSizeMB.toStringAsFixed(2)} MB");

      try {
        // Use the exact 0.7MB target approach
        processedBytes = await compressImage(
          imageBytes,
          targetWidth: 1200, // Initial width (will be adjusted)
          quality: 90, // Initial quality (will be adjusted)
        );

        // Calculate compression stats
        final double compressedSizeMB = processedBytes.length / (1024 * 1024);
        final double compressionRatio = originalSizeMB / compressedSizeMB;

        print("Image processing complete:");
        print("  - Original: ${originalSizeMB.toStringAsFixed(2)} MB");
        print("  - Final: ${compressedSizeMB.toStringAsFixed(2)} MB");

        if (originalSizeMB <= 0.7) {
          print("  - Original image preserved (≤0.7MB)");
        } else {
          print("  - Compressed to target size of 0.7MB");
          print(
              "  - Compression ratio: ${compressionRatio.toStringAsFixed(2)}x");
        }
      } catch (e) {
        print("Error during image compression: $e");
        // Fall back to original bytes if compression fails
        processedBytes = imageBytes;
      }

      print("Calling secure API service");

      try {
        // Use our secure API service via Firebase
        final response = await FoodAnalyzerApi.analyzeFoodImage(processedBytes);

        print("API call successful!");
        print('Response: $response');

        if (mounted) {
          // DO NOT set _isAnalyzing to false here to keep animation running
          setState(() {
            _analysisResult = response;
          });

          // Display the formatted results in the terminal
          _displayAnalysisResults(_analysisResult!);

          // _isAnalyzing will be set to false after navigation to FoodCardOpen
        }
      } catch (e) {
        print("API analysis error: $e");

        // Even if API fails, navigate to FoodCardOpen with default values
        if (mounted) {
          // Create a default food card with the image
          final String defaultName = "Unknown Food";
          final String defaultCalories = "0";
          final String defaultProtein = "0";
          final String defaultFat = "0";
          final String defaultCarbs = "0";
          final String healthScore = "5/10";
          final List<Map<String, dynamic>> defaultIngredients = [
            {'name': 'Unknown ingredients', 'amount': '0g', 'calories': 0}
          ];

          // Convert image to base64 for FoodCardOpen
          String? imageBase64;
          try {
            imageBase64 = base64Encode(processedBytes);
          } catch (e) {
            print("Error encoding image: $e");
          }

          print(
              "API failed, but navigating to FoodCardOpen with default values");

          // Navigate to FoodCardOpen with default values
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FoodCardOpen(
                foodName: defaultName,
                healthScore: healthScore,
                calories: defaultCalories,
                protein: defaultProtein,
                fat: defaultFat,
                carbs: defaultCarbs,
                imageBase64: imageBase64,
                ingredients: defaultIngredients,
              ),
            ),
          ).then((_) {
            // Set _isAnalyzing to false only after returning from FoodCardOpen
            if (mounted) {
              setState(() {
                _isAnalyzing = false;
              });
            }
          });
        }
      }
    } catch (e) {
      print("Error analyzing image: $e");
      if (mounted) {
        // Try to use the image even if analysis completely fails
        try {
          Uint8List imageBytes;
          if (kIsWeb && _webImageBytes != null) {
            imageBytes = _webImageBytes!;
          } else if (_imageFile != null && !kIsWeb) {
            imageBytes = await _imageFile!.readAsBytes();
          } else if (image != null) {
            imageBytes = await image.readAsBytes();
          } else {
            throw Exception("No image available");
          }

          // Create a default food card with the image
          final String defaultName = "Unknown Food";
          final String defaultCalories = "0";
          final String defaultProtein = "0";
          final String defaultFat = "0";
          final String defaultCarbs = "0";
          final String healthScore = "5/10";
          final List<Map<String, dynamic>> defaultIngredients = [
            {'name': 'Unknown ingredients', 'amount': '0g', 'calories': 0}
          ];

          // Convert image to base64 for FoodCardOpen
          String? imageBase64 = base64Encode(imageBytes);

          print(
              "Analysis completely failed, but navigating to FoodCardOpen with default values");

          // Navigate to FoodCardOpen with default values
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FoodCardOpen(
                foodName: defaultName,
                healthScore: healthScore,
                calories: defaultCalories,
                protein: defaultProtein,
                fat: defaultFat,
                carbs: defaultCarbs,
                imageBase64: imageBase64,
                ingredients: defaultIngredients,
              ),
            ),
          ).then((_) {
            if (mounted) {
              setState(() {
                _isAnalyzing = false;
              });
            }
          });
        } catch (imageError) {
          // If we can't even get the image, show an error dialog
          print("Failed to process image: $imageError");
          setState(() {
            _isAnalyzing = false;
          });
          _showCustomDialog("Analysis Failed",
              "Failed to analyze the image. Please try again.");
        }
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      print("Opening image picker gallery...");
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        // Disable video selection by using pickImage not pickVideo
        // Note: ImagePicker.pickImage already only selects images
      );

      if (pickedFile != null) {
        print("Image file selected: ${pickedFile.path}");

        if (mounted) {
          if (kIsWeb) {
            // For web platform, read the bytes first
            print("Web platform: reading image bytes first");
            final bytes = await pickedFile.readAsBytes();
            print("Web image bytes read successfully: ${bytes.length} bytes");

            // Check file size - 15MB maximum
            if (bytes.length > 15 * 1024 * 1024) {
              _showCustomDialog("File Too Large",
                  "Image must be less than 15MB. Please select a smaller image.");
              return;
            }

            // Update state with both path and bytes
            setState(() {
              _webImagePath = pickedFile.path;
              _webImageBytes = bytes;
              _imageFile = null;
              _mostRecentImage = pickedFile;
            });

            // Only analyze after we have the bytes
            print("Web image loaded, starting analysis...");
            _analyzeImage(pickedFile);
          } else {
            // For mobile platforms
            final bytes = await pickedFile.readAsBytes();

            // Check file size - 15MB maximum
            if (bytes.length > 15 * 1024 * 1024) {
              _showCustomDialog("File Too Large",
                  "Image must be less than 15MB. Please select a smaller image.");
              return;
            }

            setState(() {
              _imageFile = File(pickedFile.path);
              _webImagePath = null;
              _webImageBytes = null;
              _mostRecentImage = pickedFile;
            });

            _analyzeImage(pickedFile);
          }

          print(
              "Image set to state: ${kIsWeb ? _webImagePath : _imageFile?.path}");
        } else {
          print("Widget not mounted, can't update state");
        }
      } else {
        print("No image selected from gallery");
      }
    } catch (e) {
      print("Error picking image: $e");

      if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
        // For desktop or web
        _showUnsupportedPlatformDialog();
      }
    }
  }

  Future<void> _takePicture() async {
    try {
      print("Opening camera...");

      // Check if camera is available using _cameraOnly method
      bool isCameraAvailable = await _cameraOnly();

      if (!isCameraAvailable) {
        print("Camera not available or permission denied");
        setState(() {
          _isAnalyzing = false;
        });
        return;
      }

      // Show loading state
      setState(() {
        _isAnalyzing = true;
      });

      // Try to access camera directly, with no gallery fallback
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        // Disable video by using pickImage not pickVideo
        // Additional parameters could be set here for image quality
      );

      if (pickedFile != null) {
        print("Photo taken: ${pickedFile.path}");

        if (mounted) {
          if (kIsWeb) {
            // For web platform, read the bytes first
            print("Web platform: reading image bytes first");
            final bytes = await pickedFile.readAsBytes();
            print(
                "Web camera image bytes read successfully: ${bytes.length} bytes");

            // Check file size - 15MB maximum
            if (bytes.length > 15 * 1024 * 1024) {
              _showCustomDialog("File Too Large",
                  "Image must be less than 15MB. Please take a smaller image or adjust your camera settings.");
              setState(() {
                _isAnalyzing = false;
              });
              return;
            }

            // Update state with both path and bytes
            setState(() {
              _webImagePath = pickedFile.path;
              _webImageBytes = bytes;
              _imageFile = null;
              _mostRecentImage = pickedFile;
            });

            // Analyze the image
            _analyzeImage(pickedFile);
          } else {
            // For mobile platforms
            final bytes = await pickedFile.readAsBytes();

            // Check file size - 15MB maximum
            if (bytes.length > 15 * 1024 * 1024) {
              _showCustomDialog("File Too Large",
                  "Image must be less than 15MB. Please take a smaller image or adjust your camera settings.");
              setState(() {
                _isAnalyzing = false;
              });
              return;
            }

            setState(() {
              _imageFile = File(pickedFile.path);
              _webImagePath = null;
              _webImageBytes = null;
              _mostRecentImage = pickedFile;
            });

            // Analyze the image
            _analyzeImage(pickedFile);
          }

          print(
              "Photo set to state: ${kIsWeb ? _webImagePath : _imageFile?.path}");
        } else {
          print("Widget not mounted, can't update state");
        }
      } else {
        print("No photo taken");
        setState(() {
          _isAnalyzing = false;
        });
      }
    } catch (e) {
      print("Error taking picture: $e");
      setState(() {
        _isAnalyzing = false;
      });

      if (mounted) {
        _showCameraErrorDialog();
      }
    }
  }

  Future<bool> _cameraOnly() async {
    try {
      await _checkPermissionsSimple();

      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        maxHeight: 1000,
        maxWidth: 1000,
        imageQuality: 85, // Improved compression to ensure smaller file sizes
      );

      if (photo != null) {
        setState(() {
          _mostRecentImage = photo;
        });

        // Analyze the image directly here
        _analyzeImage(photo);
        return true;
      }
      return false;
    } catch (e) {
      print("Error picking image: $e");
      // Show error dialog instead of snackbar
      if (mounted) {
        _showCustomDialog("Error", "Failed to access camera: ${e.toString()}");
      }
      return false;
    }
  }

  // Simplified version that doesn't use missing libraries
  Future<String?> _getBase64FromPath(String path) async {
    try {
      // For web platform
      if (kIsWeb) {
        if (_webImageBytes != null) {
          return base64Encode(_webImageBytes!);
        } else {
          // Try to load from path for web
          final response = await http.get(Uri.parse(path));
          if (response.statusCode == 200) {
            return base64Encode(response.bodyBytes);
          } else {
            throw Exception('Failed to load image from URL');
          }
        }
      }
      // For mobile platforms
      else {
        final file = File(path);
        final bytes = await file.readAsBytes();

        // Simple size check
        if (bytes.length > 700000) {
          // Use our image compression helper
          final Uint8List result = await _compressBytesConsistently(
            bytes,
            quality: 80,
            targetWidth: 800,
          );
          return base64Encode(result);
        }

        return base64Encode(bytes);
      }
    } catch (e) {
      print("Error converting image to base64: $e");
      return null;
    }
  }

  Future<Uint8List> _compressImage(Uint8List imageBytes) async {
    try {
      print('Starting image compression process...');
      final double imageSizeMB = imageBytes.length / (1024 * 1024);
      print('Original image size: ${imageSizeMB.toStringAsFixed(2)} MB');

      // Target size of 0.7MB
      final int targetSizeBytes = 716800; // 0.7MB in bytes

      // If already smaller than 0.7MB, keep original
      if (imageBytes.length <= targetSizeBytes) {
        print('Image already under 0.7MB, preserving original quality');
        return imageBytes;
      }

      // Compress to exactly 0.7MB
      final Uint8List compressedImage = await compressImage(
        imageBytes,
        targetWidth: 1200, // Initial width
        quality: 90, // Initial quality
      );

      // Log results
      final double compressedSizeMB = compressedImage.length / (1024 * 1024);
      final double compressionRatio = imageSizeMB / compressedSizeMB;

      print('Image compression complete:');
      print('  - Original: ${imageSizeMB.toStringAsFixed(2)} MB');
      print('  - Compressed: ${compressedSizeMB.toStringAsFixed(2)} MB');
      print('  - Target: 0.7MB');
      print('  - Compression ratio: ${compressionRatio.toStringAsFixed(2)}x');

      return compressedImage;
    } catch (e) {
      print('Error during image compression: $e');
      return imageBytes; // Return original if compression fails
    }
  }

  void _displayAnalysisResults(Map<String, dynamic> analysisData) {
    try {
      print("\n----- FOOD ANALYSIS RESULTS -----");

      // NEW FORMAT: First check for the meal_name format which is our desired format
      if (analysisData.containsKey('meal_name')) {
        String mealName = analysisData['meal_name'];
        List<dynamic> ingredients = analysisData['ingredients'] ?? [];
        double calories =
            _extractDecimalValue(analysisData['calories']?.toString() ?? "0");
        double protein =
            _extractDecimalValue(analysisData['protein']?.toString() ?? "0");
        double fat =
            _extractDecimalValue(analysisData['fat']?.toString() ?? "0");
        double carbs =
            _extractDecimalValue(analysisData['carbs']?.toString() ?? "0");
        double vitaminC =
            _extractDecimalValue(analysisData['vitamin_c']?.toString() ?? "0");
        String healthScore = analysisData['health_score']?.toString() ?? "5/10";

        // Display in the format the user wants - with the exact format requested, adding "Name:" only in terminal output
        print("\n----- FOOD ANALYSIS RESULTS -----");
        print("Name: $mealName"); // Add "Name:" prefix only for terminal output
        String ingredientsText = ingredients.isNotEmpty
            ? ingredients.join(", ")
            : "Mixed ingredients";
        print("Ingredients: $ingredientsText");
        print(
            "Calories: ${calories.toInt()}kcal"); // Format as integer for terminal
        print("Protein: ${protein.toInt()}g");
        print("Fat: ${fat.toInt()}g");
        print("Carbs: ${carbs.toInt()}g");
        print("Vitamin C: ${vitaminC.toInt()}mg");

        // Extract and display additional nutritional information
        print("\n----- ADDITIONAL NUTRITIONAL INFORMATION -----");

        // Vitamins
        Map<String, dynamic> vitamins = analysisData['vitamins'] ?? {};
        if (vitamins.isNotEmpty) {
          print("VITAMINS:");
          vitamins.forEach((key, value) {
            String vitaminName = key;
            // Format vitamin A, B, C, D, E, K specially
            if (vitaminName.length == 1 ||
                (vitaminName.length == 2 && vitaminName.startsWith("B"))) {
              vitaminName = "Vitamin $vitaminName";
            }
            print(
                "  $vitaminName: ${_extractDecimalValue(value.toString())}${_getUnitForVitamin(key)}");
          });
        }

        // Minerals
        Map<String, dynamic> minerals = analysisData['minerals'] ?? {};
        if (minerals.isNotEmpty) {
          print("\nMINERALS:");
          minerals.forEach((key, value) {
            print(
                "  $key: ${_extractDecimalValue(value.toString())}${_getUnitForMineral(key)}");
          });
        }

        // Amino acids
        Map<String, dynamic> aminoAcids = analysisData['amino_acids'] ?? {};
        if (aminoAcids.isNotEmpty) {
          print("\nAMINO ACIDS:");
          aminoAcids.forEach((key, value) {
            print("  $key: ${_extractDecimalValue(value.toString())}g");
          });
        }

        // Other nutritional values
        Map<String, dynamic> otherNutrition =
            analysisData['nutrition_other'] ?? {};
        if (otherNutrition.isNotEmpty) {
          print("\nOTHER NUTRITION VALUES:");
          otherNutrition.forEach((key, value) {
            String unit = _getUnitForNutrient(key);
            print("  $key: ${_extractDecimalValue(value.toString())}$unit");
          });
        }

        // Additional values that might be directly in the root
        final additionalValues = [
          {'key': 'fiber', 'label': 'Fiber', 'unit': 'g'},
          {'key': 'sugar', 'label': 'Sugar', 'unit': 'g'},
          {'key': 'sodium', 'label': 'Sodium', 'unit': 'mg'},
          {'key': 'cholesterol', 'label': 'Cholesterol', 'unit': 'mg'},
          {'key': 'saturated_fat', 'label': 'Saturated Fat', 'unit': 'g'},
          {'key': 'trans_fat', 'label': 'Trans Fat', 'unit': 'g'},
          {'key': 'potassium', 'label': 'Potassium', 'unit': 'mg'},
          {'key': 'calcium', 'label': 'Calcium', 'unit': 'mg'},
          {'key': 'iron', 'label': 'Iron', 'unit': 'mg'},
        ];

        bool foundAdditional = false;
        for (var item in additionalValues) {
          if (analysisData.containsKey(item['key'])) {
            if (!foundAdditional) {
              print("\nADDITIONAL VALUES:");
              foundAdditional = true;
            }
            print(
                "  ${item['label']}: ${_extractDecimalValue(analysisData[item['key']].toString())}${item['unit']}");
          }
        }

        print("Health Score: $healthScore");
        print(
            "TOTAL CALORIES: ${calories.toInt()}kcal"); // Format as integer for terminal
        print("---------------------------------\n");

        // Save the data
        List<Map<String, dynamic>> ingredientsList = [];

        // Check if the API response includes detailed ingredient macros
        List<dynamic> ingredientMacros =
            analysisData['ingredient_macros'] ?? [];

        // Process each ingredient with macros if available
        for (int i = 0; i < ingredients.length; i++) {
          String name = ingredients[i].toString();

          // Extract weight and calories if available
          final regex = RegExp(r'(.*?)\s*\((.*?)\)\s*(\d+)kcal');
          final match = regex.firstMatch(name);

          Map<String, dynamic> ingredientData = {};

          if (match != null) {
            String ingredientName = match.group(1)?.trim() ?? name;
            String weight = match.group(2) ?? "30g";
            int kcal = int.tryParse(match.group(3) ?? "75") ?? 75;

            ingredientData = {
              'name': ingredientName,
              'amount': weight,
              'calories': kcal,
            };
          } else {
            // Default values if no match
            ingredientData = {
              'name': name,
              'amount': "30g",
              'calories': 75,
            };
          }

          // Add macronutrient data if available
          if (i < ingredientMacros.length && ingredientMacros[i] is Map) {
            Map<String, dynamic> macros =
                Map<String, dynamic>.from(ingredientMacros[i]);

            // Add protein, fat, and carbs data if available
            if (macros.containsKey('protein')) {
              // Convert the value to a number if it's not already
              var proteinValue = macros['protein'];
              if (proteinValue is String) {
                ingredientData['protein'] =
                    double.tryParse(proteinValue) ?? 0.0;
              } else if (proteinValue is num) {
                ingredientData['protein'] = proteinValue.toDouble();
              } else {
                ingredientData['protein'] = 0.0;
              }
            } else {
              ingredientData['protein'] = 0.0;
            }

            if (macros.containsKey('fat')) {
              // Convert the value to a number if it's not already
              var fatValue = macros['fat'];
              if (fatValue is String) {
                ingredientData['fat'] = double.tryParse(fatValue) ?? 0.0;
              } else if (fatValue is num) {
                ingredientData['fat'] = fatValue.toDouble();
              } else {
                ingredientData['fat'] = 0.0;
              }
            } else {
              ingredientData['fat'] = 0.0;
            }

            if (macros.containsKey('carbs') ||
                macros.containsKey('carbohydrates')) {
              // Convert the value to a number if it's not already
              var carbsValue = macros['carbs'] ?? macros['carbohydrates'];
              if (carbsValue is String) {
                ingredientData['carbs'] = double.tryParse(carbsValue) ?? 0.0;
              } else if (carbsValue is num) {
                ingredientData['carbs'] = carbsValue.toDouble();
              } else {
                ingredientData['carbs'] = 0.0;
              }
            } else {
              ingredientData['carbs'] = 0.0;
            }
          } else {
            // If no specific macros data for this ingredient, estimate based on calories
            // These are very rough estimates
            double estimatedCalories = 0.0;
            if (ingredientData['calories'] is num) {
              estimatedCalories = ingredientData['calories'].toDouble();
            } else if (ingredientData['calories'] is String) {
              estimatedCalories =
                  double.tryParse(ingredientData['calories']) ?? 0.0;
            }

            double estimatedProtein = estimatedCalories > 0
                ? (estimatedCalories * 0.15) / 4 // ~15% protein, 4kcal/g
                : 3.0;
            double estimatedFat = estimatedCalories > 0
                ? (estimatedCalories * 0.3) / 9 // ~30% fat, 9kcal/g
                : 2.0;
            double estimatedCarbs = estimatedCalories > 0
                ? (estimatedCalories * 0.55) / 4 // ~55% carbs, 4kcal/g
                : 10.0;

            ingredientData['protein'] = estimatedProtein;
            ingredientData['fat'] = estimatedFat;
            ingredientData['carbs'] = estimatedCarbs;
          }

          ingredientsList.add(ingredientData);
        }

        // Print debug information about the ingredients
        print("Ingredient list with macros:");
        for (var ingredient in ingredientsList) {
          String name = ingredient['name'] ?? 'NO NAME';
          String amount = ingredient['amount'] ?? 'NO AMOUNT';
          var calories = ingredient['calories'] ?? 'NO CALORIES';
          var protein = ingredient['protein'] ?? '0';
          var fat = ingredient['fat'] ?? '0';
          var carbs = ingredient['carbs'] ?? '0';

          print('- $name - $amount - $calories kcal - ' +
              'P: $protein, F: $fat, C: $carbs');
        }

        // Save the food card
        _saveFoodCardData(
            mealName,
            ingredientsText,
            calories.toString(),
            protein.toString(),
            fat.toString(),
            carbs.toString(),
            ingredientsList,
            healthScore);

        // Set the analysis result for the UI
        setState(() {
          _analysisResult = analysisData;
          _formattedAnalysisResult = null;
        });

        return; // Exit early as we've handled the new format
      }

      // OLD FORMAT CHECK: Check for meal format (API response format)
      if (analysisData.containsKey('meal') &&
          analysisData['meal'] is List &&
          analysisData['meal'].isNotEmpty) {
        // Process all items in the meal array, not just the first one
        List<dynamic> mealItems = analysisData['meal'];
        int totalCalories = 0;
        List<Map<String, dynamic>> allIngredientsList = [];

        // Display each food item separately
        for (int i = 0; i < mealItems.length; i++) {
          var meal = mealItems[i];

          // Format the data for console output
          String foodName = "";
          String ingredients = "";
          String calories = "0";
          String protein = "0";
          String fat = "0";
          String carbs = "0";
          String vitaminC = "0";
          List<Map<String, dynamic>> ingredientsList = [];

          // Extract food name
          if (meal.containsKey('dish')) {
            foodName = meal['dish']?.toString() ?? "";
          }

          // Extract ingredients with estimated amounts
          if (meal.containsKey('ingredients') && meal['ingredients'] is List) {
            final List<dynamic> rawIngredients = meal['ingredients'];

            // Look for per-ingredient macros if available
            List<dynamic> ingredientMacros = meal['ingredient_macros'] ?? [];

            for (int j = 0; j < rawIngredients.length; j++) {
              var ing = rawIngredients[j];
              String name = ing.toString();
              String amount = ""; // Default empty amount
              int estCalories = 0;

              // Try to estimate amount and calories for common ingredients
              if (name.toLowerCase().contains("pasta") ||
                  name.toLowerCase().contains("rigatoni")) {
                amount = "90g";
                estCalories = 320;
              } else if (name.toLowerCase().contains("cheese") ||
                  name.toLowerCase().contains("parmesan")) {
                amount = "20g";
                estCalories = 80;
              } else if (name.toLowerCase().contains("cream") ||
                  name.toLowerCase().contains("sauce")) {
                amount = "60ml";
                estCalories = 150;
              } else if (name.toLowerCase().contains("oil") ||
                  name.toLowerCase().contains("olive")) {
                amount = "15ml";
                estCalories = 120;
              } else if (name.toLowerCase().contains("herb") ||
                  name.toLowerCase().contains("basil")) {
                amount = "5g";
                estCalories = 5;
              } else if (name.toLowerCase().contains("sausage") ||
                  name.toLowerCase().contains("salami")) {
                amount = "30g";
                estCalories = 100;
              } else if (name.toLowerCase().contains("bread") ||
                  name.toLowerCase().contains("toast")) {
                amount = "40g";
                estCalories = 120;
              } else if (name.toLowerCase().contains("salad") ||
                  name.toLowerCase().contains("vegetable")) {
                amount = "50g";
                estCalories = 25;
              }

              Map<String, dynamic> ingredientData = {
                'name': name,
                'amount': amount,
                'calories': estCalories
              };

              // Add macronutrient data if available
              if (j < ingredientMacros.length && ingredientMacros[j] is Map) {
                Map<String, dynamic> macros = ingredientMacros[j];

                if (macros.containsKey('protein')) {
                  ingredientData['protein'] = macros['protein'];
                }
                if (macros.containsKey('fat')) {
                  ingredientData['fat'] = macros['fat'];
                }
                if (macros.containsKey('carbs') ||
                    macros.containsKey('carbohydrates')) {
                  ingredientData['carbs'] =
                      macros['carbs'] ?? macros['carbohydrates'];
                }
              } else {
                // Add estimated macros based on calories
                double estimatedProtein =
                    (estCalories * 0.15) / 4; // ~15% protein, 4kcal/g
                double estimatedFat =
                    (estCalories * 0.3) / 9; // ~30% fat, 9kcal/g
                double estimatedCarbs =
                    (estCalories * 0.55) / 4; // ~55% carbs, 4kcal/g

                ingredientData['protein'] = estimatedProtein.toStringAsFixed(1);
                ingredientData['fat'] = estimatedFat.toStringAsFixed(1);
                ingredientData['carbs'] = estimatedCarbs.toStringAsFixed(1);
              }

              ingredientsList.add(ingredientData);
            }

            // Keep track of all ingredients for saving
            allIngredientsList.addAll(ingredientsList);

            // Join ingredients with estimated amounts
            ingredients = ingredientsList.map((ing) {
              if (ing['amount'].toString().isNotEmpty) {
                return "${ing['name']} (${ing['amount']}; ${ing['calories']}kcal)";
              } else {
                return ing['name'];
              }
            }).join(", ");
          }

          // Extract calories
          if (meal.containsKey('calories')) {
            calories = meal['calories']?.toString() ?? "0";
            totalCalories += _extractNumericValueAsInt(calories);
          }

          // Extract macronutrients
          if (meal.containsKey('macronutrients') &&
              meal['macronutrients'] is Map) {
            var macros = meal['macronutrients'];
            protein = macros['protein']?.toString() ?? "0";
            fat = macros['fat']?.toString() ?? "0";
            carbs = macros['carbohydrates']?.toString() ?? "0";
          }

          // Look for vitamin C in any available field
          if (meal.containsKey('vitamins') && meal['vitamins'] is Map) {
            vitaminC = meal['vitamins']['C']?.toString() ?? "0";
          }

          // Print each item individually
          print("Food item ${i + 1}: $foodName");
          print("Ingredients: $ingredients");
          print("Calories: ${_extractNumericValue(calories)}kcal");
          print("Protein: ${_extractNumericValue(protein)}g");
          print("Fat: ${_extractNumericValue(fat)}g");
          print("Carbs: ${_extractNumericValue(carbs)}g");
          print("Vitamin C: ${_extractNumericValue(vitaminC)}mg");
          print("---");
        }

        // Print total calories from all items
        print("TOTAL CALORIES: ${totalCalories}kcal");
        print("---------------------------------\n");

        // Save combined data to shared preferences
        if (mealItems.isNotEmpty) {
          // For saving, we'll use the first item's name but indicate it contains multiple items
          String combinedName =
              mealItems[0]['dish']?.toString() ?? "Analyzed Meal";
          if (mealItems.length > 1) {
            combinedName += " and ${mealItems.length - 1} other items";
          }

          // Get combined calories as string
          String combinedCalories = totalCalories.toString();

          // Sum up all macros from all items
          double totalProtein = 0;
          double totalFat = 0;
          double totalCarbs = 0;

          // Process each meal item
          for (var mealItem in mealItems) {
            if (mealItem.containsKey('macronutrients') &&
                mealItem['macronutrients'] is Map) {
              var macros = mealItem['macronutrients'];

              // Add protein
              if (macros.containsKey('protein')) {
                totalProtein +=
                    _extractDecimalValue(macros['protein'].toString());
              }

              // Add fat
              if (macros.containsKey('fat')) {
                totalFat += _extractDecimalValue(macros['fat'].toString());
              }

              // Add carbs
              if (macros.containsKey('carbohydrates')) {
                totalCarbs +=
                    _extractDecimalValue(macros['carbohydrates'].toString());
              }
            }
          }

          // Convert the summed macros to strings
          String combinedProtein = totalProtein.toString();
          String combinedFat = totalFat.toString();
          String combinedCarbs = totalCarbs.toString();

          // Get all ingredients combined
          String combinedIngredients =
              allIngredientsList.map((ing) => ing['name']).toSet().join(", ");

          // Print the combined macros for verification
          print("\nCOMBINED MACROS:");
          print("Total Protein: ${totalProtein.toStringAsFixed(1)}g");
          print("Total Fat: ${totalFat.toStringAsFixed(1)}g");
          print("Total Carbs: ${totalCarbs.toStringAsFixed(1)}g");

          // Extract and display any additional nutritional information
          print("\n----- ADDITIONAL NUTRITIONAL INFORMATION -----");

          // Combine all nutritional info from all meal items
          Map<String, dynamic> combinedVitamins = {};
          Map<String, dynamic> combinedMinerals = {};
          Map<String, dynamic> combinedAminoAcids = {};
          Map<String, dynamic> combinedOtherNutrition = {};

          for (var mealItem in mealItems) {
            // Process vitamins
            if (mealItem.containsKey('vitamins') &&
                mealItem['vitamins'] is Map) {
              Map<String, dynamic> vitamins =
                  Map<String, dynamic>.from(mealItem['vitamins'] as Map);
              vitamins.forEach((key, value) {
                double currentValue = _extractDecimalValue(value.toString());
                if (combinedVitamins.containsKey(key)) {
                  combinedVitamins[key] = combinedVitamins[key] + currentValue;
                } else {
                  combinedVitamins[key] = currentValue;
                }
              });
            }

            // Process minerals
            if (mealItem.containsKey('minerals') &&
                mealItem['minerals'] is Map) {
              Map<String, dynamic> minerals =
                  Map<String, dynamic>.from(mealItem['minerals'] as Map);
              minerals.forEach((key, value) {
                double currentValue = _extractDecimalValue(value.toString());
                if (combinedMinerals.containsKey(key)) {
                  combinedMinerals[key] = combinedMinerals[key] + currentValue;
                } else {
                  combinedMinerals[key] = currentValue;
                }
              });
            }

            // Process amino acids
            if (mealItem.containsKey('amino_acids') &&
                mealItem['amino_acids'] is Map) {
              Map<String, dynamic> aminoAcids =
                  Map<String, dynamic>.from(mealItem['amino_acids'] as Map);
              aminoAcids.forEach((key, value) {
                double currentValue = _extractDecimalValue(value.toString());
                if (combinedAminoAcids.containsKey(key)) {
                  combinedAminoAcids[key] =
                      combinedAminoAcids[key] + currentValue;
                } else {
                  combinedAminoAcids[key] = currentValue;
                }
              });
            }

            // Process other nutrition values
            if (mealItem.containsKey('nutrition_other') &&
                mealItem['nutrition_other'] is Map) {
              Map<String, dynamic> otherNutrition =
                  Map<String, dynamic>.from(mealItem['nutrition_other'] as Map);
              otherNutrition.forEach((key, value) {
                double currentValue = _extractDecimalValue(value.toString());
                if (combinedOtherNutrition.containsKey(key)) {
                  combinedOtherNutrition[key] =
                      combinedOtherNutrition[key] + currentValue;
                } else {
                  combinedOtherNutrition[key] = currentValue;
                }
              });
            }

            // Process additional values that might be directly in the meal item
            final additionalValues = [
              {'key': 'fiber', 'label': 'Fiber', 'unit': 'g'},
              {'key': 'sugar', 'label': 'Sugar', 'unit': 'g'},
              {'key': 'sodium', 'label': 'Sodium', 'unit': 'mg'},
              {'key': 'cholesterol', 'label': 'Cholesterol', 'unit': 'mg'},
              {'key': 'saturated_fat', 'label': 'Saturated Fat', 'unit': 'g'},
              {'key': 'trans_fat', 'label': 'Trans Fat', 'unit': 'g'},
              {'key': 'potassium', 'label': 'Potassium', 'unit': 'mg'},
              {'key': 'calcium', 'label': 'Calcium', 'unit': 'mg'},
              {'key': 'iron', 'label': 'Iron', 'unit': 'mg'},
            ];

            for (var item in additionalValues) {
              if (mealItem.containsKey(item['key'])) {
                double currentValue =
                    _extractDecimalValue(mealItem[item['key']].toString());
                String key = item['label'] as String;
                if (combinedOtherNutrition.containsKey(key)) {
                  combinedOtherNutrition[key] =
                      combinedOtherNutrition[key] + currentValue;
                } else {
                  combinedOtherNutrition[key] = currentValue;
                }
              }
            }
          }

          // Display combined vitamins
          if (combinedVitamins.isNotEmpty) {
            print("VITAMINS:");
            combinedVitamins.forEach((key, value) {
              String vitaminName = key;
              // Format vitamin A, B, C, D, E, K specially
              if (vitaminName.length == 1 ||
                  (vitaminName.length == 2 && vitaminName.startsWith("B"))) {
                vitaminName = "Vitamin $vitaminName";
              }
              print(
                  "  $vitaminName: ${value.toStringAsFixed(1)}${_getUnitForVitamin(key)}");
            });
          }

          // Display combined minerals
          if (combinedMinerals.isNotEmpty) {
            print("\nMINERALS:");
            combinedMinerals.forEach((key, value) {
              print(
                  "  $key: ${value.toStringAsFixed(1)}${_getUnitForMineral(key)}");
            });
          }

          // Display combined amino acids
          if (combinedAminoAcids.isNotEmpty) {
            print("\nAMINO ACIDS:");
            combinedAminoAcids.forEach((key, value) {
              print("  $key: ${value.toStringAsFixed(1)}g");
            });
          }

          // Display combined other nutrition values
          if (combinedOtherNutrition.isNotEmpty) {
            print("\nOTHER NUTRITION VALUES:");
            combinedOtherNutrition.forEach((key, value) {
              String unit = _getUnitForNutrient(key);
              print("  $key: ${value.toStringAsFixed(1)}$unit");
            });
          }

          print("---------------------------------\n");

          _saveFoodCardData(combinedName, combinedIngredients, combinedCalories,
              combinedProtein, combinedFat, combinedCarbs, allIngredientsList);
        }

        // Store result but we've already navigated
        setState(() {
          _analysisResult = analysisData;
          _formattedAnalysisResult = null;
        });

        return; // Exit early after handling the meal format
      }

      // Try alternative formats (same as before)
      // Format the data for console output
      String foodName = "";
      String ingredients = "";
      String calories = "0";
      String protein = "0";
      String fat = "0";
      String carbs = "0";
      String vitaminC = "0";
      List<Map<String, dynamic>> ingredientsList = [];

      // Food name
      if (analysisData.containsKey('dish')) {
        foodName = analysisData['dish']?.toString() ?? "";
      } else if (analysisData.containsKey('dishName')) {
        foodName = analysisData['dishName']?.toString() ?? "";
      } else if (analysisData.containsKey('description')) {
        foodName = analysisData['description']?.toString() ?? "";
      }

      // Ingredients
      if (analysisData.containsKey('ingredients') &&
          analysisData['ingredients'] is List) {
        final List<dynamic> rawIngredients = analysisData['ingredients'];
        for (var ing in rawIngredients) {
          String name = ing.toString();
          String amount = ""; // Default empty amount
          int estCalories = 0;

          // Try to estimate amount and calories for common ingredients
          if (name.toLowerCase().contains("pasta") ||
              name.toLowerCase().contains("rigatoni")) {
            amount = "90g";
            estCalories = 320;
          } else if (name.toLowerCase().contains("cheese") ||
              name.toLowerCase().contains("parmesan")) {
            amount = "20g";
            estCalories = 80;
          } else if (name.toLowerCase().contains("cream") ||
              name.toLowerCase().contains("sauce")) {
            amount = "60ml";
            estCalories = 150;
          } else if (name.toLowerCase().contains("oil") ||
              name.toLowerCase().contains("olive")) {
            amount = "15ml";
            estCalories = 120;
          } else if (name.toLowerCase().contains("herb") ||
              name.toLowerCase().contains("basil")) {
            amount = "5g";
            estCalories = 5;
          }

          ingredientsList
              .add({'name': name, 'amount': amount, 'calories': estCalories});
        }

        // Join ingredients with estimated amounts
        ingredients = ingredientsList.map((ing) {
          if (ing['amount'].toString().isNotEmpty) {
            return "${ing['name']} (${ing['amount']}; ${ing['calories']}kcal)";
          } else {
            return ing['name'];
          }
        }).join(", ");
      }

      // Calories
      if (analysisData.containsKey('calories')) {
        calories = analysisData['calories']?.toString() ?? "0";
      }

      // Macronutrients
      if (analysisData.containsKey('macros') && analysisData['macros'] is Map) {
        var macros = analysisData['macros'];
        protein = macros['protein']?.toString() ?? "0";
        fat = macros['fat']?.toString() ?? "0";
        carbs = macros['carbs']?.toString() ?? "0";
      } else if (analysisData.containsKey('macronutrients') &&
          analysisData['macronutrients'] is Map) {
        var macros = analysisData['macronutrients'];
        protein = macros['protein']?.toString() ?? "0";
        fat = macros['fat']?.toString() ?? "0";
        carbs = macros['carbohydrates']?.toString() ?? "0";
      }

      // Vitamin C
      if (analysisData.containsKey('vitamins') &&
          analysisData['vitamins'] is Map) {
        vitaminC = analysisData['vitamins']['C']?.toString() ?? "0";
      }

      // Print results to terminal in specified format with units
      print("Food name: $foodName");
      print("Ingredients: $ingredients");
      print("Calories: ${_extractNumericValue(calories)}kcal");
      print("Protein: ${_extractNumericValue(protein)}g");
      print("Fat: ${_extractNumericValue(fat)}g");
      print("Carbs: ${_extractNumericValue(carbs)}g");
      print("Vitamin C: ${_extractNumericValue(vitaminC)}mg");

      // Extract and display additional nutritional information for the alternative format
      print("\n----- ADDITIONAL NUTRITIONAL INFORMATION -----");

      // Vitamins
      if (analysisData.containsKey('vitamins') &&
          analysisData['vitamins'] is Map) {
        Map<String, dynamic> vitamins =
            Map<String, dynamic>.from(analysisData['vitamins']);
        if (vitamins.isNotEmpty) {
          print("VITAMINS:");
          vitamins.forEach((key, value) {
            String vitaminName = key;
            // Format vitamin A, B, C, D, E, K specially
            if (vitaminName.length == 1 ||
                (vitaminName.length == 2 && vitaminName.startsWith("B"))) {
              vitaminName = "Vitamin $vitaminName";
            }
            print(
                "  $vitaminName: ${_extractDecimalValue(value.toString())}${_getUnitForVitamin(key)}");
          });
        }
      }

      // Minerals
      if (analysisData.containsKey('minerals') &&
          analysisData['minerals'] is Map) {
        Map<String, dynamic> minerals =
            Map<String, dynamic>.from(analysisData['minerals']);
        if (minerals.isNotEmpty) {
          print("\nMINERALS:");
          minerals.forEach((key, value) {
            print(
                "  $key: ${_extractDecimalValue(value.toString())}${_getUnitForMineral(key)}");
          });
        }
      }

      // Amino acids
      if (analysisData.containsKey('amino_acids') &&
          analysisData['amino_acids'] is Map) {
        Map<String, dynamic> aminoAcids =
            Map<String, dynamic>.from(analysisData['amino_acids']);
        if (aminoAcids.isNotEmpty) {
          print("\nAMINO ACIDS:");
          aminoAcids.forEach((key, value) {
            print("  $key: ${_extractDecimalValue(value.toString())}g");
          });
        }
      }

      // Other nutritional values
      if (analysisData.containsKey('nutrition_other') &&
          analysisData['nutrition_other'] is Map) {
        Map<String, dynamic> otherNutrition =
            Map<String, dynamic>.from(analysisData['nutrition_other']);
        if (otherNutrition.isNotEmpty) {
          print("\nOTHER NUTRITION VALUES:");
          otherNutrition.forEach((key, value) {
            String unit = _getUnitForNutrient(key);
            print("  $key: ${_extractDecimalValue(value.toString())}$unit");
          });
        }
      }

      // Additional values that might be directly in the root
      final additionalValues = [
        {'key': 'fiber', 'label': 'Fiber', 'unit': 'g'},
        {'key': 'sugar', 'label': 'Sugar', 'unit': 'g'},
        {'key': 'sodium', 'label': 'Sodium', 'unit': 'mg'},
        {'key': 'cholesterol', 'label': 'Cholesterol', 'unit': 'mg'},
        {'key': 'saturated_fat', 'label': 'Saturated Fat', 'unit': 'g'},
        {'key': 'trans_fat', 'label': 'Trans Fat', 'unit': 'g'},
        {'key': 'potassium', 'label': 'Potassium', 'unit': 'mg'},
        {'key': 'calcium', 'label': 'Calcium', 'unit': 'mg'},
        {'key': 'iron', 'label': 'Iron', 'unit': 'mg'},
      ];

      bool foundAdditional = false;
      for (var item in additionalValues) {
        if (analysisData.containsKey(item['key'])) {
          if (!foundAdditional) {
            print("\nADDITIONAL VALUES:");
            foundAdditional = true;
          }
          print(
              "  ${item['label']}: ${_extractDecimalValue(analysisData[item['key']].toString())}${item['unit']}");
        }
      }

      print("---------------------------------\n");

      // Save the food card to SharedPreferences for the Recent Activity section
      _saveFoodCardData(foodName, ingredients, calories, protein, fat, carbs,
          ingredientsList);

      // We don't need to store or display the formatted text anymore
      setState(() {
        // Set the analysis result but don't display it visually
        _analysisResult = analysisData;
        _formattedAnalysisResult = null;
      });
    } catch (e) {
      print("Error formatting analysis results: $e");

      setState(() {
        _analysisResult = analysisData;
        _formattedAnalysisResult = null;
        _isAnalyzing = false; // Make sure to reset analyzing state on error
      });

      // Show error dialog
      _showCustomDialog("Analysis Error",
          "There was an error processing the analysis results: ${e.toString()}");
    }
  }

  // Helper method to extract numeric value from a string, preserving decimal places
  String _extractNumericValue(String input) {
    // Try to extract digits from the string, including decimal values
    final match = RegExp(r'(\d+\.?\d*)').firstMatch(input);
    if (match != null && match.group(1) != null) {
      // Return the exact extracted value with decimal precision
      return match.group(1)!;
    }
    return "0"; // Return string "0" as fallback (without decimal)
  }

  // Helper method to extract numeric value from a string and convert to int
  int _extractNumericValueAsInt(String input) {
    // Try to extract digits from the string, including possible decimal values
    final match = RegExp(r'(\d+\.?\d*)').firstMatch(input);
    if (match != null && match.group(1) != null) {
      // Parse as double first to handle potential decimal values
      final value = double.tryParse(match.group(1)!) ?? 0.0;
      // Then round to nearest int
      return value.round();
    }
    return 0;
  }

  // Helper method to extract numeric value with decimal places from a string
  double _extractDecimalValue(String input) {
    // Try to extract number with possible decimal point
    final match = RegExp(r'(\d+\.?\d*)').firstMatch(input);
    if (match != null && match.group(1) != null) {
      // Use original value without de-rounding
      return double.tryParse(match.group(1)!) ?? 0.0;
    }
    return 0.0;
  }

  // Gets exact raw calorie value as integer
  int _getRawCalorieValue(double calories) {
    // Just convert to integer, no rounding to multiples
    return calories.toInt();
  }

  // Save food card data to SharedPreferences
  Future<void> _saveFoodCardData(
      String foodName,
      String ingredients,
      String calories,
      String protein,
      String fat,
      String carbs,
      List<Map<String, dynamic>> ingredientsList,
      [String healthScore = "5/10"]) async {
    try {
      // Get the current image bytes
      Uint8List? imageBytes;
      if (_webImageBytes != null) {
        imageBytes = _webImageBytes;
        print("Using web image bytes: ${imageBytes!.length} bytes");
      } else if (_webImagePath != null && kIsWeb) {
        try {
          imageBytes = await getWebImageBytes(_webImagePath!);
          print("Got web image bytes from path: ${imageBytes!.length} bytes");
        } catch (e) {
          print("Error getting web image bytes: $e");
        }
      } else if (_imageFile != null && !kIsWeb) {
        try {
          // Read file bytes for non-web platforms
          imageBytes = await _imageFile!.readAsBytes();
          print("Read file bytes: ${imageBytes.length} bytes");
        } catch (e) {
          print("Error reading image file bytes: $e");
        }
      }

      // Convert image to base64 for storage
      String? base64Image;
      if (imageBytes != null) {
        try {
          // Compress image for storage
          Uint8List compressedImage = await compressImage(
            imageBytes,
            quality: 70,
            targetWidth: 300,
          );
          base64Image = base64Encode(compressedImage);
        } catch (e) {
          print("Error encoding image: $e");
        }
      }

      // Create food card data - store raw values with decimal precision
      final Map<String, dynamic> foodCard = {
        'name': foodName.isNotEmpty ? foodName : 'Analyzed Meal',
        'calories':
            calories, // Store original calories string with decimal places
        'protein': protein, // Use original protein value
        'fat': fat, // Use original fat value
        'carbs': carbs, // Use original carbs value
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'image': base64Image,
        'ingredients':
            ingredientsList, // Store full ingredient objects, not just names
        'health_score': healthScore, // Store health score in the food card
      };

      // Load existing food cards
      final prefs = await SharedPreferences.getInstance();
      final List<String> storedCards = prefs.getStringList('food_cards') ?? [];

      // Add new food card as JSON
      storedCards.insert(0, jsonEncode(foodCard));

      // Limit to last 10 cards to prevent excessive storage
      if (storedCards.length > 10) {
        storedCards.removeRange(10, storedCards.length);
      }

      // Save updated list
      await prefs.setStringList('food_cards', storedCards);
      print("Food card saved successfully");

      // After saving, navigate directly to FoodCardOpen with the detected food name
      if (mounted) {
        // Prepare high-quality image for FoodCardOpen
        String? highQualityImageBase64;
        if (_webImageBytes != null) {
          // Use original image bytes for best quality
          highQualityImageBase64 = base64Encode(_webImageBytes!);
        } else if (_imageFile != null && !kIsWeb) {
          try {
            // Read file bytes directly for best quality
            final originalBytes = _imageFile!.readAsBytesSync();
            highQualityImageBase64 = base64Encode(originalBytes);
          } catch (e) {
            print("Error reading original image file: $e");
          }
        }

        // Don't set _isAnalyzing to false, keep the loading animation until navigation
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FoodCardOpen(
              foodName: foodName,
              healthScore: healthScore,
              calories: calories.toString(),
              protein: protein.toString(),
              fat: fat.toString(),
              carbs: carbs.toString(),
              imageBase64: highQualityImageBase64 ?? base64Image,
              ingredients: ingredientsList, // Pass ingredients list
            ),
          ),
        ).then((_) {
          // Set _isAnalyzing to false only after returning from FoodCardOpen
          if (mounted) {
            setState(() {
              _isAnalyzing = false;
            });
          }
        });
      }
    } catch (e) {
      print("Error saving food card: $e");
      // Make sure to set _isAnalyzing to false on error
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }

  // Test the echo function to verify callable functions work
  Future<void> _testEchoFunction() async {
    // Function logic removed
  }

  // Test the simple image analyzer function
  Future<void> _testSimpleImageAnalyzer() async {
    // Function logic removed
  }

  @override
  Widget build(BuildContext context) {
    print("Building SnapFood widget, has image: $_hasImage");
    if (_imageFile != null) {
      print("Image file path: ${_imageFile!.path}");
      // Only check file existence on non-web platforms
      if (!kIsWeb) {
        print("Image file exists: ${_imageFile!.existsSync()}");
      }
    }
    if (_webImagePath != null) {
      print("Web image path: $_webImagePath");
    }

    // Call analyzeImage with the most recent image if there is a pending request
    if (_pendingAnalysis && _mostRecentImage != null) {
      _pendingAnalysis = false;
      _analyzeImage(_mostRecentImage);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Background - either selected image or black background
            if (_hasImage)
              Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: _getImageProvider(),
                    fit: BoxFit.contain, // Show original size, not zoomed in
                  ),
                  color: Colors.black, // Black background for letterboxing
                ),
              )
            else
              Container(
                color: Colors.black,
                width: double.infinity,
                height: double.infinity,
              ),

            // Top corner frames as a group
            Positioned(
              top: 102, // Distance from gray circle (21+36+45=102)
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 29),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildCornerFrame(topLeft: true),
                    _buildCornerFrame(topRight: true),
                  ],
                ),
              ),
            ),

            // Bottom corner frames as a group
            Positioned(
              bottom: 223, // Adjusted for 45px gap (109+69+45=223)
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 29),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildCornerFrame(bottomLeft: true),
                    _buildCornerFrame(bottomRight: true),
                  ],
                ),
              ),
            ),

            // Gray circle behind back button
            Positioned(
              top: 21,
              left: 29,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            // Back button
            Positioned(
              top: 21,
              left: 29,
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
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
              ),
            ),

            // Loading indicator while analyzing
            if (_isAnalyzing)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.7),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                        SizedBox(height: 20),
                        Text(
                          "Analyzing meal...",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Bottom action buttons (Scan Food, Scan Code, Add Photo)
            Positioned(
              bottom:
                  109, // Adjusted to create 24px gap with shutter button (15 + 70 + 24 = 109)
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 29),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Scan Food button
                    GestureDetector(
                      onTap: () {
                        _setActiveButton('Scan Food');
                      },
                      child: Container(
                        width: 99,
                        height: 69, // Increased to 69px as requested
                        decoration: BoxDecoration(
                          color: _activeButton == 'Scan Food'
                              ? Colors.white
                              : Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Image.asset(
                                'assets/images/foodscan.png',
                                width: 31,
                                height: 31,
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Scan Food',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Scan Code button
                    GestureDetector(
                      onTap: () {
                        _setActiveButton('Scan Code');
                      },
                      child: Container(
                        width: 99,
                        height: 69, // Increased to 69px as requested
                        decoration: BoxDecoration(
                          color: _activeButton == 'Scan Code'
                              ? Colors.white
                              : Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Image.asset(
                                'assets/images/qrcodescan.png',
                                width: 31,
                                height: 31,
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Scan Code',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Add Photo button
                    GestureDetector(
                      onTap: () {
                        _setActiveButton('Add Photo');
                      },
                      child: Container(
                        width: 99,
                        height: 69, // Increased to 69px as requested
                        decoration: BoxDecoration(
                          color: _activeButton == 'Add Photo'
                              ? Colors.white
                              : Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                  top: 8.0,
                                  left:
                                      2.0), // Added 2px padding to the left to shift image right
                              child: Image.asset(
                                'assets/images/addphoto.png',
                                width: 31,
                                height: 31,
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Add Photo',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Shutter button - camera only, no gallery fallback
            Positioned(
              bottom: 15,
              left: 29, // Adjusted to match 29px padding
              right: 29, // Adjusted to match 29px padding
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Flash button
                  Padding(
                    padding: const EdgeInsets.only(right: 40),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Image.asset(
                        'assets/images/flashwhite.png',
                        width: 37,
                        height: 37,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  // Shutter button - camera only, no gallery fallback
                  GestureDetector(
                    onTap:
                        _cameraOnly, // New dedicated camera function with no gallery fallback
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Empty space to balance the layout
                  const SizedBox(width: 80),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Get image provider based on available sources
  ImageProvider _getImageProvider() {
    // For web or if web path is available
    if (_webImagePath != null) {
      return NetworkImage(_webImagePath!);
    }
    // For web with bytes
    else if (_webImageBytes != null) {
      return MemoryImage(_webImageBytes!);
    }
    // Default placeholder for all other cases
    else {
      return const AssetImage('assets/images/placeholder.png');
    }
  }

  // Helper method to build corner frames
  Widget _buildCornerFrame({
    bool topLeft = false,
    bool topRight = false,
    bool bottomLeft = false,
    bool bottomRight = false,
  }) {
    return SizedBox(
      width: 50,
      height: 50,
      child: CustomPaint(
        painter: CornerPainter(
          topLeft: topLeft,
          topRight: topRight,
          bottomLeft: bottomLeft,
          bottomRight: bottomRight,
        ),
      ),
    );
  }

  // Helper widget to build macros row
  Widget _buildMacrosRow(Map<String, dynamic> macros) {
    // Handle different formats of macros data
    int? protein, carbs, fat;

    // Case 1: Format as in {"protein": 10, "carbs": 20, "fat": 15}
    if (macros.containsKey('protein')) {
      protein = macros['protein'] as int?;
    }
    if (macros.containsKey('carbs')) {
      carbs = macros['carbs'] as int?;
    } else if (macros.containsKey('carbohydrates')) {
      carbs = macros['carbohydrates'] as int?;
    }
    if (macros.containsKey('fat')) {
      fat = macros['fat'] as int?;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        if (protein != null)
          _buildMacroItem('Protein', protein, Colors.blue.shade300),
        if (carbs != null)
          _buildMacroItem('Carbs', carbs, Colors.green.shade300),
        if (fat != null) _buildMacroItem('Fat', fat, Colors.red.shade300),
      ],
    );
  }

  // Helper widget to build a single macro nutrient item
  Widget _buildMacroItem(String name, num value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            name,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          Text(
            "$value g",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build ingredients list
  List<Widget> _buildIngredientsList(List<dynamic> ingredients) {
    return ingredients.map<Widget>((ingredient) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "• ",
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            Expanded(
              child: Text(
                ingredient,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  // Helper method to build meal analysis widgets
  List<Widget> _buildMealAnalysis(Map<String, dynamic> meal) {
    final widgets = <Widget>[];

    // Show dish name
    if (meal.containsKey('dish')) {
      widgets.add(
        Text(
          "${meal['dish']}",
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
      widgets.add(SizedBox(height: 8));
    }

    // Show calories
    if (meal.containsKey('calories')) {
      widgets.add(
        Text(
          "Calories: ${meal['calories']} kcal",
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
      );
      widgets.add(SizedBox(height: 5));
    }

    // Show macros
    if (meal.containsKey('macronutrients')) {
      widgets.add(_buildMacrosRow(meal['macronutrients']));
      widgets.add(SizedBox(height: 10));
    }

    // Show ingredients
    if (meal.containsKey('ingredients') && meal['ingredients'] is List) {
      widgets.add(
        Text(
          "Ingredients:",
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
      widgets.add(SizedBox(height: 5));
      widgets.addAll(_buildIngredientsList(meal['ingredients']));
    }

    return widgets;
  }

  // Function to get web image bytes by handling different URL formats
  Future<Uint8List> getWebImageBytes(String path) async {
    try {
      if (path.startsWith('data:')) {
        // Handle data URLs
        final int startIndex = path.indexOf(',') + 1;
        final String base64Data = path.substring(startIndex);
        return base64Decode(base64Data);
      } else if (path.startsWith('blob:') || path.startsWith('http')) {
        // Use HTTP GET for blob and http URLs
        final response = await http.get(Uri.parse(path));
        if (response.statusCode == 200) {
          return response.bodyBytes;
        } else {
          throw Exception('Failed to load image: ${response.statusCode}');
        }
      } else {
        // For other paths
        throw Exception('Unsupported image path format');
      }
    } catch (e) {
      print('Error in getWebImageBytes: $e');
      rethrow; // Rethrow to be handled by caller
    }
  }

  @override
  void dispose() {
    // Clean up resources
    super.dispose();
  }

  // Helper method to get optimized image bytes for local analysis
  Future<Uint8List> _optimizeImageBytes(Uint8List imageBytes) async {
    if (imageBytes.length < 300 * 1024) {
      // Small enough, no need to optimize
      return imageBytes;
    }

    try {
      // Use our unified image compression function
      return await compressImage(imageBytes, quality: 85, targetWidth: 800);
    } catch (e) {
      print("Error optimizing image bytes: $e");
      return imageBytes;
    }
  }

  // Compress image and convert to base64
  Future<String> _compressAndConvertToBase64(Uint8List imageBytes) async {
    try {
      // Compress the image first
      Uint8List compressedBytes = await compressImage(
        imageBytes,
        quality: 85,
        targetWidth: 1024,
      );

      // Convert to base64
      return base64Encode(compressedBytes);
    } catch (e) {
      print("Error in compress and convert: $e");
      return base64Encode(imageBytes); // Fallback to original
    }
  }

  // Helper method for optimizing single image bytes
  Future<Uint8List> _optimizeSingleImage(
    Uint8List bytes, {
    int targetWidth = 800,
    int quality = 85,
  }) async {
    try {
      if (bytes.length < 100 * 1024) return bytes; // Skip small files

      return await compressImage(
        bytes,
        targetWidth: targetWidth,
        quality: quality,
      );
    } catch (e) {
      print("Error optimizing single image: $e");
      return bytes;
    }
  }

  // Handle Uint8List compression consistently
  Future<Uint8List> _compressBytesConsistently(
    Uint8List bytes, {
    int quality = 85,
    int targetWidth = 800,
  }) async {
    try {
      return await compressImage(
        bytes,
        quality: quality,
        targetWidth: targetWidth,
      );
    } catch (e) {
      print("Compression error: $e");
      return bytes;
    }
  }

  // Web-specific function to compress images using canvas
  Future<Uint8List> _compressWebImageWithCanvas(
      Uint8List imageData, int maxDimension) async {
    try {
      return await compressImage(imageData, targetWidth: maxDimension);
    } catch (e) {
      print("Error compressing web image: $e");
      return imageData; // Return original if compression fails
    }
  }

  // Helper method to prepare an image for analysis when only file/bytes are available
  void _prepareImageForAnalysis() async {
    // Create an XFile from the available image source
    XFile? fileToAnalyze;

    try {
      if (_imageFile != null) {
        // Mobile platform with File
        fileToAnalyze = XFile(_imageFile!.path);
      } else if (_webImageBytes != null && kIsWeb) {
        // For web, we need to handle this differently
        // Create a data URL and set it as webImagePath
        final base64Image = base64Encode(_webImageBytes!);
        final dataUrl = 'data:image/jpeg;base64,$base64Image';
        fileToAnalyze = XFile(dataUrl);
      } else if (_webImagePath != null) {
        // Web platform with path
        fileToAnalyze = XFile(_webImagePath!);
      }

      if (fileToAnalyze != null) {
        setState(() {
          _isAnalyzing = true;
          _mostRecentImage = fileToAnalyze;
        });
        await _analyzeImage(fileToAnalyze);
      } else {
        print("No valid image source found for analysis");
        _showCustomDialog('Error', 'No image available to analyze');
      }
    } catch (e) {
      print("Error preparing image for analysis: $e");
      _showCustomDialog('Error', 'Error preparing image: ${e.toString()}');
    }
  }

  // Helper method to reduce image size on web platforms
  Future<Uint8List> _reduceImageSizeForWeb(
      Uint8List originalBytes, int targetWidth) async {
    if (!kIsWeb) {
      return originalBytes; // Only for web
    }

    // This function will be implemented by using the html package
    // and is only used on web platforms
    try {
      // Use our unified compressImage function
      return await compressImage(originalBytes, targetWidth: targetWidth);
    } catch (e) {
      print("Web resize error: $e");
      return originalBytes;
    }
  }

  // Custom styled dialog to show messages - replaces all SnackBars
  void _showCustomDialog(String title, String message) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 24.0, horizontal: 20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16.0),
                Text(
                  message,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16.0,
                    fontWeight: FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20.0),
                TextButton(
                  child: Text(
                    "OK",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Show any error alerts with proper styling
  void _showErrorAlert(String message) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 24.0, horizontal: 20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Analysis Error",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16.0),
                Text(
                  message,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16.0,
                    fontWeight: FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20.0),
                TextButton(
                  child: Text(
                    "OK",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showUnsupportedPlatformDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 24.0, horizontal: 20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Camera Unavailable",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16.0),
                Text(
                  "Camera access is not available on this platform. Please use the 'Add Photo' button to select an image from your gallery.",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16.0,
                    fontWeight: FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20.0),
                TextButton(
                  child: Text(
                    "OK",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCameraErrorDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 24.0, horizontal: 20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Camera Error",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16.0),
                Text(
                  "There was an error accessing the camera. Please check your camera permissions and try again.",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16.0,
                    fontWeight: FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20.0),
                TextButton(
                  child: Text(
                    "OK",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper method to check if we have an image
  bool get _hasImage =>
      _imageFile != null || _webImagePath != null || _webImageBytes != null;

  void _scanFood() {
    print("Scanning food...");
    // If we have an image, analyze it
    if (_hasImage && !_isAnalyzing && _mostRecentImage != null) {
      _analyzeImage(_mostRecentImage);
    } else if (_hasImage && !_isAnalyzing) {
      // Show dialog to take a new picture instead of using the broken _prepareImageForAnalysis
      _showCustomDialog(
          "Analysis needed", "Please take a new picture to analyze food.");
    }
  }

  void _scanCode() {
    print("Scanning QR/Barcode...");
    // Placeholder for code scanning functionality
  }

  void _setActiveButton(String buttonName) {
    setState(() {
      _activeButton = buttonName;
    });
    print("Active button changed to: $_activeButton");

    // Perform action based on the selected button
    switch (buttonName) {
      case 'Scan Food':
        _scanFood();
        break;
      case 'Scan Code':
        _scanCode();
        break;
      case 'Add Photo':
        _pickImage();
        break;
    }
  }

  // Format the analysis results for display
  String _formatAnalysisResult(Map<String, dynamic> analysis) {
    // This is no longer used for displaying UI, but we keep it for compatibility
    return "";
  }

  // Helper method to determine unit for a vitamin
  String _getUnitForVitamin(String vitaminName) {
    // Common units for vitamins
    vitaminName = vitaminName.toUpperCase();
    if (vitaminName == 'A') return 'μg'; // Vitamin A - micrograms
    if (vitaminName == 'C') return 'mg'; // Vitamin C - milligrams
    if (vitaminName == 'D') return 'μg'; // Vitamin D - micrograms
    if (vitaminName == 'E') return 'mg'; // Vitamin E - milligrams
    if (vitaminName.startsWith('B'))
      return 'mg'; // B Vitamins - usually milligrams
    if (vitaminName == 'K') return 'μg'; // Vitamin K - micrograms
    return 'mg'; // Default to milligrams
  }

  // Helper method to determine unit for a mineral
  String _getUnitForMineral(String mineralName) {
    // Common units for minerals
    mineralName = mineralName.toLowerCase();
    if (mineralName == 'sodium' ||
        mineralName == 'potassium' ||
        mineralName == 'calcium' ||
        mineralName == 'magnesium') return 'mg';
    if (mineralName == 'iron' ||
        mineralName == 'zinc' ||
        mineralName == 'copper') return 'mg';
    if (mineralName == 'selenium') return 'μg';
    return 'mg'; // Default to milligrams
  }

  // Helper method to determine unit for other nutrients
  String _getUnitForNutrient(String nutrientName) {
    // Common units for other nutrients
    nutrientName = nutrientName.toLowerCase();
    if (nutrientName.contains('fiber') ||
        nutrientName.contains('sugar') ||
        nutrientName.contains('fat')) return 'g';
    if (nutrientName.contains('cholesterol') || nutrientName.contains('sodium'))
      return 'mg';
    if (nutrientName.contains('calorie')) return 'kcal';
    return ''; // Default to no unit if unknown
  }
}

// Custom painter for the corner frames
class CornerPainter extends CustomPainter {
  final bool topLeft;
  final bool topRight;
  final bool bottomLeft;
  final bool bottomRight;

  CornerPainter({
    this.topLeft = false,
    this.topRight = false,
    this.bottomLeft = false,
    this.bottomRight = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final width = size.width;
    final height = size.height;
    final lineLength = size.width * 0.7;

    if (topLeft) {
      // Top line
      canvas.drawLine(
        Offset(0, 0),
        Offset(lineLength, 0),
        paint,
      );
      // Left line
      canvas.drawLine(
        Offset(0, 0),
        Offset(0, lineLength),
        paint,
      );
    } else if (topRight) {
      // Top line
      canvas.drawLine(
        Offset(width, 0),
        Offset(width - lineLength, 0),
        paint,
      );
      // Right line
      canvas.drawLine(
        Offset(width, 0),
        Offset(width, lineLength),
        paint,
      );
    } else if (bottomLeft) {
      // Bottom line
      canvas.drawLine(
        Offset(0, height),
        Offset(lineLength, height),
        paint,
      );
      // Left line
      canvas.drawLine(
        Offset(0, height),
        Offset(0, height - lineLength),
        paint,
      );
    } else if (bottomRight) {
      // Bottom line
      canvas.drawLine(
        Offset(width, height),
        Offset(width - lineLength, height),
        paint,
      );
      // Right line
      canvas.drawLine(
        Offset(width, height),
        Offset(width, height - lineLength),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CornerPainter oldDelegate) => false;
}
