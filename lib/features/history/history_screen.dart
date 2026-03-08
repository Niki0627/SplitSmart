// lib/features/history/history_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/providers.dart';
import '../../core/firebase_service.dart';
import '../../shared/widgets.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});
  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String _filter = 'All';
  final _filters = ['All', 'Paid', 'Owe', 'Settled'];

  @override
  Widget build(BuildContext context) {
    final allExpensesAsync = ref.watch(allExpensesProvider);
    final uid = firebaseService.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: CustomScrollView(slivers: [
        SliverAppBar(
          pinned: true, floating: false, expandedHeight: 0,
          backgroundColor: AppColors.backgroundDark,
          automaticallyImplyLeading: false,
          title: const Text('Activity', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
          surfaceTintColor: Colors.transparent,
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Row(children: _filters.map((f) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(f),
                selected: _filter == f,
                onSelected: (_) => setState(() => _filter = f),
                selectedColor: AppColors.primary.withValues(alpha: 0.2),
                checkmarkColor: AppColors.primary,
                backgroundColor: const Color(0xFF1A2E2C),
                side: BorderSide(color: _filter == f ? AppColors.primary : AppColors.primary.withValues(alpha: 0.15)),
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: _filter == f ? AppColors.primary : AppColors.slate400,
                  fontSize: 12,
                ),
              ),
            )).toList()),
          ),
        ),
        allExpensesAsync.when(
          data: (expenses) {
            final filtered = expenses.where((e) {
              switch (_filter) {
                case 'Paid': return e.paidBy == uid;
                case 'Owe': return e.paidBy != uid && e.participants.contains(uid);
                default: return true;
              }
            }).toList();

            if (filtered.isEmpty) {
              return SliverToBoxAdapter(child: EmptyState(
                icon: Icons.receipt_long_rounded,
                title: 'No activity',
                subtitle: 'Your expenses will appear here',
              ));
            }

            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              sliver: SliverList(delegate: SliverChildBuilderDelegate(
                (_, i) => Padding(padding: const EdgeInsets.only(bottom: 10),
                  child: ExpenseCard(expense: filtered[i], currentUserId: uid)),
                childCount: filtered.length,
              )),
            );
          },
          loading: () => SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(delegate: SliverChildBuilderDelegate(
              (_, i) => Padding(padding: const EdgeInsets.only(bottom: 10), child: ShimmerBox(height: 80)),
              childCount: 5,
            )),
          ),
          error: (e, _) => SliverToBoxAdapter(child: Center(child: Text('Error: $e'))),
        ),
      ]),
    );
  }
}
