// lib/shared/main_shell.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final index = _indexFromRoute(location);
    return Scaffold(
      body: child,
      bottomNavigationBar: _BottomNav(currentIndex: index),
      floatingActionButton: location == '/home'
          ? FloatingActionButton(
              onPressed: () => context.push('/groups/create'),
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.backgroundDark,
              elevation: 4,
              shape: const CircleBorder(),
              child: const Icon(Icons.add, size: 28),
            )
          : null,
    );
  }

  int _indexFromRoute(String location) {
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/history')) return 1;
    if (location.startsWith('/analytics')) return 2;
    if (location.startsWith('/reminders')) return 3;
    if (location.startsWith('/settings')) return 4;
    return 0;
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  const _BottomNav({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B1A),
        border: Border(top: BorderSide(color: AppColors.primary.withValues(alpha: 0.15), width: 1)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20)],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(icon: Icons.grid_view_rounded, label: 'Home', index: 0, currentIndex: currentIndex, route: '/home'),
              _NavItem(icon: Icons.receipt_long_rounded, label: 'Activity', index: 1, currentIndex: currentIndex, route: '/history'),
              _NavItem(icon: Icons.pie_chart_rounded, label: 'Analytics', index: 2, currentIndex: currentIndex, route: '/analytics'),
              _NavItem(icon: Icons.notifications_rounded, label: 'Alerts', index: 3, currentIndex: currentIndex, route: '/reminders'),
              _NavItem(icon: Icons.person_rounded, label: 'Profile', index: 4, currentIndex: currentIndex, route: '/settings'),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int currentIndex;
  final String route;
  const _NavItem({required this.icon, required this.label, required this.index, required this.currentIndex, required this.route});

  @override
  Widget build(BuildContext context) {
    final isActive = currentIndex == index;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => context.go(route),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: isActive
            ? BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isActive ? AppColors.primary : AppColors.slate500, size: 22),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10, fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? AppColors.primary : AppColors.slate500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
