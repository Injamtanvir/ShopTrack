import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'platform_utils.dart';

class ImageUtils {
  static Future<File?> compressImage(File file, {int quality = 70}) async {
    try {
      final dir = await getTemporaryDirectory();
      final targetPath = path.join(dir.path, '${DateTime.now().millisecondsSinceEpoch}.jpg');
      
      var result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: quality,
        format: CompressFormat.jpeg,
      );
      
      return result != null ? File(result.path) : null;
    } catch (e) {
      debugPrint('Error compressing image: $e');
      return file; // Return original file if compression fails
    }
  }
  
  static Future<File?> pickAndCompressImage(ImageSource source, {BuildContext? context}) async {
    try {
      // Skip permissions check for web and try direct picking
      if (kIsWeb) {
        final picker = ImagePicker();
        final pickedFile = await picker.pickImage(
          source: source,
          imageQuality: 85,
          maxWidth: 1000,
          maxHeight: 1000,
        );
        
        if (pickedFile == null) return null;
        
        return File(pickedFile.path);
      }
      
      // For non-web platforms, try with permissions
      if (!kIsWeb) {
        bool permissionGranted = false;
        
        // Only check permissions on Android and iOS
        if (PlatformUtils.isMobile) {
          try {
            // Request specific permission based on source
            if (source == ImageSource.camera) {
              final status = await Permission.camera.request();
              permissionGranted = status.isGranted;
              debugPrint('Camera permission status: $status');
            } else {
              // For gallery access, we may need different permissions based on platform
              if (PlatformUtils.isAndroid) {
                // On Android 13+ (API 33+), use photos permission
                // On older Android, use storage permission
                try {
                  final storageStatus = await Permission.storage.request();
                  final photosStatus = await Permission.photos.request();
                  permissionGranted = storageStatus.isGranted || photosStatus.isGranted;
                  debugPrint('Storage permission: $storageStatus, Photos permission: $photosStatus');
                } catch (e) {
                  debugPrint('Error requesting Android permissions: $e');
                  // Try with just storage as fallback
                  final status = await Permission.storage.request();
                  permissionGranted = status.isGranted;
                }
              } else if (PlatformUtils.isIOS) {
                final status = await Permission.photos.request();
                permissionGranted = status.isGranted;
                debugPrint('Photos permission status: $status');
              } else {
                // On desktop platforms, no permission needed
                permissionGranted = true;
              }
            }
          } catch (e) {
            debugPrint('Error requesting permissions: $e');
            // Continue anyway, the image_picker might have its own permission handling
            permissionGranted = true;
          }
        } else {
          // Desktop platforms don't need runtime permissions
          permissionGranted = true;
        }
        
        if (!permissionGranted && context != null) {
          _showPermissionDeniedMessage(context, source);
          return null;
        }
      }
      
      // If we got here, we can try to pick an image
      try {
        final picker = ImagePicker();
        final pickedFile = await picker.pickImage(
          source: source,
          imageQuality: 85,
          maxWidth: 1000,
          maxHeight: 1000,
        );
        
        if (pickedFile == null) return null;
        
        File imageFile = File(pickedFile.path);
        
        // For web or small files, return as is
        if (kIsWeb) return imageFile;
        
        // Check file size
        try {
          final fileSize = await imageFile.length() / (1024 * 1024);
          // If file is already small enough, return it
          if (fileSize < 1.0) {
            return imageFile;
          }
        } catch (e) {
          debugPrint('Error checking file size: $e');
          // If we can't check size, assume it needs compression
        }
        
        // Compress and return
        return await compressImage(imageFile);
      } catch (e) {
        debugPrint('Error in image picker: $e');
        if (context != null) {
          _showErrorDialog(context, e.toString());
        }
        return null;
      }
    } catch (e) {
      debugPrint('Error in pickAndCompressImage: $e');
      if (context != null) {
        _showErrorDialog(context, e.toString());
      }
      return null;
    }
  }
  
  static void _showPermissionDeniedMessage(BuildContext context, ImageSource source) {
    final String sourceType = source == ImageSource.camera ? 'Camera' : 'Gallery';
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$sourceType permission denied. Please allow access in settings.'),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Settings',
          onPressed: () {
            openAppSettings();
          },
        ),
      ),
    );
  }
  
  static void _showPermissionDialog(BuildContext context, String permissionType) {
    PlatformUtils.showPlatformDialog(
      context: context,
      title: '$permissionType Permission Required',
      message: 'Please enable $permissionType access in your device settings to upload photos.',
      cancelText: 'Cancel',
      confirmText: 'Open Settings',
      onConfirm: () {
        openAppSettings();
      },
    );
  }
  
  static void _showErrorDialog(BuildContext context, String errorMessage) {
    PlatformUtils.showPlatformDialog(
      context: context,
      title: 'Error Picking Image',
      message: 'There was an error accessing your photos: $errorMessage',
      confirmText: 'OK',
    );
  }
  
  static Future<bool> isValidImage(File? file) async {
    if (file == null) {
      debugPrint('Image validation failed: file is null');
      return false;
    }
    
    try {
      debugPrint('Validating image: ${file.path}');
      
      // On web platform, just return true as we can't properly check
      if (kIsWeb) {
        debugPrint('Running on web platform, skipping detailed validation');
        return true;
      }
      
      // Check file size (Max 5MB)
      final fileSize = await file.length();
      debugPrint('File size: ${fileSize / 1024 / 1024}MB');
      if (fileSize > 5 * 1024 * 1024) {
        debugPrint('Image too large: ${fileSize / 1024 / 1024}MB');
        return false;
      }
      
      // Check file extension
      final extension = path.extension(file.path).toLowerCase();
      debugPrint('File extension: $extension');
      
      final isValid = ['.jpg', '.jpeg', '.png'].contains(extension);
      debugPrint('Is valid extension: $isValid');
      return isValid;
    } catch (e) {
      debugPrint('Error validating image: $e');
      return true; // Return true on error to prevent blocking the upload process
    }
  }
} 