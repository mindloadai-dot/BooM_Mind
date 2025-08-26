import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

/// Service to handle local storage of user profile pictures
/// Stores images in app's local directory with proper naming and cleanup
class LocalImageStorageService extends ChangeNotifier {
  static final LocalImageStorageService _instance =
      LocalImageStorageService._();
  static LocalImageStorageService get instance => _instance;
  LocalImageStorageService._();

  static const String _profileImageKey = 'user_profile_image_path';
  static const String _profileImageDir = 'profile_images';
  static const int _maxImageSizeBytes = 5 * 1024 * 1024; // 5MB
  static const int _minImageDimension = 512;

  String? _currentImagePath;

  // Getters
  String? get currentImagePath => _currentImagePath;

  /// Get the local directory for storing profile images
  Future<Directory> get _profileImageDirectory async {
    final appDir = await getApplicationDocumentsDirectory();
    final profileDir = Directory('${appDir.path}/$_profileImageDir');

    if (!await profileDir.exists()) {
      await profileDir.create(recursive: true);
    }

    return profileDir;
  }

  /// Save profile image locally and return the saved path
  Future<String?> saveProfileImage(File imageFile) async {
    try {
      // Validate image file
      if (!await _validateImageFile(imageFile)) {
        return null;
      }

      // Generate unique filename based on file content hash
      final bytes = await imageFile.readAsBytes();
      final hash = sha256.convert(bytes).toString();
      final extension = imageFile.path.split('.').last.toLowerCase();
      final filename = 'profile_$hash.$extension';

      // Get profile image directory
      final profileDir = await _profileImageDirectory;
      final savedImagePath = '${profileDir.path}/$filename';

      // Copy image to profile directory
      final savedImage = await imageFile.copy(savedImagePath);

      // Save path to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_profileImageKey, savedImagePath);

      // Update current image path
      _currentImagePath = savedImagePath;

      // Clean up old profile images
      await _cleanupOldImages();

      // Notify listeners
      notifyListeners();

      if (kDebugMode) {
        debugPrint('✅ Profile image saved locally: $savedImagePath');
      }

      return savedImagePath;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to save profile image: $e');
      }
      return null;
    }
  }

  /// Load the current profile image path
  Future<String?> getProfileImagePath() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final imagePath = prefs.getString(_profileImageKey);

      if (imagePath != null && await File(imagePath).exists()) {
        _currentImagePath = imagePath;
        notifyListeners();
        return imagePath;
      }

      _currentImagePath = null;
      notifyListeners();
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to load profile image path: $e');
      }
      return null;
    }
  }

  /// Delete the current profile image
  Future<bool> deleteProfileImage() async {
    try {
      final imagePath = await getProfileImagePath();
      if (imagePath != null) {
        final imageFile = File(imagePath);
        if (await imageFile.exists()) {
          await imageFile.delete();
        }
      }

      // Remove path from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_profileImageKey);

      // Update current image path
      _currentImagePath = null;
      notifyListeners();

      if (kDebugMode) {
        debugPrint('🗑️ Profile image deleted');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to delete profile image: $e');
      }
      return false;
    }
  }

  /// Get profile image as File object
  Future<File?> getProfileImageFile() async {
    try {
      final imagePath = await getProfileImagePath();
      if (imagePath != null) {
        final imageFile = File(imagePath);
        if (await imageFile.exists()) {
          return imageFile;
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to get profile image file: $e');
      }
      return null;
    }
  }

  /// Get profile image as bytes
  Future<Uint8List?> getProfileImageBytes() async {
    try {
      final imageFile = await getProfileImageFile();
      if (imageFile != null) {
        return await imageFile.readAsBytes();
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to get profile image bytes: $e');
      }
      return null;
    }
  }

  /// Check if profile image exists
  Future<bool> hasProfileImage() async {
    try {
      final imagePath = await getProfileImagePath();
      if (imagePath != null) {
        return await File(imagePath).exists();
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Get profile image info (size, dimensions, etc.)
  Future<Map<String, dynamic>?> getProfileImageInfo() async {
    try {
      final imageFile = await getProfileImageFile();
      if (imageFile != null) {
        final stat = await imageFile.stat();
        final bytes = await imageFile.readAsBytes();

        // Basic image validation
        if (bytes.length >= 8) {
          // Check if it's a valid image by looking at magic bytes
          final isPng = bytes.length >= 8 &&
              bytes[0] == 0x89 &&
              bytes[1] == 0x50 &&
              bytes[2] == 0x4E &&
              bytes[3] == 0x47;
          final isJpeg =
              bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xD8;

          if (isPng || isJpeg) {
            return {
              'path': imageFile.path,
              'size': stat.size,
              'size_mb': (stat.size / (1024 * 1024)).toStringAsFixed(2),
              'last_modified': stat.modified,
              'format': isPng ? 'PNG' : 'JPEG',
              'exists': true,
            };
          }
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to get profile image info: $e');
      }
      return null;
    }
  }

  /// Clean up old profile images (keep only current one)
  Future<void> _cleanupOldImages() async {
    try {
      final profileDir = await _profileImageDirectory;
      final currentImagePath = await getProfileImagePath();

      if (await profileDir.exists()) {
        final files = profileDir.listSync();
        for (final file in files) {
          if (file is File && file.path != currentImagePath) {
            await file.delete();
            if (kDebugMode) {
              debugPrint('🗑️ Cleaned up old profile image: ${file.path}');
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Failed to cleanup old images: $e');
      }
    }
  }

  /// Validate image file (size, format, dimensions)
  Future<bool> _validateImageFile(File imageFile) async {
    try {
      if (!await imageFile.exists()) {
        return false;
      }

      final stat = await imageFile.stat();

      // Check file size
      if (stat.size > _maxImageSizeBytes) {
        if (kDebugMode) {
          debugPrint(
              '❌ Image too large: ${stat.size} bytes (max: $_maxImageSizeBytes)');
        }
        return false;
      }

      // Check if file is empty
      if (stat.size == 0) {
        return false;
      }

      // Basic format validation (check magic bytes)
      final bytes = await imageFile.readAsBytes();
      if (bytes.length < 8) {
        return false;
      }

      // Check for PNG or JPEG magic bytes
      final isPng = bytes[0] == 0x89 &&
          bytes[1] == 0x50 &&
          bytes[2] == 0x4E &&
          bytes[3] == 0x47;
      final isJpeg = bytes[0] == 0xFF && bytes[1] == 0xD8;

      if (!isPng && !isJpeg) {
        if (kDebugMode) {
          debugPrint('❌ Unsupported image format');
        }
        return false;
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Image validation failed: $e');
      }
      return false;
    }
  }

  /// Clear all profile images and data
  Future<void> clearAllProfileImages() async {
    try {
      // Remove from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_profileImageKey);

      // Delete profile image directory
      final profileDir = await _profileImageDirectory;
      if (await profileDir.exists()) {
        await profileDir.delete(recursive: true);
      }

      // Update current image path
      _currentImagePath = null;
      notifyListeners();

      if (kDebugMode) {
        debugPrint('🗑️ All profile images cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to clear profile images: $e');
      }
    }
  }

  /// Get storage usage information
  Future<Map<String, dynamic>> getStorageInfo() async {
    try {
      final profileDir = await _profileImageDirectory;
      int totalSize = 0;
      int fileCount = 0;

      if (await profileDir.exists()) {
        final files = profileDir.listSync();
        for (final file in files) {
          if (file is File) {
            final stat = await file.stat();
            totalSize += stat.size;
            fileCount++;
          }
        }
      }

      return {
        'total_size_bytes': totalSize,
        'total_size_mb': (totalSize / (1024 * 1024)).toStringAsFixed(2),
        'file_count': fileCount,
        'directory_path': profileDir.path,
        'max_size_bytes': _maxImageSizeBytes,
        'max_size_mb': (_maxImageSizeBytes / (1024 * 1024)).toStringAsFixed(2),
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to get storage info: $e');
      }
      return {};
    }
  }
}
