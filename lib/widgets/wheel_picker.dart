import 'package:flutter/material.dart';

/// Custom wheel picker widget similar to iOS picker
class WheelPicker extends StatefulWidget {
  final int min;
  final int max;
  final int value;
  final ValueChanged<int> onChanged;
  final String? suffix;
  final double itemHeight;

  const WheelPicker({
    super.key,
    required this.min,
    required this.max,
    required this.value,
    required this.onChanged,
    this.suffix,
    this.itemHeight = 50.0,
  });

  @override
  State<WheelPicker> createState() => _WheelPickerState();
}

class _WheelPickerState extends State<WheelPicker> {
  late FixedExtentScrollController _controller;
  late int _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.value.clamp(widget.min, widget.max);
    final index = _selectedValue - widget.min;
    _controller = FixedExtentScrollController(initialItem: index);
  }

  @override
  void didUpdateWidget(WheelPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _selectedValue = widget.value.clamp(widget.min, widget.max);
      final index = _selectedValue - widget.min;
      if (_controller.hasClients) {
        _controller.animateToItem(
          index,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSelectedItemChanged(int index) {
    final newValue = widget.min + index;
    if (newValue != _selectedValue) {
      setState(() => _selectedValue = newValue);
      widget.onChanged(newValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final itemCount = widget.max - widget.min + 1;

    return Container(
      height: widget.itemHeight * 5,
      decoration: BoxDecoration(
        color: Colors.transparent,
      ),
      child: Stack(
        children: [
          // Fade gradients at top and bottom
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: widget.itemHeight * 2,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      colorScheme.background,
                      colorScheme.background.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: widget.itemHeight * 2,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      colorScheme.background.withValues(alpha: 0.0),
                      colorScheme.background,
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Center highlight band
          Positioned(
            top: widget.itemHeight * 2,
            left: 0,
            right: 0,
            height: widget.itemHeight,
            child: Container(
              decoration: BoxDecoration(
                border: Border.symmetric(
                  horizontal: BorderSide(
                    color: colorScheme.primary.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                color: colorScheme.primary.withValues(alpha: 0.05),
              ),
            ),
          ),
          // ListWheelScrollView
          ListWheelScrollView.useDelegate(
            controller: _controller,
            itemExtent: widget.itemHeight,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: _onSelectedItemChanged,
            perspective: 0.003,
            diameterRatio: 1.2,
            squeeze: 1.0,
            useMagnifier: false,
            childDelegate: ListWheelChildBuilderDelegate(
              builder: (context, index) {
                if (index < 0 || index >= itemCount) {
                  return const SizedBox.shrink();
                }
                final value = widget.min + index;
                final isSelected = value == _selectedValue;

                return Center(
                  child: Text(
                    '${value}${widget.suffix ?? ''}',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: isSelected ? 20 : 16,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected
                          ? colorScheme.onSurface
                          : colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                );
              },
              childCount: itemCount,
            ),
          ),
        ],
      ),
    );
  }
}

