// lib/shared/main_shell.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/theme.dart';
import 'shooting_stars_grid.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final index = _indexFromRoute(location);

    return Scaffold(
      extendBody: true,
      body: ShootingStarsGrid(padding: EdgeInsets.zero, child: child),
      bottomNavigationBar: SafeArea(
        bottom: true,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: _BottomNav(currentIndex: index),
        ),
      ),
    );
  }

  int _indexFromRoute(String location) {
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/history')) return 1;
    if (location.startsWith('/analytics')) return 3;
    if (location.startsWith('/reminders')) return 4;
    if (location.startsWith('/settings')) return 4;
    return 0;
  }
}

class _BottomNav extends StatefulWidget {
  final int currentIndex;
  const _BottomNav({required this.currentIndex});

  @override
  State<_BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<_BottomNav> {
  int? _hoveredIndex;

  double _getScale(int index) {
    if (_hoveredIndex == null) {
      if (widget.currentIndex == index) return 1.08;
      if (index == 2) return 1.0; // Central action button
      return 1.0;
    }
    if (_hoveredIndex == index) return 1.32;
    if ((_hoveredIndex! - index).abs() == 1) return 1.15;
    return 0.95; // Shrink adjacent-to-adjacent elements slightly
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 460),
        child: _buildBentoSegment(
          context,
          children: [
            _NavItem(
              icon: LucideIcons.layoutGrid,
              label: 'Home',
              index: 0,
              currentIndex: widget.currentIndex,
              scale: _getScale(0),
              onHover: (idx) => setState(() => _hoveredIndex = idx),
              onTap: () => context.go('/home'),
            ),
            _NavItem(
              icon: LucideIcons.fileText,
              label: 'Activity',
              index: 1,
              currentIndex: widget.currentIndex,
              scale: _getScale(1),
              onHover: (idx) => setState(() => _hoveredIndex = idx),
              onTap: () => context.go('/history'),
            ),
            _NavItem(
              icon: LucideIcons.plus,
              label: 'Add',
              index: 2,
              currentIndex: -1,
              scale: _getScale(2),
              onHover: (idx) => setState(() => _hoveredIndex = idx),
              onTap: () => context.push('/groups/create'),
              isActionButton: true,
            ),
            _NavItem(
              icon: LucideIcons.pieChart,
              label: 'Insights',
              index: 3,
              currentIndex: widget.currentIndex,
              scale: _getScale(3),
              onHover: (idx) => setState(() => _hoveredIndex = idx),
              onTap: () => context.go('/analytics'),
            ),
            _NavItem(
              icon: LucideIcons.settings,
              label: 'Settings',
              index: 4,
              currentIndex: widget.currentIndex,
              scale: _getScale(4),
              onHover: (idx) => setState(() => _hoveredIndex = idx),
              onTap: () => context.go('/settings'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBentoSegment(BuildContext context,
      {required List<Widget> children}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? Colors.black.withValues(alpha: 0.22)
        : Colors.white.withValues(alpha: 0.45);
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: borderColor.withValues(alpha: 0.25),
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: children,
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final int index;
  final int currentIndex;
  final double scale;
  final ValueChanged<int?> onHover;
  final VoidCallback onTap;
  final bool isActionButton;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.scale,
    required this.onHover,
    required this.onTap,
    this.isActionButton = false,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isActive = widget.currentIndex == widget.index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? AppColors.cyan : AppColors.primaryDark;

    final double finalScale = widget.scale * (_isPressed ? 1.2 : 1.0);

    Widget iconWidget;
    if (widget.isActionButton) {
      iconWidget = AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isDark ? Colors.white : Colors.black,
          shape: BoxShape.circle,
          boxShadow: [
            if (_isPressed)
              BoxShadow(
                color: (isDark ? AppColors.cyan : AppColors.primary)
                    .withValues(alpha: 0.5),
                blurRadius: 15,
                spreadRadius: 4,
                offset: const Offset(0, 8),
              )
            else
              BoxShadow(
                color: (isDark ? AppColors.cyan : AppColors.primary)
                    .withValues(alpha: 0.25),
                blurRadius: 10,
                spreadRadius: 1,
              )
          ],
        ),
        child: Icon(
          LucideIcons.plus,
          color: isDark ? Colors.black : Colors.white,
          size: 24,
        ),
      );
    } else {
      iconWidget = AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.15)
              : (_isPressed || _isHovered
                  ? activeColor.withValues(alpha: 0.1)
                  : Colors.transparent),
          shape: BoxShape.circle,
          border: isActive
              ? Border.all(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  width: 1,
                )
              : null,
          boxShadow: _isPressed
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.2),
                    blurRadius: 12,
                    spreadRadius: 2,
                    offset: const Offset(0, 6),
                  )
                ]
              : null,
        ),
        child: Icon(
          widget.icon,
          color: isActive
              ? activeColor
              : (_isPressed ? activeColor : AppColors.slate500),
          size: 22,
          semanticLabel: widget.label,
        ),
      );
    }

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: MouseRegion(
        onEnter: (_) {
          setState(() => _isHovered = true);
          widget.onHover(widget.index);
        },
        onExit: (_) {
          setState(() => _isHovered = false);
          widget.onHover(null);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutBack,
                scale: finalScale,
                child: iconWidget,
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                  color: isActive ? activeColor : AppColors.slate500,
                ),
                child: Text(widget.label),
              ),
              const SizedBox(height: 4),
              // Mac dock active indicator dot
              if (!widget.isActionButton)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isActive ? 4 : 0,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isActive ? activeColor : Colors.transparent,
                    shape: BoxShape.circle,
                    boxShadow: isActive && isDark
                        ? [
                            BoxShadow(
                              color: activeColor.withValues(alpha: 0.8),
                              blurRadius: 6,
                              spreadRadius: 1,
                            )
                          ]
                        : null,
                  ),
                )
              else
                const SizedBox(height: 4), // Spacer matching dot height
            ],
          ),
        ),
      ),
    );
  }
}
