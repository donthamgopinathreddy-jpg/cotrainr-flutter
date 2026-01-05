import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'weekly_insights_page.dart';
import 'subscription_page.dart';
import 'refer_friend_page.dart';
import 'settings_page.dart';
import 'dart:ui';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // User data - Now fetched from Supabase
  String _userName = 'Loading...';
  String _userID = '@loading';
  bool _isTrainer = false;
  int _currentLevel = 1;
  String _currentRank = 'Beginner';

  // Stats
  int _steps = 0;
  final int _stepsGoal = 10000;
  double _water = 0; // L
  final double _waterGoal = 2.5; // L
  int _calories = 0;
  final int _caloriesGoal = 2000;

  // Body metrics
  double? _height; // cm
  double? _weight; // kg
  double? _bmi;
  String? _gender;

  // Images (read from Supabase profile table)
  String? _coverImageUrl;
  String? _avatarImageUrl;

  // Interests (optional) - from categories
  List<String> _interests = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {
        print('⚠️ [PROFILE] No user ID found');
        setState(() => _isLoading = false);
        return;
      }

      print('🔵 [PROFILE] Fetching profile for user: $userId');

      // Fetch profile data
      final response = await supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response != null && mounted) {
        print('✅ [PROFILE] Profile data received: ${response.keys}');
        print('🔵 [PROFILE] User ID: ${response['user_id']}');
        print('🔵 [PROFILE] Display name: ${response['display_name']}');
        print(
          '🔵 [PROFILE] First name: ${response['first_name']}, Last name: ${response['last_name']}',
        );
        print(
          '🔵 [PROFILE] Height: ${response['height_cm']}, Weight: ${response['weight_kg']}',
        );

        // Get display_name if available, otherwise combine first_name + last_name
        _userName =
            response['display_name'] ??
            '${response['first_name'] ?? ''} ${response['last_name'] ?? ''}'
                .trim();
        if (_userName.isEmpty) {
          _userName = response['user_id'] ?? 'User';
        }

        // Get user ID
        final userId = response['user_id'];
        _userID = userId != null ? '@$userId' : '@user';

        // Get role
        _isTrainer = response['role'] == 'trainer';

        // Get body metrics
        _height = response['height_cm'] != null
            ? (response['height_cm'] as num).toDouble()
            : null;
        _weight = response['weight_kg'] != null
            ? (response['weight_kg'] as num).toDouble()
            : null;
        _bmi = response['bmi'] != null
            ? (response['bmi'] as num).toDouble()
            : null;
        _gender = response['gender'] as String?;

        // Get images from storage paths
        final supabase = Supabase.instance.client;
        _coverImageUrl = response['cover_path'] != null
            ? supabase.storage
                  .from('covers')
                  .getPublicUrl(response['cover_path'])
            : null;
        _avatarImageUrl = response['avatar_path'] != null
            ? supabase.storage
                  .from('avatars')
                  .getPublicUrl(response['avatar_path'])
            : null;

        // Get categories/interests
        if (response['categories'] != null) {
          final categories = response['categories'] as List<dynamic>?;
          _interests = categories?.map((e) => e.toString()).toList() ?? [];
        }

        setState(() => _isLoading = false);
        print(
          '✅ [PROFILE] Profile data loaded: Name=$_userName, UserID=$_userID, Height=$_height, Weight=$_weight',
        );
      } else {
        print('⚠️ [PROFILE] No profile data found');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('❌ [PROFILE] Error fetching profile: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const coverHeight = 240.0; // 220-260 range
    const avatarRadius = 44.0; // 84-96 total size = 42-48 radius
    const overlap = 24.0; // 20-28 overlap

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF111827)
          : const Color(0xFFFAFAFA),
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Top Cover + Profile Section
            _buildTopSection(coverHeight, avatarRadius, overlap, isDark),

            // Spacer for avatar overlap (reduced since avatar is in blur panel)
            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // User Info Section (Settings button - positioned like streak tile on home)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildUserInfoSection(isDark),
              ),
            ),

            // Consistent spacing between tiles
            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // Stats Row
            SliverToBoxAdapter(child: _buildStatsRow(isDark)),

            // Action Buttons Section
            SliverToBoxAdapter(child: _buildActionButtons(isDark)),

            // Interests Section (optional)
            if (_interests.isNotEmpty)
              SliverToBoxAdapter(child: _buildInterestsSection(isDark)),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  // Top Cover + Profile Section (with blur effect like home page)
  Widget _buildTopSection(
    double coverHeight,
    double avatarRadius,
    double overlap,
    bool isDark,
  ) {
    final bodyBg = isDark ? const Color(0xFF0B1220) : const Color(0xFFF6F7FB);
    final blurH = 180.0;

    return SliverToBoxAdapter(
      child: SizedBox(
        height: coverHeight,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Cover Image
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  image: _coverImageUrl != null
                      ? DecorationImage(
                          image: NetworkImage(_coverImageUrl!),
                          fit: BoxFit.cover,
                        )
                      : const DecorationImage(
                          image: NetworkImage(
                            'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800',
                          ),
                          fit: BoxFit.cover,
                        ),
                ),
              ),
            ),

            // Top gradient overlay for status bar readability
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.center,
                    colors: [
                      Colors.black.withValues(alpha: 0.55),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Top buttons - Back and Edit Cover (no rounded background)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Blur effect panel (like home page)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              top: coverHeight - blurH,
              child: _buildSmoothBlurBlend(bodyBg, isDark),
            ),
          ],
        ),
      ),
    );
  }

  // Smooth Blur Blend (same as home page)
  Widget _buildSmoothBlurBlend(Color bodyBg, bool isDark) {
    return ClipRect(
      child: Stack(
        children: [
          // Blur effect with gradient mask
          ShaderMask(
            shaderCallback: (rect) {
              return LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.white.withValues(alpha: 0.3),
                  Colors.white.withValues(alpha: 0.7),
                  Colors.white,
                ],
                stops: const [0.0, 0.3, 0.65, 1.0],
              ).createShader(rect);
            },
            blendMode: BlendMode.dstIn,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.white.withValues(alpha: 0.15),
                      Colors.white.withValues(alpha: 0.4),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
          ),
          // Background gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  bodyBg.withValues(alpha: 0.3),
                  bodyBg.withValues(alpha: 0.7),
                  bodyBg,
                ],
                stops: const [0.0, 0.4, 0.75, 1.0],
              ),
            ),
          ),
          // User info on blur panel with profile picture beside name
          Positioned(
            left: 16,
            right: 16,
            top: 24,
            bottom: 18,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Profile Avatar beside text (aligned with name) - Display only
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.22),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: _avatarImageUrl != null
                            ? Image.network(
                                _avatarImageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: const Color(
                                      0xFF14B8A6,
                                    ).withValues(alpha: 0.3),
                                  );
                                },
                              )
                            : Image.network(
                                'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: const Color(
                                      0xFF14B8A6,
                                    ).withValues(alpha: 0.3),
                                  );
                                },
                              ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Name
                      Text(
                        _userName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: bodyBg == const Color(0xFF0B1220)
                              ? Colors.white
                              : const Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // User ID
                      Text(
                        _userID,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: bodyBg == const Color(0xFF0B1220)
                              ? Colors.white.withValues(alpha: 0.75)
                              : const Color(0xFF1F2937).withValues(alpha: 0.65),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Badge and Level Row
                      Row(
                        children: [
                          // User/Trainer Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              gradient: _isTrainer
                                  ? const LinearGradient(
                                      colors: [
                                        Color(0xFFFF7A00),
                                        Color(0xFFFFC300),
                                      ],
                                    )
                                  : const LinearGradient(
                                      colors: [
                                        Color(0xFF6366F1),
                                        Color(0xFF8B5CF6),
                                      ],
                                    ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _isTrainer
                                      ? Icons.verified_rounded
                                      : Icons.person_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _isTrainer ? 'Trainer' : 'User',
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Level Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: bodyBg == const Color(0xFF0B1220)
                                  ? Colors.white.withValues(alpha: 0.15)
                                  : const Color(
                                      0xFF1F2937,
                                    ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: bodyBg == const Color(0xFF0B1220)
                                    ? Colors.white.withValues(alpha: 0.2)
                                    : const Color(
                                        0xFF1F2937,
                                      ).withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'LVL $_currentLevel',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: bodyBg == const Color(0xFF0B1220)
                                        ? Colors.white
                                        : const Color(0xFF1F2937),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _currentRank,
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: bodyBg == const Color(0xFF0B1220)
                                        ? Colors.white.withValues(alpha: 0.7)
                                        : const Color(
                                            0xFF1F2937,
                                          ).withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // User Info Section (removed duplicate name and userid)
  Widget _buildUserInfoSection(bool isDark) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // User Info Card - Name, User ID, Height, Weight
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name
              Text(
                _userName,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              // User ID
              Text(
                _userID,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 20),
              // Divider
              Divider(
                height: 1,
                thickness: 1,
                color: colorScheme.onSurface.withValues(alpha: 0.1),
              ),
              const SizedBox(height: 20),
              // Height, Weight, and Gender Row
              Row(
                children: [
                  // Height
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Height',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _height != null
                              ? '${_height!.toStringAsFixed(0)} cm'
                              : 'Not set',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Weight
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Weight',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _weight != null
                              ? '${_weight!.toStringAsFixed(1)} kg'
                              : 'Not set',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Gender
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gender',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _gender != null && _gender!.isNotEmpty
                              ? _formatGender(_gender!)
                              : 'Not set',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Settings button (clean with icon)
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsPage()),
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.settings_rounded,
                  color: colorScheme.onSurface,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  'Settings',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Stats Row (Steps avg, Water avg, Calories avg)
  Widget _buildStatsRow(bool isDark) {
    // Calculate averages (simplified - in real app would come from API)
    final stepsAvg = (_steps * 7 / 7).round(); // Weekly average
    final waterAvg = _water; // Daily average
    final caloriesAvg = _calories; // Daily average

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              icon: Icons.directions_walk_rounded,
              value: _formatNumber(stepsAvg),
              label: 'Steps avg',
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WeeklyInsightsPage(
                      type: 'steps',
                      title: 'Steps',
                      icon: Icons.directions_walk_rounded,
                      gradientColors: const [
                        Color(0xFF14B8A6),
                        Color(0xFF84CC16),
                      ],
                      currentValue: _steps,
                      goal: _stepsGoal,
                      weeklyData: [7500, 8200, 6900, 8500, 9100, 8800, _steps],
                    ),
                  ),
                );
              },
              isDark: isDark,
            ),
          ),
          Expanded(
            child: _buildStatItem(
              icon: Icons.water_drop_rounded,
              value: '${waterAvg}L',
              label: 'Water avg',
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WeeklyInsightsPage(
                      type: 'water',
                      title: 'Water',
                      icon: Icons.water_drop_rounded,
                      gradientColors: const [
                        Color(0xFF3B82F6),
                        Color(0xFF06B6D4),
                      ],
                      currentValue: (_water * 1000).round(),
                      goal: (_waterGoal * 1000).round(),
                      weeklyData: [
                        2000,
                        2200,
                        1800,
                        2400,
                        2100,
                        2300,
                        (_water * 1000).round(),
                      ],
                    ),
                  ),
                );
              },
              isDark: isDark,
            ),
          ),
          Expanded(
            child: _buildStatItem(
              icon: Icons.whatshot_rounded,
              value: '$caloriesAvg',
              label: 'Calories avg',
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WeeklyInsightsPage(
                      type: 'calories',
                      title: 'Calories',
                      icon: Icons.whatshot_rounded,
                      gradientColors: const [
                        Color(0xFFFF6B6B),
                        Color(0xFFFF8FA3),
                      ],
                      currentValue: _calories,
                      goal: _caloriesGoal,
                      weeklyData: const [
                        1800,
                        1900,
                        1750,
                        2000,
                        1850,
                        1950,
                        1856,
                      ],
                    ),
                  ),
                );
              },
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(
            icon,
            size: 24,
            color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  // Action Buttons Section
  Widget _buildActionButtons(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          // Refer a Friend (full width)
          _buildActionButton(
            title: 'Refer a Friend',
            icon: Icons.person_add_rounded,
            gradientColors: const [Color(0xFF14B8A6), Color(0xFF84CC16)],
            isDark: isDark,
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ReferFriendPage(),
                ),
              );
            },
            fullWidth: true,
          ),
          const SizedBox(height: 12),
          // Subscription (full width)
          _buildActionButton(
            title: 'Subscription',
            icon: Icons.star_rounded,
            gradientColors: const [Color(0xFFFF7A00), Color(0xFFFFC300)],
            isDark: isDark,
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SubscriptionPage(),
                ),
              );
            },
            fullWidth: true,
          ),
          const SizedBox(height: 12),
          // Become a Trainer (full width)
          _buildActionButton(
            title: 'Become a Trainer',
            icon: Icons.fitness_center_rounded,
            gradientColors: const [Color(0xFF3B82F6), Color(0xFF06B6D4)],
            isDark: isDark,
            onTap: () {
              HapticFeedback.lightImpact();
              // TODO: Implement become trainer page
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Become a trainer feature coming soon')),
              );
            },
            fullWidth: true,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String title,
    required IconData icon,
    required List<Color> gradientColors,
    required bool isDark,
    required VoidCallback onTap,
    bool fullWidth = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: fullWidth ? double.infinity : null,
        padding: const EdgeInsets.all(16),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradientColors),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1F2937),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Interests Section (optional)
  Widget _buildInterestsSection(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Interests',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 36,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _interests.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: EdgeInsets.only(
                    right: index < _interests.length - 1 ? 8 : 0,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF8B5CF6),
                        Color(0xFF6366F1),
                        Color(0xFF14B8A6),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Center(
                    child: Text(
                      _interests[index],
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Images are now edited in Edit Profile page only
  // Profile page only displays images from Supabase profile table

  String _formatGender(String gender) {
    switch (gender.toLowerCase()) {
      case 'male':
        return 'Male';
      case 'female':
        return 'Female';
      case 'other':
        return 'Other';
      case 'prefer_not_to_say':
        return 'Prefer not to say';
      default:
        return gender;
    }
  }

  String _formatNumber(int value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return value.toString();
  }
}
