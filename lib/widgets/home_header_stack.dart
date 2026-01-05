import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';

class HomeHeaderStack extends StatelessWidget {
  final String userName;
  final String? coverImageUrl;
  final String? avatarImageUrl;
  final int notificationCount;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onCoverEditTap;
  final bool isLoading;

  const HomeHeaderStack({
    super.key,
    required this.userName,
    this.coverImageUrl,
    this.avatarImageUrl,
    this.notificationCount = 0,
    this.onNotificationTap,
    this.onAvatarTap,
    this.onCoverEditTap,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final bodyBg = isDarkMode
        ? const Color(0xFF0B1220)
        : const Color(0xFFF6F7FB);
    final coverH = 300.0;
    final blurH = 180.0;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 8 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: SizedBox(
              height: coverH,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: _buildCoverImage(isDarkMode),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.only(
                          top: 12,
                          left: 16,
                          right: 16,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (onCoverEditTap != null)
                              _buildBlurredButton(
                                icon: Icons.edit_rounded,
                                onTap: onCoverEditTap!,
                              ),
                            if (onCoverEditTap != null) const SizedBox(width: 12),
                            _buildNotificationButton(),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    top: coverH - blurH,
                    child: _buildSmoothBlurBlend(bodyBg),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCoverImage(bool isDark) {
    if (coverImageUrl != null) {
      return Image.network(
        coverImageUrl!,
        width: double.infinity,
        height: 300,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildDefaultCover(isDark);
        },
      );
    }
    return _buildDefaultCover(isDark);
  }

  Widget _buildDefaultCover(bool isDark) {
    return Container(
      width: double.infinity,
      height: 300,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF14B8A6).withValues(alpha: 0.3),
            const Color(0xFF84CC16).withValues(alpha: 0.6),
          ],
        ),
      ),
    );
  }

  Widget _buildBlurredButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onNotificationTap?.call();
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(
            Icons.notifications_outlined,
            color: Colors.white,
            size: 28,
          ),
          if (notificationCount > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF4444),
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSmoothBlurBlend(Color bodyBg) {
    return ClipRect(
      child: Stack(
        children: [
          ShaderMask(
            shaderCallback: (rect) {
              return LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.white.withValues(alpha: 0.3),
                  Colors.white.withValues(alpha: 0.7),
                  Colors.white,
                ],
                stops: const [0.0, 0.3, 0.65, 1.0],
              ).createShader(rect);
            },
            blendMode: BlendMode.dstIn,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.white.withValues(alpha: 0.15),
                      Colors.white.withValues(alpha: 0.4),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  bodyBg.withValues(alpha: 0.3),
                  bodyBg.withValues(alpha: 0.7),
                  bodyBg,
                ],
                stops: const [0.0, 0.4, 0.75, 1.0],
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            top: 24,
            bottom: 18,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildBottomLeftAvatar(),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Welcome',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: bodyBg == const Color(0xFF0B1220)
                              ? Colors.white.withValues(alpha: 0.85)
                              : const Color(0xFF1F2937).withValues(alpha: 0.65),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isLoading ? 'Loading...' : userName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          color: bodyBg == const Color(0xFF0B1220)
                              ? Colors.white
                              : const Color(0xFF1F2937),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomLeftAvatar() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onAvatarTap?.call();
      },
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipOval(
          child: avatarImageUrl != null
              ? Image.network(
                  avatarImageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildDefaultAvatar();
                  },
                )
              : _buildDefaultAvatar(),
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: const Color(0xFF14B8A6).withValues(alpha: 0.3),
      child: const Icon(Icons.person, color: Colors.white, size: 36),
    );
  }
}

