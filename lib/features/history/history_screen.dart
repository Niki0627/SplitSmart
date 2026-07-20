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
  DateTime? _selectedDate;

  @override
  Widget build(BuildContext context) {
    final allExpensesAsync = ref.watch(allExpensesProvider);
    final uid = firebaseService.currentUser?.uid ?? '';
    
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chipBorderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Scaffold(
      body: CustomScrollView(slivers: [
        SliverAppBar(
          pinned: true, 
          floating: false, 
          expandedHeight: 0,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          automaticallyImplyLeading: false,
          title: Text(
            'Activity', 
            style: TextStyle(
              fontSize: 19, 
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.slate900,
            ),
          ),
          surfaceTintColor: Colors.transparent,
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      avatar: const Icon(Icons.calendar_today, size: 16),
                      label: Text(
                        _selectedDate == null 
                          ? 'Pick Date' 
                          : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                      ),
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: Theme.of(context).colorScheme.copyWith(
                                  primary: primaryColor,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (date != null) {
                          setState(() => _selectedDate = date);
                        } else if (_selectedDate != null) {
                           // If user cancels, maybe they want to clear it?
                           // Let's add a long press or close button to clear, or just leave it.
                           // Actually, showing a dialog to clear it if already picked is better, 
                           // but for now let's just let them select another day.
                        }
                      },
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      side: BorderSide(color: _selectedDate != null ? primaryColor : chipBorderColor),
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: _selectedDate != null ? primaryColor : AppColors.slate500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if (_selectedDate != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () => setState(() => _selectedDate = null),
                        child: Icon(Icons.clear, size: 18, color: AppColors.slate500),
                      ),
                    ),
                  ..._filters.map((f) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(f),
                      selected: _filter == f,
                      onSelected: (_) => setState(() => _filter = f),
                      selectedColor: primaryColor.withValues(alpha: 0.2),
                      checkmarkColor: primaryColor,
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      side: BorderSide(
                        color: _filter == f ? primaryColor : chipBorderColor,
                      ),
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: _filter == f ? primaryColor : AppColors.slate500,
                        fontSize: 12,
                      ),
                    ),
                  )),
                ],
              ),
            ),
          ),
        ),
        allExpensesAsync.when(
          data: (expenses) {
            final filtered = expenses.where((e) {
              if (_selectedDate != null) {
                if (e.date.year != _selectedDate!.year || 
                    e.date.month != _selectedDate!.month || 
                    e.date.day != _selectedDate!.day) {
                  return false;
                }
              }

              switch (_filter) {
                case 'Paid': return e.paidBy == uid;
                case 'Owe': return e.paidBy != uid && e.participants.contains(uid);
                default: return true;
              }
            }).toList();

            if (filtered.isEmpty) {
              return const SliverToBoxAdapter(child: EmptyState(
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
              (_, i) => const Padding(padding: EdgeInsets.only(bottom: 10), child: ShimmerBox(height: 80)),
              childCount: 5,
            )),
          ),
          error: (e, _) => SliverToBoxAdapter(child: Center(child: Text('Error: $e'))),
        ),
      ]),
    );
  }
}
