import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/firebase_service.dart';
import '../../core/models.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../shared/widgets.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(groupsProvider);
    final expenses = ref.watch(allExpensesProvider);
    final user = ref.watch(currentUserProvider).value;
    final name =
        user?.name.isNotEmpty == true ? user!.name.split(' ').first : 'there';
    final initials = user?.initials ?? 'S';
    final uid = firebaseService.currentUser?.uid ?? '';

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: Theme.of(context).colorScheme.primary,
          onRefresh: () async {
            ref.invalidate(groupsProvider);
            ref.invalidate(allExpensesProvider);
            await Future.wait([
              ref.read(groupsProvider.future),
              ref.read(allExpensesProvider.future)
            ]);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics()),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 116),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Row(children: [
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            const Text('YOUR SPLITS',
                                style: TextStyle(
                                    color: AppColors.slate500,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11,
                                    letterSpacing: 1.4)),
                            const SizedBox(height: 5),
                            Text('Hello, $name',
                                style: const TextStyle(
                                    fontSize: 26, fontWeight: FontWeight.w800)),
                          ])),
                      UserAvatar(
                          photoUrl: user?.photoUrl,
                          initials: initials,
                          size: 42),
                    ]),
                    const SizedBox(height: 24),
                    groups.when(
                      loading: () => const ShimmerBox(height: 150, radius: 22),
                      error: (_, __) => _LoadError(
                          onRetry: () => ref.invalidate(groupsProvider)),
                      data: (items) => expenses.when(
                        loading: () => _BalanceCard(
                            groups: items, expenses: const [], uid: uid),
                        error: (_, __) => _BalanceCard(
                            groups: items, expenses: const [], uid: uid),
                        data: (list) => _BalanceCard(
                            groups: items, expenses: list, uid: uid),
                      ),
                    ),
                    const SizedBox(height: 26),
                    const SectionHeader(title: 'QUICK ACTIONS'),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                          child: _Action(
                              icon: LucideIcons.users,
                              label: 'New group',
                              onTap: () => context.push('/groups/create'))),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _Action(
                              icon: LucideIcons.receipt,
                              label: 'Activity',
                              onTap: () => context.go('/history'))),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _Action(
                              icon: LucideIcons.barChart3,
                              label: 'Insights',
                              onTap: () => context.go('/analytics'))),
                    ]),
                    const SizedBox(height: 28),
                    SectionHeader(
                        title: 'YOUR GROUPS',
                        actionLabel: 'See all',
                        onAction: () => context.go('/history')),
                    const SizedBox(height: 12),
                    groups.when(
                      loading: () => const Column(children: [
                        ShimmerBox(height: 84),
                        SizedBox(height: 10),
                        ShimmerBox(height: 84)
                      ]),
                      error: (_, __) => _LoadError(
                          onRetry: () => ref.invalidate(groupsProvider)),
                      data: (items) {
                        if (items.isEmpty) {
                          return EmptyState(
                              icon: LucideIcons.users,
                              title: 'Start your first group',
                              subtitle:
                                  'Create a group to split bills with friends.',
                              actionLabel: 'Create group',
                              onAction: () => context.push('/groups/create'));
                        }
                        return Column(children: [
                          for (final group in items.take(4)) ...[
                            GroupCard(
                                name: group.name,
                                icon: group.icon,
                                totalAmount: group.totalAmount,
                                userBalance: _groupBalance(
                                    group, expenses.value ?? const [], uid),
                                onTap: () =>
                                    context.push('/groups/${group.id}')),
                            const SizedBox(height: 10),
                          ],
                        ]);
                      },
                    ),
                    const SizedBox(height: 22),
                    SectionHeader(
                        title: 'RECENT ACTIVITY',
                        actionLabel: 'View all',
                        onAction: () => context.go('/history')),
                    const SizedBox(height: 12),
                    expenses.when(
                      loading: () => const ShimmerBox(height: 84),
                      error: (_, __) => _LoadError(
                          onRetry: () => ref.invalidate(allExpensesProvider)),
                      data: (items) => items.isEmpty
                          ? const EmptyState(
                              icon: LucideIcons.receipt,
                              title: 'No expenses yet',
                              subtitle:
                                  'Expenses added to your groups appear here.')
                          : Column(children: [
                              for (final expense in items.take(3)) ...[
                                ExpenseCard(
                                    expense: expense, currentUserId: uid),
                                const SizedBox(height: 10)
                              ]
                            ]),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _groupBalance(Group group, List<Expense> expenses, String uid) {
    return expenses.where((e) => e.groupId == group.id).fold(0.0, (sum, e) {
      final share =
          e.amount / (e.participants.isEmpty ? 1 : e.participants.length);
      return sum +
          (e.paidBy == uid
              ? e.amount - share
              : e.participants.contains(uid)
                  ? -share
                  : 0);
    });
  }
}

class _BalanceCard extends ConsumerWidget {
  final List<Group> groups;
  final List<Expense> expenses;
  final String uid;
  const _BalanceCard(
      {required this.groups, required this.expenses, required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final symbol = ref.watch(currencySymbolProvider);
    var owed = 0.0;
    var owe = 0.0;
    for (final expense in expenses) {
      final share = expense.amount /
          (expense.participants.isEmpty ? 1 : expense.participants.length);
      if (expense.paidBy == uid) owed += expense.amount - share;
      if (expense.paidBy != uid && expense.participants.contains(uid))
        owe += share;
    }
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: .18),
                blurRadius: 22,
                offset: const Offset(0, 10))
          ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(groups.isEmpty ? 'READY WHEN YOU ARE' : 'YOUR NET BALANCE',
            style: TextStyle(
                color: Colors.white.withValues(alpha: .65),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2)),
        const SizedBox(height: 9),
        Text('$symbol${(owed - owe).abs().toStringAsFixed(0)}',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 38,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(owed >= owe ? 'You are owed overall' : 'You owe overall',
            style: TextStyle(
                color: Colors.white.withValues(alpha: .72), fontSize: 13)),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(
              child: _Metric(
                  label: 'YOU GET',
                  value: '$symbol${owed.toStringAsFixed(0)}')),
          Container(
              width: 1, height: 35, color: Colors.white.withValues(alpha: .2)),
          Expanded(
              child: _Metric(
                  label: 'YOU OWE', value: '$symbol${owe.toStringAsFixed(0)}')),
        ]),
      ]),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  const _Metric({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: TextStyle(
                color: Colors.white.withValues(alpha: .55),
                fontSize: 10,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800))
      ]));
}

class _Action extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _Action({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => Material(
      color: Colors.transparent,
      child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: GlassCard(
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 8),
              child: Column(children: [
                Icon(icon, size: 20),
                const SizedBox(height: 8),
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700))
              ]))));
}

class _LoadError extends StatelessWidget {
  final VoidCallback onRetry;
  const _LoadError({required this.onRetry});
  @override
  Widget build(BuildContext context) => GlassCard(
      padding: const EdgeInsets.all(18),
      child: Row(children: [
        const Icon(LucideIcons.wifiOff, color: AppColors.slate500),
        const SizedBox(width: 12),
        const Expanded(child: Text('Could not load this section.')),
        TextButton(onPressed: onRetry, child: const Text('Retry'))
      ]));
}
