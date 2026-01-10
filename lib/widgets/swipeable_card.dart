import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Swipeable card with native gestures
class SwipeableCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onLongPress;
  final Color? swipeLeftColor;
  final Color? swipeRightColor;
  final IconData? swipeLeftIcon;
  final IconData? swipeRightIcon;
  final String? swipeLeftLabel;
  final String? swipeRightLabel;

  const SwipeableCard({
    super.key,
    required this.child,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.onDoubleTap,
    this.onLongPress,
    this.swipeLeftColor,
    this.swipeRightColor,
    this.swipeLeftIcon,
    this.swipeRightIcon,
    this.swipeLeftLabel,
    this.swipeRightLabel,
  });

  @override
  State<SwipeableCard> createState() => _SwipeableCardState();
}

class _SwipeableCardState extends State<SwipeableCard> {
  @override
  Widget build(BuildContext context) {
    Widget card = widget.child;

    // Add double tap gesture
    if (widget.onDoubleTap != null) {
      card = GestureDetector(
        onDoubleTap: () {
          HapticFeedback.mediumImpact();
          widget.onDoubleTap!();
        },
        child: card,
      );
    }

    // Add long press gesture
    if (widget.onLongPress != null) {
      card = GestureDetector(
        onLongPress: () {
          HapticFeedback.mediumImpact();
          widget.onLongPress!();
        },
        child: card,
      );
    }

    // Add swipe gestures
    if (widget.onSwipeLeft != null || widget.onSwipeRight != null) {
      DismissDirection direction = DismissDirection.horizontal;
      if (widget.onSwipeLeft != null && widget.onSwipeRight != null) {
        direction = DismissDirection.horizontal;
      } else if (widget.onSwipeLeft != null) {
        direction = DismissDirection.endToStart;
      } else if (widget.onSwipeRight != null) {
        direction = DismissDirection.startToEnd;
      }

      card = Dismissible(
        key: widget.key ?? UniqueKey(),
        direction: direction,
        onDismissed: (direction) {
          if (direction == DismissDirection.endToStart) {
            widget.onSwipeLeft?.call();
          } else {
            widget.onSwipeRight?.call();
          }
        },
        background: widget.onSwipeLeft != null
            ? Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                decoration: BoxDecoration(
                  color: widget.swipeLeftColor ?? Colors.red,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (widget.swipeLeftIcon != null)
                      Icon(
                        widget.swipeLeftIcon,
                        color: Colors.white,
                        size: 32,
                      ),
                    if (widget.swipeLeftLabel != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        widget.swipeLeftLabel!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              )
            : null,
        secondaryBackground: widget.onSwipeRight != null
            ? Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: 20),
                decoration: BoxDecoration(
                  color: widget.swipeRightColor ?? Colors.green,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    if (widget.swipeRightIcon != null)
                      Icon(
                        widget.swipeRightIcon,
                        color: Colors.white,
                        size: 32,
                      ),
                    if (widget.swipeRightLabel != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        widget.swipeRightLabel!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              )
            : null,
        child: card,
      );
    }

    return card;
  }
}


















































