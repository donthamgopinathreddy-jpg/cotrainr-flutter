import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'nutritionist_home_page.dart';
import 'clients_page.dart';
import 'quests_page.dart';
import 'cocircle_page.dart';
import 'profile_page.dart';

class NutritionistNavigation extends StatefulWidget {
  const NutritionistNavigation({super.key});

  @override
  State<NutritionistNavigation> createState() => _NutritionistNavigationState();
}

class _NutritionistNavigationState extends State<NutritionistNavigation>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late PageController _pageController;
  late List<AnimationController> _iconControllers;

  // Page gradients per spec
  final List<List<Color>> _pageGradients = [
    [const Color(0xFF14B8A6), const Color(0xFF84CC16)], // Home: teal→lime
    [const Color(0xFF6366F1), const Color(0xFF06B6D4)], // Clients: indigo→cyan
    [const Color(0xFFF59E0B), const Color(0xFFF97316)], // Quests: amber→orange
    [const Color(0xFF8B5CF6), const Color(0xFFEC4899)], // CoCircle: violet→pink
    [const Color(0xFF64748B), const Color(0xFF475569)], // Profile: blueGrey→slate
  ];

  final List<Widget> _pages = [
    const NutritionistHomePage(),
    const ClientsPage(role: 'nutritionist'),
    const QuestsPage(),
    const CoCirclePage(),
    const ProfilePage(),
  ];

  final List<String> _labels = [
    'Home',
    'Clients',
    'Quests',
    'CoCircle',
    'Profile',
  ];

  final List<IconData> _icons = [
    Icons.home_rounded,
    Icons.people_rounded,
    Icons.emoji_events_rounded,
    Icons.people_rounded,
    Icons.person_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _iconControllers = List.generate(
      5,
      (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 120),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (var controller in _iconControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (index != _currentIndex) {
      HapticFeedback.selectionClick();
      _iconControllers[index].forward().then((_) {
        _iconControllers[index].reverse();
      });
      setState(() {
        _currentIndex = index;
      });
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const BouncingScrollPhysics(),
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
              blurRadius: 18,
              offset: const Offset(0, -2),
              spreadRadius: -2,
            ),
          ],
        ),
        child: SafeArea(
          child: Container(
            height: 65,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(5, (index) {
                final isSelected = _currentIndex == index;
                final gradientColors = _pageGradients[index];
                return Expanded(
                  child: GestureDetector(
                    onTap: () => _onTabTapped(index),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeInOutCubic,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeInOutCubic,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: isSelected
                                    ? LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: gradientColors,
                                      )
                                    : null,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: gradientColors[0].withValues(alpha: 0.3),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                          spreadRadius: 0,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: AnimatedBuilder(
                                animation: _iconControllers[index],
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: 0.92 + (_iconControllers[index].value * 0.14),
                                    child: Icon(
                                      _icons[index],
                                      color: isSelected
                                          ? Colors.white
                                          : (isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280)),
                                      size: isSelected ? 24 : 22,
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _labels[index],
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 10,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                color: isSelected
                                    ? gradientColors[0]
                                    : (isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

