import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';
// import 'package:pedometer/pedometer.dart';  // Temporarily removed for build stability

class SensorService {
  static final SensorService _instance = SensorService._internal();
  factory SensorService() => _instance;
  SensorService._internal();

  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  StreamSubscription<UserAccelerometerEvent>? _userAccelerometerSubscription;
  StreamSubscription<MagnetometerEvent>? _magnetometerSubscription;
  // StreamSubscription<StepCount>? _pedometerSubscription;  // Temporarily removed

  final int _stepCount = 0;
  int get stepCount => _stepCount;

  Future<void> initialize() async {
    try {
      // Initialize pedometer - Temporarily disabled
      // await _initializePedometer();
      print('Sensor service initialized (pedometer disabled temporarily)');
    } catch (e) {
      print('Sensor initialization error: $e');
    }
  }

  // Temporarily disabled pedometer initialization
  // Future<void> _initializePedometer() async {
  //   try {
  //     late Stream<StepCount> stepCountStream;
  //     late Stream<PedestrianStatus> pedestrianStatusStream;
  //
  //     stepCountStream = Pedometer.stepCountStream;
  //     pedestrianStatusStream = Pedometer.pedestrianStatusStream;
  //
  //     _pedometerSubscription = stepCountStream.listen(
  //       (StepCount event) {
  //         _stepCount = event.steps;
  //       },
  //       onError: (error) {
  //         print('Pedometer error: $error');
  //       },
  //     );
  //
  //     pedestrianStatusStream.listen((status) {
  //       // Handle pedestrian status (walking, running, etc.)
  //     });
  //   } catch (e) {
  //     print('Pedometer initialization error: $e');
  //   }
  // }

  void startAccelerometer() {
    _accelerometerSubscription = accelerometerEventStream().listen(
      (AccelerometerEvent event) {
        // Handle accelerometer data
        // Can be used for activity detection, shake detection, etc.
      },
    );
  }

  void startGyroscope() {
    _gyroscopeSubscription = gyroscopeEventStream().listen(
      (GyroscopeEvent event) {
        // Handle gyroscope data
        // Can be used for orientation, rotation detection
      },
    );
  }

  void startMagnetometer() {
    _magnetometerSubscription = magnetometerEventStream().listen(
      (MagnetometerEvent event) {
        // Handle magnetometer data
        // Can be used for compass, orientation
      },
    );
  }

  void stopAllSensors() {
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _userAccelerometerSubscription?.cancel();
    _magnetometerSubscription?.cancel();
    // _pedometerSubscription?.cancel();  // Temporarily removed
  }

  void dispose() {
    stopAllSensors();
  }
}








