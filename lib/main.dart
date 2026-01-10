import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'services/database_service.dart';
import 'services/app_initialization.dart';
import 'services/theme_service.dart';
import 'theme/app_theme.dart';
import 'pages/splash_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Initialize Supabase first (before database service)
  if (SupabaseConfig.isConfigured) {
    try {
      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        anonKey: SupabaseConfig.supabaseAnonKey,
      );
      print('✅ Supabase initialized successfully');
    } catch (e) {
      print('❌ Error initializing Supabase: $e');
    }
  } else {
    print('⚠️ Supabase not configured. Please add credentials in lib/config/supabase_config.dart');
  }
  
  // Initialize database service
  await DatabaseService().initialize();
  
  // Initialize app services
  await AppInitialization.initializeApp();
  
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeService(),
      child: const CoTrainrApp(),
    ),
  );
}

class CoTrainrApp extends StatelessWidget {
  const CoTrainrApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return MaterialApp(
          title: 'CoTrainr',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme(),
          darkTheme: AppTheme.darkTheme(),
          themeMode: themeService.themeMode,
          home: const SplashPage(),
        );
      },
    );
  }
}
