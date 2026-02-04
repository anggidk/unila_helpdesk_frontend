import 'package:flutter/material.dart';
import 'package:unila_helpdesk_frontend/app/app_theme.dart';

class Style15NavItem {
  const Style15NavItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class Style15BottomNavBar extends StatelessWidget {
  const Style15BottomNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    required this.middleItem,
    required this.onMiddleTap,
  }) : assert(items.length == 4, 'Style15BottomNavBar expects 4 items.');

  final List<Style15NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Style15NavItem middleItem;
  final VoidCallback onMiddleTap;

  static double heightFor(BuildContext context) {
    const barHeight = 64.0;
    const fabSize = 56.0;
    const extraGap = 8.0;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final totalHeight = barHeight + (fabSize / 2);
    return totalHeight + extraGap + bottomInset;
  }

  @override
  Widget build(BuildContext context) {
    final barHeight = 64.0;
    final fabSize = 56.0;
    final totalHeight = barHeight + (fabSize / 2);
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return SizedBox(
      height: totalHeight + 8 + bottomInset,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            left: 16,
            right: 16,
            bottom: bottomInset,
            child: Container(
              height: barHeight,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(child: _NavItem(index: 0, item: items[0], selected: currentIndex == 0, onTap: onTap)),
                  Expanded(child: _NavItem(index: 1, item: items[1], selected: currentIndex == 1, onTap: onTap)),
                  SizedBox(width: fabSize),
                  Expanded(child: _NavItem(index: 2, item: items[2], selected: currentIndex == 2, onTap: onTap)),
                  Expanded(child: _NavItem(index: 3, item: items[3], selected: currentIndex == 3, onTap: onTap)),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: bottomInset + barHeight - (fabSize / 2),
            child: GestureDetector(
              onTap: onMiddleTap,
              child: Container(
                width: fabSize,
                height: fabSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.accentYellow,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentYellow.withValues(alpha: 0.5),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(
                  middleItem.icon,
                  color: AppTheme.navy,
                  size: 28,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.index,
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final int index;
  final Style15NavItem item;
  final bool selected;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppTheme.navy : AppTheme.textMuted;
    final textStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        );

    return InkWell(
      onTap: () => onTap(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(item.icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(item.label, style: textStyle),
        ],
      ),
    );
  }
}
