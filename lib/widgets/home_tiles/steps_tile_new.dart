import 'package:flutter/material.dart';
import '../analytics_tile_base.dart';
import '../mini_charts.dart';
import '../../theme/app_colors.dart';

class StepsTileNew extends StatelessWidget {
  final int steps;
  final int goal;
  final List<double> weekData;
  final VoidCallback? onTap;

  const StepsTileNew({
    super.key,
    required this.steps,
    required this.goal,
    required this.weekData,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final progress = (steps / goal).clamp(0.0, 1.0);

    return AnalyticsTileBase(
      title: 'Steps',
      icon: Icons.directions_run_rounded,
      accentColor: AppColors.accentSteps,
      valueWidget: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '${_formatSteps(steps)} / ${_formatSteps(goal)}',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: onSurface,
                height: 1.0,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'steps',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                'Goal ${_formatSteps(goal)}',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accentSteps.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${(progress * 100).round()}%',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accentSteps,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      trailingWidget: SizedBox(
        width: 44,
        height: 44,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: 1,
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation<Color>(
                onSurface.withValues(alpha: 0.1),
              ),
            ),
            CircularProgressIndicator(
              value: progress,
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentSteps),
              backgroundColor: Colors.transparent,
            ),
            Text(
              '${(progress * 100).round()}%',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: onSurface,
              ),
            ),
          ],
        ),
      ),
      miniChart: MiniBarChart7(
        values: weekData,
        accent: AppColors.accentSteps,
        highlightIndex: weekData.length - 1,
      ),
      onTap: onTap,
    );
  }

  String _formatSteps(int steps) {
    if (steps >= 1000) {
      return '${(steps / 1000).toStringAsFixed(1)}k';
    }
    return steps.toString();
  }
}

