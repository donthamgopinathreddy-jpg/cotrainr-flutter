# Health & Sensor Integration Guide

## Overview
CoTrainr integrates with Apple HealthKit (iOS) and Google Fit (Android) to sync health data, and uses device sensors for real-time tracking.

## Permissions Required

### iOS (Info.plist)
- HealthKit (Read & Write)
- Location (When In Use & Always)
- Camera
- Photo Library
- Microphone
- Motion & Fitness
- Contacts

### Android (AndroidManifest.xml)
- Activity Recognition
- Location (Fine & Coarse)
- Camera
- Storage (Read & Write)
- Notifications
- Contacts
- Microphone
- Sensors

## Health Data Synced

### Read from Health Apps
- Steps
- Heart Rate
- Active Calories
- Water Intake
- Weight
- Height
- BMI
- Distance (Walking/Running)
- Workouts
- Sleep

### Write to Health Apps
- Water Intake
- Workouts
- Custom activities

## Sensors Used

### Available Sensors
1. **Accelerometer** - Activity detection, shake detection
2. **Gyroscope** - Orientation, rotation detection
3. **Magnetometer** - Compass, orientation
4. **Pedometer** - Step counting
5. **Heart Rate** (if available) - Real-time heart rate

## Setup Instructions

### iOS Setup
1. Open `ios/Runner.xcodeproj` in Xcode
2. Select the Runner target
3. Go to "Signing & Capabilities"
4. Add "HealthKit" capability
5. Ensure all permissions are in Info.plist

### Android Setup
1. All permissions are already in AndroidManifest.xml
2. For Google Fit integration, you may need to:
   - Set up Google Cloud Console project
   - Enable Google Fit API
   - Add OAuth credentials (if needed)

## Usage

### Initialize Services
```dart
// Already done in main.dart
await AppInitialization.initializeApp();
```

### Get Health Data
```dart
final healthService = HealthService();
await healthService.initialize();

// Get today's steps
int? steps = await healthService.getStepsToday();

// Get heart rate
int? heartRate = await healthService.getHeartRate();

// Get calories
double? calories = await healthService.getCaloriesBurned();
```

### Write Health Data
```dart
// Write water intake
bool success = await healthService.writeWater(0.5); // 0.5 liters
```

### Use Sensors
```dart
final sensorService = SensorService();
await sensorService.initialize();

// Get step count
int steps = sensorService.stepCount;
```

## Testing

### iOS
- Test on a real device (HealthKit doesn't work in simulator)
- Grant permissions when prompted
- Check Health app to verify data sync

### Android
- Test on a real device with Google Fit installed
- Grant all permissions
- Check Google Fit app to verify data sync

## Troubleshooting

### Permissions Not Granted
- Check Info.plist (iOS) or AndroidManifest.xml (Android)
- Ensure permission descriptions are clear
- User may need to grant in Settings manually

### Health Data Not Syncing
- Verify HealthKit/Google Fit is set up on device
- Check if permissions are granted
- Ensure data types are requested correctly

### Sensors Not Working
- Verify device has required sensors
- Check permissions are granted
- Some sensors may not be available on all devices




















