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
  static const double _barHeight = 68.0;
  static const double _middleSize = 64.0;
  static const double _floatingGap = 24.0;
  static const double _topSpace = (_middleSize / 2) + 8;
  static const double _cornerRadius = 28.0;
  static const double _notchRadius = 36.0;

  static double heightFor(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return _barHeight + _topSpace + bottomInset + _floatingGap;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final barBottom = bottomInset + _floatingGap;
    final middleBottom = barBottom + _barHeight - (_middleSize / 2) + 2;

    return SizedBox(
      height: _barHeight + _topSpace + barBottom,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            left: 16,
            right: 16,
            bottom: barBottom,
            child: PhysicalShape(
              color: Colors.white,
              elevation: 10,
              shadowColor: Colors.black.withValues(alpha: 0.12),
              clipper: const _NotchedNavBarClipper(
                cornerRadius: _cornerRadius,
                notchRadius: _notchRadius,
              ),
              child: SizedBox(
                height: _barHeight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: _NavItem(
                          index: 0,
                          item: items[0],
                          selected: currentIndex == 0,
                          onTap: onTap,
                        ),
                      ),
                      Expanded(
                        child: _NavItem(
                          index: 1,
                          item: items[1],
                          selected: currentIndex == 1,
                          onTap: onTap,
                        ),
                      ),
                      Expanded(child: const SizedBox.shrink()),
                      Expanded(
                        child: _NavItem(
                          index: 2,
                          item: items[2],
                          selected: currentIndex == 2,
                          onTap: onTap,
                        ),
                      ),
                      Expanded(
                        child: _NavItem(
                          index: 3,
                          item: items[3],
                          selected: currentIndex == 3,
                          onTap: onTap,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: middleBottom,
            child: _FloatingMiddleButton(
              item: middleItem,
              onTap: onMiddleTap,
              size: _middleSize,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotchedNavBarClipper extends CustomClipper<Path> {
  const _NotchedNavBarClipper({
    required this.cornerRadius,
    required this.notchRadius,
  });

  final double cornerRadius;
  final double notchRadius;

  @override
  Path getClip(Size size) {
    final width = size.width;
    final height = size.height;
    final centerX = width / 2;
    final outer = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, width, height),
          Radius.circular(cornerRadius),
        ),
      );

    // True semicircle notch: cut by a full circle centered on top edge.
    final notch = Path()
      ..addOval(
        Rect.fromCircle(center: Offset(centerX, 0), radius: notchRadius),
      );

    return Path.combine(PathOperation.difference, outer, notch);
  }

  @override
  bool shouldReclip(covariant _NotchedNavBarClipper oldClipper) {
    return oldClipper.cornerRadius != cornerRadius ||
        oldClipper.notchRadius != notchRadius;
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
    final color = selected ? AppTheme.unilaBlack : AppTheme.textMuted;
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

class _FloatingMiddleButton extends StatelessWidget {
  const _FloatingMiddleButton({
    required this.item,
    required this.onTap,
    required this.size,
  });

  final Style15NavItem item;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(size / 2),
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.accentYellow,
            boxShadow: [
              BoxShadow(
                color: AppTheme.accentYellow.withValues(alpha: 0.45),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(item.icon, color: AppTheme.unilaBlack, size: 30),
        ),
      ),
    );
  }
}
