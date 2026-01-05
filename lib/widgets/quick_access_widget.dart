import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class QuickAccessTile {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  QuickAccessTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

class QuickAccessWidget extends StatelessWidget {
  final String title;
  final List<QuickAccessTile> tiles;
  final bool isDark;

  const QuickAccessWidget({
    super.key,
    required this.title,
    required this.tiles,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 96,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: tiles.length,
              itemBuilder: (context, index) {
                final tile = tiles[index];
                return Padding(
                  padding: EdgeInsets.only(
                    right: index < tiles.length - 1 ? 12 : 0,
                  ),
                  child: _buildQuickAccessTile(tile),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessTile(QuickAccessTile tile) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        tile.onTap();
      },
      child: Container(
        width: 140,
        height: 96,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1F2937)
              : Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
            BoxShadow(
              color: tile.color.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: tile.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(tile.icon, color: tile.color, size: 20),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [tile.color, tile.color.withValues(alpha: 0.6)],
                  ),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Text(
                tile.label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1F2937),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

