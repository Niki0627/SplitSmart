// lib/features/dashboard/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../core/providers.dart';
import '../../core/firebase_service.dart';
import '../../shared/widgets.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final groups = ref.watch(groupsProvider);
    final allExpenses = ref.watch(allExpensesProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Container(
              color: const Color(0xFF0D1B1A),
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 16, left: 20, right: 20, bottom: 16),
              child: Row(
                children: [
                  user.when(
                    data: (u) => UserAvatar(photoUrl: u?.photoUrl, initials: u?.initials ?? '?', size: 48),
                    loading: () => const ShimmerBox(height: 48, width: 48, radius: 24),
                    error: (_, __) => const UserAvatar(initials: '?', size: 48),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: user.when(
                      data: (u) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Welcome back,', style: TextStyle(fontSize: 13, color: AppColors.slate500)),
                        Text('Hello, ${u?.name.split(' ').first ?? 'User'}!',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                      ]),
                      loading: () => const ShimmerBox(height: 40),
                      error: (_, __) => const Text('Hello!'),
                    ),
                  ),
                  IconButton(
                    onPressed: () => context.go('/reminders'),
                    icon: const Icon(Icons.notifications_outlined, color: AppColors.slate400, size: 24),
                    style: IconButton.styleFrom(backgroundColor: AppColors.slate800, shape: const CircleBorder()),
                  ),
                ],
              ),
            ),
          ),
          // Net Balance Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: allExpenses.when(
                data: (expenses) {
                  final uid = firebaseService.currentUser?.uid ?? '';
                  final balance = firebaseService.userNetBalance(expenses, uid);
                  return Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('TOTAL NET BALANCE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary, letterSpacing: 1)),
                          const SizedBox(height: 6),
                          Text(
                            balance >= 0 ? '+₹${balance.toStringAsFixed(0)}' : '-₹${balance.abs().toStringAsFixed(0)}',
                            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: balance >= 0 ? AppColors.emerald : AppColors.rose),
                          ),
                        ])),
                        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          groups.when(
                            data: (g) => Text('${g.length} Active Groups', style: const TextStyle(fontSize: 12, color: AppColors.slate500)),
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                          const SizedBox(height: 6),
                          TextButton.icon(
                            onPressed: () => context.go('/analytics'),
                            icon: const Icon(Icons.bar_chart_rounded, size: 14, color: AppColors.primary),
                            label: const Text('Analytics', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13)),
                            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                          ),
                        ]),
                      ],
                    ),
                  );
                },
                loading: () => const ShimmerBox(height: 90),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
          ),
          // Groups Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 4, 4),
              child: SectionHeader(
                title: 'Your Groups',
                actionLabel: 'See all',
                onAction: () {},
              ),
            ),
          ),
          // Groups List
          groups.when(
            data: (groupList) {
              if (groupList.isEmpty) {
                return SliverToBoxAdapter(
                  child: EmptyState(
                    icon: Icons.group_add_rounded,
                    title: 'No groups yet',
                    subtitle: 'Create a group to start splitting expenses with friends',
                    actionLabel: 'Create Group',
                    onAction: () => context.push('/groups/create'),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final g = groupList[i];
                      final uid = firebaseService.currentUser?.uid ?? '';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: allExpenses.when(
                          data: (expenses) {
                            final groupExpenses = expenses.where((e) => e.groupId == g.id).toList();
                            final balance = firebaseService.userNetBalance(groupExpenses, uid);
                            return GroupCard(
                              name: g.name, icon: g.icon,
                              totalAmount: g.totalAmount, userBalance: balance,
                              onTap: () => context.push('/groups/${g.id}'),
                            );
                          },
                          loading: () => GroupCard(name: g.name, icon: g.icon, totalAmount: g.totalAmount, userBalance: 0, onTap: () => context.push('/groups/${g.id}')),
                          error: (_, __) => GroupCard(name: g.name, icon: g.icon, totalAmount: g.totalAmount, userBalance: 0, onTap: () => context.push('/groups/${g.id}')),
                        ),
                      );
                    },
                    childCount: groupList.length,
                  ),
                ),
              );
            },
            loading: () => SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(delegate: SliverChildBuilderDelegate(
                (_, i) => const Padding(padding: EdgeInsets.only(bottom: 12), child: ShimmerBox(height: 80)),
                childCount: 3,
              )),
            ),
            error: (e, _) => SliverToBoxAdapter(child: Center(child: Text('Error: $e'))),
          ),
        ],
      ),
    );
  }
}
