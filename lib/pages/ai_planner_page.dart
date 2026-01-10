import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AIPlannerPage extends StatefulWidget {
  const AIPlannerPage({super.key});

  @override
  State<AIPlannerPage> createState() => _AIPlannerPageState();
}

class _AIPlannerPageState extends State<AIPlannerPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _mealPromptController = TextEditingController();
  final TextEditingController _workoutPromptController = TextEditingController();
  bool _isGenerating = false;
  String? _generatedPlan;
  String? _planType;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _mealPromptController.dispose();
    _workoutPromptController.dispose();
    super.dispose();
  }

  Future<void> _generateMealPlan() async {
    if (_mealPromptController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your preferences')),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
      _planType = 'meal';
    });

    try {
      // In production, this would call your backend API/Edge Function
      // For now, we'll simulate with a delay
      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _generatedPlan = '''
**Meal Plan for ${_mealPromptController.text}**

**Breakfast:**
- Oatmeal with berries and nuts (350 cal)
- Protein: 15g, Carbs: 45g, Fat: 10g

**Lunch:**
- Grilled chicken salad with quinoa (450 cal)
- Protein: 35g, Carbs: 40g, Fat: 15g

**Dinner:**
- Salmon with sweet potato and vegetables (500 cal)
- Protein: 40g, Carbs: 50g, Fat: 20g

**Snacks:**
- Greek yogurt with almonds (200 cal)
- Protein: 20g, Carbs: 15g, Fat: 12g

**Total: 1,500 calories | Protein: 110g | Carbs: 150g | Fat: 57g**
        ''';
        _isGenerating = false;
      });
    } catch (e) {
      setState(() => _isGenerating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating plan: $e')),
      );
    }
  }

  Future<void> _generateWorkoutPlan() async {
    if (_workoutPromptController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your preferences')),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
      _planType = 'workout';
    });

    try {
      // In production, this would call your backend API/Edge Function
      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _generatedPlan = '''
**Workout Plan for ${_workoutPromptController.text}**

**Day 1 - Upper Body:**
- Bench Press: 4x8
- Rows: 4x8
- Shoulder Press: 3x10
- Bicep Curls: 3x12
- Tricep Dips: 3x12

**Day 2 - Lower Body:**
- Squats: 4x8
- Deadlifts: 4x6
- Leg Press: 3x12
- Calf Raises: 3x15

**Day 3 - Rest**

**Day 4 - Full Body:**
- Pull-ups: 3x8
- Push-ups: 3x15
- Lunges: 3x12 each leg
- Plank: 3x60s

**Day 5 - Cardio:**
- 30 min run or bike
- 20 min HIIT

**Day 6-7 - Rest**
        ''';
        _isGenerating = false;
      });
    } catch (e) {
      setState(() => _isGenerating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating plan: $e')),
      );
    }
  }

  Future<void> _savePlan() async {
    if (_generatedPlan == null) return;

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      await Supabase.instance.client.from('saved_plans').insert({
        'user_id': userId,
        'plan_type': _planType,
        'plan_content': _generatedPlan,
        'created_at': DateTime.now().toIso8601String(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plan saved successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving plan: $e')),
      );
    }
  }

  Future<void> _shareToTrainer() async {
    if (_generatedPlan == null) return;

    // Navigate to messages with pre-filled plan
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening messages to share plan...')),
    );
    // In production, navigate to messages page with plan content
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF111827) : const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'AI Planner',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFFF7A00),
          unselectedLabelColor: isDark ? Colors.grey : Colors.black54,
          indicatorColor: const Color(0xFFFF7A00),
          tabs: const [
            Tab(text: 'Meal Planner'),
            Tab(text: 'Workout Planner'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMealPlanner(isDark),
          _buildWorkoutPlanner(isDark),
        ],
      ),
    );
  }

  Widget _buildMealPlanner(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Generate Your Meal Plan',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tell us your goals, dietary preferences, and we\'ll create a personalized meal plan.',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 24),

          // Input
          TextField(
            controller: _mealPromptController,
            maxLines: 6,
            decoration: InputDecoration(
              hintText: 'e.g., "I want to lose weight, prefer vegetarian meals, 1500 calories per day"',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: isDark ? const Color(0xFF1F2937) : Colors.white,
            ),
            style: const TextStyle(fontFamily: 'Poppins'),
          ),
          const SizedBox(height: 16),

          // Generate Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isGenerating ? null : _generateMealPlan,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF7A00),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isGenerating
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Generate Meal Plan',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),

          // Generated Plan
          if (_generatedPlan != null && _planType == 'meal') ...[
            const SizedBox(height: 32),
            _buildPlanCard(_generatedPlan!, isDark),
          ],
        ],
      ),
    );
  }

  Widget _buildWorkoutPlanner(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Generate Your Workout Plan',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tell us your fitness goals, available equipment, and we\'ll create a personalized workout plan.',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 24),

          // Input
          TextField(
            controller: _workoutPromptController,
            maxLines: 6,
            decoration: InputDecoration(
              hintText: 'e.g., "I want to build muscle, have access to a gym, can train 4 days per week"',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: isDark ? const Color(0xFF1F2937) : Colors.white,
            ),
            style: const TextStyle(fontFamily: 'Poppins'),
          ),
          const SizedBox(height: 16),

          // Generate Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isGenerating ? null : _generateWorkoutPlan,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF7A00),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isGenerating
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Generate Workout Plan',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),

          // Generated Plan
          if (_generatedPlan != null && _planType == 'workout') ...[
            const SizedBox(height: 32),
            _buildPlanCard(_generatedPlan!, isDark),
          ],
        ],
      ),
    );
  }

  Widget _buildPlanCard(String plan, bool isDark) {
    return Container(
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
          Text(
            plan,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _savePlan,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Color(0xFFFF7A00)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Save Plan',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: Color(0xFFFF7A00),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _shareToTrainer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7A00),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Share to Trainer',
                    style: TextStyle(fontFamily: 'Poppins'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


