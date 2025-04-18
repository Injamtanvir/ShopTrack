import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

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
      // Check permissions first
      bool permissionGranted = await _checkPermissions(source, context: context);
      if (!permissionGranted) {
        debugPrint('Permission denied for ${source == ImageSource.camera ? 'camera' : 'gallery'}');
        return null;
      }
      
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 85, // First level of compression
        maxWidth: 1000,
        maxHeight: 1000,
      );
      
      if (pickedFile == null) {
        return null;
      }
      
      File imageFile = File(pickedFile.path);
      
      // Get file size in MB
      final fileSize = await imageFile.length() / (1024 * 1024);
      
      // If file is already small enough, return it
      if (fileSize < 1.0) {
        return imageFile;
      }
      
      // Otherwise compress it
      return await compressImage(imageFile);
    } catch (e) {
      debugPrint('Error picking image: $e');
      
      // Show error dialog if context is provided
      if (context != null) {
        _showErrorDialog(context, e.toString());
      }
      
      return null;
    }
  }
  
  static Future<bool> _checkPermissions(ImageSource source, {BuildContext? context}) async {
    if (kIsWeb) {
      debugPrint('Platform is web, no permissions needed');
      return true; // Web doesn't need permission checks
    }
    
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      debugPrint('Platform is desktop (${Platform.operatingSystem}), no permissions needed');
      return true; // Desktop platforms don't need runtime permissions
    }

    try {
      PermissionStatus status;
      
      if (source == ImageSource.camera) {
        // Camera permission
        debugPrint('Requesting camera permission...');
        status = await Permission.camera.request();
        debugPrint('Camera permission status: $status');
      } else {
        if (Platform.isIOS) {
          // iOS photos permission
          debugPrint('Platform is iOS, requesting photos permission...');
          status = await Permission.photos.request();
          debugPrint('Photos permission status: $status');
        } else if (Platform.isAndroid) {
          // Android permissions vary by version
          debugPrint('Platform is Android, checking version...');
          bool isAndroid13Plus = await _isAndroid13OrHigher();
          debugPrint('Is Android 13+: $isAndroid13Plus');
          
          // For Android 13+, we need more granular permissions
          if (isAndroid13Plus) {
            debugPrint('Requesting photos permission for Android 13+...');
            status = await Permission.photos.request();
            debugPrint('Photos permission status: $status');
            // If photos permission is not needed, try storage
            if (status.isDenied) {
              debugPrint('Photos permission denied, trying storage permission...');
              status = await Permission.storage.request();
              debugPrint('Storage permission status: $status');
            }
          } else {
            debugPrint('Requesting storage permission for older Android...');
            status = await Permission.storage.request();
            debugPrint('Storage permission status: $status');
          }
        } else {
          // For other platforms, default to storage
          debugPrint('Unknown platform, defaulting to storage permission...');
          status = await Permission.storage.request();
          debugPrint('Storage permission status: $status');
        }
      }
      
      if (status.isGranted) {
        debugPrint('Permission granted');
        return true;
      } else if (status.isPermanentlyDenied && context != null) {
        debugPrint('Permission permanently denied, showing settings dialog');
        // Show dialog to open app settings
        _showPermissionDialog(context, source == ImageSource.camera ? 'camera' : 'photo library');
        return false;
      } else if (status.isDenied && context != null) {
        debugPrint('Permission denied, showing error message');
        // Show denied message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${source == ImageSource.camera ? 'Camera' : 'Photos'} permission denied. Please grant permission to continue.'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () {
                openAppSettings();
              },
            ),
          ),
        );
        return false;
      }
      
      debugPrint('Permission check failed: $status');
      return false;
    } catch (e) {
      debugPrint('Error checking permissions: $e');
      return false;
    }
  }
  
  // Helper to check if device is running Android 13+
  static Future<bool> _isAndroid13OrHigher() async {
    if (!Platform.isAndroid) return false;
    
    try {
      final sdkVersion = int.tryParse(await _getAndroidSdkVersion()) ?? 0;
      return sdkVersion >= 33; // Android 13 is API level 33
    } catch (e) {
      return false;
    }
  }
  
  // Helper to get Android SDK version
  static Future<String> _getAndroidSdkVersion() async {
    try {
      return Platform.version.split(' ').first;
    } catch (e) {
      return '0';
    }
  }
  
  static void _showPermissionDialog(BuildContext context, String permissionType) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$permissionType Permission Required'),
        content: Text('Please enable $permissionType access in your device settings to upload photos.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
  
  static void _showErrorDialog(BuildContext context, String errorMessage) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Error Picking Image'),
        content: Text('There was an error accessing your photos: $errorMessage'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  
  static Future<bool> isValidImage(File? file) async {
    if (file == null) {
      return false;
    }
    
    try {
      // Check file size (Max 5MB)
      final fileSize = await file.length();
      if (fileSize > 5 * 1024 * 1024) {
        return false;
      }
      
      // Check file extension
      final extension = path.extension(file.path).toLowerCase();
      return ['.jpg', '.jpeg', '.png'].contains(extension);
    } catch (e) {
      return false;
    }
  }
} 