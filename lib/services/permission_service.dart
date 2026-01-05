import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  /// Request all necessary permissions for the app
  Future<Map<Permission, PermissionStatus>> requestAllPermissions() async {
    final permissions = [
      // Health & Fitness
      Permission.activityRecognition,
      Permission.sensors,
      
      // Location
      Permission.location,
      Permission.locationWhenInUse,
      Permission.locationAlways,
      
      // Camera & Media
      Permission.camera,
      Permission.photos,
      Permission.videos,
      
      // Storage
      Permission.storage,
      Permission.manageExternalStorage,
      
      // Notifications
      Permission.notification,
      
      // Contacts (for social features)
      Permission.contacts,
      
      // Microphone (for video sessions)
      Permission.microphone,
      
      // Phone (for calling features)
      Permission.phone,
    ];

    Map<Permission, PermissionStatus> statuses = {};
    
    for (var permission in permissions) {
      final status = await permission.status;
      if (!status.isGranted) {
        final result = await permission.request();
        statuses[permission] = result;
      } else {
        statuses[permission] = status;
      }
    }

    return statuses;
  }

  /// Request health permissions specifically
  Future<bool> requestHealthPermissions() async {
    final permissions = [
      Permission.activityRecognition,
      Permission.sensors,
    ];

    bool allGranted = true;
    for (var permission in permissions) {
      final status = await permission.request();
      if (!status.isGranted) {
        allGranted = false;
      }
    }

    return allGranted;
  }

  /// Request location permissions
  Future<bool> requestLocationPermissions() async {
    final status = await Permission.locationWhenInUse.request();
    if (status.isGranted) {
      return true;
    }

    // Try always location if when in use is denied
    final alwaysStatus = await Permission.locationAlways.request();
    return alwaysStatus.isGranted;
  }

  /// Request camera permissions
  Future<bool> requestCameraPermissions() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  /// Request storage permissions
  Future<bool> requestStoragePermissions() async {
    if (await Permission.storage.isGranted) {
      return true;
    }

    final status = await Permission.storage.request();
    return status.isGranted;
  }

  /// Check if a specific permission is granted
  Future<bool> isPermissionGranted(Permission permission) async {
    final status = await permission.status;
    return status.isGranted;
  }

  /// Open app settings if permission is permanently denied
  Future<bool> openSettings() async {
    return await openAppSettings();
  }
}

