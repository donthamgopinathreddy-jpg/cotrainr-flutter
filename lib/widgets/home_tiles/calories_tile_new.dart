import 'package:flutter/material.dart';
import '../analytics_tile_base.dart';
import '../mini_charts.dart';
import '../../theme/app_colors.dart';

class CaloriesTileNew extends StatelessWidget {
  final int calories;
  final int target;
  final int burned;
  final int intake;
  final List<double> weekData;
  final VoidCallback? onTap;

  const CaloriesTileNew({
    super.key,
    required this.calories,
    required this.target,
    required this.burned,
    required this.intake,
    required this.weekData,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return AnalyticsTileBase(
      title: 'Calories',
      icon: Icons.whatshot_rounded,
      accentColor: AppColors.accentCalories,
      valueWidget: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _formatNumber(calories),
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
            'kcal',
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
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.accentCalories,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'Burned',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  color: onSurface.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.accentCalories.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'Intake',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  color: onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Target ${_formatNumber(target)}',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
      trailingWidget: MiniStackedBar(
        consumed: calories.toDouble(),
        target: target.toDouble(),
        accent: AppColors.accentCalories,
      ),
      miniChart: MiniBarChart7(
        values: weekData,
        accent: AppColors.accentCalories,
        highlightIndex: weekData.length - 1,
      ),
      onTap: onTap,
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toString();
  }
}

