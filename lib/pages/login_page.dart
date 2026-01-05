import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'signup_page.dart';
import '../main_navigation.dart';
import 'trainer_navigation.dart';
import 'nutritionist_navigation.dart';
import '../services/streak_service.dart';
import '../l10n/app_localizations.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _identifierFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    _identifierFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.selectionClick();
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.lightImpact();

    try {
      final supabase = Supabase.instance.client;
      final identifier = _identifierController.text.trim();
      
      final isEmail = identifier.contains('@');
      
      String? email;
      if (isEmail) {
        email = identifier;
      } else {
        // User ID login: look up email by user_id
        final profileResponse = await supabase
            .from('profiles')
            .select('email')
            .eq('user_id', identifier)
            .maybeSingle();
        
        if (profileResponse == null) {
          throw Exception('Account not found, check your Email or User ID');
        }
        email = profileResponse['email'] as String;
      }

      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: _passwordController.text,
      );

      if (response.user != null) {
        if (response.user!.emailConfirmedAt == null) {
          throw Exception('Please verify your email to continue');
        }

        HapticFeedback.lightImpact();
        if (mounted) {
          // Record daily login for streak
          await StreakService.recordLogin();
          
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n?.welcomeBackSignedIn ?? 'Welcome back, you are signed in'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
          
          // Check user role and navigate accordingly
          final profileResponse = await supabase
              .from('profiles')
              .select('role')
              .eq('id', response.user!.id)
              .maybeSingle();
          
          final userRole = profileResponse?['role'] as String?;
          
          Widget destination;
          if (userRole == 'trainer') {
            destination = const TrainerNavigation();
          } else if (userRole == 'nutritionist') {
            destination = const NutritionistNavigation();
          } else {
            destination = const MainNavigation();
          }
          
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => destination,
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
              transitionDuration: const Duration(milliseconds: 300),
            ),
          );
        }
      }
    } on AuthException catch (e) {
      String errorMessage = 'Invalid email or password';
      
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        if (e.message.contains('Invalid login credentials')) {
          errorMessage = l10n?.invalidCredentials ?? 'Invalid email or password';
        } else if (e.message.contains('Email not confirmed')) {
          errorMessage = l10n?.verifyEmail ?? 'Please verify your email to continue';
        } else if (e.message.contains('Too many requests')) {
          errorMessage = 'Too many attempts, please wait and try again';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
      HapticFeedback.selectionClick();
    } catch (e) {
      String errorMessage = 'Connection issue, try again in a moment';
      
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        if (e.toString().contains('Account not found')) {
          errorMessage = l10n?.accountNotFound ?? 'Account not found, check your Email or User ID';
        } else if (e.toString().contains('network') || e.toString().contains('Connection')) {
          errorMessage = 'Connection issue, try again in a moment';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
      HapticFeedback.selectionClick();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0B1220) : Colors.white,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar with wordmark and help icon
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.bolt_rounded,
                          color: colorScheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'CoTrainr',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colorScheme.surface,
                        ),
                        child: Icon(
                          Icons.help_outline_rounded,
                          size: 20,
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        // TODO: Navigate to help/support page
                      },
                    ),
                  ],
                ),
              ),
              
              // Main content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 40),
                        
                        // Header
                        Text(
                          l10n?.welcomeBack ?? 'Welcome back!',
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
                          l10n?.signInToContinue ?? 'Sign in to continue your fitness journey',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 15,
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 48),
                        
                        // Email or User ID field
                        _buildUnderlineInput(
                          label: (l10n?.emailOrUserId ?? 'Email or User ID').toUpperCase(),
                          controller: _identifierController,
                          focusNode: _identifierFocusNode,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          colorScheme: colorScheme,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return l10n?.required ?? 'Required';
                            }
                            if (!value.contains('@')) {
                              final userIdRegex = RegExp(r'^[a-zA-Z0-9_]+$');
                              if (!userIdRegex.hasMatch(value)) {
                                return 'Invalid format';
                              }
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 32),
                        
                        // Password field
                        _buildUnderlineInput(
                          label: (l10n?.password ?? 'Password').toUpperCase(),
                          controller: _passwordController,
                          focusNode: _passwordFocusNode,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          colorScheme: colorScheme,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 20,
                              color: colorScheme.onSurface.withValues(alpha: 0.4),
                            ),
                            onPressed: () {
                              setState(() => _obscurePassword = !_obscurePassword);
                            },
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return l10n?.required ?? 'Required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Forgot password link
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              // TODO: Navigate to forgot password
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            ),
                            child: Text(
                              l10n?.forgotPassword ?? 'Forgot Password?',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        
                        // Continue button
                        _buildContinueButton(colorScheme, l10n),
                        const SizedBox(height: 24),
                        
                        // Sign up link
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${l10n?.dontHaveAccount ?? "Don't have an account?"} ',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  Navigator.push(
                                    context,
                                    PageRouteBuilder(
                                      pageBuilder: (context, animation, secondaryAnimation) =>
                                          const SignupPage(),
                                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                        return SlideTransition(
                                          position: Tween<Offset>(
                                            begin: const Offset(1.0, 0.0),
                                            end: Offset.zero,
                                          ).animate(animation),
                                          child: child,
                                        );
                                      },
                                      transitionDuration: const Duration(milliseconds: 300),
                                    ),
                                  );
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  l10n?.signUp ?? 'Sign Up',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUnderlineInput({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    bool obscureText = false,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    required ColorScheme colorScheme,
  }) {
    final hasFocus = focusNode.hasFocus;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface.withValues(alpha: 0.6),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onFieldSubmitted: (_) {
            if (textInputAction == TextInputAction.done) {
              _handleLogin();
            } else {
              FocusScope.of(context).nextFocus();
            }
          },
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            suffixIcon: suffixIcon,
            hintText: label == 'EMAIL OR USER ID' 
                ? 'email@example.com or your_userid'
                : 'Enter your password',
            hintStyle: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.4),
              fontWeight: FontWeight.normal,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            border: UnderlineInputBorder(
              borderSide: BorderSide(
                color: colorScheme.onSurface.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: colorScheme.onSurface.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: colorScheme.primary,
                width: 2,
              ),
            ),
            errorBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: colorScheme.error,
                width: 1,
              ),
            ),
            focusedErrorBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: colorScheme.error,
                width: 2,
              ),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildContinueButton(ColorScheme colorScheme, AppLocalizations? l10n) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary,
            colorScheme.secondary,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _handleLogin,
          borderRadius: BorderRadius.circular(28),
          child: Center(
            child: _isLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        colorScheme.onPrimary,
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        l10n?.signIn ?? 'Sign In',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onPrimary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: colorScheme.onPrimary,
                        size: 20,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
