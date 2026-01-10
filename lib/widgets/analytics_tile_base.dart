import 'package:flutter/material.dart';
import 'frosted_card.dart';

class AnalyticsTileBase extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accentColor;
  final Widget valueWidget;
  final Widget? trailingWidget;
  final Widget? miniChart;
  final VoidCallback? onTap;

  const AnalyticsTileBase({
    super.key,
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.valueWidget,
    this.trailingWidget,
    this.miniChart,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return FrostedCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Row with Modern Icon Style
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: accentColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: onSurface.withValues(alpha: 0.55),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Value and Trailing Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: valueWidget),
              if (trailingWidget != null) ...[
                const SizedBox(width: 12),
                trailingWidget!,
              ],
            ],
          ),

          // Mini Chart
          if (miniChart != null) ...[
            const SizedBox(height: 16),
            miniChart!,
          ],
        ],
      ),
    );
  }
}

