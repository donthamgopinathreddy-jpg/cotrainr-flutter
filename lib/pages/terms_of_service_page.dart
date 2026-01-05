import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

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
          'Terms of Service',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF1F2937),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFFF7A00),
                  const Color(0xFFFFC300),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF7A00).withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  Icons.description_rounded,
                  size: 48,
                  color: Colors.white,
                ),
                const SizedBox(height: 16),
                Text(
                  'Terms of Service',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Last updated: ${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Terms Content
          _buildSection(
            context,
            '1. Acceptance of Terms',
            'By accessing and using CoTrainr, you accept and agree to be bound by the terms and provision of this agreement. If you do not agree to abide by the above, please do not use this service.',
            isDark,
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            '2. Use License',
            'Permission is granted to temporarily download one copy of CoTrainr for personal, non-commercial transitory viewing only. This is the grant of a license, not a transfer of title, and under this license you may not:\n\n• Modify or copy the materials\n• Use the materials for any commercial purpose\n• Attempt to decompile or reverse engineer any software\n• Remove any copyright or other proprietary notations',
            isDark,
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            '3. User Account',
            'You are responsible for maintaining the confidentiality of your account and password. You agree to accept responsibility for all activities that occur under your account. You must notify us immediately of any unauthorized use of your account.',
            isDark,
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            '4. Health and Fitness Data',
            'CoTrainr collects and processes health and fitness data including steps, calories, water intake, and workout information. By using our service, you consent to the collection and use of this data to provide personalized fitness tracking and recommendations. We do not sell your personal health data to third parties.',
            isDark,
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            '5. Prohibited Uses',
            'You may not use CoTrainr:\n\n• In any way that violates any applicable law or regulation\n• To transmit any malicious code or viruses\n• To impersonate or attempt to impersonate the company\n• To engage in any automated use of the system\n• To interfere with or disrupt the service or servers',
            isDark,
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            '6. Intellectual Property',
            'All content, features, and functionality of CoTrainr, including but not limited to text, graphics, logos, icons, images, and software, are the exclusive property of CoTrainr and are protected by international copyright, trademark, and other intellectual property laws.',
            isDark,
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            '7. Disclaimer',
            'The materials on CoTrainr are provided on an "as is" basis. CoTrainr makes no warranties, expressed or implied, and hereby disclaims and negates all other warranties including, without limitation, implied warranties or conditions of merchantability, fitness for a particular purpose, or non-infringement of intellectual property or other violation of rights.',
            isDark,
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            '8. Limitations',
            'In no event shall CoTrainr or its suppliers be liable for any damages (including, without limitation, damages for loss of data or profit, or due to business interruption) arising out of the use or inability to use the materials on CoTrainr, even if CoTrainr or a CoTrainr authorized representative has been notified orally or in writing of the possibility of such damage.',
            isDark,
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            '9. Accuracy of Materials',
            'The materials appearing on CoTrainr could include technical, typographical, or photographic errors. CoTrainr does not warrant that any of the materials on its website are accurate, complete, or current. CoTrainr may make changes to the materials contained on its website at any time without notice.',
            isDark,
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            '10. Modifications',
            'CoTrainr may revise these terms of service at any time without notice. By using this service you are agreeing to be bound by the then current version of these terms of service.',
            isDark,
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            '11. Governing Law',
            'These terms and conditions are governed by and construed in accordance with the laws of India and you irrevocably submit to the exclusive jurisdiction of the courts in that location.',
            isDark,
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            '12. Contact Information',
            'If you have any questions about these Terms of Service, please contact us at:\n\nEmail: support@cotrainr.com\nWebsite: www.cotrainr.com',
            isDark,
          ),
          const SizedBox(height: 32),

          // Agreement Checkbox
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F2937) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: const Color(0xFFFF7A00),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'By using CoTrainr, you acknowledge that you have read, understood, and agree to be bound by these Terms of Service.',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}







