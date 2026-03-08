// lib/features/groups/group_details_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../core/providers.dart';
import '../../core/firebase_service.dart';
import '../../shared/widgets.dart';

class GroupDetailsScreen extends ConsumerStatefulWidget {
  final String groupId;
  const GroupDetailsScreen({super.key, required this.groupId});
  @override
  ConsumerState<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends ConsumerState<GroupDetailsScreen> {
  int _tab = 0; // 0=All, 1=Yours, 2=Balances

  @override
  Widget build(BuildContext context) {
    final groupAsync = ref.watch(groupsProvider).whenData(
      (groups) => groups.firstWhere((g) => g.id == widget.groupId, orElse: () => throw Exception('Not found')));
    final expensesAsync = ref.watch(groupExpensesProvider(widget.groupId));

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: groupAsync.when(
        data: (group) => CustomScrollView(slivers: [
          // AppBar
          SliverAppBar(
            pinned: true, floating: false, expandedHeight: 0,
            backgroundColor: AppColors.backgroundDark,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            title: Column(children: [
              Text(group.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              Text('${group.memberIds.length} Members', style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
            ]),
            centerTitle: true,
            actions: [
              IconButton(icon: const Icon(Icons.more_vert_rounded, color: Colors.white), onPressed: () => _showGroupMenu(context, group)),
            ],
          ),

          // Summary + CTA
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(children: [
                Text('₹${group.totalAmount.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w800, letterSpacing: -1)),
                const Text('Group Total Spending', style: TextStyle(color: AppColors.slate500, fontSize: 13)),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => context.push('/groups/${widget.groupId}/tally'),
                      icon: const Icon(Icons.account_balance_wallet_rounded, size: 18),
                      label: const Text('Calculate & Tally'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary, foregroundColor: AppColors.backgroundDark,
                        padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: () => context.push('/groups/${widget.groupId}/settle'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Settle Up', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ]),
                const SizedBox(height: 16),
              ]),
            ),
          ),

          // Tabs
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                ...['All Expenses', 'Your Debt', 'Balances'].asMap().entries.map((e) {
                  final i = e.key;
                  final label = e.value;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _tab = i),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _tab == i ? AppColors.primary : const Color(0xFF1A2E2C),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _tab == i ? AppColors.primary : AppColors.primary.withValues(alpha: 0.15)),
                        ),
                        child: Text(label, style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13,
                          color: _tab == i ? AppColors.backgroundDark : AppColors.slate300,
                        )),
                      ),
                    ),
                  );
                }),
              ]),
            ),
          ),

          // Expenses or Balances
          SliverToBoxAdapter(
            child: Padding(padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: SectionHeader(title: _tab == 2 ? 'Member Balances' : 'Recent Expenses', actionLabel: 'See All', onAction: () {})),
          ),

          expensesAsync.when(
            data: (expenses) {
              final uid = firebaseService.currentUser?.uid ?? '';
              final filtered = _tab == 1 ? expenses.where((e) => e.participants.contains(uid) && e.paidBy != uid).toList() : expenses;

              if (_tab == 2) {
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                  sliver: SliverList(delegate: SliverChildBuilderDelegate(
                    (_, i) {
                      final memberId = group.memberIds[i];
                      final memberExpenses = expenses.where((e) => e.participants.contains(memberId) || e.paidBy == memberId).toList();
                      final balance = firebaseService.userNetBalance(memberExpenses, memberId);
                      return Padding(padding: const EdgeInsets.only(bottom: 10), child: _MemberBalanceRow(memberId: memberId, balance: balance));
                    },
                    childCount: group.memberIds.length,
                  )),
                );
              }

              if (filtered.isEmpty) {
                return SliverToBoxAdapter(child: EmptyState(
                  icon: Icons.receipt_long_rounded, title: 'No expenses yet',
                  subtitle: 'Add your first expense to get started',
                ));
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                sliver: SliverList(delegate: SliverChildBuilderDelegate(
                  (_, i) => Padding(padding: const EdgeInsets.only(bottom: 10),
                    child: ExpenseCard(expense: filtered[i], currentUserId: uid,
                      onLongPress: () => _confirmDelete(context, filtered[i]))),
                  childCount: filtered.length,
                )),
              );
            },
            loading: () => SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(delegate: SliverChildBuilderDelegate(
                (_, i) => Padding(padding: const EdgeInsets.only(bottom: 10), child: ShimmerBox(height: 80)),
                childCount: 3,
              )),
            ),
            error: (e, _) => SliverToBoxAdapter(child: Center(child: Text('Error: $e'))),
          ),
        ]),
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/groups/${widget.groupId}/expense'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.backgroundDark,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Expense', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  void _showGroupMenu(BuildContext context, group) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A2E2C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 8),
        Container(
          width: 36, height: 4,
          decoration: BoxDecoration(color: AppColors.slate700, borderRadius: BorderRadius.circular(2)),
        ),
        ListTile(
          leading: const Icon(Icons.edit_rounded, color: AppColors.primary),
          title: const Text('Edit Group'),
          subtitle: const Text('Rename, change icon or remove members', style: TextStyle(fontSize: 12)),
          onTap: () {
            Navigator.pop(context);
            context.push('/groups/${widget.groupId}/edit');
          },
        ),
        ListTile(
          leading: const Icon(Icons.person_add_rounded, color: AppColors.primary),
          title: const Text('Add Member'),
          subtitle: const Text('Search by email or phone number', style: TextStyle(fontSize: 12)),
          onTap: () {
            Navigator.pop(context);
            context.push('/groups/${widget.groupId}/add-member');
          },
        ),
        ListTile(
          leading: const Icon(Icons.delete_outline_rounded, color: AppColors.rose),
          title: Text('Delete Group', style: TextStyle(color: AppColors.rose)),
          onTap: () {
            Navigator.pop(context);
            _confirmDeleteGroup(context);
          },
        ),
        const SizedBox(height: 20),
      ]),
    );
  }

  void _confirmDeleteGroup(BuildContext context) {
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: const Color(0xFF1A2E2C),
      title: const Text('Delete Group?'),
      content: const Text('This will permanently delete the group and all its expenses.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(onPressed: () async {
          Navigator.pop(context);
          await firebaseService.deleteGroup(widget.groupId);
          if (mounted) context.go('/home');
        }, child: Text('Delete', style: TextStyle(color: AppColors.rose))),
      ],
    ));
  }

  void _confirmDelete(BuildContext context, exp) {
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: const Color(0xFF1A2E2C),
      title: const Text('Delete Expense?'),
      content: Text('Delete "${exp.description}"?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(onPressed: () async {
          Navigator.pop(context);
          await firebaseService.deleteExpense(exp.id, widget.groupId, exp.amount);
        }, child: Text('Delete', style: TextStyle(color: AppColors.rose))),
      ],
    ));
  }
}

class _MemberBalanceRow extends StatelessWidget {
  final String memberId;
  final double balance;
  const _MemberBalanceRow({required this.memberId, required this.balance});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFF1A2E2C), borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1))),
      child: Row(children: [
        UserAvatar(initials: memberId[0].toUpperCase(), size: 38),
        const SizedBox(width: 12),
        Expanded(child: Text(memberId, style: const TextStyle(fontWeight: FontWeight.w600))),
        BalanceBadge(amount: balance, compact: true),
      ]),
    );
  }
}
