import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class ReportProblemPage extends StatefulWidget {
  const ReportProblemPage({super.key});

  @override
  State<ReportProblemPage> createState() => _ReportProblemPageState();
}

class _ReportProblemPageState extends State<ReportProblemPage> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _stepsController = TextEditingController();
  String _problemType = 'bug';
  String _severity = 'medium';
  bool _isSubmitting = false;

  final List<Map<String, String>> _problemTypes = [
    {'value': 'bug', 'label': 'Bug', 'icon': '🐛'},
    {'value': 'crash', 'label': 'App Crash', 'icon': '💥'},
    {'value': 'performance', 'label': 'Performance Issue', 'icon': '⚡'},
    {'value': 'ui', 'label': 'UI/UX Issue', 'icon': '🎨'},
    {'value': 'other', 'label': 'Other', 'icon': '❓'},
  ];

  final List<Map<String, String>> _severities = [
    {'value': 'low', 'label': 'Low', 'color': '0xFF10B981'},
    {'value': 'medium', 'label': 'Medium', 'color': '0xFFFFC300'},
    {'value': 'high', 'label': 'High', 'color': '0xFFFF7A00'},
    {'value': 'critical', 'label': 'Critical', 'color': '0xFFEF4444'},
  ];

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    _stepsController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    HapticFeedback.mediumImpact();

    try {
      final subject = _subjectController.text.trim();
      final description = _descriptionController.text.trim();
      final steps = _stepsController.text.trim();
      final problemTypeLabel = _problemTypes
          .firstWhere((type) => type['value'] == _problemType)['label']!;
      final severityLabel = _severities
          .firstWhere((sev) => sev['value'] == _severity)['label']!;

      final emailBody = '''
Problem Type: $problemTypeLabel
Severity: $severityLabel

Subject: $subject

Description:
$description

Steps to Reproduce:
${steps.isNotEmpty ? steps : 'Not provided'}

---
Sent from CoTrainr App
''';

      final uri = Uri.parse(
        'mailto:support@cotrainr.com?subject=${Uri.encodeComponent('Problem Report: $subject')}&body=${Uri.encodeComponent(emailBody)}',
      );

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Opening email client...'),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
            ),
          );
          // Clear form after a delay
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              _subjectController.clear();
              _descriptionController.clear();
              _stepsController.clear();
              setState(() {
                _problemType = 'bug';
                _severity = 'medium';
              });
            }
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Could not open email client. Please email support@cotrainr.com directly.'),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

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
          'Report a Problem',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF1F2937),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.bug_report_rounded,
                    color: const Color(0xFFEF4444),
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Help us fix the issue',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : const Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Provide as much detail as possible',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Problem Type
            Text(
              'Problem Type',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _problemTypes.map((type) {
                final isSelected = _problemType == type['value'];
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _problemType = type['value']!);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFEF4444)
                          : (isDark ? const Color(0xFF1F2937) : Colors.white),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFEF4444)
                            : (isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          type['icon']!,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          type['label']!,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Severity
            Text(
              'Severity',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _severities.map((sev) {
                final isSelected = _severity == sev['value'];
                final color = Color(int.parse(sev['color']!));
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _severity = sev['value']!);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color
                          : (isDark ? const Color(0xFF1F2937) : Colors.white),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? color
                            : (isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      sev['label']!,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280)),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Subject
            Text(
              'Subject',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _subjectController,
              decoration: InputDecoration(
                hintText: 'Brief description of the problem',
                hintStyle: TextStyle(
                  fontFamily: 'Poppins',
                  color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF1F2937) : Colors.white,
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
              style: TextStyle(
                fontFamily: 'Poppins',
                color: isDark ? Colors.white : const Color(0xFF1F2937),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a subject';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Description
            Text(
              'Problem Description',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: 'Describe what went wrong...',
                hintStyle: TextStyle(
                  fontFamily: 'Poppins',
                  color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF1F2937) : Colors.white,
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
                contentPadding: const EdgeInsets.all(20),
              ),
              style: TextStyle(
                fontFamily: 'Poppins',
                color: isDark ? Colors.white : const Color(0xFF1F2937),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please describe the problem';
                }
                if (value.trim().length < 20) {
                  return 'Please provide more details (at least 20 characters)';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Steps to Reproduce
            Text(
              'Steps to Reproduce (Optional)',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _stepsController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: '1. Step one\n2. Step two\n3. Step three...',
                hintStyle: TextStyle(
                  fontFamily: 'Poppins',
                  color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF1F2937) : Colors.white,
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
                contentPadding: const EdgeInsets.all(20),
              ),
              style: TextStyle(
                fontFamily: 'Poppins',
                color: isDark ? Colors.white : const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Submit Report',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Info
            Text(
              'Your report will be sent to support@cotrainr.com',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}







