import 'dart:async';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'daily_stats_service.dart';

class StepCounterService {
  static StreamSubscription<StepCount>? _stepCountSubscription;
  static StreamSubscription<PedestrianStatus>? _pedestrianStatusSubscription;
  static int _lastStepCount = 0;
  static int _baselineStepCount = 0; // Steps at the start of the day
  static bool _isInitialized = false;
  static Timer? _syncTimer;
  static Timer? _dateCheckTimer;

  /// Initialize step counter service
  static Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Request necessary permissions
      final hasPermission = await _requestPermissions();
      if (!hasPermission) {
        print('❌ [STEP_COUNTER] Permissions not granted');
        return false;
      }

      // Check if it's a new day and reset baseline if needed
      await _checkAndResetDailyBaseline();
      
      // Initialize pedometer
      await _initializePedometer();
      
      // Start periodic sync to database
      _startPeriodicSync();
      
      // Start daily date check timer (check every minute)
      _startDateCheckTimer();
      
      _isInitialized = true;
      print('✅ [STEP_COUNTER] Service initialized');
      return true;
    } catch (e) {
      print('❌ [STEP_COUNTER] Error initializing: $e');
      return false;
    }
  }

  /// Request necessary permissions
  static Future<bool> _requestPermissions() async {
    try {
      // For Android: Request activity recognition permission
      final activityStatus = await Permission.activityRecognition.request();
      
      // For iOS: Motion & Fitness is handled via Info.plist, but we can check
      // Note: iOS doesn't require runtime permission for step counting via pedometer
      
      // Check Android permission
      if (activityStatus.isGranted) {
        print('✅ [STEP_COUNTER] Activity recognition permission granted');
        return true;
      }
      
      // If denied permanently, return false
      if (activityStatus.isPermanentlyDenied) {
        print('⚠️ [STEP_COUNTER] Activity recognition permanently denied. Please enable in settings.');
        return false;
      }
      
      // For iOS, pedometer works without explicit permission (uses motion framework)
      // So we can proceed even if Android permission is not granted (for testing)
      print('⚠️ [STEP_COUNTER] Permission status: $activityStatus');
      
      // Try to proceed anyway (iOS will work, Android might not)
      return true;
    } catch (e) {
      print('❌ [STEP_COUNTER] Error requesting permissions: $e');
      // On iOS, pedometer works without explicit permission, so return true
      return true;
    }
  }

  /// Check if it's a new day and reset baseline if needed
  static Future<void> _checkAndResetDailyBaseline() async {
    try {
      final today = DateTime.now();
      final todayDate = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      
      // Get stored date and baseline
      final prefs = await SharedPreferences.getInstance();
      final storedDate = prefs.getString('step_baseline_date') ?? '';
      final storedBaseline = prefs.getInt('step_baseline_count') ?? 0;
      
      // If it's a new day, reset the baseline
      if (storedDate != todayDate) {
        print('📅 [STEP_COUNTER] New day detected! Resetting baseline.');
        
        // Get current cumulative step count from pedometer
        try {
          final currentCumulative = await Pedometer.stepCountStream.first;
          _baselineStepCount = currentCumulative.steps;
          _lastStepCount = 0; // Reset daily steps to 0 for new day
          
          // Save new baseline
          await prefs.setInt('step_baseline_count', _baselineStepCount);
          await prefs.setString('step_baseline_date', todayDate);
          
          // Reset database steps for the new day
          try {
            await DailyStatsService.updateSteps(0);
            print('✅ [STEP_COUNTER] Reset database steps to 0 for new day');
          } catch (e) {
            print('⚠️ [STEP_COUNTER] Could not reset database steps: $e');
          }
          
          print('✅ [STEP_COUNTER] Baseline reset to: $_baselineStepCount steps, daily steps: 0');
        } catch (e) {
          print('⚠️ [STEP_COUNTER] Could not get pedometer count for baseline, using stored: $e');
          // Use the last cumulative count as new baseline
          final lastCumulative = await getLastCumulativeStepCount();
          _baselineStepCount = lastCumulative > 0 ? lastCumulative : storedBaseline;
          _lastStepCount = 0;
          
          await prefs.setInt('step_baseline_count', _baselineStepCount);
          await prefs.setString('step_baseline_date', todayDate);
        }
      } else {
        // Same day, use stored baseline
        _baselineStepCount = storedBaseline;
        print('📅 [STEP_COUNTER] Using existing baseline: $_baselineStepCount steps');
      }
    } catch (e) {
      print('❌ [STEP_COUNTER] Error checking/resetting daily baseline: $e');
    }
  }

  /// Start timer to check for date changes (every minute)
  static void _startDateCheckTimer() {
    _dateCheckTimer?.cancel();
    _dateCheckTimer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      await _checkAndResetDailyBaseline();
    });
  }

  /// Initialize pedometer streams
  static Future<void> _initializePedometer() async {
    try {
      // Get initial step count
      final initialStepCount = await Pedometer.stepCountStream.first;
      final cumulativeSteps = initialStepCount.steps;
      
      // Calculate daily steps = cumulative - baseline
      final dailySteps = cumulativeSteps - _baselineStepCount;
      _lastStepCount = dailySteps > 0 ? dailySteps : 0;
      
      // Save current cumulative count
      await _saveStepCount(cumulativeSteps);
      
      print('📊 [STEP_COUNTER] Initial: Cumulative=$cumulativeSteps, Baseline=$_baselineStepCount, Daily=$_lastStepCount');
      
      // Listen to step count stream
      _stepCountSubscription = Pedometer.stepCountStream.listen(
        (StepCount stepCount) {
          _onStepCount(stepCount);
        },
        onError: (error) {
          print('❌ [STEP_COUNTER] Error in step count stream: $error');
        },
      );

      // Listen to pedestrian status stream (optional)
      _pedestrianStatusSubscription = Pedometer.pedestrianStatusStream.listen(
        (PedestrianStatus status) {
          print('🚶 [STEP_COUNTER] Pedestrian status: ${status.status}');
        },
        onError: (error) {
          print('❌ [STEP_COUNTER] Error in pedestrian status stream: $error');
        },
      );
      
      print('✅ [STEP_COUNTER] Pedometer streams initialized');
    } catch (e) {
      print('❌ [STEP_COUNTER] Error initializing pedometer: $e');
      rethrow;
    }
  }

  /// Handle step count updates
  static void _onStepCount(StepCount stepCount) async {
    try {
      // Check if it's a new day first
      await _checkAndResetDailyBaseline();
      
      final cumulativeSteps = stepCount.steps;
      
      // Calculate daily steps = cumulative - baseline
      final dailySteps = cumulativeSteps - _baselineStepCount;
      final validDailySteps = dailySteps > 0 ? dailySteps : 0;
      
      // Calculate steps since last update
      final stepsSinceLastUpdate = validDailySteps - _lastStepCount;
      
      if (stepsSinceLastUpdate > 0 || validDailySteps != _lastStepCount) {
        print('👣 [STEP_COUNTER] Cumulative: $cumulativeSteps, Baseline: $_baselineStepCount, Daily: $validDailySteps (+$stepsSinceLastUpdate)');
        
        // Update last known values
        _lastStepCount = validDailySteps;
        
        // Save cumulative count to local storage (for baseline calculation)
        await _saveStepCount(cumulativeSteps);
        
        // Sync daily steps to database (async, don't wait)
        _syncToDatabase(validDailySteps);
      }
    } catch (e) {
      print('❌ [STEP_COUNTER] Error handling step count: $e');
    }
  }

  /// Save step count to local storage (saves cumulative count)
  static Future<void> _saveStepCount(int cumulativeSteps) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('last_cumulative_step_count', cumulativeSteps);
      await prefs.setString('last_step_update', DateTime.now().toIso8601String());
    } catch (e) {
      print('❌ [STEP_COUNTER] Error saving step count: $e');
    }
  }

  /// Get last saved cumulative step count from local storage
  static Future<int> getLastCumulativeStepCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('last_cumulative_step_count') ?? 0;
    } catch (e) {
      print('❌ [STEP_COUNTER] Error getting last cumulative step count: $e');
      return 0;
    }
  }
  
  /// Get current daily step count (calculated from cumulative - baseline)
  static Future<int> getCurrentDailySteps() async {
    try {
      // Check if it's a new day and reset baseline if needed
      await _checkAndResetDailyBaseline();
      
      // Get current cumulative from pedometer if available
      int cumulativeSteps = 0;
      if (_isInitialized) {
        try {
          final currentCount = await Pedometer.stepCountStream.first;
          cumulativeSteps = currentCount.steps;
        } catch (e) {
          // Fallback to stored cumulative
          cumulativeSteps = await getLastCumulativeStepCount();
        }
      } else {
        cumulativeSteps = await getLastCumulativeStepCount();
      }
      
      // Calculate daily steps = cumulative - baseline
      final dailySteps = cumulativeSteps - _baselineStepCount;
      return dailySteps > 0 ? dailySteps : 0;
    } catch (e) {
      print('❌ [STEP_COUNTER] Error getting current daily steps: $e');
      return 0;
    }
  }

  /// Sync step count to database
  static Future<void> _syncToDatabase(int steps) async {
    try {
      // Get today's stats first
      final todayStats = await DailyStatsService.getTodayStats();
      final currentSteps = todayStats['steps'] as int;
      
      // Only update if new count is higher (prevents reset issues)
      if (steps > currentSteps) {
        await DailyStatsService.updateSteps(steps);
        print('✅ [STEP_COUNTER] Synced $steps steps to database');
      }
    } catch (e) {
      print('❌ [STEP_COUNTER] Error syncing to database: $e');
    }
  }

  /// Start periodic sync to database (every 5 minutes)
  static void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      try {
        // Check for new day first
        await _checkAndResetDailyBaseline();
        
        // Get current daily steps
        final currentSteps = await getCurrentDailySteps();
        if (currentSteps >= 0) {
          await _syncToDatabase(currentSteps);
        }
      } catch (e) {
        print('❌ [STEP_COUNTER] Error in periodic sync: $e');
      }
    });
  }

  /// Get current step count (daily steps)
  static Future<int> getCurrentStepCount() async {
    try {
      // If initialized and we have a recent count, use it
      if (_isInitialized && _lastStepCount > 0) {
        // But first check if it's a new day
        await _checkAndResetDailyBaseline();
        return _lastStepCount;
      }
      
      // Otherwise calculate from cumulative and baseline
      return await getCurrentDailySteps();
    } catch (e) {
      print('❌ [STEP_COUNTER] Error getting current step count: $e');
      return 0;
    }
  }

  /// Manually sync steps to database
  static Future<void> syncNow() async {
    try {
      final currentSteps = await getCurrentStepCount();
      if (currentSteps > 0) {
        await _syncToDatabase(currentSteps);
      }
    } catch (e) {
      print('❌ [STEP_COUNTER] Error in manual sync: $e');
    }
  }

  /// Dispose and cleanup
  static Future<void> dispose() async {
    try {
      await _stepCountSubscription?.cancel();
      await _pedestrianStatusSubscription?.cancel();
      _syncTimer?.cancel();
      _dateCheckTimer?.cancel();
      _isInitialized = false;
      print('✅ [STEP_COUNTER] Service disposed');
    } catch (e) {
      print('❌ [STEP_COUNTER] Error disposing: $e');
    }
  }

  /// Check if service is initialized
  static bool get isInitialized => _isInitialized;

  /// Check if permissions are granted
  static Future<bool> checkPermissions() async {
    try {
      final activityStatus = await Permission.activityRecognition.status;
      final sensorStatus = await Permission.sensors.status;
      
      return activityStatus.isGranted || sensorStatus.isGranted;
    } catch (e) {
      print('❌ [STEP_COUNTER] Error checking permissions: $e');
      return false;
    }
  }

  /// Request permissions (can be called from UI)
  static Future<bool> requestPermissions() async {
    return await _requestPermissions();
  }
}

