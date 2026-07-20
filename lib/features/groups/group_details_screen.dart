// lib/features/groups/group_details_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme.dart';
import '../../core/providers.dart';
import '../../core/firebase_service.dart';
import '../../shared/widgets.dart';
import '../../shared/shooting_stars_grid.dart';

class GroupDetailsScreen extends ConsumerStatefulWidget {
  final String groupId;
  const GroupDetailsScreen({super.key, required this.groupId});
  @override
  ConsumerState<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends ConsumerState<GroupDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final groupAsync = ref.watch(groupsProvider).whenData(
      (groups) => groups.firstWhere((g) => g.id == widget.groupId, orElse: () => groups.first));
    final expensesAsync = ref.watch(groupExpensesProvider(widget.groupId));
    final settlementsAsync = ref.watch(groupSettlementsProvider(widget.groupId));
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textThemeColor = isDark ? Colors.white : AppColors.slate900;
    final currencySymbol = ref.watch(currencySymbolProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: null,
        automaticallyImplyLeading: false,
        toolbarHeight: 0,
      ),
      body: ShootingStarsGrid(
        padding: EdgeInsets.zero,
        child: groupAsync.when(
        data: (group) {
          return expensesAsync.when(
            data: (expenses) {
              return settlementsAsync.when(
                data: (settlements) {
                  final uid = firebaseService.currentUser?.uid ?? '';
                  
                  double totalOwedToYou = 0;
                  double totalYouOwe = 0;
                  
                  final memberBalances = <String, double>{};
                  
                  for (final memberId in group.memberIds) {
                    if (memberId == uid) continue;
                    final memberExpenses = expenses.where((e) => e.participants.contains(memberId) || e.paidBy == memberId).toList();
                    final memberSettlements = settlements.where((s) => s.from == memberId || s.to == memberId).toList();
                    final balance = firebaseService.userNetBalance(memberExpenses, memberSettlements, memberId);
                    
                    memberBalances[memberId] = balance;
                    if (balance > 0) {
                      totalOwedToYou += balance;
                    } else if (balance < 0) {
                      totalYouOwe += balance.abs();
                    }
                  }
                  
                  final isOverallOwed = totalOwedToYou >= totalYouOwe;
                  final overallNet = (totalOwedToYou - totalYouOwe).abs();
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  group.name,
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: textThemeColor,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${group.memberIds.length} members',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.slate400,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.blue.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                onPressed: () => _showGroupMenu(context, group),
                                icon: Icon(LucideIcons.menu, color: isDark ? AppColors.blue : AppColors.slate900),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        
                        // You are owed / You owe
                        Text(
                          isOverallOwed ? 'You are owed' : 'You owe',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: textThemeColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$currencySymbol${overallNet.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w800,
                            color: textThemeColor,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Summary Cards
                        Row(
                          children: [
                            Expanded(
                              child: _SummaryCard(
                                title: isOverallOwed ? 'You owe' : 'You are owed',
                                amount: isOverallOwed ? totalYouOwe : totalOwedToYou,
                                amountColor: isOverallOwed ? AppColors.rose : AppColors.emerald,
                                currencySymbol: currencySymbol,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _SummaryCard(
                                title: 'Total spend',
                                amount: group.totalAmount,
                                amountColor: textThemeColor,
                                currencySymbol: currencySymbol,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        
                        // Balances
                        Text(
                          'Balances',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppColors.slate400,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        Expanded(
                          child: ListView.separated(
                            itemCount: memberBalances.length,
                            separatorBuilder: (context, index) => Divider(color: AppColors.borderDark.withValues(alpha: 0.5), height: 32),
                            itemBuilder: (context, index) {
                              final memberId = memberBalances.keys.elementAt(index);
                              final balance = memberBalances[memberId]!;
                              return _BalanceRowItem(
                                memberId: memberId,
                                balance: balance,
                                currencySymbol: currencySymbol,
                              );
                            },
                          ),
                        ),
                        
                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => context.push('/groups/${widget.groupId}/expense'),
                                icon: Icon(LucideIcons.plus, size: 18, color: isDark ? AppColors.slate900 : Colors.white),
                                label: Text('Add expense', style: TextStyle(color: isDark ? AppColors.slate900 : Colors.white)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDark ? Colors.white : AppColors.slate900,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 0,
                                  textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => context.push('/groups/${widget.groupId}/settle'),
                                icon: Icon(LucideIcons.smartphone, size: 18, color: textThemeColor),
                                label: Text('Settle via UPI', style: TextStyle(color: textThemeColor)),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  side: BorderSide(color: AppColors.borderDark),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      )),
    );
  }

  void _showGroupMenu(BuildContext context, group) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.slate500.withValues(alpha: 0.3), 
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: Icon(LucideIcons.edit3, color: isDark ? Colors.white : AppColors.slate900),
            title: const Text('Edit Group', style: TextStyle(fontWeight: FontWeight.w700)),
            subtitle: const Text('Rename, change icon or remove members', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            onTap: () {
              Navigator.pop(context);
              context.push('/groups/${widget.groupId}/edit');
            },
          ),
          ListTile(
            leading: Icon(LucideIcons.userPlus, color: isDark ? Colors.white : AppColors.slate900),
            title: const Text('Add Member', style: TextStyle(fontWeight: FontWeight.w700)),
            subtitle: const Text('Search by email or phone number', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            onTap: () {
              Navigator.pop(context);
              context.push('/groups/${widget.groupId}/add-member');
            },
          ),
          ListTile(
            leading: const Icon(LucideIcons.trash2, color: AppColors.rose),
            title: const Text('Delete Group', style: TextStyle(color: AppColors.rose, fontWeight: FontWeight.w700)),
            onTap: () {
              Navigator.pop(context);
              _confirmDeleteGroup(context);
            },
          ),
          const SizedBox(height: 32),
        ]),
      ),
    );
  }

  void _confirmDeleteGroup(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context, 
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? AppColors.cardDark : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Delete Group?', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('This will permanently delete the group and all its expenses.', style: TextStyle(fontWeight: FontWeight.w500)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text('Cancel', style: TextStyle(color: AppColors.slate500, fontWeight: FontWeight.w700)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await firebaseService.deleteGroup(widget.groupId);
              if (!context.mounted) return;
              context.go('/home');
            }, 
            child: const Text('Delete', style: TextStyle(color: AppColors.rose, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color amountColor;
  final String currencySymbol;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.amountColor,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.borderDark.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.slate400,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$currencySymbol${amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: amountColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceRowItem extends StatelessWidget {
  final String memberId;
  final double balance;
  final String currencySymbol;

  const _BalanceRowItem({
    required this.memberId,
    required this.balance,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final initials = memberId.isNotEmpty ? memberId.substring(0, math.min(2, memberId.length)).toUpperCase() : '?';
    
    final isPositive = balance > 0;
    final isZero = balance.abs() < 0.01;
    final color = isZero ? AppColors.slate500 : (isPositive ? AppColors.emerald : AppColors.rose);
    
    String label;
    if (isZero) {
      label = 'Settled up';
    } else if (isPositive) {
      label = '${memberId.split(' ').first} owes you';
    } else {
      label = 'You owe ${memberId.split(' ').first}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              initials,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: isDark ? Colors.white : AppColors.slate900,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 15,
                color: isDark ? Colors.white : AppColors.slate900,
              ),
            ),
          ),
          Text(
            isZero ? 'Settled' : '$currencySymbol${balance.abs().toStringAsFixed(0)}',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
