import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class QuestsPage extends StatefulWidget {
  const QuestsPage({super.key});

  @override
  State<QuestsPage> createState() => _QuestsPageState();
}

class _QuestsPageState extends State<QuestsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _dailyQuests = [];
  List<Map<String, dynamic>> _weeklyQuests = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadQuests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadQuests() async {
    setState(() => _isLoading = true);
    try {
      // Load from database
      final today = DateTime.now();
      final startOfWeek = today.subtract(Duration(days: today.weekday - 1));

      final dailyResponse = await Supabase.instance.client
          .from('user_quests')
          .select('''
            *,
            quests:quest_id (*)
          ''')
          .eq('type', 'daily')
          .gte('created_at', DateTime(today.year, today.month, today.day).toIso8601String())
          .limit(10);

      final weeklyResponse = await Supabase.instance.client
          .from('user_quests')
          .select('''
            *,
            quests:quest_id (*)
          ''')
          .eq('type', 'weekly')
          .gte('created_at', startOfWeek.toIso8601String())
          .limit(10);

      // Process responses
      _dailyQuests = dailyResponse.map((q) => q).toList();
      _weeklyQuests = weeklyResponse.map((q) => q).toList();

      // Generate demo quests if database is empty
      if (_dailyQuests.isEmpty) {
        _generateDailyQuests();
      }
      if (_weeklyQuests.isEmpty) {
        _generateWeeklyQuests();
      }
    } catch (e) {
      print('Error loading quests: $e');
      _generateDailyQuests();
      _generateWeeklyQuests();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _generateDailyQuests() {
    setState(() {
      _dailyQuests = [
        {
          'quest_id': 'd1',
          'title': '10,000 steps before 8:00 AM',
          'description': 'Complete 10,000 steps before 8:00 AM',
          'type': 'daily',
          'points': 50,
          'progress': 7500,
          'target': 10000,
          'completed': false,
          'icon': Icons.directions_walk,
        },
        {
          'quest_id': 'd2',
          'title': 'Drink 2.5L water today',
          'description': 'Drink at least 2.5 liters of water',
          'type': 'daily',
          'points': 30,
          'progress': 1500,
          'target': 2500,
          'completed': false,
          'icon': Icons.water_drop,
        },
        {
          'quest_id': 'd3',
          'title': 'Hit 500 active calories',
          'description': 'Burn 500 active calories through exercise',
          'type': 'daily',
          'points': 40,
          'target': 500,
          'progress': 320,
          'completed': false,
          'icon': Icons.local_fire_department,
        },
        {
          'quest_id': 'd4',
          'title': 'Complete a 20 minute workout',
          'description': 'Log a workout session of at least 20 minutes',
          'type': 'daily',
          'points': 35,
          'target': 20,
          'progress': 0,
          'completed': false,
          'icon': Icons.fitness_center,
        },
      ];
    });
  }

  void _generateWeeklyQuests() {
    setState(() {
      _weeklyQuests = [
        {
          'quest_id': 'w1',
          'title': '70,000 steps this week',
          'description': 'Accumulate 70,000 steps over the week',
          'type': 'weekly',
          'points': 150,
          'progress': 45000,
          'target': 70000,
          'completed': false,
          'icon': Icons.directions_walk,
        },
        {
          'quest_id': 'w2',
          'title': '7 day water consistency',
          'description': 'Drink 2L+ water every day for 7 days',
          'type': 'weekly',
          'points': 100,
          'progress': 5,
          'target': 7,
          'completed': false,
          'icon': Icons.water_drop,
        },
        {
          'quest_id': 'w3',
          'title': 'Log meals at least 5 days',
          'description': 'Log your meals for at least 5 days this week',
          'type': 'weekly',
          'points': 80,
          'progress': 3,
          'target': 5,
          'completed': false,
          'icon': Icons.restaurant,
        },
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF111827) : const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Quests',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1F2937),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF7A00), Color(0xFFFFC300)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.stars, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '1,250',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Tabs
            TabBar(
              controller: _tabController,
              labelColor: const Color(0xFFFF7A00),
              unselectedLabelColor: isDark ? Colors.grey : Colors.black54,
              indicatorColor: const Color(0xFFFF7A00),
              tabs: const [
                Tab(text: 'Daily'),
                Tab(text: 'Weekly'),
                Tab(text: 'Competitions'),
              ],
            ),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildQuestsList(_dailyQuests, isDark),
                  _buildQuestsList(_weeklyQuests, isDark),
                  _buildCompetitionsList(isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestsList(List<Map<String, dynamic>> quests, bool isDark) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: quests.length,
      itemBuilder: (context, index) {
        return _buildQuestCard(quests[index], isDark);
      },
    );
  }

  Widget _buildQuestCard(Map<String, dynamic> quest, bool isDark) {
    final progress = quest['progress'] as num? ?? 0;
    final target = quest['target'] as num? ?? 1;
    final completed = quest['completed'] as bool? ?? false;
    final progressPercent = (progress / target).clamp(0.0, 1.0);
    final icon = quest['icon'] as IconData? ?? Icons.flag;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        gradient: !isDark
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  const Color(0xFFFFF8E1).withValues(alpha: 0.3),
                  const Color(0xFFFFE0B2).withValues(alpha: 0.2),
                ],
                stops: const [0.0, 0.6, 1.0],
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF7A00).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFFFF7A00), size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quest['title'] as String? ?? 'Quest',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      quest['description'] as String? ?? '',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              if (completed)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 20),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${progress.toInt()}/${target.toInt()}',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1F2937),
                    ),
                  ),
                  Text(
                    '${(progressPercent * 100).toInt()}%',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progressPercent,
                  backgroundColor: isDark ? const Color(0xFF374151) : Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    completed ? Colors.green : const Color(0xFFFF7A00),
                  ),
                  minHeight: 8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Points
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.stars, color: Color(0xFFFFC300), size: 20),
                  const SizedBox(width: 4),
                  Text(
                    '${quest['points'] ?? 0} points',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFFFC300),
                    ),
                  ),
                ],
              ),
              if (!completed)
                ElevatedButton(
                  onPressed: () {
                    // Handle quest action
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7A00),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Complete',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 12),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompetitionsList(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF7A00), Color(0xFFFFC300)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              const Icon(Icons.emoji_events, color: Colors.white, size: 48),
              const SizedBox(height: 16),
              Text(
                'No active competitions',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Check back soon for exciting competitions!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
