import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';

class AnimatedBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AnimatedBottomNav({super.key, required this.currentIndex, required this.onTap});

  static const _items = [
    (icon: Icons.home_outlined, active: Icons.home_rounded, label: 'Home'),
    (icon: Icons.receipt_long_outlined, active: Icons.receipt_long_rounded, label: 'Transactions'),
    (icon: Icons.savings_outlined, active: Icons.savings_rounded, label: 'Goals'),
    (icon: Icons.bar_chart_outlined, active: Icons.bar_chart_rounded, label: 'Analytics'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: const BoxDecoration(
        color: AppColors.bg800,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        children: List.generate(_items.length, (i) {
          final item = _items[i];
          final selected = currentIndex == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(i),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: selected ? 48 : 0,
                      height: selected ? 4 : 0,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: selected ? [
                          BoxShadow(color: AppColors.primary.withOpacity(0.5), blurRadius: 6, spreadRadius: 1)
                        ] : [],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Icon(
                      selected ? item.active : item.icon,
                      color: selected ? AppColors.primary : AppColors.textMuted,
                      size: 22,
                    ).animate(target: selected ? 1 : 0)
                      .scale(begin: const Offset(1, 1), end: const Offset(1.15, 1.15), duration: 200.ms),
                    const SizedBox(height: 4),
                    Text(
                      item.label,
                      style: TextStyle(
                        color: selected ? AppColors.primary : AppColors.textMuted,
                        fontSize: 10,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
