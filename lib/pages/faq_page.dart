import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FAQPage extends StatefulWidget {
  const FAQPage({super.key});

  @override
  State<FAQPage> createState() => _FAQPageState();
}

class _FAQPageState extends State<FAQPage> {
  final List<FAQItem> _faqs = [
    FAQItem(
      question: 'How do I track my steps?',
      answer:
          'CoTrainr automatically tracks your steps using your phone\'s built-in sensors. Make sure you\'ve granted activity recognition permissions. Your steps are synced throughout the day and displayed on your home screen.',
    ),
    FAQItem(
      question: 'How do quests work?',
      answer:
          'Quests are daily and weekly challenges that help you stay active. Complete quests to earn XP and coins. Daily quests reset every day, while weekly quests reset every Monday. You can view your progress in the Quests tab.',
    ),
    FAQItem(
      question: 'What are achievements?',
      answer:
          'Achievements are milestones you unlock by reaching certain goals, like walking 10,000 steps in a day or maintaining a 7-day streak. Each achievement gives you XP and coins as rewards.',
    ),
    FAQItem(
      question: 'How do I change my profile picture?',
      answer:
          'Go to your Profile page, tap on your profile picture, and select a new image from your gallery. Make sure you grant camera and storage permissions when prompted.',
    ),
    FAQItem(
      question: 'Can I compete with friends?',
      answer:
          'Yes! Join competitions to compete with other users. You can see leaderboards and track your progress. Competitions are based on steps, water intake, calories burned, or overall fitness.',
    ),
    FAQItem(
      question: 'How do I set goals?',
      answer:
          'You can set daily, weekly, or monthly goals for steps, water intake, calories, workouts, or weight. Goals help you stay motivated and track your progress over time.',
    ),
    FAQItem(
      question: 'What happens if I lose my streak?',
      answer:
          'If you miss a day, your streak resets to 0. However, you can start a new streak the next day. Streaks give you bonus XP multipliers, so try to maintain them!',
    ),
    FAQItem(
      question: 'How do I report a bug or issue?',
      answer:
          'Go to Help Center > Report a Problem and describe the issue you\'re experiencing. Our support team will review it and get back to you via email.',
    ),
    FAQItem(
      question: 'Is my data secure?',
      answer:
          'Yes, we take your privacy seriously. All data is encrypted and stored securely. You can manage your privacy settings in Settings > Privacy.',
    ),
    FAQItem(
      question: 'How do I delete my account?',
      answer:
          'Go to Settings > Privacy > Data & Privacy > Delete Account. Please note that this action is permanent and cannot be undone.',
    ),
    FAQItem(
      question: 'Can I use CoTrainr without internet?',
      answer:
          'Yes, you can track your steps and view your data offline. However, you\'ll need internet to sync data, join competitions, and access social features.',
    ),
    FAQItem(
      question: 'How do I contact support?',
      answer:
          'You can reach us at support@cotrainr.com or use the Help Center to send feedback or report problems. We typically respond within 24-48 hours.',
    ),
  ];

  int? _expandedIndex;

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
          'Frequently Asked Questions',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF1F2937),
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(20),
            color: isDark ? const Color(0xFF1F2937) : Colors.white,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search FAQs...',
                hintStyle: TextStyle(
                  fontFamily: 'Poppins',
                  color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF111827) : const Color(0xFFF9FAFB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Color(0xFFFF7A00),
                    width: 2,
                  ),
                ),
              ),
              style: TextStyle(
                fontFamily: 'Poppins',
                color: isDark ? Colors.white : const Color(0xFF1F2937),
              ),
            ),
          ),
          // FAQ List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _faqs.length,
              itemBuilder: (context, index) {
                final faq = _faqs[index];
                final isExpanded = _expandedIndex == index;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1F2937) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isExpanded
                          ? const Color(0xFFFF7A00)
                          : (isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
                      width: isExpanded ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      initiallyExpanded: isExpanded,
                      onExpansionChanged: (expanded) {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _expandedIndex = expanded ? index : null;
                        });
                      },
                      title: Text(
                        faq.question,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF1F2937),
                        ),
                      ),
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            faq.answer,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                              height: 1.6,
                            ),
                          ),
                        ),
                      ],
                      iconColor: const Color(0xFFFF7A00),
                      collapsedIconColor: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
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
}

class FAQItem {
  final String question;
  final String answer;

  FAQItem({required this.question, required this.answer});
}







