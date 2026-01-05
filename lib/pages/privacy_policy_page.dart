import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

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
          'Privacy Policy',
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
                  const Color(0xFF6366F1),
                  const Color(0xFF8B5CF6),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  Icons.privacy_tip_rounded,
                  size: 48,
                  color: Colors.white,
                ),
                const SizedBox(height: 16),
                Text(
                  'Privacy Policy',
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

          // Privacy Content
          _buildSection(
            context,
            '1. Introduction',
            'CoTrainr ("we", "our", or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application and services.',
            isDark,
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            '2. Information We Collect',
            'We collect information that you provide directly to us, including:\n\n• Account Information: Name, email address, phone number, date of birth, gender\n• Health & Fitness Data: Steps, calories burned, water intake, workout data, body metrics (height, weight, BMI)\n• Profile Information: Profile photos, cover images, display name\n• Usage Data: App interactions, feature usage, preferences\n• Device Information: Device type, operating system, unique device identifiers',
            isDark,
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            '3. How We Use Your Information',
            'We use the information we collect to:\n\n• Provide and maintain our services\n• Personalize your fitness experience\n• Track and display your health and fitness progress\n• Send you notifications and updates\n• Improve our services and develop new features\n• Respond to your inquiries and provide customer support\n• Detect, prevent, and address technical issues\n• Comply with legal obligations',
            isDark,
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            '4. Data Storage and Security',
            'Your data is stored securely using industry-standard encryption. We use Supabase for data storage, which provides:\n\n• End-to-end encryption for data in transit\n• Encrypted data at rest\n• Regular security audits and updates\n• Access controls and authentication\n\nWe implement appropriate technical and organizational measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction.',
            isDark,
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            '5. Data Sharing and Disclosure',
            'We do not sell your personal information. We may share your information only in the following circumstances:\n\n• With your explicit consent\n• To comply with legal obligations or court orders\n• To protect our rights, privacy, safety, or property\n• In connection with a business transfer (merger, acquisition, etc.)\n• With service providers who assist us in operating our app (under strict confidentiality agreements)',
            isDark,
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            '6. Health and Fitness Data',
            'Your health and fitness data is sensitive information. We:\n\n• Only collect data necessary for app functionality\n• Do not share health data with third parties for advertising\n• Allow you to control what data is shared\n• Provide tools to delete your health data\n• Comply with applicable health data protection laws',
            isDark,
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            '7. Your Rights and Choices',
            'You have the right to:\n\n• Access your personal data\n• Correct inaccurate or incomplete data\n• Request deletion of your data\n• Object to processing of your data\n• Request data portability\n• Withdraw consent at any time\n• Opt-out of certain communications\n\nTo exercise these rights, contact us at support@cotrainr.com',
            isDark,
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            '8. Cookies and Tracking Technologies',
            'We use cookies and similar tracking technologies to track activity on our app and store certain information. You can instruct your browser to refuse all cookies or to indicate when a cookie is being sent.',
            isDark,
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            '9. Third-Party Services',
            'Our app may contain links to third-party websites or services. We are not responsible for the privacy practices of these third parties. We encourage you to read their privacy policies.',
            isDark,
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            '10. Children\'s Privacy',
            'CoTrainr is not intended for children under the age of 13. We do not knowingly collect personal information from children under 13. If you are a parent or guardian and believe your child has provided us with personal information, please contact us immediately.',
            isDark,
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            '11. Data Retention',
            'We retain your personal information for as long as necessary to provide our services and fulfill the purposes outlined in this policy, unless a longer retention period is required or permitted by law. When you delete your account, we will delete or anonymize your personal information, except where we are required to retain it for legal purposes.',
            isDark,
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            '12. International Data Transfers',
            'Your information may be transferred to and processed in countries other than your country of residence. These countries may have data protection laws that differ from those in your country. We take appropriate safeguards to ensure your data is protected in accordance with this Privacy Policy.',
            isDark,
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            '13. Changes to This Privacy Policy',
            'We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "Last updated" date. You are advised to review this Privacy Policy periodically for any changes.',
            isDark,
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            '14. Contact Us',
            'If you have any questions about this Privacy Policy, please contact us:\n\nEmail: support@cotrainr.com\nWebsite: www.cotrainr.com\n\nWe will respond to your inquiry within 30 days.',
            isDark,
          ),
          const SizedBox(height: 32),

          // Data Protection Notice
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.shield_rounded,
                  color: const Color(0xFF6366F1),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your privacy is important to us. We are committed to protecting your personal information and being transparent about how we use it.',
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







