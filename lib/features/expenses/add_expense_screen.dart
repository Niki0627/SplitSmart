// lib/features/expenses/add_expense_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../core/providers.dart';
import '../../core/models.dart';
import '../../core/firebase_service.dart';
import '../../shared/widgets.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  final String groupId;
  const AddExpenseScreen({super.key, required this.groupId});
  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _amount = TextEditingController();
  final _desc = TextEditingController();
  ExpenseCategory _category = ExpenseCategory.food;
  SplitType _splitType = SplitType.equal;
  DateTime _date = DateTime.now();
  String? _paidBy;
  bool _loading = false;

  final _categoryIcons = {
    ExpenseCategory.food: (Icons.restaurant_rounded, 'Food'),
    ExpenseCategory.travel: (Icons.flight_rounded, 'Travel'),
    ExpenseCategory.movie: (Icons.movie_rounded, 'Movie'),
    ExpenseCategory.bills: (Icons.receipt_long_rounded, 'Bills'),
    ExpenseCategory.groceries: (Icons.local_grocery_store_rounded, 'Grocery'),
    ExpenseCategory.utilities: (Icons.lightbulb_rounded, 'Utilities'),
    ExpenseCategory.other: (Icons.more_horiz_rounded, 'Other'),
  };

  @override
  void dispose() { _amount.dispose(); _desc.dispose(); super.dispose(); }

  Future<void> _save() async {
    final amtText = _amount.text.trim();
    if (amtText.isEmpty || double.tryParse(amtText) == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid amount'), backgroundColor: AppColors.rose, behavior: SnackBarBehavior.floating));
      return;
    }
    if (_desc.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a description'), backgroundColor: AppColors.rose, behavior: SnackBarBehavior.floating));
      return;
    }
    setState(() => _loading = true);
    try {
      final uid = firebaseService.currentUser?.uid ?? '';
      final payer = _paidBy ?? uid;
      final group = ref.read(groupsProvider).value?.firstWhere((g) => g.id == widget.groupId);
      final members = group?.memberIds ?? [uid];
      final payerName = payer == uid ? (ref.read(currentUserProvider).value?.name ?? 'You') : 'Member';
      await firebaseService.addExpense(
        groupId: widget.groupId,
        description: _desc.text.trim(),
        amount: double.parse(amtText),
        paidBy: payer, paidByName: payerName,
        splitType: _splitType, participants: members,
        category: _category, date: _date,
      );
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.rose));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupAsync = ref.watch(groupsProvider);
    final group = groupAsync.value?.firstWhere((g) => g.id == widget.groupId, orElse: () => throw Exception(''));
    final uid = firebaseService.currentUser?.uid ?? '';
    _paidBy ??= uid;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        leading: IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => context.pop()),
        title: const Text('Rapid Entry'),
        actions: [IconButton(icon: const Icon(Icons.history_rounded, color: AppColors.primary), onPressed: () => context.go('/history'))],
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        // Amount + Paid By
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.primary.withValues(alpha: 0.15))),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('TOTAL AMOUNT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary, letterSpacing: 1.5)),
              const SizedBox(height: 6),
              Row(children: [
                const Text('₹', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.primary)),
                const SizedBox(width: 6),
                Expanded(
                  child: TextField(
                    controller: _amount,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    autofocus: true,
                    style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: Colors.white),
                    decoration: const InputDecoration(hintText: '0.00', hintStyle: TextStyle(color: AppColors.slate700), border: InputBorder.none, contentPadding: EdgeInsets.zero, isDense: true),
                  ),
                ),
              ]),
            ])),
            Container(width: 1, height: 40, color: AppColors.primary.withValues(alpha: 0.2)),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('PAID BY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary, letterSpacing: 1.5)),
              const SizedBox(height: 6),
              DropdownButton<String>(
                value: _paidBy,
                underline: const SizedBox(),
                dropdownColor: const Color(0xFF1A2E2C),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                items: [
                  DropdownMenuItem(value: uid, child: const Text('You')),
                  if (group != null) ...group.memberIds.where((m) => m != uid).map((m) => DropdownMenuItem(value: m, child: Text('Member'))),
                ],
                onChanged: (v) => setState(() => _paidBy = v),
              ),
            ])),
          ]),
        ),
        const SizedBox(height: 20),

        // Category
        const Text('CATEGORY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.slate500, letterSpacing: 1.5)),
        const SizedBox(height: 10),
        GridView.extent(
          maxCrossAxisExtent: 90, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 1.1,
          children: _categoryIcons.entries.map((e) {
            final isSelected = _category == e.key;
            return GestureDetector(
              onTap: () => setState(() => _category = e.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : const Color(0xFF1A2E2C),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isSelected ? AppColors.primary : AppColors.primary.withValues(alpha: 0.1), width: isSelected ? 2 : 1),
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(e.value.$1, color: isSelected ? AppColors.primary : AppColors.slate500, size: 22),
                  const SizedBox(height: 4),
                  Text(e.value.$2, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isSelected ? AppColors.primary : AppColors.slate500)),
                ]),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),

        // Description + Date
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('DESCRIPTION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.slate500, letterSpacing: 1.5)),
            const SizedBox(height: 8),
            TextField(controller: _desc, style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(hintText: 'Dinner, tickets...', isDense: true)),
          ])),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('DATE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.slate500, letterSpacing: 1.5)),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final d = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime.now());
                if (d != null) setState(() => _date = d);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.primary.withValues(alpha: 0.15))),
                child: Row(children: [
                  const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text('${_date.day}/${_date.month}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                ]),
              ),
            ),
          ])),
        ]),
        const SizedBox(height: 20),

        // Split Type
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('SPLIT TYPE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.slate500, letterSpacing: 1.5)),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
            child: Text(_splitType.name[0].toUpperCase() + _splitType.name.substring(1), style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w700))),
        ]),
        const SizedBox(height: 10),
        Row(children: SplitType.values.map((st) {
          final isSelected = _splitType == st;
          final icons = [Icons.balance_rounded, Icons.format_list_numbered_rounded, Icons.percent_rounded];
          final labels = ['Equal', 'Unequal', '%'];
          final idx = SplitType.values.indexOf(st);
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: idx < 2 ? 8 : 0),
              child: GestureDetector(
                onTap: () => setState(() => _splitType = st),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : const Color(0xFF1A2E2C),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isSelected ? AppColors.primary : AppColors.primary.withValues(alpha: 0.15)),
                  ),
                  child: Column(children: [
                    Icon(icons[idx], size: 18, color: isSelected ? AppColors.backgroundDark : AppColors.slate400),
                    const SizedBox(height: 4),
                    Text(labels[idx], style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isSelected ? AppColors.backgroundDark : AppColors.slate400)),
                  ]),
                ),
              ),
            ),
          );
        }).toList()),
        const SizedBox(height: 100),
      ]),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: PrimaryButton(label: 'Save Expense', icon: Icons.check_circle_rounded, onPressed: _loading ? null : _save, loading: _loading),
        ),
      ),
    );
  }
}
