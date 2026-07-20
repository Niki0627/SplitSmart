// lib/features/expenses/calculate_tally_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme.dart';
import '../../core/providers.dart';
import '../../core/models.dart';
import '../../core/firebase_service.dart';
import '../../shared/widgets.dart';
import '../../shared/shooting_stars_grid.dart';

class CalculateTallyScreen extends ConsumerWidget {
  final String groupId;
  const CalculateTallyScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupAsync = ref.watch(groupsProvider).whenData(
        (gs) => gs.firstWhere((g) => g.id == groupId, orElse: () => gs.first));
    final expensesAsync = ref.watch(groupExpensesProvider(groupId));
    final settlementsAsync = ref.watch(groupSettlementsProvider(groupId));
    final currencySymbol = ref.watch(currencySymbolProvider);

    final memberIds = groupAsync.value?.memberIds ?? [];
    final membersAsync = ref.watch(groupMembersProvider(memberIds));

    // Build name lookup
    final nameMap = <String, String>{};
    final initialsMap = <String, String>{};
    membersAsync.whenData((members) {
      for (final m in members) {
        nameMap[m.uid] = m.name;
        initialsMap[m.uid] = m.initials;
      }
    });

    final uid = firebaseService.currentUser?.uid ?? '';

    String resolveName(String id) {
      if (id == uid) return 'You';
      return nameMap[id] ?? 'Member';
    }

    String resolveInitials(String id) {
      if (id == uid) return 'ME';
      return initialsMap[id] ?? (id.isNotEmpty ? id[0].toUpperCase() : '?');
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textThemeColor = isDark ? Colors.white : AppColors.slate900;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: textThemeColor), 
          onPressed: () => context.pop(),
        ),
        title: const Text('Calculate & Tally', style: TextStyle(fontWeight: FontWeight.w800)),
        surfaceTintColor: Colors.transparent,
      ),
      body: ShootingStarsGrid(
        padding: EdgeInsets.zero,
        child: expensesAsync.when(
          data: (expenses) {
            return settlementsAsync.when(
              data: (settlements) {
                if (expenses.isEmpty) {
                  return const EmptyState(
                    icon: LucideIcons.fileText,
                    title: 'No expenses',
                    subtitle: 'Add expenses to calculate balances',
                  );
                }

                final group = groupAsync.value;
                final ids = group?.memberIds ?? [uid];
                final balances = firebaseService.calculateBalances(expenses, settlements, ids);

                // Collect all debts
                final debts = <_Debt>[];
                for (final from in balances.keys) {
                  for (final to in balances[from]!.keys) {
                    final amt = balances[from]![to]!;
                    if (amt > 0.01) {
                      debts.add(_Debt(from: from, to: to, amount: amt));
                    }
                  }
                }

                final totalSpent = expenses.fold(0.0, (sum, e) => sum + e.amount);
                final perPerson = ids.isEmpty ? 0.0 : totalSpent / ids.length;

                return ListView(padding: const EdgeInsets.all(20), children: [
                  // Summary Card
                  GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('GROUP SUMMARY',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: isDark ? AppColors.cyan : AppColors.primaryDark, letterSpacing: 1.5)),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(child: _StatBox(label: 'Total Spent', value: '$currencySymbol${totalSpent.toStringAsFixed(0)}')),
                        Container(width: 1.2, height: 40, color: primaryColor.withValues(alpha: 0.2)),
                        Expanded(child: _StatBox(label: 'Per Person', value: '$currencySymbol${perPerson.toStringAsFixed(0)}')),
                        Container(width: 1.2, height: 40, color: primaryColor.withValues(alpha: 0.2)),
                        Expanded(child: _StatBox(label: 'Expenses', value: '${expenses.length}')),
                      ]),
                    ]),
                  ),
                  const SizedBox(height: 24),

                  // Who Owes Whom
                  Text('SETTLEMENTS NEEDED',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: textThemeColor)),
                  const SizedBox(height: 12),
                  if (debts.isEmpty)
                    GlassCard(
                      bgColor: AppColors.emerald.withValues(alpha: 0.12),
                      border: Border.all(color: AppColors.emerald.withValues(alpha: 0.35)),
                      padding: const EdgeInsets.all(20),
                      child: Row(children: [
                        const Icon(LucideIcons.checkCircle, color: AppColors.emerald, size: 30),
                        const SizedBox(width: 14),
                        Expanded(child: Text('All settled up! Everyone is even.',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: textThemeColor))),
                      ]),
                    )
                  else
                    ...debts.map((d) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Row(children: [
                          UserAvatar(initials: resolveInitials(d.from), size: 40),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(resolveName(d.from),
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: textThemeColor)),
                            const SizedBox(height: 2),
                            Text('owes',
                              style: TextStyle(color: AppColors.slate500, fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(resolveName(d.to),
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: textThemeColor)),
                          ])),
                          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                            Text('$currencySymbol${d.amount.toStringAsFixed(0)}',
                              style: const TextStyle(color: AppColors.rose, fontWeight: FontWeight.w800, fontSize: 18)),
                            const SizedBox(height: 6),
                            if (d.from == uid || d.to == uid)
                              GestureDetector(
                                onTap: () => context.push('/groups/$groupId/settle'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: primaryColor,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text('Settle',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.black)),
                                ),
                              ),
                          ]),
                        ]),
                      ),
                    )),

                  const SizedBox(height: 24),
                  Text('EXPENSE BREAKDOWN',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: textThemeColor)),
                  const SizedBox(height: 12),
                  ...expenses.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GlassCard(
                      padding: const EdgeInsets.all(12),
                      child: Row(children: [
                        Container(
                          width: 38, height: 38,
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(_catIcon(e.category), color: isDark ? AppColors.cyan : AppColors.primaryDark, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(e.description,
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: textThemeColor)),
                          const SizedBox(height: 2),
                          Text('Paid by ${e.paidBy == uid ? "You" : (nameMap[e.paidBy] ?? e.paidByName)}',
                            style: const TextStyle(color: AppColors.slate500, fontSize: 12, fontWeight: FontWeight.w500)),
                        ])),
                        Text('$currencySymbol${e.amount.toStringAsFixed(0)}',
                          style: TextStyle(fontWeight: FontWeight.w800, color: isDark ? AppColors.slate300 : AppColors.slate700, fontSize: 14)),
                      ]),
                    ),
                  )),
                  const SizedBox(height: 40),
                ]);
              },
              loading: () => Center(child: CircularProgressIndicator(color: primaryColor)),
              error: (e, _) => Center(child: Text('Error: $e')),
            );
          },
          loading: () => Center(child: CircularProgressIndicator(color: primaryColor)),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }

  IconData _catIcon(ExpenseCategory cat) {
    switch (cat) {
      case ExpenseCategory.food: return LucideIcons.utensils;
      case ExpenseCategory.travel: return LucideIcons.plane;
      case ExpenseCategory.movie: return LucideIcons.film;
      case ExpenseCategory.bills: return LucideIcons.fileText;
      case ExpenseCategory.groceries: return LucideIcons.shoppingCart;
      case ExpenseCategory.utilities: return LucideIcons.zap;
      case ExpenseCategory.other: return LucideIcons.moreHorizontal;
    }
  }
}

class _Debt {
  final String from, to;
  final double amount;
  _Debt({required this.from, required this.to, required this.amount});
}

class _StatBox extends StatelessWidget {
  final String label, value;
  const _StatBox({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    final textThemeColor = Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.slate900;
    return Column(children: [
      Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textThemeColor)),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(fontSize: 11, color: AppColors.slate500, fontWeight: FontWeight.w600)),
    ]);
  }
}
