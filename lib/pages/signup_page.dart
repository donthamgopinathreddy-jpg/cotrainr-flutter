import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main_navigation.dart';
import 'dart:math' as math;

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  
  // Step 1: Account
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  // Step 2: Identity
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _userIdController = TextEditingController();
  bool _userIdAvailable = false;
  bool _checkingUserId = false;
  
  // Step 3: Phone + Category
  final _phoneController = TextEditingController();
  String? _selectedCategory;
  
  // Step 4: Body Metrics
  double _heightCm = 170.0;
  double _weightKg = 70.0;
  bool _useMetric = true;
  
  // Step 5: Role
  String? _selectedRole;
  int? _yearsExperience;
  List<String> _selectedSpecialties = [];
  
  final List<String> _categories = [
    'Fat loss',
    'Muscle gain',
    'Strength',
    'Boxing',
    'Yoga',
    'Running',
    'Rehab',
  ];
  
  bool _isSubmitting = false;

  @override
  void dispose() {
    _pageController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _userIdController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _checkUserIdAvailability(String userId) async {
    if (userId.length < 3) {
      setState(() {
        _userIdAvailable = false;
        _checkingUserId = false;
      });
      return;
    }

    setState(() => _checkingUserId = true);

    try {
      await Future.delayed(const Duration(milliseconds: 500)); // Debounce
      
      final response = await Supabase.instance.client
          .from('profiles')
          .select('user_id_handle')
          .eq('user_id_handle', userId.toLowerCase())
          .maybeSingle();

      setState(() {
        _userIdAvailable = response == null;
        _checkingUserId = false;
      });
    } catch (e) {
      setState(() {
        _userIdAvailable = false;
        _checkingUserId = false;
      });
    }
  }

  bool _validateStep(int step) {
    switch (step) {
      case 0:
        if (_emailController.text.isEmpty || !_emailController.text.contains('@')) {
          return false;
        }
        if (_passwordController.text.length < 8) return false;
        if (_passwordController.text != _confirmPasswordController.text) return false;
        return _validatePassword(_passwordController.text);
      case 1:
        return _firstNameController.text.isNotEmpty &&
            _lastNameController.text.isNotEmpty &&
            _userIdController.text.length >= 3 &&
            _userIdAvailable;
      case 2:
        return _phoneController.text.length >= 10 && _selectedCategory != null;
      case 3:
        return true; // Always valid, has defaults
      case 4:
        if (_selectedRole == null) return false;
        if ((_selectedRole == 'Trainer' || _selectedRole == 'Nutritionist') &&
            (_yearsExperience == null || _selectedSpecialties.isEmpty)) {
          return false;
        }
        return true;
      default:
        return false;
    }
  }

  bool _validatePassword(String password) {
    return password.length >= 8 &&
        password.contains(RegExp(r'[A-Z]')) &&
        password.contains(RegExp(r'[a-z]')) &&
        password.contains(RegExp(r'[0-9]')) &&
        password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
  }

  void _nextStep() {
    if (_validateStep(_currentStep)) {
      if (_currentStep < 4) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        setState(() => _currentStep++);
      } else {
        _submitSignup();
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    }
  }

  Future<void> _submitSignup() async {
    setState(() => _isSubmitting = true);

    try {
      // Calculate BMI
      final bmi = _weightKg / math.pow(_heightCm / 100, 2);
      String bmiStatus;
      if (bmi < 18.5) {
        bmiStatus = 'underweight';
      } else if (bmi < 25) {
        bmiStatus = 'normal';
      } else if (bmi < 30) {
        bmiStatus = 'overweight';
      } else {
        bmiStatus = 'obese';
      }

      // Create auth account
      final authResponse = await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (authResponse.user == null) {
        throw Exception('Failed to create account');
      }

      // Create profile
      await Supabase.instance.client.from('profiles').insert({
        'user_id': authResponse.user!.id,
        'user_id_handle': _userIdController.text.toLowerCase(),
        'email': _emailController.text.trim(),
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'display_name': '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
        'phone': _phoneController.text.trim(),
        'role': _selectedRole!.toLowerCase(),
        'category_preferences': [_selectedCategory],
        'height': _heightCm,
        'weight': _weightKg,
        'bmi': bmi,
        'bmi_status': bmiStatus,
        'years_experience': _yearsExperience,
        'specialties': _selectedSpecialties,
        'subscription_plan': 'free',
      });

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainNavigation()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Signup failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF111827) : const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? Colors.white : const Color(0xFF1F2937),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Step ${_currentStep + 1} of 5',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF1F2937),
          ),
        ),
      ),
      body: Column(
        children: [
          // Progress indicator
          _buildProgressIndicator(),
          
          // Page content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep1Account(),
                _buildStep2Identity(),
                _buildStep3PhoneCategory(),
                _buildStep4BodyMetrics(),
                _buildStep5Role(),
              ],
            ),
          ),
          
          // Navigation buttons
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: List.generate(5, (index) {
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: index < 4 ? 8 : 0),
              height: 4,
              decoration: BoxDecoration(
                color: index <= _currentStep
                    ? const Color(0xFFFF7A00)
                    : Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStep1Account() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final password = _passwordController.text;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Create Account',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Set up your email and password',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 32),
          
          // Email
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || !value.contains('@')) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Password
          TextFormField(
            controller: _passwordController,
            obscureText: true,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          
          // Password rules checklist
          _buildPasswordRules(password),
          const SizedBox(height: 16),
          
          // Confirm Password
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              prefixIcon: const Icon(Icons.lock_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordRules(String password) {
    final rules = [
      {'text': '8+ characters', 'met': password.length >= 8},
      {'text': '1 uppercase', 'met': password.contains(RegExp(r'[A-Z]'))},
      {'text': '1 lowercase', 'met': password.contains(RegExp(r'[a-z]'))},
      {'text': '1 number', 'met': password.contains(RegExp(r'[0-9]'))},
      {'text': '1 special character', 'met': password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))},
    ];

    return Column(
      children: rules.map((rule) {
        final met = rule['met'] as bool;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Icon(
                met ? Icons.check_circle : Icons.circle_outlined,
                size: 20,
                color: met ? Colors.green : Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(
                rule['text'] as String,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: met ? Colors.green : Colors.grey,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStep2Identity() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Identity',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 32),
          
          // First Name
          TextFormField(
            controller: _firstNameController,
            decoration: InputDecoration(
              labelText: 'First Name',
              prefixIcon: const Icon(Icons.person_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Last Name
          TextFormField(
            controller: _lastNameController,
            decoration: InputDecoration(
              labelText: 'Last Name',
              prefixIcon: const Icon(Icons.person_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // User ID
          TextFormField(
            controller: _userIdController,
            onChanged: (value) {
              if (value.isNotEmpty) {
                _checkUserIdAvailability(value);
              }
            },
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]')),
            ],
            decoration: InputDecoration(
              labelText: 'User ID',
              hintText: '@username',
              prefixText: '@',
              prefixIcon: const Icon(Icons.alternate_email),
              suffixIcon: _checkingUserId
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : _userIdController.text.length >= 3
                      ? Icon(
                          _userIdAvailable ? Icons.check_circle : Icons.cancel,
                          color: _userIdAvailable ? Colors.green : Colors.red,
                        )
                      : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              helperText: 'Letters, numbers, underscore only',
            ),
          ),
          if (_userIdController.text.length >= 3 && !_checkingUserId)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _userIdAvailable ? 'Available' : 'Already taken',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: _userIdAvailable ? Colors.green : Colors.red,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStep3PhoneCategory() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Phone & Category',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 32),
          
          // Phone
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Phone Number (India)',
              prefixIcon: const Icon(Icons.phone_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              helperText: '10 digit Indian phone number',
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
          ),
          const SizedBox(height: 32),
          
          Text(
            'Select Category',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          
          // Category grid
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _categories.map((category) {
              final isSelected = _selectedCategory == category;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = category),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFFF7A00)
                        : (isDark ? const Color(0xFF1F2937) : Colors.white),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFFF7A00)
                          : (isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
                    ),
                  ),
                  child: Text(
                    category,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white : const Color(0xFF1F2937)),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStep4BodyMetrics() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bmi = _weightKg / math.pow(_heightCm / 100, 2);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Body Metrics',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'BMI will be calculated automatically',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 32),
          
          // Unit toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildUnitToggle('Metric', _useMetric),
              const SizedBox(width: 16),
              _buildUnitToggle('Imperial', !_useMetric),
            ],
          ),
          const SizedBox(height: 32),
          
          // Height
          Text(
            'Height',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          _buildWheelSelector(
            value: _useMetric ? _heightCm : _heightCm / 2.54,
            min: _useMetric ? 100 : 39,
            max: _useMetric ? 250 : 98,
            unit: _useMetric ? 'cm' : 'in',
            onChanged: (value) {
              setState(() {
                if (_useMetric) {
                  _heightCm = value;
                } else {
                  _heightCm = value * 2.54;
                }
              });
            },
          ),
          const SizedBox(height: 32),
          
          // Weight
          Text(
            'Weight',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          _buildWheelSelector(
            value: _useMetric ? _weightKg : _weightKg * 2.20462,
            min: _useMetric ? 30 : 66,
            max: _useMetric ? 200 : 440,
            unit: _useMetric ? 'kg' : 'lb',
            onChanged: (value) {
              setState(() {
                if (_useMetric) {
                  _weightKg = value;
                } else {
                  _weightKg = value / 2.20462;
                }
              });
            },
          ),
          const SizedBox(height: 32),
          
          // BMI Display
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F2937) : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  'BMI',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  bmi.toStringAsFixed(1),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitToggle(String label, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => _useMetric = label == 'Metric'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF7A00) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF7A00) : Colors.grey,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildWheelSelector({
    required double value,
    required double min,
    required double max,
    required String unit,
    required Function(double) onChanged,
  }) {
    // Simplified wheel selector - in production, use a proper wheel picker package
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1F2937)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${value.toStringAsFixed(_useMetric && unit == 'cm' ? 0 : 1)} $unit',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: value > min
                    ? () => onChanged(value - (_useMetric && unit == 'cm' ? 1 : 0.5))
                    : null,
              ),
              const SizedBox(width: 32),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: value < max
                    ? () => onChanged(value + (_useMetric && unit == 'cm' ? 1 : 0.5))
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep5Role() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Role',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 32),
          
          // Role selection
          _buildRoleOption('Client', Icons.person_outlined, isDark),
          const SizedBox(height: 12),
          _buildRoleOption('Trainer', Icons.fitness_center, isDark),
          const SizedBox(height: 12),
          _buildRoleOption('Nutritionist', Icons.restaurant, isDark),
          
          // Trainer/Nutritionist specific fields
          if (_selectedRole == 'Trainer' || _selectedRole == 'Nutritionist') ...[
            const SizedBox(height: 32),
            Text(
              'Years of Experience',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 16),
            _buildWheelSelector(
              value: _yearsExperience?.toDouble() ?? 1,
              min: 0,
              max: 50,
              unit: 'years',
              onChanged: (value) => setState(() => _yearsExperience = value.toInt()),
            ),
            const SizedBox(height: 32),
            Text(
              'Specialties',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _categories.map((category) {
                final isSelected = _selectedSpecialties.contains(category);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedSpecialties.remove(category);
                      } else {
                        _selectedSpecialties.add(category);
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFFF7A00)
                          : (isDark ? const Color(0xFF1F2937) : Colors.white),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFFF7A00)
                            : (isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
                      ),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.white : const Color(0xFF1F2937)),
                      ),
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

  Widget _buildRoleOption(String role, IconData icon, bool isDark) {
    final isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFF7A00).withValues(alpha: 0.1)
              : (isDark ? const Color(0xFF1F2937) : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFF7A00)
                : (isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFFF7A00), size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                role,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1F2937),
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Color(0xFFFF7A00)),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : const Color(0xFFFAFAFA),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Color(0xFFFF7A00)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Back',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFF7A00),
                  ),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF7A00),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      _currentStep == 4 ? 'Submit' : 'Next',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

