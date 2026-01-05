import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../services/theme_provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with TickerProviderStateMixin {
  int _selectedTab = 0; // 0: Overview, 1: Posts, 2: Progress, 3: Saved
  final PageController _tabController = PageController();
  
  final bool _isTrainer = false;
  final String _userName = 'Alex Johnson';
  final String _userID = '@alexjohnson';
  
  // Stats
  final int _postsCount = 24;
  final int _followersCount = 1200;
  final int _followingCount = 456;
  final double _bmi = 22.4;
  final double _height = 170; // cm
  final double _weight = 70; // kg
  
  // Images
  File? _coverImage;
  File? _avatarImage;
  final ImagePicker _picker = ImagePicker();
  
  // Categories
  final List<String> _categories = ['Strength Training', 'Yoga', 'Cardio'];
  
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final coverHeight = screenWidth * 0.30; // 30% of screen width
    
    // Navigation bar height is 65 + SafeArea padding
    final bottomNavBarHeight = 65.0 + MediaQuery.of(context).padding.bottom;
    final safeAreaTop = MediaQuery.of(context).padding.top;
    
    // Calculate available height for tab content
    final estimatedHeaderHeight = coverHeight + 50; // cover + avatar overlap
    final estimatedOtherContentHeight = 350; // identity, actions, stats, tabs
    final tabContentHeight = (screenHeight - safeAreaTop - estimatedHeaderHeight - estimatedOtherContentHeight - bottomNavBarHeight).clamp(400.0, double.infinity);
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF111827) : const Color(0xFFFAFAFA),
      extendBody: false,
      body: SafeArea(
        top: true,
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header - Cover + Profile Image
            _buildHeader(coverHeight, isDark),
            
            // Identity Section
            SliverToBoxAdapter(
              child: _buildIdentitySection(isDark),
            ),
            
            // Quick Action Row
            SliverToBoxAdapter(
              child: _buildQuickActions(isDark),
            ),
            
            // Social Stats Row
            SliverToBoxAdapter(
              child: _buildSocialStats(isDark),
            ),
            
            // Profile Tabs
            SliverToBoxAdapter(
              child: _buildProfileTabs(isDark),
            ),
            
            // Tab Content
            SliverToBoxAdapter(
              child: _buildTabContent(isDark, bottomNavBarHeight, tabContentHeight),
            ),
          ],
        ),
      ),
    );
  }

  // Header - Cover + Profile Image (Editable)
  Widget _buildHeader(double coverHeight, bool isDark) {
    return SliverToBoxAdapter(
      child: Stack(
        children: [
          // Cover Image (Editable on tap)
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _showCoverImagePicker();
            },
            child: Container(
              height: coverHeight,
              width: double.infinity,
              decoration: BoxDecoration(
                image: _coverImage != null
                    ? DecorationImage(
                        image: FileImage(_coverImage!),
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
          
          // Profile Image (Editable on tap, overlaps cover)
          Positioned(
            left: 20,
            bottom: -50,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                _showAvatarImagePicker();
              },
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  image: _avatarImage != null
                      ? DecorationImage(
                          image: FileImage(_avatarImage!),
                          fit: BoxFit.cover,
                        )
                      : const DecorationImage(
                          image: NetworkImage(
                            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
                          ),
                          fit: BoxFit.cover,
                        ),
                ),
                child: Stack(
                  children: [
                    // Edit indicator (subtle)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1F2937) : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Icon(
                          Icons.camera_alt_rounded,
                          size: 16,
                          color: isDark ? Colors.white : const Color(0xFF1F2937),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Identity Section
  Widget _buildIdentitySection(bool isDark) {
    // Avatar size is 100, positioned at -50, so top padding should be 100/2 + 12 = 62 (using 60)
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Full Name
          Text(
            _userName,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 26,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 6),
          // User ID
          Text(
            _userID,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 12),
          // Role Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isTrainer ? Icons.verified_rounded : Icons.person_rounded,
                  size: 14,
                  color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                ),
                const SizedBox(width: 6),
                Text(
                  _isTrainer ? 'Trainer' : 'Client',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Quick Action Row
  Widget _buildQuickActions(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              'Edit Profile',
              Icons.edit_outlined,
              () {
                HapticFeedback.lightImpact();
                // Navigate to Edit Profile
              },
              isDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              'Settings',
              Icons.settings_outlined,
              () {
                HapticFeedback.lightImpact();
                _showSettings(isDark);
              },
              isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onTap, bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(
              color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isDark ? Colors.white : const Color(0xFF1F2937),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : const Color(0xFF1F2937),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Social Stats Row
  Widget _buildSocialStats(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(_postsCount, 'Posts', () {
            HapticFeedback.lightImpact();
            setState(() => _selectedTab = 1);
            _tabController.jumpToPage(1);
          }, isDark),
          _buildStatItem(_followersCount, 'Followers', () {
            HapticFeedback.lightImpact();
            // Show followers list
          }, isDark),
          _buildStatItem(_followingCount, 'Following', () {
            HapticFeedback.lightImpact();
            // Show following list
          }, isDark),
        ],
      ),
    );
  }

  Widget _buildStatItem(int count, String label, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            _formatCount(count),
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  // Profile Tabs
  Widget _buildProfileTabs(bool isDark) {
    final tabs = ['Overview', 'Posts', 'Progress', 'Saved'];
    
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
            width: 0.5,
          ),
        ),
      ),
      child: SizedBox(
        height: 50,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: tabs.length,
          itemBuilder: (context, index) {
            final isSelected = _selectedTab == index;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _selectedTab = index;
                });
                _tabController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: Container(
                margin: const EdgeInsets.only(right: 32),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isSelected
                          ? (isDark ? Colors.white : const Color(0xFF1F2937))
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  tabs[index],
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? (isDark ? Colors.white : const Color(0xFF1F2937))
                        : (isDark ? const Color(0xFF6B6B6B) : const Color(0xFF9E9E9E)),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Tab Content
  Widget _buildTabContent(bool isDark, double bottomNavBarHeight, double height) {
    return SizedBox(
      height: height,
      child: PageView(
        controller: _tabController,
        onPageChanged: (index) {
          setState(() {
            _selectedTab = index;
          });
        },
        children: [
          _buildOverviewTab(isDark, bottomNavBarHeight),
          _buildPostsTab(isDark, bottomNavBarHeight),
          _buildProgressTab(isDark, bottomNavBarHeight),
          _buildSavedTab(isDark, bottomNavBarHeight),
        ],
      ),
    );
  }

  // Overview Tab
  Widget _buildOverviewTab(bool isDark, double bottomPadding) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: bottomPadding + 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Role
          _buildOverviewItem(
            'Role',
            _isTrainer ? 'Trainer' : 'Client',
            Icons.person_outline_rounded,
            isDark,
          ),
          const SizedBox(height: 16),
          
          // Categories
          _buildOverviewItem(
            'Categories',
            _categories.join(', '),
            Icons.category_outlined,
            isDark,
            isCategories: true,
          ),
          const SizedBox(height: 16),
          
          // Height, Weight, BMI
          _buildBodyMetrics(isDark),
          const SizedBox(height: 16),
          
          // Subscription Plan
          _buildSubscriptionPlan(isDark),
        ],
      ),
    );
  }

  Widget _buildOverviewItem(String label, String value, IconData icon, bool isDark, {bool isCategories = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (isCategories)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories.map((cat) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  cat,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                  ),
                ),
              );
            }).toList(),
          )
        else
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
            ),
          ),
      ],
    );
  }

  Widget _buildBodyMetrics(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.straighten_outlined,
              size: 18,
              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
            ),
            const SizedBox(width: 8),
            Text(
              'Body Metrics',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildMetricItem('Height', '${_height.toStringAsFixed(0)} cm', isDark),
            _buildMetricItem('Weight', '${_weight.toStringAsFixed(0)} kg', isDark),
            _buildMetricItem('BMI', _bmi.toStringAsFixed(1), isDark),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricItem(String label, String value, bool isDark) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  Widget _buildSubscriptionPlan(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.card_membership_outlined,
              size: 18,
              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
            ),
            const SizedBox(width: 8),
            Text(
              'Subscription',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1F2937) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Free Plan',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Basic features',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  // Upgrade
                },
                child: const Text('Upgrade'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Posts Tab
  Widget _buildPostsTab(bool isDark, double bottomPadding) {
    return GridView.builder(
      padding: EdgeInsets.only(
        left: 4,
        right: 4,
        top: 4,
        bottom: bottomPadding + 4,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: _postsCount,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            // Open post detail
          },
          child: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(
                  'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400&sig=$index',
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
        );
      },
    );
  }

  // Progress Tab
  Widget _buildProgressTab(bool isDark, double bottomPadding) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: bottomPadding + 20,
      ),
      child: Column(
        children: [
          _buildProgressTile('Steps', '8,234', '/ 10,000', 0.82, Icons.directions_walk_rounded, isDark),
          const SizedBox(height: 16),
          _buildProgressTile('Calories', '1,856', 'kcal', null, Icons.whatshot_rounded, isDark),
          const SizedBox(height: 16),
          _buildProgressTile('Water', '1.2L', '/ 2.5L', 0.48, Icons.water_drop_rounded, isDark),
          const SizedBox(height: 16),
          _buildProgressTile('BMI', _bmi.toStringAsFixed(1), 'Normal', null, Icons.monitor_weight_outlined, isDark),
        ],
      ),
    );
  }

  Widget _buildProgressTile(String title, String value, String subtitle, double? progress, IconData icon, bool isDark) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        // Navigate to detailed insights
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: isDark ? Colors.white : const Color(0xFF1F2937)),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                    ),
                  ),
                ),
              ],
            ),
            if (progress != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDark ? Colors.white : const Color(0xFF1F2937),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Saved Tab
  Widget _buildSavedTab(bool isDark, double bottomPadding) {
    return ListView(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: bottomPadding + 20,
      ),
      children: [
        Text(
          'Saved Trainers',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 12),
        _buildSavedItem('Trainer Name', 'Strength Training', '2.5 km', isDark),
        _buildSavedItem('Trainer Name 2', 'Yoga', '5.2 km', isDark),
        const SizedBox(height: 24),
        Text(
          'Saved Centers',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 12),
        _buildSavedItem('Fitness Center', 'Gym', '1.8 km', isDark),
      ],
    );
  }

  Widget _buildSavedItem(String name, String category, String distance, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$category • $distance',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded),
              onPressed: () {
                // Navigate to profile/maps
              },
            ),
          ],
        ),
      ),
    );
  }

  // Image Pickers
  void _showCoverImagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded),
                title: const Text('Take Photo'),
                onTap: () async {
                  Navigator.pop(context);
                  final image = await _picker.pickImage(source: ImageSource.camera);
                  if (image != null) {
                    setState(() {
                      _coverImage = File(image.path);
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: const Text('Choose from Gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  final image = await _picker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    setState(() {
                      _coverImage = File(image.path);
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAvatarImagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded),
                title: const Text('Take Photo'),
                onTap: () async {
                  Navigator.pop(context);
                  final image = await _picker.pickImage(source: ImageSource.camera);
                  if (image != null) {
                    setState(() {
                      _avatarImage = File(image.path);
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: const Text('Choose from Gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  final image = await _picker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    setState(() {
                      _avatarImage = File(image.path);
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Settings
  void _showSettings(bool isDark) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
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
                    'Settings',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
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
                  // Appearance
                  _buildSettingSection('Appearance', [
                    _buildSettingItem('Light', Icons.light_mode_outlined, () {
                      themeProvider.setThemeMode(ThemeMode.light);
                    }, themeProvider.themeMode == ThemeMode.light, isDark),
                    _buildSettingItem('Dark', Icons.dark_mode_outlined, () {
                      themeProvider.setThemeMode(ThemeMode.dark);
                    }, themeProvider.themeMode == ThemeMode.dark, isDark),
                    _buildSettingItem('System', Icons.brightness_auto_outlined, () {
                      themeProvider.setThemeMode(ThemeMode.system);
                    }, themeProvider.themeMode == ThemeMode.system, isDark),
                  ], isDark),
                  
                  const SizedBox(height: 24),
                  
                  // Units
                  _buildSettingSection('Units', [
                    _buildSettingItem('Height: cm', Icons.straighten_outlined, () {}, false, isDark),
                    _buildSettingItem('Weight: kg', Icons.monitor_weight_outlined, () {}, false, isDark),
                  ], isDark),
                  
                  const SizedBox(height: 24),
                  
                  // Account
                  _buildSettingSection('Account', [
                    _buildSettingItem('Change Password', Icons.lock_outline, () {}, false, isDark),
                    _buildSettingItem('Logout', Icons.logout_outlined, () {}, false, isDark, isDestructive: true),
                  ], isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingSection(String title, List<Widget> items, bool isDark) {
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

  Widget _buildSettingItem(String title, IconData icon, VoidCallback onTap, bool isSelected, bool isDark, {bool isDestructive = false}) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive
            ? Colors.red
            : (isDark ? Colors.white : const Color(0xFF1F2937)),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 15,
          color: isDestructive
              ? Colors.red
              : (isDark ? Colors.white : const Color(0xFF1F2937)),
        ),
      ),
      trailing: isSelected
          ? Icon(
              Icons.check_rounded,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
            )
          : null,
      onTap: onTap,
    );
  }

  String _formatCount(int value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return value.toString();
  }
}
