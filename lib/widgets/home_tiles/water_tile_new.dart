import 'package:flutter/material.dart';
import '../analytics_tile_base.dart';
import '../mini_charts.dart';
import '../../theme/app_colors.dart';

class WaterTileNew extends StatelessWidget {
  final double waterLiters;
  final double goalLiters;
  final List<double> weekData;
  final VoidCallback? onTap;
  final Function(double)? onQuickAdd;

  const WaterTileNew({
    super.key,
    required this.waterLiters,
    required this.goalLiters,
    required this.weekData,
    this.onTap,
    this.onQuickAdd,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final progress = (waterLiters / goalLiters).clamp(0.0, 1.0);

    return AnalyticsTileBase(
      title: 'Water',
      icon: Icons.opacity_rounded,
      accentColor: AppColors.accentWater,
      valueWidget: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              waterLiters.toStringAsFixed(1),
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
            'L',
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
                'Goal ${goalLiters.toStringAsFixed(1)}L',
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
                  color: AppColors.accentWater.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${(progress * 100).round()}%',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accentWater,
                  ),
                ),
              ),
            ],
          ),
          if (onQuickAdd != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                _QuickAddChip(
                  label: '+200ml',
                  onTap: () => onQuickAdd!(0.2),
                  accent: AppColors.accentWater,
                ),
                const SizedBox(width: 6),
                _QuickAddChip(
                  label: '+500ml',
                  onTap: () => onQuickAdd!(0.5),
                  accent: AppColors.accentWater,
                ),
                const SizedBox(width: 6),
                _QuickAddChip(
                  label: '+1L',
                  onTap: () => onQuickAdd!(1.0),
                  accent: AppColors.accentWater,
                ),
              ],
            ),
          ],
        ],
      ),
      trailingWidget: SizedBox(
        width: 44,
        height: 44,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.accentWater.withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: FractionallySizedBox(
                    heightFactor: progress,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.accentWater.withValues(alpha: 0.3),
                            AppColors.accentWater,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Icon(
              Icons.water_drop_rounded,
              color: AppColors.accentWater,
              size: 20,
            ),
          ],
        ),
      ),
      miniChart: MiniLineSpark7(
        values: weekData,
        accent: AppColors.accentWater,
      ),
      onTap: onTap,
    );
  }
}

class _QuickAddChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color accent;

  const _QuickAddChip({
    required this.label,
    required this.onTap,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(
            color: onSurface.withValues(alpha: 0.18),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: onSurface.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}

