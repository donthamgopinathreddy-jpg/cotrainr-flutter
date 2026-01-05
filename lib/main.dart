import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:workmanager/workmanager.dart'; // Temporarily disabled - updating package
import 'services/theme_provider.dart';
import 'services/language_provider.dart';
import 'services/step_counter_service.dart';
import 'pages/splash_page.dart';
import 'config/supabase_config.dart';
import 'l10n/app_localizations.dart';

// Background task callback - temporarily disabled while updating workmanager package
// @pragma('vm:entry-point')
// void callbackDispatcher() {
//   Workmanager().executeTask((task, inputData) async {
//     try {
//       print('🔄 [BACKGROUND] Task: $task');
//       
//       if (task == 'stepSyncTask') {
//         // Sync steps to database
//         await StepCounterService.syncNow();
//         return true;
//       }
//       
//       return false;
//     } catch (e) {
//       print('❌ [BACKGROUND] Error: $e');
//       return false;
//     }
//   });
// }

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
    debug: true, // Set to true for development to see detailed errors
  );
  
  // Initialize Workmanager for background tasks
  // Temporarily disabled while updating to workmanager 0.9.0+
  // TODO: Re-enable after updating package and verifying API compatibility
  // try {
  //   await Workmanager().initialize(
  //     callbackDispatcher,
  //     isInDebugMode: true, // Set to false in production
  //   );
  //   
  //   // Register periodic task for step syncing (every 15 minutes)
  //   await Workmanager().registerPeriodicTask(
  //     'stepSyncTask',
  //     'stepSyncTask',
  //     frequency: const Duration(minutes: 15),
  //     constraints: Constraints(
  //       networkType: NetworkType.not_required,
  //       requiresBatteryNotLow: false,
  //       requiresCharging: false,
  //       requiresDeviceIdle: false,
  //       requiresStorageNotLow: false,
  //     ),
  //   );
  // } catch (e) {
  //   print('⚠️ [MAIN] Workmanager initialization failed: $e');
  //   print('⚠️ [MAIN] Background step syncing will not be available');
  // }
  
  // Initialize step counter service (will request permissions)
  // Don't await - let it initialize in background
  StepCounterService.initialize().then((success) {
    if (success) {
      print('✅ [MAIN] Step counter service initialized');
    } else {
      print('⚠️ [MAIN] Step counter service initialization failed - permissions may be needed');
    }
  });
  
  runApp(const CoTrainrApp());
}

class CoTrainrApp extends StatelessWidget {
  const CoTrainrApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: Consumer2<ThemeProvider, LanguageProvider>(
        builder: (context, themeProvider, languageProvider, _) {
          return MaterialApp(
            title: 'CoTrainr',
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.themeMode,
            theme: _buildLightTheme(),
            darkTheme: _buildDarkTheme(),
            locale: languageProvider.locale,
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en', 'US'),
              Locale('hi', 'IN'),
              Locale('bn', 'BD'),
              Locale('te', 'IN'),
              Locale('mr', 'IN'),
              Locale('ta', 'IN'),
              Locale('ur', 'PK'),
              Locale('gu', 'IN'),
              Locale('kn', 'IN'),
              Locale('or', 'IN'),
              Locale('pa', 'IN'),
              Locale('ml', 'IN'),
              Locale('as', 'IN'),
              Locale('ne', 'NP'),
              Locale('si', 'LK'),
              Locale('sa', 'IN'),
              Locale('kok', 'IN'),
              Locale('mai', 'IN'),
              Locale('mni', 'IN'),
              Locale('sat', 'IN'),
            ],
            // Force rebuild when locale changes
            key: ValueKey(languageProvider.locale.toString()),
            home: const SplashPage(),
            // Smooth theme transitions
            themeAnimationDuration: const Duration(milliseconds: 300),
            themeAnimationCurve: Curves.easeOutCubic,
          );
        },
      ),
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Poppins',
      colorScheme: ColorScheme.light(
        // Brand accent: Orange to Yellow gradient
        primary: const Color(0xFFFF7A00), // Orange
        secondary: const Color(0xFFFFC300), // Yellow
        tertiary: const Color(0xFF14B8A6), // Teal for secondary accents
        // Background: Very light warm neutral, not pure white
        background: const Color(0xFFF6F7FB), // Warm light grey
        // Surface: White with slight tint
        surface: const Color(0xFFFFFFFF),
        surfaceContainerHighest: const Color(0xFFF9FAFB), // Elevated surface
        // Text colors
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: const Color(0xFF1F2937), // Near black
        onBackground: const Color(0xFF1F2937),
        // Status colors
        error: const Color(0xFFEF4444),
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: const Color(0xFFF6F7FB), // Warm light background
      cardTheme: CardThemeData(
        elevation: 0, // No elevation, use shadow instead
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        color: const Color(0xFFFFFFFF),
        shadowColor: Colors.black.withOpacity(0.06),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF1F2937),
        titleTextStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1F2937),
          letterSpacing: -0.5,
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1F2937)),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1F2937),
          letterSpacing: -1,
          height: 1.2,
        ),
        displayMedium: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1F2937),
          letterSpacing: -0.5,
          height: 1.2,
        ),
        displaySmall: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1F2937),
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1F2937),
          letterSpacing: 0,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1F2937),
          letterSpacing: 0,
        ),
        titleMedium: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1F2937),
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: Color(0xFF4B5563),
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Color(0xFF4B5563),
          height: 1.5,
        ),
        bodySmall: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: Color(0xFF6B7280),
        ),
        labelLarge: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1F2937),
          letterSpacing: 0.5,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: const Color(0xFF14B8A6),
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 4,
        backgroundColor: const Color(0xFF14B8A6),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Poppins',
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        // Brand accent: Orange to Yellow gradient
        primary: Color(0xFFFF7A00), // Orange
        secondary: Color(0xFFFFC300), // Yellow
        tertiary: Color(0xFF14B8A6), // Teal for secondary accents
        // Background: Deep navy/charcoal, not pure black
        background: Color(0xFF0B1220), // Deep navy
        // Surface: Slightly lighter than background
        surface: Color(0xFF1F2937),
        surfaceContainerHighest: Color(0xFF2A3441), // Elevated surface
        // Text colors
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Color(0xFFF9FAFB), // Off white
        onBackground: Color(0xFFF9FAFB),
        // Status colors
        error: Color(0xFFEF4444),
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: const Color(0xFF0B1220), // Deep navy background
      cardTheme: CardThemeData(
        elevation: 0, // No elevation, use shadow instead
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        color: const Color(0xFF1F2937),
        shadowColor: Colors.black.withOpacity(0.4),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: Color(0xFFF9FAFB),
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: Color(0xFFF9FAFB),
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: Color(0xFFF9FAFB)),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: -1,
          height: 1.2,
        ),
        displayMedium: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: -0.5,
          height: 1.2,
        ),
        displaySmall: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: 0,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: 0,
        ),
        titleMedium: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: Color(0xFFD1D5DB),
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Color(0xFFD1D5DB),
          height: 1.5,
        ),
        bodySmall: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: Color(0xFF9CA3AF),
        ),
        labelLarge: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          // Use gradient for primary buttons (will be handled with ShaderMask)
          backgroundColor: const Color(0xFFFF7A00),
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 0,
        backgroundColor: const Color(0xFFFF7A00),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
