// lib/features/expenses/calculate_tally_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../core/providers.dart';
import '../../core/firebase_service.dart';
import '../../shared/widgets.dart';

class CalculateTallyScreen extends ConsumerWidget {
  final String groupId;
  const CalculateTallyScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupAsync = ref.watch(groupsProvider).whenData((gs) => gs.firstWhere((g) => g.id == groupId));
    final expensesAsync = ref.watch(groupExpensesProvider(groupId));

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
        title: const Text('Calculate & Tally'),
        surfaceTintColor: Colors.transparent,
      ),
      body: expensesAsync.when(
        data: (expenses) {
          if (expenses.isEmpty) {
            return const EmptyState(icon: Icons.receipt_long_rounded, title: 'No expenses', subtitle: 'Add expenses to calculate balances');
          }
          final uid = firebaseService.currentUser?.uid ?? '';
          final group = groupAsync.value;
          final memberIds = group?.memberIds ?? [uid];
          final balances = firebaseService.calculateBalances(expenses, memberIds);

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
          final perPerson = totalSpent / memberIds.length;

          return ListView(padding: const EdgeInsets.all(20), children: [
            // Summary Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [AppColors.primary.withValues(alpha: 0.15), AppColors.primary.withValues(alpha: 0.05)]),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('GROUP SUMMARY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary, letterSpacing: 1.5)),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _StatBox(label: 'Total Spent', value: '₹${totalSpent.toStringAsFixed(0)}')),
                  Container(width: 1, height: 40, color: AppColors.primary.withValues(alpha: 0.2)),
                  Expanded(child: _StatBox(label: 'Per Person', value: '₹${perPerson.toStringAsFixed(0)}')),
                  Container(width: 1, height: 40, color: AppColors.primary.withValues(alpha: 0.2)),
                  Expanded(child: _StatBox(label: 'Transactions', value: '${expenses.length}')),
                ]),
              ]),
            ),
            const SizedBox(height: 24),

            // Who Owes Whom
            const Text('SETTLEMENTS NEEDED', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            if (debts.isEmpty)
              Container(
                padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: AppColors.emerald.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.emerald.withValues(alpha: 0.3))),
                child: const Row(children: [
                  Icon(Icons.check_circle_rounded, color: AppColors.emerald, size: 32),
                  SizedBox(width: 12),
                  Expanded(child: Text('All settled up! Everyone is even.', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15))),
                ]),
              )
            else ...debts.map((d) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFF1A2E2C), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.primary.withValues(alpha: 0.1))),
                child: Row(children: [
                  UserAvatar(initials: d.from[0].toUpperCase(), size: 40),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(d.from == uid ? 'You' : 'Member', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    Text('owes', style: const TextStyle(color: AppColors.slate500, fontSize: 12)),
                    Text(d.to == uid ? 'You' : 'Member', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  ])),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('₹${d.amount.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.rose, fontWeight: FontWeight.w800, fontSize: 18)),
                    const SizedBox(height: 6),
                    if (d.from == uid || d.to == uid)
                      GestureDetector(
                        onTap: () => context.push('/groups/$groupId/settle'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20)),
                          child: const Text('Settle', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.backgroundDark)),
                        ),
                      ),
                  ]),
                ]),
              ),
            )),

            const SizedBox(height: 24),
            // Expense breakdown
            const Text('EXPENSE BREAKDOWN', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            ...expenses.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Icon(_catIcon(e.category), color: AppColors.primary, size: 18)),
                const SizedBox(width: 12),
                Expanded(child: Text(e.description, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
                Text('₹${e.amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.slate300)),
              ]),
            )),
          ]);
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  IconData _catIcon(category) {
    switch (category) {
      case dynamic _ when category.toString().contains('food'): return Icons.restaurant;
      case dynamic _ when category.toString().contains('travel'): return Icons.flight;
      case dynamic _ when category.toString().contains('movie'): return Icons.movie;
      default: return Icons.receipt_long;
    }
  }
}

class _Debt { final String from, to; final double amount; _Debt({required this.from, required this.to, required this.amount}); }

class _StatBox extends StatelessWidget {
  final String label, value;
  const _StatBox({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
    const SizedBox(height: 4),
    Text(label, style: const TextStyle(fontSize: 11, color: AppColors.slate500)),
  ]);
}
