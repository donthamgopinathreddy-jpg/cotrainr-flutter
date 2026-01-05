import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // Login Page
      'login': 'Login',
      'welcome_back': 'Welcome back!',
      'sign_in_to_continue': 'Sign in to continue your fitness journey',
      'email_or_user_id': 'Email or User ID',
      'password': 'Password',
      'forgot_password': 'Forgot Password?',
      'sign_in': 'Sign In',
      'dont_have_account': "Don't have an account?",
      'sign_up': 'Sign Up',
      'welcome_back_signed_in': 'Welcome back, you are signed in',
      'account_not_found': 'Account not found, check your Email or User ID',
      'verify_email': 'Please verify your email to continue',
      'invalid_credentials': 'Invalid email or password',
      'login_error': 'Login failed. Please try again.',
      
      // Signup Page
      'create_account': 'Create Account',
      'join_us': 'Join us and start your fitness journey',
      'step': 'Step',
      'of': 'of',
      'next': 'Next',
      'back': 'Back',
      'create': 'Create',
      'email': 'Email',
      'enter_email': 'Enter your email',
      'invalid_email': 'Please enter a valid email',
      'password_requirements': 'Password Requirements',
      'min_8_chars': 'At least 8 characters',
      'one_uppercase': 'One uppercase letter',
      'one_lowercase': 'One lowercase letter',
      'one_number': 'One number',
      'one_special': 'One special character',
      'confirm_password': 'Confirm Password',
      'passwords_match': 'Passwords match',
      'passwords_dont_match': 'Passwords do not match',
      'user_id': 'User ID',
      'enter_user_id': 'Enter your user ID',
      'user_id_available': 'User ID is available',
      'user_id_taken': 'User ID is already taken',
      'first_name': 'First Name',
      'last_name': 'Last Name',
      'phone': 'Phone',
      'date_of_birth': 'Date of Birth',
      'gender': 'Gender',
      'male': 'Male',
      'female': 'Female',
      'other': 'Other',
      'height': 'Height',
      'weight': 'Weight',
      'role': 'Role',
      'client': 'Client',
      'trainer': 'Trainer',
      'account_created': 'Account created successfully!',
      'verification_email_sent': 'Verification email sent. Please check your inbox.',
      'signup_error': 'Sign up failed. Please try again.',
      
      // Common
      'required': 'Required',
      'loading': 'Loading...',
      'error': 'Error',
      'success': 'Success',
      'cancel': 'Cancel',
      'ok': 'OK',
      'save': 'Save',
      'edit': 'Edit',
      'delete': 'Delete',
    },
    'hi': {
      // Login Page
      'login': 'लॉगिन',
      'welcome_back': 'वापसी पर स्वागत है!',
      'sign_in_to_continue': 'अपनी फिटनेस यात्रा जारी रखने के लिए साइन इन करें',
      'email_or_user_id': 'ईमेल या उपयोगकर्ता आईडी',
      'password': 'पासवर्ड',
      'forgot_password': 'पासवर्ड भूल गए?',
      'sign_in': 'साइन इन',
      'dont_have_account': 'खाता नहीं है?',
      'sign_up': 'साइन अप',
      'welcome_back_signed_in': 'वापसी पर स्वागत है, आप साइन इन हैं',
      'account_not_found': 'खाता नहीं मिला, अपना ईमेल या उपयोगकर्ता आईडी जांचें',
      'verify_email': 'जारी रखने के लिए कृपया अपना ईमेल सत्यापित करें',
      'invalid_credentials': 'अमान्य ईमेल या पासवर्ड',
      'login_error': 'लॉगिन विफल। कृपया पुनः प्रयास करें।',
      
      // Signup Page
      'create_account': 'खाता बनाएं',
      'join_us': 'हमसे जुड़ें और अपनी फिटनेस यात्रा शुरू करें',
      'step': 'चरण',
      'of': 'का',
      'next': 'अगला',
      'back': 'वापस',
      'create': 'बनाएं',
      'email': 'ईमेल',
      'enter_email': 'अपना ईमेल दर्ज करें',
      'invalid_email': 'कृपया एक वैध ईमेल दर्ज करें',
      'password_requirements': 'पासवर्ड आवश्यकताएं',
      'min_8_chars': 'कम से कम 8 वर्ण',
      'one_uppercase': 'एक बड़ा अक्षर',
      'one_lowercase': 'एक छोटा अक्षर',
      'one_number': 'एक संख्या',
      'one_special': 'एक विशेष वर्ण',
      'confirm_password': 'पासवर्ड की पुष्टि करें',
      'passwords_match': 'पासवर्ड मेल खाते हैं',
      'passwords_dont_match': 'पासवर्ड मेल नहीं खाते',
      'user_id': 'उपयोगकर्ता आईडी',
      'enter_user_id': 'अपनी उपयोगकर्ता आईडी दर्ज करें',
      'user_id_available': 'उपयोगकर्ता आईडी उपलब्ध है',
      'user_id_taken': 'उपयोगकर्ता आईडी पहले से ली गई है',
      'first_name': 'पहला नाम',
      'last_name': 'अंतिम नाम',
      'phone': 'फोन',
      'date_of_birth': 'जन्म तिथि',
      'gender': 'लिंग',
      'male': 'पुरुष',
      'female': 'महिला',
      'other': 'अन्य',
      'height': 'ऊंचाई',
      'weight': 'वजन',
      'role': 'भूमिका',
      'client': 'ग्राहक',
      'trainer': 'प्रशिक्षक',
      'account_created': 'खाता सफलतापूर्वक बनाया गया!',
      'verification_email_sent': 'सत्यापन ईमेल भेजा गया। कृपया अपना इनबॉक्स जांचें।',
      'signup_error': 'साइन अप विफल। कृपया पुनः प्रयास करें।',
      
      // Common
      'required': 'आवश्यक',
      'loading': 'लोड हो रहा है...',
      'error': 'त्रुटि',
      'success': 'सफलता',
      'cancel': 'रद्द करें',
      'ok': 'ठीक',
      'save': 'सहेजें',
      'edit': 'संपादित करें',
      'delete': 'हटाएं',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? 
           _localizedValues['en']?[key] ?? 
           key;
  }

  // Getters for common translations
  String get login => translate('login');
  String get welcomeBack => translate('welcome_back');
  String get signInToContinue => translate('sign_in_to_continue');
  String get emailOrUserId => translate('email_or_user_id');
  String get password => translate('password');
  String get forgotPassword => translate('forgot_password');
  String get signIn => translate('sign_in');
  String get dontHaveAccount => translate('dont_have_account');
  String get signUp => translate('sign_up');
  String get welcomeBackSignedIn => translate('welcome_back_signed_in');
  String get accountNotFound => translate('account_not_found');
  String get verifyEmail => translate('verify_email');
  String get invalidCredentials => translate('invalid_credentials');
  String get loginError => translate('login_error');
  
  String get createAccount => translate('create_account');
  String get joinUs => translate('join_us');
  String get step => translate('step');
  String get stepOf => translate('of');
  String get next => translate('next');
  String get back => translate('back');
  String get create => translate('create');
  String get email => translate('email');
  String get enterEmail => translate('enter_email');
  String get invalidEmail => translate('invalid_email');
  String get passwordRequirements => translate('password_requirements');
  String get min8Chars => translate('min_8_chars');
  String get oneUppercase => translate('one_uppercase');
  String get oneLowercase => translate('one_lowercase');
  String get oneNumber => translate('one_number');
  String get oneSpecial => translate('one_special');
  String get confirmPassword => translate('confirm_password');
  String get passwordsMatch => translate('passwords_match');
  String get passwordsDontMatch => translate('passwords_dont_match');
  String get userId => translate('user_id');
  String get enterUserId => translate('enter_user_id');
  String get userIdAvailable => translate('user_id_available');
  String get userIdTaken => translate('user_id_taken');
  String get firstName => translate('first_name');
  String get lastName => translate('last_name');
  String get phone => translate('phone');
  String get dateOfBirth => translate('date_of_birth');
  String get gender => translate('gender');
  String get male => translate('male');
  String get female => translate('female');
  String get other => translate('other');
  String get height => translate('height');
  String get weight => translate('weight');
  String get role => translate('role');
  String get client => translate('client');
  String get trainer => translate('trainer');
  String get accountCreated => translate('account_created');
  String get verificationEmailSent => translate('verification_email_sent');
  String get signupError => translate('signup_error');
  
  String get required => translate('required');
  String get loading => translate('loading');
  String get error => translate('error');
  String get success => translate('success');
  String get cancel => translate('cancel');
  String get ok => translate('ok');
  String get save => translate('save');
  String get edit => translate('edit');
  String get delete => translate('delete');
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'hi', 'bn', 'te', 'mr', 'ta', 'ur', 'gu', 'kn', 'or', 'pa', 'ml', 'as', 'ne', 'si', 'sa', 'kok', 'mai', 'mni', 'sat'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

