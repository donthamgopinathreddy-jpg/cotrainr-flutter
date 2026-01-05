import 'sensor_service.dart';
import 'permission_service.dart';
// import 'health_service.dart';  // Temporarily removed for build stability

class AppInitialization {
  static Future<void> initializeApp() async {
    try {
      // Request all permissions first
      final permissionService = PermissionService();
      await permissionService.requestAllPermissions();

      // Initialize health service - Temporarily disabled
      // final healthService = HealthService();
      // await healthService.initialize();

      // Initialize sensor service (without pedometer)
      final sensorService = SensorService();
      await sensorService.initialize();
      sensorService.startAccelerometer();
      sensorService.startGyroscope();
      sensorService.startMagnetometer();

      print('App initialization complete');
    } catch (e) {
      print('App initialization error: $e');
    }
  }
}
