import 'dart:typed_data';
import 'package:flutter/foundation.dart';

// For web, we'll use our custom methods
import 'web_impl.dart' if (dart.library.io) 'web_impl_stub.dart';

// Only import the package on mobile platforms
import 'package:flutter_image_compress/flutter_image_compress.dart'
    if (dart.library.html) 'web_image_compress_stub.dart';

/// Compress an image to a smaller size
/// For web, this uses canvas resize
/// For mobile, this uses flutter_image_compress
Future<Uint8List> compressImage(
  Uint8List imageBytes, {
  int quality = 85,
  int targetWidth = 800,
  int? targetHeight,
}) async {
  if (imageBytes.isEmpty) {
    return Uint8List(0);
  }

  try {
    if (kIsWeb) {
      // Web implementation
      return await resizeWebImage(imageBytes, targetWidth,
          targetHeight: targetHeight, quality: quality);
    } else {
      // Mobile implementation
      return await FlutterImageCompress.compressWithList(
        imageBytes,
        quality: quality,
        minWidth: targetWidth,
        minHeight: targetHeight ?? 0,
      );
    }
  } catch (e) {
    print('Error compressing image: $e');
    // Return original bytes as fallback
    return imageBytes;
  }
}
