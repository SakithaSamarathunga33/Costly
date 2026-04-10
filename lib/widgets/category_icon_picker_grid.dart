import 'package:flutter/material.dart';

import '../utils/constants.dart';

/// Icon grid for category dialogs. When the keyboard is open, height is limited
/// so several full rows stay on screen; remaining icons scroll inside the grid.
class CategoryIconPickerGrid extends StatelessWidget {
  const CategoryIconPickerGrid({
    super.key,
    required this.selectedIcon,
    required this.selectedColor,
    required this.primary,
    required this.onIconSelected,
  });

  final String selectedIcon;
  final int selectedColor;
  final Color primary;
  final ValueChanged<String> onIconSelected;

  static const int _crossAxisCount = 6;
  static const double _mainAxisSpacing = 10;
  static const double _crossAxisSpacing = 10;
  /// Rows visible when IME is open (scroll inside grid for the rest).
  static const int _rowsWhenKeyboardOpen = 4;
  /// Extra px so rows are not clipped by subpixel / padding rounding.
  static const double _keyboardViewportHeightBuffer = 12;

  double _gridCrossExtent(double? maxWidth, BuildContext context) {
    var w = maxWidth ?? 0;
    if (!w.isFinite || w <= 0) {
      final screenW = MediaQuery.sizeOf(context).width;
      // Dialog: horizontal insetPadding ~24*2 + dialog padding ~24*2
      w = (screenW - 96).clamp(200.0, screenW);
    }
    return (w - (_crossAxisCount - 1) * _crossAxisSpacing) / _crossAxisCount;
  }

  @override
  Widget build(BuildContext context) {
    final imeOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Square cells: main-axis extent must match cross-axis cell width.
        final cellExtent = _gridCrossExtent(constraints.maxWidth, context);
        final clampHeight = _rowsWhenKeyboardOpen * cellExtent +
            (_rowsWhenKeyboardOpen - 1) * _mainAxisSpacing +
            _keyboardViewportHeightBuffer;

        final entries = kIconPool.entries.toList();

        final gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _crossAxisCount,
          mainAxisSpacing: _mainAxisSpacing,
          crossAxisSpacing: _crossAxisSpacing,
          mainAxisExtent: cellExtent,
        );

        Widget grid = GridView.builder(
          padding: EdgeInsets.zero,
          gridDelegate: gridDelegate,
          itemCount: entries.length,
          shrinkWrap: !imeOpen,
          physics: imeOpen
              ? const ClampingScrollPhysics()
              : const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final entry = entries[index];
            final isActive = entry.key == selectedIcon;
            return GestureDetector(
              onTap: () => onIconSelected(entry.key),
              child: Container(
                decoration: BoxDecoration(
                  color: isActive ? primary : const Color(0xFFF8F6FC),
                  borderRadius: BorderRadius.circular(12),
                  border: isActive
                      ? null
                      : Border.all(color: Colors.grey.withOpacity(0.15)),
                ),
                child: Icon(
                  entry.value,
                  size: 22,
                  color: isActive ? Colors.white : Color(selectedColor),
                ),
              ),
            );
          },
        );

        if (imeOpen) {
          return SizedBox(height: clampHeight, child: grid);
        }
        return grid;
      },
    );
  }
}
