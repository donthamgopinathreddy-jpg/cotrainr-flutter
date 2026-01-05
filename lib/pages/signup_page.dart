import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import '../widgets/wheel_picker.dart';
import '../main_navigation.dart';
import 'trainer_navigation.dart';
import 'nutritionist_navigation.dart';
import 'email_verification_page.dart';
import '../services/streak_service.dart';
import '../l10n/app_localizations.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  int _currentStep = 0;
  final PageController _pageController = PageController();

  // Step 1: Account
  final _step1FormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Step 2: Identity
  final _step2FormKey = GlobalKey<FormState>();
  final _userIdController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isCheckingUserId = false;
  String? _userIdStatus; // 'available', 'taken', null

  // Step 3: Personal
  final _dobDayController = TextEditingController();
  final _dobMonthController = TextEditingController();
  final _dobYearController = TextEditingController();
  String? _selectedGender;
  DateTime? _selectedDob;

  // Step 4: Height
  bool _heightUnitIsCm = true;
  int _heightCm = 170;
  int _heightFeet = 5;
  int _heightInches = 7;

  // Step 5: Weight
  bool _weightUnitIsKg = true;
  int _weightKg = 70;
  int _weightLb = 154;
  String? _selectedRole;
  int _trainerExperience = 0;
  List<String> _selectedCategories = [];

  // Categories with icons
  final List<Map<String, dynamic>> _categories = [
    {'label': 'Boxing', 'icon': Icons.sports_mma_rounded, 'value': 'boxing'},
    {'label': 'Strength', 'icon': Icons.fitness_center_rounded, 'value': 'strength'},
    {'label': 'Yoga', 'icon': Icons.self_improvement_rounded, 'value': 'yoga'},
    {'label': 'Mobility', 'icon': Icons.accessibility_new_rounded, 'value': 'mobility'},
    {'label': 'Zumba', 'icon': Icons.music_note_rounded, 'value': 'zumba'},
    {'label': 'Nutrition', 'icon': Icons.restaurant_rounded, 'value': 'nutrition'},
  ];

  bool _isCreating = false;
  Timer? _userIdCheckTimer;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _userIdController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _dobDayController.dispose();
    _dobMonthController.dispose();
    _dobYearController.dispose();
    _userIdCheckTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  // Password validation
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasNumber = false;
  bool _hasSpecialChar = false;
  bool _passwordsMatch = false;

  void _validatePassword(String password) {
    setState(() {
      _hasMinLength = password.length >= 8;
      _hasUppercase = password.contains(RegExp(r'[A-Z]'));
      _hasLowercase = password.contains(RegExp(r'[a-z]'));
      _hasNumber = password.contains(RegExp(r'[0-9]'));
      _hasSpecialChar = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
      _checkPasswordMatch();
    });
  }

  void _checkPasswordMatch() {
    setState(() {
      _passwordsMatch = _passwordController.text == _confirmPasswordController.text &&
          _confirmPasswordController.text.isNotEmpty;
    });
  }

  // User ID availability check (uses user_id from profiles table)
  Future<void> _checkUserIdAvailability(String userId) async {
    if (userId.isEmpty) {
      setState(() => _userIdStatus = null);
      return;
    }

    // Validate format
    final userIdRegex = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!userIdRegex.hasMatch(userId)) {
      setState(() => _userIdStatus = null);
      return;
    }

    setState(() => _isCheckingUserId = true);

    try {
      final supabase = Supabase.instance.client;
      // Check against user_id in profiles table (case-sensitive, unique)
      final response = await supabase
          .from('profiles')
          .select('user_id')
          .eq('user_id', userId)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _isCheckingUserId = false;
          _userIdStatus = response == null ? 'available' : 'taken';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingUserId = false;
          _userIdStatus = null;
        });
      }
    }
  }

  void _onUserIdChanged(String value) {
    _userIdCheckTimer?.cancel();
    _userIdCheckTimer = Timer(const Duration(milliseconds: 500), () {
      _checkUserIdAvailability(value);
    });
  }

  // Calculate age from DOB
  String? _calculateAge() {
    if (_selectedDob == null) return null;
    final now = DateTime.now();
    int years = now.year - _selectedDob!.year;
    int months = now.month - _selectedDob!.month;
    if (months < 0) {
      years--;
      months += 12;
    }
    return '$years years, $months months';
  }

  // Height conversion
  void _updateHeightFromFeetInches() {
    _heightCm = ((_heightFeet * 12) + _heightInches) * 2.54.round();
  }

  void _updateFeetInchesFromCm() {
    final totalInches = (_heightCm / 2.54).round();
    _heightFeet = totalInches ~/ 12;
    _heightInches = totalInches % 12;
  }

  // Weight conversion
  void _updateWeightFromLb() {
    _weightKg = (_weightLb * 0.453592).round();
  }

  void _updateLbFromKg() {
    _weightLb = (_weightKg * 2.20462).round();
  }

  // Navigation
  void _nextStep() {
    // Validate form if it's step 1
    if (_currentStep == 0 && _step1FormKey.currentState != null) {
      if (!_step1FormKey.currentState!.validate()) {
        HapticFeedback.selectionClick();
        return;
      }
    }
    
    // Validate form if it's step 2
    if (_currentStep == 1 && _step2FormKey.currentState != null) {
      if (!_step2FormKey.currentState!.validate()) {
        HapticFeedback.selectionClick();
        return;
      }
    }
    
    if (_validateCurrentStep()) {
      HapticFeedback.lightImpact();
      if (_currentStep < 4) {
        setState(() => _currentStep++);
        _pageController.nextPage(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
        );
      } else {
        _createAccount();
      }
    } else {
      HapticFeedback.selectionClick();
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_getValidationErrorMessage()),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  String _getValidationErrorMessage() {
    switch (_currentStep) {
      case 0:
        if (_emailController.text.isEmpty) {
          return 'Email is required';
        }
        if (_passwordController.text.isEmpty) {
          return 'Password is required';
        }
        if (_confirmPasswordController.text.isEmpty) {
          return 'Please confirm your password';
        }
        if (!_passwordsMatch) {
          return 'Passwords do not match';
        }
        return 'Please complete all password requirements';
      case 1:
        if (_userIdController.text.isEmpty) {
          return 'User ID is required';
        }
        if (_userIdStatus != 'available') {
          return 'Please choose an available User ID';
        }
        if (_firstNameController.text.isEmpty) {
          return 'First name is required';
        }
        if (_lastNameController.text.isEmpty) {
          return 'Last name is required';
        }
        if (_phoneController.text.length != 10) {
          return 'Please enter a valid 10 digit mobile number';
        }
        return 'Please complete all fields';
      case 2:
        if (_selectedDob == null) {
          return 'Please enter your date of birth';
        }
        if (_selectedGender == null) {
          return 'Please select your gender';
        }
        return 'Please complete all fields';
      case 4:
        if (_selectedRole == null) {
          return 'Please select your role';
        }
        if ((_selectedRole == 'trainer' || _selectedRole == 'nutritionist') && _selectedCategories.isEmpty) {
          return 'Please select at least one category';
        }
        return 'Please complete all fields';
      default:
        return 'Please complete all required fields';
    }
  }

  void _previousStep() {
    HapticFeedback.lightImpact();
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        if (_emailController.text.isEmpty ||
            _passwordController.text.isEmpty ||
            _confirmPasswordController.text.isEmpty) {
          return false;
        }
        if (!_hasMinLength ||
            !_hasUppercase ||
            !_hasLowercase ||
            !_hasNumber ||
            !_hasSpecialChar) {
          return false;
        }
        if (!_passwordsMatch) {
          return false;
        }
        return true;
      case 1:
        if (_userIdController.text.isEmpty ||
            _firstNameController.text.isEmpty ||
            _lastNameController.text.isEmpty ||
            _phoneController.text.length != 10) {
          return false;
        }
        if (_userIdStatus != 'available') {
          return false;
        }
        return true;
      case 2:
        if (_selectedDob == null || _selectedGender == null) {
          return false;
        }
        return true;
      case 3:
        return true; // Height always valid
      case 4:
        if (_selectedRole == null) {
          return false;
        }
        if ((_selectedRole == 'trainer' || _selectedRole == 'nutritionist') && _selectedCategories.isEmpty) {
          return false;
        }
        return true;
      default:
        return false;
    }
  }

  Future<void> _createAccount() async {
    if (!_validateCurrentStep()) {
      HapticFeedback.selectionClick();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_getValidationErrorMessage()),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    setState(() => _isCreating = true);
    HapticFeedback.mediumImpact();

    try {
      print('🔵 [SIGNUP] Starting account creation...');
      final supabase = Supabase.instance.client;

      print('🔵 [SIGNUP] Email: ${_emailController.text.trim()}');
      print('🔵 [SIGNUP] User ID: ${_userIdController.text.trim()}');
      print('🔵 [SIGNUP] Role: $_selectedRole');

      // Create auth user
      print('🔵 [SIGNUP] Creating auth user...');
      late AuthResponse authResponse;
      try {
        authResponse = await supabase.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          data: {
            // Optional metadata (not used by trigger, but can be useful)
            'user_id': _userIdController.text.trim(),
          },
        );
      } catch (signupError) {
        print('❌ [SIGNUP] SignUp call failed: $signupError');
        print('❌ [SIGNUP] Error type: ${signupError.runtimeType}');
        print('❌ [SIGNUP] Full error: ${signupError.toString()}');
        
        // Check if it's a database trigger error
        final errorString = signupError.toString().toLowerCase();
        if (errorString.contains('database error') || 
            errorString.contains('trigger') ||
            errorString.contains('unexpected_failure')) {
          // The user might have been created but trigger failed
          // Try to get the current user
          await Future.delayed(const Duration(milliseconds: 1000));
          final currentUser = supabase.auth.currentUser;
          if (currentUser != null) {
            print('⚠️ [SIGNUP] User created but trigger failed, signing in...');
            // Try to sign in to get a proper auth response
            try {
              authResponse = await supabase.auth.signInWithPassword(
                email: _emailController.text.trim(),
                password: _passwordController.text,
              );
            } catch (signInError) {
              throw Exception(
                'Database error during signup. User may have been created but profile setup failed. '
                'Please try logging in or contact support.'
              );
            }
          } else {
            throw Exception(
              'Database error during signup. This might be due to a database trigger issue. '
              'Please contact support or try again later.'
            );
          }
        } else {
          rethrow;
        }
      }

      print('🔵 [SIGNUP] Auth response received');
      print('🔵 [SIGNUP] User: ${authResponse.user?.id ?? "null"}');
      print('🔵 [SIGNUP] Session: ${authResponse.session != null ? "exists" : "null"}');

      if (authResponse.user == null) {
        String errorMsg = 'Failed to create account';
        if (authResponse.session == null) {
          errorMsg = 'Account creation failed. Please check your email and try again.';
        }
        print('❌ [SIGNUP] Auth user creation failed: $errorMsg');
        throw Exception(errorMsg);
      }

      print('✅ [SIGNUP] Auth user created: ${authResponse.user!.id}');

      // Get user ID from auth response
      final userId = authResponse.user!.id;

      // Note: If session is null, email confirmation is required
      // We'll handle this after profile creation by navigating to verification page

      // Prepare profile data with all fields
      // Note: display_name is auto-generated by database (first_name + last_name)
      // Note: BMI is auto-calculated by database trigger when height/weight are set
      final profileData = {
        'id': userId,
        'user_id': _userIdController.text.trim(), // Searchable user ID for login
        'email': _emailController.text.trim().toLowerCase(),
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'phone': '+91${_phoneController.text.trim()}',
        'role': _selectedRole,
        'category': _selectedCategories.isNotEmpty 
            ? _selectedCategories.first 
            : 'general', // Primary category
        'categories': _selectedCategories, // All selected categories
        'height_cm': _heightCm,
        'weight_kg': _weightKg,
        'dob': _selectedDob != null ? _selectedDob!.toIso8601String().split('T')[0] : null, // Date of birth (YYYY-MM-DD)
        'gender': _selectedGender, // Gender (male, female, other, prefer_not_to_say)
        // BMI and bmi_status will be auto-calculated by database trigger
        'avatar_path': null, // Will be set when user uploads avatar
        'cover_path': null, // Will be set when user uploads cover
      };

      print('🔵 [SIGNUP] Inserting profile with data: $profileData');
      
      // Try to insert profile directly first (if session exists)
      // If that fails due to RLS, use the database function
      try {
        await supabase.from('profiles').insert(profileData);
        print('✅ [SIGNUP] Profile inserted successfully');
      } catch (profileError) {
        print('⚠️ [SIGNUP] Direct insert failed, trying via function: $profileError');
        
        // If it's an RLS error, use the database function
        if (profileError.toString().contains('row-level security') || 
            profileError.toString().contains('42501')) {
          try {
            await supabase.rpc('create_user_profile', params: {
              'p_id': userId,
              'p_user_id': _userIdController.text.trim(),
              'p_email': _emailController.text.trim().toLowerCase(),
              'p_first_name': _firstNameController.text.trim(),
              'p_last_name': _lastNameController.text.trim(),
              'p_phone': '+91${_phoneController.text.trim()}',
              'p_role': _selectedRole,
              'p_category': _selectedCategories.isNotEmpty ? _selectedCategories.first : 'general',
              'p_categories': _selectedCategories,
              'p_height_cm': _heightCm,
              'p_weight_kg': _weightKg,
              'p_dob': _selectedDob != null ? _selectedDob!.toIso8601String().split('T')[0] : null,
              'p_gender': _selectedGender,
              'p_avatar_path': null,
              'p_cover_path': null,
            });
            print('✅ [SIGNUP] Profile inserted successfully via function');
          } catch (functionError) {
            print('❌ [SIGNUP] Function insert also failed: $functionError');
            // Check for unique constraint violations
            if (functionError.toString().contains('duplicate key') && 
                functionError.toString().contains('user_id')) {
              throw Exception('The chosen username is already taken. Please go back and choose another.');
            }
            if (functionError.toString().contains('duplicate key') && 
                functionError.toString().contains('email')) {
              throw Exception('An account with this email already exists.');
            }
            rethrow;
          }
        } else {
          // If it's a unique constraint violation on user_id, the username is taken
          if (profileError.toString().contains('duplicate key value violates unique constraint') &&
              (profileError.toString().contains('user_id') || profileError.toString().contains('profiles_user_id_unique'))) {
            throw Exception('The chosen username is already taken. Please go back and choose another.');
          }
          // If it's a unique constraint violation on email
          if (profileError.toString().contains('duplicate key value violates unique constraint') &&
              (profileError.toString().contains('email') || profileError.toString().contains('profiles_email_unique'))) {
            throw Exception('An account with this email already exists.');
          }
          rethrow;
        }
      }

      // If trainer, create trainer_profiles entry
      if (_selectedRole == 'trainer') {
        print('🔵 [SIGNUP] Creating trainer profile...');
        try {
          await supabase.from('trainer_profiles').insert({
            'user_id': userId,
            'years_experience': _trainerExperience,
            'specialties': _selectedCategories,
            'verified': false,
          });
          print('✅ [SIGNUP] Trainer profile created');
        } catch (trainerError) {
          print('❌ [SIGNUP] Trainer profile creation failed: $trainerError');
          // Don't fail signup if trainer profile creation fails
          print('⚠️ [SIGNUP] Continuing despite trainer profile error...');
        }
      }
      
      // If nutritionist, create nutritionist_profiles entry (if table exists)
      if (_selectedRole == 'nutritionist') {
        print('🔵 [SIGNUP] Creating nutritionist profile...');
        try {
          // Try to insert into nutritionist_profiles if table exists
          // If table doesn't exist yet, this will fail silently
          await supabase.from('nutritionist_profiles').insert({
            'user_id': userId,
            'years_experience': _trainerExperience,
            'specialties': _selectedCategories,
            'verified': false,
          });
          print('✅ [SIGNUP] Nutritionist profile created');
        } catch (nutritionistError) {
          print('⚠️ [SIGNUP] Nutritionist profile creation failed (table may not exist yet): $nutritionistError');
          // Don't fail signup if nutritionist profile creation fails
          print('⚠️ [SIGNUP] Continuing despite nutritionist profile error...');
        }
      }

      // Success
      if (mounted) {
        // Check if email confirmation is required (session is null)
        // Use authResponse.session, not currentSession (which might be a different user)
        final session = authResponse.session;
        final email = _emailController.text.trim();
        
        if (session == null) {
          // Email confirmation required - navigate to verification page
          print('🔵 [SIGNUP] Email confirmation required, navigating to verification page');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => EmailVerificationPage(email: email),
            ),
          );
        } else {
          // Session exists - user is already verified, proceed to app
          print('✅ [SIGNUP] Session exists, user is verified');
          
          // Record first login for streak
          try {
            await StreakService.recordLogin();
          } catch (e) {
            print('Error recording initial login: $e');
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Account created, welcome to CoTrainr'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              behavior: SnackBarBehavior.floating,
            ),
          );

          // Navigate based on role
          if (_selectedRole == 'trainer') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const TrainerNavigation(),
              ),
            );
          } else if (_selectedRole == 'nutritionist') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const NutritionistNavigation(),
              ),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const MainNavigation(),
              ),
            );
          }
        }
      }
    } catch (e, stackTrace) {
      print('❌ [SIGNUP] Error occurred: $e');
      print('❌ [SIGNUP] Stack trace: $stackTrace');
      
      if (mounted) {
        String errorMessage = 'Failed to create account';
        
        // Parse Supabase errors
        final errorString = e.toString().toLowerCase();
        
        if (errorString.contains('user already registered') || 
            errorString.contains('already registered')) {
          errorMessage = 'An account with this email already exists';
        } else if (errorString.contains('invalid email') || 
                   errorString.contains('email format')) {
          errorMessage = 'Please enter a valid email address';
        } else if (errorString.contains('password')) {
          errorMessage = 'Password does not meet requirements';
        } else if (errorString.contains('duplicate key') || 
                   errorString.contains('unique constraint')) {
          errorMessage = 'Username or email already exists';
        } else if (errorString.contains('foreign key') || 
                   errorString.contains('constraint')) {
          errorMessage = 'Database error. Please try again.';
        } else if (errorString.contains('network') || 
                   errorString.contains('connection')) {
          errorMessage = 'Network error. Please check your connection.';
        } else if (e.toString().isNotEmpty) {
          // Show the actual error message for debugging
          errorMessage = e.toString()
              .replaceAll('Exception: ', '')
              .replaceAll('PostgrestException: ', '')
              .replaceAll('AuthException: ', '');
          
          // Limit error message length
          if (errorMessage.length > 100) {
            errorMessage = '${errorMessage.substring(0, 100)}...';
          }
        }
        
        print('❌ [SIGNUP] Showing error to user: $errorMessage');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Account Creation Failed',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  errorMessage,
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
      HapticFeedback.selectionClick();
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: _previousStep,
              )
            : IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
        title: Text(
          '${l10n?.step ?? 'Step'} ${_currentStep + 1} ${l10n?.stepOf ?? 'of'} 5',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: Container(
            height: 4,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (_currentStep + 1) / 5,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colorScheme.primary, colorScheme.secondary],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildStep1(colorScheme, isDark, l10n),
          _buildStep2(colorScheme, isDark, l10n),
          _buildStep3(colorScheme, isDark, l10n),
          _buildStep4(colorScheme, isDark, l10n),
          _buildStep5(colorScheme, isDark, l10n),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: _AnimatedButton(
            onPressed: _isCreating ? null : _nextStep,
            isLoading: _isCreating,
            text: _currentStep == 4 ? (l10n?.createAccount ?? 'Create Account') : (l10n?.next ?? 'Next'),
            colorScheme: colorScheme,
          ),
        ),
      ),
    );
  }

  // Step 1: Account (Email and Password only)
  Widget _buildStep1(ColorScheme colorScheme, bool isDark, AppLocalizations? l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Form(
        key: _step1FormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            // Title Section
            Text(
              l10n?.createAccount ?? 'Create Account',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n?.joinUs ?? 'Join us and start your fitness journey',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 15,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 40),
            
            // Email
            _buildModernInput(
              label: l10n?.email ?? 'Email',
              controller: _emailController,
              colorScheme: colorScheme,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              prefixIcon: Icons.email_outlined,
              validator: (value) {
                if (value == null || value.isEmpty) return l10n?.required ?? 'Required';
                if (!value.contains('@') || !value.contains('.')) return l10n?.invalidEmail ?? 'Please enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 24),
            
            // Password
            _buildModernInput(
              label: l10n?.password ?? 'Password',
              controller: _passwordController,
              colorScheme: colorScheme,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.next,
              prefixIcon: Icons.lock_outline_rounded,
              onChanged: (_) {
                HapticFeedback.selectionClick();
                _validatePassword(_passwordController.text);
              },
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return l10n?.required ?? 'Required';
                if (!_hasMinLength || !_hasUppercase || !_hasLowercase || !_hasNumber || !_hasSpecialChar) {
                  return 'Password does not meet requirements';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Horizontal Password Checklist
            _buildHorizontalPasswordChecklist(colorScheme),
            const SizedBox(height: 24),
            
            // Confirm Password
            _buildModernInput(
              label: l10n?.confirmPassword ?? 'Confirm Password',
              controller: _confirmPasswordController,
              colorScheme: colorScheme,
              obscureText: _obscureConfirmPassword,
              textInputAction: TextInputAction.done,
              prefixIcon: Icons.lock_outline_rounded,
              onChanged: (_) {
                HapticFeedback.selectionClick();
                _checkPasswordMatch();
              },
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                onPressed: () {
                  setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                },
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Please confirm your password';
                if (value != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
            // Password match indicator
            if (_confirmPasswordController.text.isNotEmpty) ...[
              const SizedBox(height: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _passwordsMatch
                    ? Row(
                        key: const ValueKey('match'),
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            size: 16,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Passwords match',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        key: const ValueKey('no-match'),
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            size: 16,
                            color: Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Passwords do not match',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  String _getHintText(String label) {
    switch (label.toLowerCase()) {
      case 'email':
        return 'alex@example.com';
      case 'username':
      case 'user id':
        return 'cotrainr_alex';
      case 'password':
        return 'Enter your password';
      case 'confirm password':
        return 'Confirm your password';
      case 'first name':
        return 'Enter your first name';
      case 'last name':
        return 'Enter your last name';
      case 'phone number':
      case 'phone':
        return 'e.g. 9876543210';
      default:
        return 'Enter your ${label.toLowerCase()}';
    }
  }

  Widget _buildModernInput({
    required String label,
    required TextEditingController controller,
    required ColorScheme colorScheme,
    bool obscureText = false,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    IconData? prefixIcon,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface.withValues(alpha: 0.6),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            textCapitalization: textCapitalization,
            onChanged: onChanged,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              prefixIcon: prefixIcon != null
                  ? Icon(
                      prefixIcon,
                      color: colorScheme.onSurface.withValues(alpha: 0.4),
                      size: 20,
                    )
                  : null,
              suffixIcon: suffixIcon,
              hintText: _getHintText(label),
              hintStyle: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.4),
                fontWeight: FontWeight.normal,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
            ),
            validator: validator,
          ),
        ),
      ],
    );
  }

  // Step 2: Profile (User ID, First Name, Last Name, Phone)
  Widget _buildStep2(ColorScheme colorScheme, bool isDark, AppLocalizations? l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _step2FormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            // Title Section
            Text(
              'Create your profile',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose a unique username and add your details.',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 15,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 40),
            
            // User ID with new availability checker design
            _buildUserIdInput(colorScheme),
            const SizedBox(height: 24),
            
            // First Name
            _buildModernInput(
              label: 'First Name',
              controller: _firstNameController,
              colorScheme: colorScheme,
              textInputAction: TextInputAction.next,
              prefixIcon: Icons.person_outline_rounded,
              textCapitalization: TextCapitalization.words,
              onChanged: (value) {
                HapticFeedback.selectionClick();
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'First name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            
            // Last Name
            _buildModernInput(
              label: 'Last Name',
              controller: _lastNameController,
              colorScheme: colorScheme,
              textInputAction: TextInputAction.next,
              prefixIcon: Icons.person_outline_rounded,
              textCapitalization: TextCapitalization.words,
              onChanged: (value) {
                HapticFeedback.selectionClick();
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Last name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            
            // Phone Number
            Text(
              'PHONE NUMBER',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.onSurface.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                  child: const Text(
                    '+91',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      maxLength: 10,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: 'e.g. 9876543210',
                        hintStyle: TextStyle(
                          color: colorScheme.onSurface.withValues(alpha: 0.4),
                          fontWeight: FontWeight.normal,
                        ),
                        counterText: '',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Phone number is required';
                        }
                        if (value.length != 10) {
                          return 'Enter a valid 10 digit mobile number';
                        }
                        return null;
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Step 3: Personal
  Widget _buildStep3(ColorScheme colorScheme, bool isDark, AppLocalizations? l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal Details',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Date of birth and gender',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 32),
          // Date of Birth
          Text(
            'Date of Birth',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildDateInput(
                  controller: _dobDayController,
                  hint: 'DD',
                  colorScheme: colorScheme,
                  isDark: isDark,
                  maxLength: 2,
                  onChanged: (value) {
                    if (value.length == 2) {
                      FocusScope.of(context).nextFocus();
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDateInput(
                  controller: _dobMonthController,
                  hint: 'MM',
                  colorScheme: colorScheme,
                  isDark: isDark,
                  maxLength: 2,
                  onChanged: (value) {
                    if (value.length == 2) {
                      FocusScope.of(context).nextFocus();
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: _buildDateInput(
                  controller: _dobYearController,
                  hint: 'YYYY',
                  colorScheme: colorScheme,
                  isDark: isDark,
                  maxLength: 4,
                  onChanged: (value) {
                    if (value.length == 4) {
                      _validateAndSetDob();
                    }
                  },
                ),
              ),
            ],
          ),
          if (_calculateAge() != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Age: ${_calculateAge()}',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: colorScheme.primary,
                ),
              ),
            ),
          const SizedBox(height: 32),
          // Gender
          Text(
            'Gender',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildGenderChip(
                  'Male',
                  Icons.person_rounded,
                  'male',
                  colorScheme,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildGenderChip(
                  'Female',
                  Icons.person_outline_rounded,
                  'female',
                  colorScheme,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildGenderChip(
                  'Other',
                  Icons.diversity_3_rounded,
                  'other',
                  colorScheme,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _validateAndSetDob() {
    final day = int.tryParse(_dobDayController.text);
    final month = int.tryParse(_dobMonthController.text);
    final year = int.tryParse(_dobYearController.text);

    if (day != null && month != null && year != null) {
      try {
        final dob = DateTime(year, month, day);
        if (dob.isBefore(DateTime.now())) {
          setState(() => _selectedDob = dob);
        }
      } catch (e) {
        // Invalid date
      }
    }
  }

  Widget _buildGenderChip(
    String label,
    IconData icon,
    String value,
    ColorScheme colorScheme,
  ) {
    final isSelected = _selectedGender == value;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedGender = value);
        HapticFeedback.selectionClick();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.1)
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurface.withValues(alpha: 0.7),
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Step 4: Height
  Widget _buildStep4(ColorScheme colorScheme, bool isDark, AppLocalizations? l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Height',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select your height',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 32),
          // Unit toggle
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _heightUnitIsCm = true;
                        _updateFeetInchesFromCm();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _heightUnitIsCm
                            ? colorScheme.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'cm',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _heightUnitIsCm
                              ? colorScheme.onPrimary
                              : colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _heightUnitIsCm = false;
                        _updateHeightFromFeetInches();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !_heightUnitIsCm
                            ? colorScheme.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'ft in',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: !_heightUnitIsCm
                              ? colorScheme.onPrimary
                              : colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Wheel picker
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: _heightUnitIsCm
                ? WheelPicker(
                    key: const ValueKey('cm'),
                    min: 120,
                    max: 220,
                    value: _heightCm,
                    onChanged: (value) {
                      HapticFeedback.selectionClick();
                      setState(() => _heightCm = value);
                    },
                    suffix: ' cm',
                  )
                : Row(
                    key: const ValueKey('ftin'),
                    children: [
                      Expanded(
                        child: WheelPicker(
                          min: 4,
                          max: 7,
                          value: _heightFeet,
                          onChanged: (value) {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _heightFeet = value;
                              _updateHeightFromFeetInches();
                            });
                          },
                          suffix: ' ft',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: WheelPicker(
                          min: 0,
                          max: 11,
                          value: _heightInches,
                          onChanged: (value) {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _heightInches = value;
                              _updateHeightFromFeetInches();
                            });
                          },
                          suffix: ' in',
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // Step 5: Weight + Role + Categories
  Widget _buildStep5(ColorScheme colorScheme, bool isDark, AppLocalizations? l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weight & Role',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select your weight and role',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 32),
          // Weight unit toggle
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _weightUnitIsKg = true;
                        _updateLbFromKg();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _weightUnitIsKg
                            ? colorScheme.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'kg',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _weightUnitIsKg
                              ? colorScheme.onPrimary
                              : colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _weightUnitIsKg = false;
                        _updateWeightFromLb();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !_weightUnitIsKg
                            ? colorScheme.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'lb',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: !_weightUnitIsKg
                              ? colorScheme.onPrimary
                              : colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Weight wheel picker
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: _weightUnitIsKg
                ? WheelPicker(
                    key: const ValueKey('kg'),
                    min: 30,
                    max: 180,
                    value: _weightKg,
                    onChanged: (value) {
                      HapticFeedback.selectionClick();
                      setState(() => _weightKg = value);
                    },
                    suffix: ' kg',
                  )
                : WheelPicker(
                    key: const ValueKey('lb'),
                    min: 66,
                    max: 400,
                    value: _weightLb,
                    onChanged: (value) {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _weightLb = value;
                        _updateWeightFromLb();
                      });
                    },
                    suffix: ' lb',
                  ),
          ),
          const SizedBox(height: 48),
          // Role selector
          Text(
            'Role',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildRoleChip('Client', 'client', colorScheme),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildRoleChip('Trainer', 'trainer', colorScheme),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildRoleChip('Nutritionist', 'nutritionist', colorScheme),
              ),
            ],
          ),
          if (_selectedRole == 'trainer' || _selectedRole == 'nutritionist') ...[
            const SizedBox(height: 32),
            Text(
              'Years of Experience',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            WheelPicker(
              min: 0,
              max: 20,
              value: _trainerExperience,
              onChanged: (value) {
                setState(() => _trainerExperience = value);
              },
              suffix: ' years',
            ),
            const SizedBox(height: 32),
            Text(
              'Categories',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _categories.map((category) {
                final isSelected =
                    _selectedCategories.contains(category['value']);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedCategories.remove(category['value']);
                      } else {
                        _selectedCategories.add(category['value'] as String);
                      }
                    });
                    HapticFeedback.selectionClick();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primary.withValues(alpha: 0.1)
                          : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSelected
                            ? colorScheme.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          category['icon'],
                          size: 20,
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          category['label'],
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRoleChip(String label, String value, ColorScheme colorScheme) {
    final isSelected = _selectedRole == value;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedRole = value);
        HapticFeedback.selectionClick();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.1)
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? colorScheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? colorScheme.primary
                : colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }

  Widget _buildDateInput({
    required TextEditingController controller,
    required String hint,
    required ColorScheme colorScheme,
    required bool isDark,
    int? maxLength,
    void Function(String)? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: maxLength,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: onChanged,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 16,
          color: colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: colorScheme.onSurface.withValues(alpha: 0.4),
          ),
          counterText: '',
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }

  // Horizontal Password Checklist
  Widget _buildHorizontalPasswordChecklist(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        alignment: WrapAlignment.start,
        children: [
          _buildSmallPasswordCheck('8+', _hasMinLength, colorScheme),
          _buildSmallPasswordCheck('A-Z', _hasUppercase, colorScheme),
          _buildSmallPasswordCheck('a-z', _hasLowercase, colorScheme),
          _buildSmallPasswordCheck('0-9', _hasNumber, colorScheme),
          _buildSmallPasswordCheck('!@#', _hasSpecialChar, colorScheme),
        ],
      ),
    );
  }

  Widget _buildSmallPasswordCheck(String label, bool isValid, ColorScheme colorScheme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isValid 
            ? Colors.green.withValues(alpha: 0.15)
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isValid 
              ? Colors.green.withValues(alpha: 0.5)
              : colorScheme.onSurface.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              isValid ? Icons.check_rounded : Icons.close_rounded,
              key: ValueKey(isValid),
              size: 14,
              color: isValid ? Colors.green : colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isValid
                  ? Colors.green
                  : colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  // New User ID Input with redesigned availability checker
  Widget _buildUserIdInput(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'USER ID',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface.withValues(alpha: 0.6),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: _userIdController,
            textInputAction: TextInputAction.next,
            onChanged: _onUserIdChanged,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(
                Icons.alternate_email_rounded,
                color: colorScheme.onSurface.withValues(alpha: 0.4),
                size: 20,
              ),
              suffixIcon: _buildUserIdAvailabilityIndicator(colorScheme),
              hintText: 'cotrainr_alex',
              hintStyle: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.4),
                fontWeight: FontWeight.normal,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'User ID is required';
              }
              if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                return 'Only letters, numbers, and underscore allowed';
              }
              if (_userIdStatus == 'taken') {
                return 'This User ID is already taken';
              }
              if (_userIdStatus != 'available' && value.isNotEmpty) {
                return 'Please wait for availability check';
              }
              return null;
            },
          ),
        ),
        // Availability status below input
        if (_userIdController.text.isNotEmpty) ...[
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _isCheckingUserId
                ? Row(
                    key: const ValueKey('checking'),
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Checking availability...',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  )
                : _userIdStatus == 'available'
                    ? Row(
                        key: const ValueKey('available'),
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check_rounded,
                              size: 12,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Available',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      )
                    : _userIdStatus == 'taken'
                        ? Row(
                            key: const ValueKey('taken'),
                            children: [
                              Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 12,
                                  color: Colors.red,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Already taken',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          )
                        : const SizedBox.shrink(),
          ),
        ],
      ],
    );
  }

  Widget _buildUserIdAvailabilityIndicator(ColorScheme colorScheme) {
    if (_isCheckingUserId) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              colorScheme.primary,
            ),
          ),
        ),
      );
    }
    
    if (_userIdStatus == 'available') {
      return Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_rounded,
            size: 16,
            color: Colors.green,
          ),
        ),
      );
    }
    
    if (_userIdStatus == 'taken') {
      return Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.close_rounded,
            size: 16,
            color: Colors.red,
          ),
        ),
      );
    }
    
    return const SizedBox.shrink();
  }

}

// Animated Button with scale effect
class _AnimatedButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String text;
  final ColorScheme colorScheme;

  const _AnimatedButton({
    required this.onPressed,
    required this.isLoading,
    required this.text,
    required this.colorScheme,
  });

  @override
  State<_AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        if (widget.onPressed != null && !widget.isLoading) {
          _controller.forward();
        }
      },
      onTapUp: (_) {
        _controller.reverse();
        if (widget.onPressed != null && !widget.isLoading) {
          widget.onPressed!();
        }
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: widget.onPressed != null
                ? LinearGradient(
                    colors: [widget.colorScheme.primary, widget.colorScheme.secondary],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : null,
            color: widget.onPressed == null
                ? widget.colorScheme.onSurface.withValues(alpha: 0.1)
                : null,
            borderRadius: BorderRadius.circular(18),
            boxShadow: widget.onPressed != null
                ? [
                    BoxShadow(
                      color: widget.colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: widget.isLoading
              ? Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        widget.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                )
              : Center(
                  child: Text(
                    widget.text,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: widget.onPressed != null
                          ? widget.colorScheme.onPrimary
                          : widget.colorScheme.onSurface.withValues(alpha: 0.5),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

