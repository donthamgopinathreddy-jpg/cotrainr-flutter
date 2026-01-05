import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/theme_provider.dart';
import '../services/language_provider.dart';
import '../services/notification_settings_service.dart';
import 'edit_profile_page.dart';
import 'login_page.dart';
import 'help_center_page.dart';
import 'faq_page.dart';
import 'feedback_page.dart';
import 'report_problem_page.dart';
import 'terms_of_service_page.dart';
import 'privacy_policy_page.dart';
import 'app_version_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // User profile data
  String _userName = 'Loading...';
  String _userID = '@loading';
  String? _avatarUrl;
  bool _isLoadingProfile = true;
  
  // Settings state
  bool _showActivityStatus = true;
  bool _allowMessages = true;
  bool _showEmail = false;
  bool _showPhone = false;
  
  bool _twoFactorEnabled = false;
  bool _loginAlerts = true;
  bool _sessionTimeout = true;
  
  bool _pushNotifications = true;
  bool _questReminders = true;
  bool _achievementAlerts = true;
  bool _socialUpdates = true;
  
  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadNotificationSettings();
    _loadPrivacySettings();
    _loadSecuritySettings();
  }
  
  Future<void> _loadSecuritySettings() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      
      if (user != null) {
        // Check if MFA is enabled
        try {
          final response = await supabase.auth.mfa.listFactors();
          // Check if there are any verified factors
          final factors = response.all;
          final mfaEnabled = factors.isNotEmpty &&
              factors.any((factor) => factor.status == 'verified');
          
          if (mounted) {
            setState(() {
              _twoFactorEnabled = mfaEnabled;
            });
          }
        } catch (e) {
          // MFA might not be configured, default to false
          if (mounted) {
            setState(() {
              _twoFactorEnabled = false;
            });
          }
        }
      }
    } catch (e) {
      print('Error loading security settings: $e');
    }
  }
  
  Future<void> _loadPrivacySettings() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await supabase
          .from('profiles')
          .select('show_activity_status, allow_messages, show_email, show_phone')
          .eq('id', userId)
          .maybeSingle();

      if (response != null && mounted) {
        setState(() {
          _showActivityStatus = response['show_activity_status'] as bool? ?? true;
          _allowMessages = response['allow_messages'] as bool? ?? true;
          _showEmail = response['show_email'] as bool? ?? false;
          _showPhone = response['show_phone'] as bool? ?? false;
        });
      }
    } catch (e) {
      print('Error loading privacy settings: $e');
    }
  }
  
  Future<void> _savePrivacySettings() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      await supabase
          .from('profiles')
          .update({
            'show_activity_status': _showActivityStatus,
            'allow_messages': _allowMessages,
            'show_email': _showEmail,
            'show_phone': _showPhone,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Privacy settings saved'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error saving privacy settings: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _loadNotificationSettings() async {
    try {
      final settings = await NotificationSettingsService.getAllSettings();
      if (mounted) {
        setState(() {
          _pushNotifications = settings['pushNotifications'] ?? true;
          _questReminders = settings['questReminders'] ?? true;
          _achievementAlerts = settings['achievementAlerts'] ?? true;
          _socialUpdates = settings['socialUpdates'] ?? true;
        });
      }
    } catch (e) {
      print('Error loading notification settings: $e');
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        setState(() => _isLoadingProfile = false);
        return;
      }

      final response = await supabase
          .from('profiles')
          .select('display_name, user_id, avatar_path')
          .eq('id', userId)
          .maybeSingle();

      if (response != null && mounted) {
        setState(() {
          _userName = response['display_name'] ?? 
                     '${response['first_name'] ?? ''} ${response['last_name'] ?? ''}'.trim();
          if (_userName.isEmpty) {
            _userName = response['user_id'] ?? 'User';
          }
          _userID = '@${response['user_id'] ?? 'user'}';
          
          final avatarPath = response['avatar_path'];
          if (avatarPath != null) {
            _avatarUrl = supabase.storage.from('avatars').getPublicUrl(avatarPath);
          }
          _isLoadingProfile = false;
        });
      } else {
        setState(() => _isLoadingProfile = false);
      }
    } catch (e) {
      print('Error loading profile in settings: $e');
      if (mounted) {
        setState(() => _isLoadingProfile = false);
      }
    }
  }
  
  // Indian languages list
  final List<Map<String, String>> _indianLanguages = [
    {'code': 'en', 'name': 'English', 'native': 'English'},
    {'code': 'hi', 'name': 'Hindi', 'native': 'हिन्दी'},
    {'code': 'bn', 'name': 'Bengali', 'native': 'বাংলা'},
    {'code': 'te', 'name': 'Telugu', 'native': 'తెలుగు'},
    {'code': 'mr', 'name': 'Marathi', 'native': 'मराठी'},
    {'code': 'ta', 'name': 'Tamil', 'native': 'தமிழ்'},
    {'code': 'ur', 'name': 'Urdu', 'native': 'اردو'},
    {'code': 'gu', 'name': 'Gujarati', 'native': 'ગુજરાતી'},
    {'code': 'kn', 'name': 'Kannada', 'native': 'ಕನ್ನಡ'},
    {'code': 'or', 'name': 'Odia', 'native': 'ଓଡ଼ିଆ'},
    {'code': 'pa', 'name': 'Punjabi', 'native': 'ਪੰਜਾਬੀ'},
    {'code': 'ml', 'name': 'Malayalam', 'native': 'മലയാളം'},
    {'code': 'as', 'name': 'Assamese', 'native': 'অসমীয়া'},
    {'code': 'ne', 'name': 'Nepali', 'native': 'नेपाली'},
    {'code': 'si', 'name': 'Sinhala', 'native': 'සිංහල'},
    {'code': 'sa', 'name': 'Sanskrit', 'native': 'संस्कृतम्'},
    {'code': 'kok', 'name': 'Konkani', 'native': 'कोंकणी'},
    {'code': 'mai', 'name': 'Maithili', 'native': 'मैथिली'},
    {'code': 'mni', 'name': 'Manipuri', 'native': 'ꯃꯅꯤꯄꯨꯔꯤ'},
    {'code': 'sat', 'name': 'Santali', 'native': 'ᱥᱟᱱᱛᱟᱲᱤ'},
  ];

  Future<void> _deleteAccount() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      
      if (userId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error: User not found'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Delete user data from profiles table (cascade will handle related data)
      await supabase
          .from('profiles')
          .delete()
          .eq('id', userId);

      // Sign out
      await supabase.auth.signOut();

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error deleting account: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting account: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Logout',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(
            fontFamily: 'Poppins',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Logout',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: Color(0xFFEF4444),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout != true) {
      return;
    }

    try {
      final supabase = Supabase.instance.client;
      
      // Sign out from Supabase
      await supabase.auth.signOut();
      
      if (context.mounted) {
        // Navigate to login page and clear navigation stack
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const LoginPage(),
          ),
          (route) => false,
        );
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Logged out successfully'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging out: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF111827) : const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1F2937) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? Colors.white : const Color(0xFF1F2937),
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Settings',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF1F2937),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // Profile Header for Continuity
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F2937) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundImage: _avatarUrl != null
                      ? NetworkImage(_avatarUrl!)
                      : null,
                  child: _avatarUrl == null
                      ? Icon(
                          Icons.person_rounded,
                          size: 32,
                          color: isDark ? Colors.white : const Color(0xFF1F2937),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _userName,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _userID,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Account Section
          _buildSettingsSection('Account', [
            _buildSettingsItem('Edit Profile', Icons.person_outline_rounded, () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfilePage(),
                ),
              );
            }, isDark),
            _buildSettingsItem('Privacy', Icons.lock_outline_rounded, () {
              HapticFeedback.lightImpact();
              _showPrivacySettings(isDark);
            }, isDark),
            _buildSettingsItem('Security', Icons.security_rounded, () {
              HapticFeedback.lightImpact();
              _showSecuritySettings(isDark);
            }, isDark),
          ], isDark),
          
          const SizedBox(height: 24),
          
          // App Section
          _buildSettingsSection('App', [
            _buildAppearanceItem(isDark),
            _buildSettingsItem('Notifications', Icons.notifications_outlined, () {
              HapticFeedback.lightImpact();
              _showNotificationSettings(isDark);
            }, isDark),
            _buildSettingsItem('Language', Icons.language_rounded, () {
              HapticFeedback.lightImpact();
              _showLanguageSettings(isDark);
            }, isDark),
          ], isDark),
          
          const SizedBox(height: 24),
          
          // Support Section
          _buildSettingsSection('Support', [
            _buildSettingsItem('Help Center', Icons.help_outline_rounded, () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HelpCenterPage()),
              );
            }, isDark),
            _buildSettingsItem('FAQ', Icons.quiz_outlined, () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FAQPage()),
              );
            }, isDark),
            _buildSettingsItem('Feedback', Icons.feedback_outlined, () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FeedbackPage()),
              );
            }, isDark),
            _buildSettingsItem('Report a Problem', Icons.report_outlined, () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReportProblemPage()),
              );
            }, isDark),
          ], isDark),
          
          const SizedBox(height: 24),
          
          // About Section
          _buildSettingsSection('About', [
            _buildSettingsItem('Terms of Service', Icons.description_outlined, () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TermsOfServicePage()),
              );
            }, isDark),
            _buildSettingsItem('Privacy Policy', Icons.privacy_tip_outlined, () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
              );
            }, isDark),
            _buildSettingsItem('App Version', Icons.info_outline_rounded, () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AppVersionPage()),
              );
            }, isDark),
          ], isDark),
          
          const SizedBox(height: 32),
          
          // Logout Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () async {
                HapticFeedback.mediumImpact();
                await _handleLogout(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Logout',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> items, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF111827) : const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildSettingsItem(String title, IconData icon, VoidCallback onTap, bool isDark, {bool showChevron = true, Widget? trailing}) {
    return ListTile(
      leading: Icon(icon, color: isDark ? Colors.white : const Color(0xFF1F2937)),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 15,
          color: isDark ? Colors.white : const Color(0xFF1F2937),
        ),
      ),
      trailing: trailing ?? (showChevron ? Icon(
        Icons.chevron_right_rounded,
        color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
      ) : null),
      onTap: onTap,
    );
  }

  Widget _buildAppearanceItem(bool isDark) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF111827) : const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              ListTile(
                leading: Icon(
                  Icons.palette_outlined,
                  color: isDark ? Colors.white : const Color(0xFF1F2937),
                ),
                title: Text(
                  'Appearance',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildThemeIcon(
                      icon: Icons.light_mode_rounded,
                      label: 'Light',
                      themeMode: ThemeMode.light,
                      currentMode: themeProvider.themeMode,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        themeProvider.setThemeMode(ThemeMode.light);
                      },
                      isDark: isDark,
                    ),
                    _buildThemeIcon(
                      icon: Icons.dark_mode_rounded,
                      label: 'Dark',
                      themeMode: ThemeMode.dark,
                      currentMode: themeProvider.themeMode,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        themeProvider.setThemeMode(ThemeMode.dark);
                      },
                      isDark: isDark,
                    ),
                    _buildThemeIcon(
                      icon: Icons.brightness_auto_rounded,
                      label: 'System',
                      themeMode: ThemeMode.system,
                      currentMode: themeProvider.themeMode,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        themeProvider.setThemeMode(ThemeMode.system);
                      },
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeIcon({
    required IconData icon,
    required String label,
    required ThemeMode themeMode,
    required ThemeMode currentMode,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final isSelected = currentMode == themeMode;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : (isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : (isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280)),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : (isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Privacy Settings Page
  void _showPrivacySettings(bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Text(
                    'Privacy',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1F2937),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: isDark ? Colors.white : const Color(0xFF1F2937),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildPrivacySection('Privacy Settings', [
                    _buildSwitchTile(
                      'Show Activity Status',
                      'Show when you\'re active',
                      _showActivityStatus,
                      (value) async {
                        setState(() => _showActivityStatus = value);
                        await _savePrivacySettings();
                      },
                      isDark: isDark,
                    ),
                    _buildSwitchTile(
                      'Allow Messages',
                      'Let others send you messages',
                      _allowMessages,
                      (value) async {
                        setState(() => _allowMessages = value);
                        await _savePrivacySettings();
                      },
                      isDark: isDark,
                    ),
                    _buildSwitchTile(
                      'Show Email',
                      'Display email on profile',
                      _showEmail,
                      (value) async {
                        setState(() => _showEmail = value);
                        await _savePrivacySettings();
                      },
                      isDark: isDark,
                    ),
                    _buildSwitchTile(
                      'Show Phone',
                      'Display phone number on profile',
                      _showPhone,
                      (value) async {
                        setState(() => _showPhone = value);
                        await _savePrivacySettings();
                      },
                      isDark: isDark,
                    ),
                  ], isDark),
                  const SizedBox(height: 24),
                  _buildPrivacySection('Account', [
                    _buildSettingsItem('Delete Account', Icons.delete_outline_rounded, () {
                      HapticFeedback.lightImpact();
                      _showDeleteAccountDialog(isDark);
                    }, isDark, showChevron: false),
                  ], isDark),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Security Settings Page
  void _showSecuritySettings(bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Text(
                    'Security',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1F2937),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: isDark ? Colors.white : const Color(0xFF1F2937),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildPrivacySection('Account Security', [
                    _buildSwitchTile(
                      'Two-Factor Authentication',
                      'Add an extra layer of security',
                      _twoFactorEnabled,
                      (value) async {
                        if (value) {
                          await _enableTwoFactor(isDark);
                        } else {
                          await _disableTwoFactor(isDark);
                        }
                      },
                      isDark: isDark,
                    ),
                    _buildSwitchTile(
                      'Login Alerts',
                      'Get notified of new logins',
                      _loginAlerts,
                      (value) => setState(() => _loginAlerts = value),
                      isDark: isDark,
                    ),
                    _buildSwitchTile(
                      'Session Timeout',
                      'Auto-logout after inactivity',
                      _sessionTimeout,
                      (value) => setState(() => _sessionTimeout = value),
                      isDark: isDark,
                    ),
                  ], isDark),
                  const SizedBox(height: 24),
                  _buildPrivacySection('Password', [
                    _buildSettingsItem('Change Password', Icons.lock_rounded, () {
                      HapticFeedback.lightImpact();
                      _showChangePasswordDialog(isDark);
                    }, isDark),
                  ], isDark),
                  const SizedBox(height: 24),
                  _buildPrivacySection('Active Sessions', [
                    _buildSettingsItem('Manage Sessions', Icons.devices_rounded, () {
                      HapticFeedback.lightImpact();
                      _showActiveSessions(isDark);
                    }, isDark),
                  ], isDark),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Notification Settings Page
  void _showNotificationSettings(bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Text(
                    'Notifications',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1F2937),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: isDark ? Colors.white : const Color(0xFF1F2937),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildPrivacySection('Push Notifications', [
                    _buildSwitchTile(
                      'Enable Push Notifications',
                      'Receive notifications on your device',
                      _pushNotifications,
                      (value) async {
                        setState(() {
                          _pushNotifications = value;
                          // If push notifications are disabled, disable all other notifications
                          if (!value) {
                            _questReminders = false;
                            _achievementAlerts = false;
                            _socialUpdates = false;
                          }
                        });
                        // Save to storage
                        await NotificationSettingsService.setPushNotificationsEnabled(value);
                        if (!value) {
                          await NotificationSettingsService.setQuestRemindersEnabled(false);
                          await NotificationSettingsService.setAchievementAlertsEnabled(false);
                          await NotificationSettingsService.setSocialUpdatesEnabled(false);
                        }
                      },
                      isDark: isDark,
                    ),
                  ], isDark),
                  const SizedBox(height: 24),
                  _buildPrivacySection('Activity Notifications', [
                    _buildSwitchTile(
                      'Quest Reminders',
                      'Get reminded about daily quests',
                      _questReminders,
                      (value) async {
                        if (_pushNotifications) {
                          setState(() => _questReminders = value);
                          await NotificationSettingsService.setQuestRemindersEnabled(value);
                        }
                      },
                      isDark: isDark,
                      enabled: _pushNotifications,
                    ),
                    _buildSwitchTile(
                      'Achievement Alerts',
                      'Notify when you unlock achievements',
                      _achievementAlerts,
                      (value) async {
                        if (_pushNotifications) {
                          setState(() => _achievementAlerts = value);
                          await NotificationSettingsService.setAchievementAlertsEnabled(value);
                        }
                      },
                      isDark: isDark,
                      enabled: _pushNotifications,
                    ),
                    _buildSwitchTile(
                      'Social Updates',
                      'Get notified about likes, comments, follows',
                      _socialUpdates,
                      (value) async {
                        if (_pushNotifications) {
                          setState(() => _socialUpdates = value);
                          await NotificationSettingsService.setSocialUpdatesEnabled(value);
                        }
                      },
                      isDark: isDark,
                      enabled: _pushNotifications,
                    ),
                  ], isDark),
                  if (!_pushNotifications)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark 
                              ? const Color(0xFF374151).withValues(alpha: 0.5)
                              : const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark 
                                ? const Color(0xFF6B7280)
                                : const Color(0xFFFCD34D),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 20,
                              color: isDark 
                                  ? const Color(0xFF9CA3AF)
                                  : const Color(0xFF92400E),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Enable push notifications to receive activity notifications',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 13,
                                  color: isDark 
                                      ? const Color(0xFF9CA3AF)
                                      : const Color(0xFF92400E),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Language Settings Page
  void _showLanguageSettings(bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Text(
                    'Language',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1F2937),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: isDark ? Colors.white : const Color(0xFF1F2937),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  Text(
                    'Select Language',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._indianLanguages.map((lang) => _buildLanguageItem(
                    lang['name']!,
                    lang['native']!,
                    lang['code']!,
                    isDark,
                  )),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageItem(String name, String native, String code, bool isDark) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: true);
    final isSelected = languageProvider.languageCode == code;
    return GestureDetector(
      onTap: () async {
        HapticFeedback.selectionClick();
        await languageProvider.setLanguage(code);
        if (mounted) {
          Navigator.pop(context);
          // Give a moment for the app to rebuild with new locale
          await Future.delayed(const Duration(milliseconds: 100));
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Language changed to $name'),
                backgroundColor: const Color(0xFF10B981),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFF7A00).withValues(alpha: 0.1)
              : (isDark ? const Color(0xFF111827) : const Color(0xFFFAFAFA)),
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    native,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFFFF7A00),
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacySection(String title, List<Widget> items, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF111827) : const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, ValueChanged<bool> onChanged, {required bool isDark, bool enabled = true}) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: enabled 
              ? (isDark ? Colors.white : const Color(0xFF1F2937))
              : (isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF)),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13,
          color: enabled 
              ? (isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280))
              : (isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF)),
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: enabled ? onChanged : null,
        activeTrackColor: const Color(0xFFFF7A00),
        activeThumbColor: Colors.white,
      ),
    );
  }

  void _showDeleteAccountDialog(bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1F2937) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Text(
          'Delete Account',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF1F2937),
          ),
        ),
        content: Text(
          'This action cannot be undone. All your data will be permanently deleted.',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteAccount();
            },
            child: const Text(
              'Delete',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: Color(0xFFEF4444),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(bool isDark) {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1F2937) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Text(
          'Change Password',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF1F2937),
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPasswordField('Current Password', oldPasswordController, isDark),
              const SizedBox(height: 12),
              _buildPasswordField('New Password', newPasswordController, isDark),
              const SizedBox(height: 12),
              _buildPasswordField('Confirm Password', confirmPasswordController, isDark),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              final newPassword = newPasswordController.text;
              final confirmPassword = confirmPasswordController.text;
              
              if (newPassword.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a new password'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              if (newPassword.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password must be at least 6 characters'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              if (newPassword != confirmPassword) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Passwords do not match'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              // Change password with Supabase
              try {
                final supabase = Supabase.instance.client;
                
                // Update password
                await supabase.auth.updateUser(
                  UserAttributes(password: newPassword),
                );
                
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password changed successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                print('Error changing password: $e');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error changing password: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Change',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: Color(0xFFFF7A00),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _enableTwoFactor(bool isDark) async {
    try {
      final supabase = Supabase.instance.client;
      
      // Generate MFA factor
      final factor = await supabase.auth.mfa.enroll(
        factorType: FactorType.totp,
      );
      
      // Get QR code data
      final qrCode = factor.totp?.qrCode;
      
      if (context.mounted && qrCode != null) {
        Navigator.pop(context); // Close security settings if open
        _showTwoFactorSetupDialog(isDark, qrCode, factor.id);
      }
    } catch (e) {
      print('Error enabling two-factor authentication: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error setting up two-factor authentication: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _disableTwoFactor(bool isDark) async {
    try {
      final supabase = Supabase.instance.client;
      
      // Get all factors
      final response = await supabase.auth.mfa.listFactors();
      final factors = response.all ?? [];
      final totpFactor = factors.firstWhere(
        (factor) => factor.status == 'verified',
        orElse: () => throw Exception('No verified MFA factor found'),
      );
      
      // Unenroll the factor (takes positional argument)
      await supabase.auth.mfa.unenroll(totpFactor.id);
      
      if (mounted) {
        setState(() {
          _twoFactorEnabled = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Two-factor authentication disabled'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error disabling two-factor authentication: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error disabling two-factor authentication: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _showTwoFactorSetupDialog(bool isDark, String qrCodeData, String factorId) {
    final codeController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1F2937) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Text(
          'Set Up Two-Factor Authentication',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF1F2937),
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Scan this QR code with your authenticator app (Google Authenticator, Authy, etc.)',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 16),
              // QR Code URL - you can use qr_flutter package or display as text
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF111827) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                  ),
                ),
                child: Text(
                  'QR Code URL:\n$qrCodeData',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Enter the 6-digit code from your authenticator app to verify:',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 8,
                  color: isDark ? Colors.white : const Color(0xFF1F2937),
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: isDark ? const Color(0xFF111827) : const Color(0xFFF3F4F6),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  counterText: '',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (mounted) {
                setState(() {
                  _twoFactorEnabled = false;
                });
              }
            },
            child: Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              final code = codeController.text;
              
              if (code.length != 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a 6-digit code'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              try {
                final supabase = Supabase.instance.client;
                
                // Challenge first, then verify
                final challenge = await supabase.auth.mfa.challenge(factorId: factorId);
                
                // Verify the code
                await supabase.auth.mfa.verify(
                  factorId: factorId,
                  challengeId: challenge.id,
                  code: code,
                );
                
                if (context.mounted) {
                  Navigator.pop(context);
                  setState(() {
                    _twoFactorEnabled = true;
                  });
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Two-factor authentication enabled successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                print('Error verifying two-factor code: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Invalid code. Please try again: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text(
              'Verify',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: Color(0xFFFF7A00),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField(String label, TextEditingController controller, bool isDark) {
    return TextField(
      controller: controller,
      obscureText: true,
      style: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 14,
        color: isDark ? Colors.white : const Color(0xFF1F2937),
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontFamily: 'Poppins',
          color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF111827) : const Color(0xFFF3F4F6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  void _showActiveSessions(bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Text(
                    'Active Sessions',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1F2937),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: isDark ? Colors.white : const Color(0xFF1F2937),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildSessionItem('iPhone 14 Pro', 'Current Device', 'Now', true, isDark),
                  _buildSessionItem('Samsung Galaxy S23', 'Mumbai, India', '2 hours ago', false, isDark),
                  _buildSessionItem('Chrome Browser', 'Delhi, India', '1 day ago', false, isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionItem(String device, String location, String time, bool isCurrent, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrent
            ? const Color(0xFFFF7A00).withValues(alpha: 0.1)
            : (isDark ? const Color(0xFF111827) : const Color(0xFFFAFAFA)),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrent
              ? const Color(0xFFFF7A00)
              : (isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
          width: isCurrent ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            device.contains('iPhone') || device.contains('Samsung')
                ? Icons.smartphone_rounded
                : Icons.computer_rounded,
            size: 32,
            color: isCurrent ? const Color(0xFFFF7A00) : (isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      device,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF1F2937),
                      ),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF7A00),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Current',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  location,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
          if (!isCurrent)
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444)),
              onPressed: () {
                HapticFeedback.lightImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Session ended for $device')),
                );
              },
            ),
        ],
      ),
    );
  }
}

