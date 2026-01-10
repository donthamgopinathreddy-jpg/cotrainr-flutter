import 'package:flutter/material.dart';
import '../frosted_card.dart';

class StreakWideTile extends StatelessWidget {
  final int streakDays;
  final double weeklyProgress;
  final List<bool> last7Days;
  final VoidCallback? onTap;

  const StreakWideTile({
    super.key,
    required this.streakDays,
    required this.weeklyProgress,
    required this.last7Days,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return FrostedCard(
      onTap: onTap,
      child: SizedBox(
        height: 80,
        child: Row(
          children: [
            // Square Icon Container (Smaller)
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFF7A00), Color(0xFFFFC300)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF7A00).withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.local_fire_department_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),

            // Center Text
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$streakDays Day Streak',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: onSurface,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Keep it up!',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),

            // Mini Calendar Dots (Smaller)
            Row(
              children: last7Days.map((isActive) {
                return Container(
                  width: 5,
                  height: 5,
                  margin: const EdgeInsets.only(left: 3),
                  decoration: BoxDecoration(
                    gradient: isActive
                        ? const LinearGradient(
                            colors: [Color(0xFFFF7A00), Color(0xFFFFC300)],
                          )
                        : null,
                    color: isActive
                        ? null
                        : onSurface.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                    border: isActive
                        ? null
                        : Border.all(
                            color: onSurface.withValues(alpha: 0.18),
                            width: 1,
                          ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: onSurface.withValues(alpha: 0.55),
            ),
          ],
        ),
      ),
    );
  }
}

