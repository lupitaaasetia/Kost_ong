// utils/image_picker_helper.dart
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:image_picker_for_web/image_picker_for_web.dart' as web_picker;

/// Helper class untuk image picker yang support web dan mobile
class ImagePickerHelper {
  static final ImagePicker _picker = ImagePicker();

  /// Pick single image - universal untuk web dan mobile
  /// Returns Uint8List untuk kompatibilitas penuh
  static Future<Uint8List?> pickImage() async {
    if (kIsWeb) {
      return await _pickImageWeb();
    } else {
      return await _pickImageMobile();
    }
  }

  /// Pick image khusus untuk web menggunakan image_picker_for_web
  static Future<Uint8List?> _pickImageWeb() async {
    try {
      final webPicker = web_picker.ImagePickerPlugin();
      final image = await webPicker.getImageFromSource(
        source: ImageSource.gallery,
      );

      if (image != null) {
        return await image.readAsBytes();
      }
      return null;
    } catch (e) {
      print('Error picking image on web: $e');
      return null;
    }
  }

  /// Pick image khusus untuk mobile (Android/iOS)
  static Future<Uint8List?> _pickImageMobile() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        return await image.readAsBytes();
      }
      return null;
    } catch (e) {
      print('Error picking image on mobile: $e');
      return null;
    }
  }

  /// Take photo from camera (mobile only)
  static Future<Uint8List?> takePhoto() async {
    if (kIsWeb) {
      print('Camera not supported on web');
      return null;
    }

    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (photo != null) {
        return await photo.readAsBytes();
      }
      return null;
    } catch (e) {
      print('Error taking photo: $e');
      return null;
    }
  }

  /// Pick multiple images - universal untuk web dan mobile
  static Future<List<Uint8List>> pickMultipleImages() async {
    if (kIsWeb) {
      return await _pickMultipleImagesWeb();
    } else {
      return await _pickMultipleImagesMobile();
    }
  }

  /// Pick multiple images untuk web
  static Future<List<Uint8List>> _pickMultipleImagesWeb() async {
    try {
      final webPicker = web_picker.ImagePickerPlugin();
      final images = await webPicker.getMultiImageWithOptions();

      List<Uint8List> imageBytes = [];
      if (images != null) {
        for (var image in images) {
          final bytes = await image.readAsBytes();
          imageBytes.add(bytes);
        }
      }
      return imageBytes;
    } catch (e) {
      print('Error picking multiple images on web: $e');
      return [];
    }
  }

  /// Pick multiple images untuk mobile
  static Future<List<Uint8List>> _pickMultipleImagesMobile() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      List<Uint8List> imageBytes = [];
      for (var image in images) {
        final bytes = await image.readAsBytes();
        imageBytes.add(bytes);
      }
      return imageBytes;
    } catch (e) {
      print('Error picking multiple images on mobile: $e');
      return [];
    }
  }

  /// Pick image from specific source (mobile only)
  /// Untuk web, selalu menggunakan gallery
  static Future<Uint8List?> pickImageFromSource(ImageSource source) async {
    if (kIsWeb) {
      // Web hanya support gallery
      return await _pickImageWeb();
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        return await image.readAsBytes();
      }
      return null;
    } catch (e) {
      print('Error picking image from $source: $e');
      return null;
    }
  }

  /// Validate image size
  static bool validateImageSize(Uint8List imageBytes, {int maxSizeInMB = 2}) {
    final double fileSizeInMB = imageBytes.length / (1024 * 1024);
    return fileSizeInMB <= maxSizeInMB;
  }

  /// Get image size in MB
  static double getImageSizeInMB(Uint8List imageBytes) {
    return imageBytes.length / (1024 * 1024);
  }

  /// Compress image if needed (basic implementation)
  static Future<Uint8List?> compressImage(
    Uint8List imageBytes, {
    int quality = 85,
  }) async {
    // Untuk implementasi yang lebih kompleks,
    // bisa menggunakan package seperti flutter_image_compress
    // Saat ini hanya return original bytes
    return imageBytes;
  }
}
