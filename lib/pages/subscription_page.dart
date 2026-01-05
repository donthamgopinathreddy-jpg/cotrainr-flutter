import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'payment_page.dart';

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  String _currentPlan = 'FREE';
  final PageController _pageController = PageController(viewportFraction: 0.88);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: const Text(
          'Subscription Plans',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text(
                    'Choose Your Plan',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select the plan that best fits your needs',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Current Plan Badge
                  _buildCurrentPlanBadge(colorScheme),
                  const SizedBox(height: 24),

                  // Horizontal Scrolling Plans
                  SizedBox(
                    height: 580,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: 3,
                      itemBuilder: (context, index) {
                        final plans = [
                          _PlanData(
                            id: 'FREE',
                            title: 'FREE',
                            price: '₹0',
                            period: '',
                            rules: [
                              _PlanRule('Trainers', 'Limited'),
                              _PlanRule('Chats', 'Limited'),
                              _PlanRule('Video Sessions', 'Limited'),
                              _PlanRule('Nutritionists', 'No'),
                              _PlanRule('Centers', 'No'),
                              _PlanRule('AI Meal Planner', 'No'),
                              _PlanRule('AI Workout Planner', 'No'),
                            ],
                            gradient: null,
                            icon: Icons.free_breakfast_rounded,
                          ),
                          _PlanData(
                            id: 'BASIC',
                            title: 'BASIC',
                            price: '₹199',
                            period: '/month',
                            rules: [
                              _PlanRule('Trainers', 'Full'),
                              _PlanRule('Chats', 'Unlimited'),
                              _PlanRule('Video Sessions', 'Unlimited'),
                              _PlanRule('Nutritionists', 'Limited'),
                              _PlanRule('Centers', 'Limited'),
                              _PlanRule('AI Meal Planner', 'Limited'),
                              _PlanRule('AI Workout Planner', 'No'),
                            ],
                            gradient: const [Color(0xFF14B8A6), Color(0xFF84CC16)],
                            icon: Icons.star_rounded,
                          ),
                          _PlanData(
                            id: 'PREMIUM',
                            title: 'PREMIUM',
                            price: '₹299',
                            period: '/month',
                            rules: [
                              _PlanRule('Trainers', 'Full'),
                              _PlanRule('Chats', 'Unlimited'),
                              _PlanRule('Video Sessions', 'Unlimited'),
                              _PlanRule('Nutritionists', 'Full'),
                              _PlanRule('Centers', 'Full'),
                              _PlanRule('AI Meal Planner', 'Full'),
                              _PlanRule('AI Workout Planner', 'Full'),
                            ],
                            gradient: const [Color(0xFFFF7A00), Color(0xFFFFC300)],
                            icon: Icons.workspace_premium_rounded,
                          ),
                        ];

                        final plan = plans[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: _buildPlanCard(
                            plan: plan,
                            colorScheme: colorScheme,
                            isDark: isDark,
                            isSelected: _currentPlan == plan.id,
                            onSelect: () => _selectPlan(plan.id),
                            onPay: () => _navigateToPayment(plan),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Page Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      final planIds = ['FREE', 'BASIC', 'PREMIUM'];
                      return Container(
                        width: 32,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: _currentPlan == planIds[index]
                              ? colorScheme.primary
                              : colorScheme.onSurface.withOpacity(0.2),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentPlanBadge(ColorScheme colorScheme) {
    String planName = _currentPlan == 'FREE' ? 'Free' : _currentPlan == 'BASIC' ? 'Basic' : 'Premium';
    Color badgeColor = _currentPlan == 'FREE'
        ? Colors.grey
        : _currentPlan == 'BASIC'
            ? const Color(0xFF14B8A6)
            : const Color(0xFFFF7A00);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded, color: badgeColor, size: 20),
          const SizedBox(width: 12),
          Text(
            'Current Plan: $planName',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard({
    required _PlanData plan,
    required ColorScheme colorScheme,
    required bool isDark,
    required bool isSelected,
    required VoidCallback onSelect,
    required VoidCallback onPay,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: isSelected
            ? Border.all(
                width: 2.5,
                color: plan.gradient != null ? plan.gradient![0] : colorScheme.primary,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
            spreadRadius: -4,
          ),
          if (isSelected && plan.gradient != null)
            BoxShadow(
              color: plan.gradient![0].withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Gradient
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: plan.gradient != null
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: plan.gradient!,
                    )
                  : null,
              color: plan.gradient == null
                  ? (isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6))
                  : null,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: plan.gradient != null
                        ? Colors.white.withValues(alpha: 0.2)
                        : colorScheme.onSurface.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    plan.icon,
                    color: plan.gradient != null ? Colors.white : colorScheme.onSurface,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  plan.title,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: plan.gradient != null
                        ? Colors.white
                        : colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      plan.price,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: plan.gradient != null
                            ? Colors.white
                            : colorScheme.onSurface,
                      ),
                    ),
                    if (plan.period.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6, left: 4),
                        child: Text(
                          plan.period,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            color: plan.gradient != null
                                ? Colors.white.withValues(alpha: 0.8)
                                : colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          // Plan Rules
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Features',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.separated(
                      itemCount: plan.rules.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final rule = plan.rules[index];
                        final isAvailable = rule.value != 'No';
                        return Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: isAvailable
                                    ? (plan.gradient != null
                                        ? plan.gradient![0].withValues(alpha: 0.15)
                                        : colorScheme.primary.withValues(alpha: 0.15))
                                    : colorScheme.onSurface.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                isAvailable
                                    ? Icons.check_rounded
                                    : Icons.close_rounded,
                                size: 16,
                                color: isAvailable
                                    ? (plan.gradient != null
                                        ? plan.gradient![0]
                                        : colorScheme.primary)
                                    : colorScheme.onSurface.withOpacity(0.3),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                rule.feature,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isAvailable
                                    ? (plan.gradient != null
                                        ? plan.gradient![0].withValues(alpha: 0.15)
                                        : colorScheme.primary.withValues(alpha: 0.15))
                                    : colorScheme.onSurface.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                rule.value,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isAvailable
                                      ? (plan.gradient != null
                                          ? plan.gradient![0]
                                          : colorScheme.primary)
                                      : colorScheme.onSurface.withOpacity(0.4),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Buttons
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Select Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      onSelect();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(
                        color: isSelected
                            ? (plan.gradient != null
                                ? plan.gradient![0]
                                : colorScheme.primary)
                            : colorScheme.onSurface.withOpacity(0.3),
                        width: isSelected ? 2 : 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      isSelected ? 'Current Plan' : 'Select Plan',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? (plan.gradient != null
                                ? plan.gradient![0]
                                : colorScheme.primary)
                            : colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
                if (plan.id != 'FREE') ...[
                  const SizedBox(height: 12),
                  // Pay Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        onPay();
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        backgroundColor: plan.gradient != null
                            ? plan.gradient![0]
                            : colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: ShaderMask(
                        shaderCallback: (bounds) => plan.gradient != null
                            ? LinearGradient(
                                colors: plan.gradient!,
                              ).createShader(bounds)
                            : const LinearGradient(
                                colors: [Colors.white, Colors.white],
                              ).createShader(bounds),
                        child: const Text(
                          'Pay Now',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _selectPlan(String plan) {
    setState(() {
      _currentPlan = plan;
    });
    HapticFeedback.mediumImpact();
  }

  void _navigateToPayment(_PlanData plan) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentPage(
          planId: plan.id,
          planName: plan.title,
          planPrice: plan.price,
        ),
      ),
    );
  }
}

class _PlanData {
  final String id;
  final String title;
  final String price;
  final String period;
  final List<_PlanRule> rules;
  final List<Color>? gradient;
  final IconData icon;

  _PlanData({
    required this.id,
    required this.title,
    required this.price,
    required this.period,
    required this.rules,
    this.gradient,
    required this.icon,
  });
}

class _PlanRule {
  final String feature;
  final String value;

  _PlanRule(this.feature, this.value);
}
