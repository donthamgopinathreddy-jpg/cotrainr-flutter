import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/theme_service.dart';
import '../services/user_profile_service.dart';
import '../widgets/frosted_card.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final UserProfileService _profileService = UserProfileService();
  Map<String, dynamic>? _profile;
  String? _avatarUrl;
  String? _coverImageUrl;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await _profileService.getCurrentUserProfile();
    setState(() {
      _profile = profile;
      _avatarUrl = _profileService.getProfilePhotoUrl();
      _coverImageUrl = _profileService.getCoverPhotoUrl();
    });
  }

  Future<void> _handleLogout() async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging out: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeService = Provider.of<ThemeService>(context);
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: CustomScrollView(
        slivers: [
          // Modern Header with Cover Image
          _buildModernHeader(isDark, onSurface),
          
          // Body Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats Cards Row
                  _buildStatsRow(isDark, onSurface),
                  const SizedBox(height: 20),

                  // Quick Actions
                  _buildSectionTitle('Quick Actions', isDark),
                  const SizedBox(height: 12),
                  _buildQuickActions(isDark, onSurface),
                  const SizedBox(height: 24),

                  // Settings Section
                  _buildSectionTitle('Settings', isDark),
                  const SizedBox(height: 12),
                  _buildSettingsSection(themeService, isDark, onSurface),
                  const SizedBox(height: 24),

                  // Account Section
                  _buildSectionTitle('Account', isDark),
                  const SizedBox(height: 12),
                  _buildAccountSection(isDark, onSurface),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernHeader(bool isDark, Color onSurface) {
    final displayName = _profile?['first_name'] as String? ?? 
                        _profile?['display_name'] as String? ?? 'User';
    final role = _profile?['role'] as String? ?? 'client';
    final userIdHandle = _profile?['user_id_handle'] as String? ?? '@user';
    
    return SliverAppBar(
      expandedHeight: 280,
      floating: false,
      pinned: true,
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Cover Image
            _coverImageUrl != null && _coverImageUrl!.isNotEmpty
                ? Image.network(
                    _coverImageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                        ),
                      );
                    },
                  )
                : Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                    ),
                  ),
            
            // Top Gradient Scrim
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 100,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.4),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Frosted Panel
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 140,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          (isDark ? AppColors.surfaceDark : AppColors.surfaceLight)
                              .withValues(alpha: 0.85),
                          (isDark ? AppColors.surfaceDark : AppColors.surfaceLight)
                              .withValues(alpha: 0.95),
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Profile Avatar (partially outside)
                        Transform.translate(
                          offset: const Offset(0, -20),
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark ? AppColors.surfaceDark : Colors.white,
                                width: 4,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: _avatarUrl != null && _avatarUrl!.isNotEmpty
                                  ? Image.network(
                                      _avatarUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          decoration: BoxDecoration(
                                            gradient: AppColors.primaryGradient,
                                          ),
                                          child: const Icon(
                                            Icons.person,
                                            size: 50,
                                            color: Colors.white,
                                          ),
                                        );
                                      },
                                    )
                                  : Container(
                                      decoration: BoxDecoration(
                                        gradient: AppColors.primaryGradient,
                                      ),
                                      child: const Icon(
                                        Icons.person,
                                        size: 50,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // User Info
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: onSurface,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                userIdHandle,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                  color: onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  role.toUpperCase(),
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Edit Button
                        Container(
                          decoration: BoxDecoration(
                            color: (isDark ? AppColors.surfaceDark : Colors.white)
                                .withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.edit_rounded, size: 20),
                            color: AppColors.primaryGradient.colors.first,
                            onPressed: () {
                              // Navigate to edit profile
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(bool isDark, Color onSurface) {
    // Mock stats - replace with real data
    final stats = [
      {'label': 'Streak', 'value': '7', 'icon': Icons.local_fire_department_rounded, 'color': AppColors.primaryGradient.colors.first},
      {'label': 'Workouts', 'value': '24', 'icon': Icons.fitness_center_rounded, 'color': AppColors.accentSteps},
      {'label': 'Total Steps', 'value': '42k', 'icon': Icons.directions_run_rounded, 'color': AppColors.accentCalories},
    ];

    return Row(
      children: stats.map((stat) {
        return Expanded(
          child: FrostedCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (stat['color'] as Color).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      stat['icon'] as IconData,
                      color: stat['color'] as Color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    stat['value'] as String,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    stat['label'] as String,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: isDark ? Colors.white : const Color(0xFF1F2937),
      ),
    );
  }

  Widget _buildQuickActions(bool isDark, Color onSurface) {
    final actions = [
      {'icon': Icons.edit_rounded, 'label': 'Edit Profile', 'color': AppColors.primaryGradient.colors.first},
      {'icon': Icons.share_rounded, 'label': 'Share Profile', 'color': AppColors.accentSteps},
      {'icon': Icons.qr_code_rounded, 'label': 'QR Code', 'color': AppColors.accentCalories},
    ];

    return Row(
      children: actions.map((action) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FrostedCard(
              onTap: () {
                HapticFeedback.lightImpact();
                // Handle action
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    Icon(
                      action['icon'] as IconData,
                      color: action['color'] as Color,
                      size: 24,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      action['label'] as String,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: onSurface.withValues(alpha: 0.8),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSettingsSection(ThemeService themeService, bool isDark, Color onSurface) {
    return FrostedCard(
      child: Column(
        children: [
          _buildModernSettingsTile(
            icon: Icons.palette_rounded,
            title: 'Theme',
            subtitle: _getThemeModeLabel(themeService.themeMode),
            isDark: isDark,
            onSurface: onSurface,
            trailing: _buildThemeToggle(themeService, isDark),
          ),
          const Divider(height: 1, indent: 56),
          _buildModernSettingsTile(
            icon: Icons.notifications_rounded,
            title: 'Notifications',
            subtitle: 'Manage notifications',
            isDark: isDark,
            onSurface: onSurface,
            onTap: () {},
          ),
          const Divider(height: 1, indent: 56),
          _buildModernSettingsTile(
            icon: Icons.lock_rounded,
            title: 'Privacy',
            subtitle: 'Privacy settings',
            isDark: isDark,
            onSurface: onSurface,
            onTap: () {},
          ),
          const Divider(height: 1, indent: 56),
          _buildModernSettingsTile(
            icon: Icons.help_outline_rounded,
            title: 'Help Center',
            subtitle: 'Get support',
            isDark: isDark,
            onSurface: onSurface,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection(bool isDark, Color onSurface) {
    return FrostedCard(
      child: Column(
        children: [
          _buildModernSettingsTile(
            icon: Icons.info_outline_rounded,
            title: 'About',
            subtitle: 'App version & info',
            isDark: isDark,
            onSurface: onSurface,
            onTap: () {},
          ),
          const Divider(height: 1, indent: 56),
          _buildModernSettingsTile(
            icon: Icons.logout_rounded,
            title: 'Logout',
            subtitle: 'Sign out of your account',
            isDark: isDark,
            onSurface: onSurface,
            titleColor: Colors.red,
            onTap: _handleLogout,
          ),
        ],
      ),
    );
  }

  Widget _buildModernSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
    required Color onSurface,
    Widget? trailing,
    VoidCallback? onTap,
    Color? titleColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryGradient.colors.first.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: titleColor ?? AppColors.primaryGradient.colors.first,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: titleColor ?? onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null)
              trailing
            else if (onTap != null)
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: onSurface.withValues(alpha: 0.55),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeToggle(ThemeService themeService, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: PopupMenuButton<ThemeMode>(
        icon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getThemeIcon(themeService.themeMode),
              size: 14,
              color: Colors.white,
            ),
            const SizedBox(width: 6),
            Text(
              _getThemeModeLabel(themeService.themeMode),
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.arrow_drop_down_rounded,
              size: 16,
              color: Colors.white,
            ),
          ],
        ),
        offset: const Offset(0, 40),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        onSelected: (ThemeMode mode) {
          themeService.setThemeMode(mode);
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: ThemeMode.system,
            child: Row(
              children: [
                Icon(Icons.brightness_auto_rounded, size: 18),
                const SizedBox(width: 12),
                const Text('System'),
              ],
            ),
          ),
          PopupMenuItem(
            value: ThemeMode.light,
            child: Row(
              children: [
                Icon(Icons.light_mode_rounded, size: 18),
                const SizedBox(width: 12),
                const Text('Light'),
              ],
            ),
          ),
          PopupMenuItem(
            value: ThemeMode.dark,
            child: Row(
              children: [
                Icon(Icons.dark_mode_rounded, size: 18),
                const SizedBox(width: 12),
                const Text('Dark'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getThemeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return Icons.brightness_auto_rounded;
      case ThemeMode.light:
        return Icons.light_mode_rounded;
      case ThemeMode.dark:
        return Icons.dark_mode_rounded;
    }
  }

  String _getThemeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }
}
