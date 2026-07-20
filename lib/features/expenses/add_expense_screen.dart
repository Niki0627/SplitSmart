// lib/features/expenses/add_expense_screen.dart
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
    ExpenseCategory.food: (LucideIcons.utensils, 'Food'),
    ExpenseCategory.travel: (LucideIcons.plane, 'Travel'),
    ExpenseCategory.movie: (LucideIcons.film, 'Movie'),
    ExpenseCategory.bills: (LucideIcons.fileText, 'Bills'),
    ExpenseCategory.groceries: (LucideIcons.shoppingCart, 'Grocery'),
    ExpenseCategory.utilities: (LucideIcons.zap, 'Utilities'),
    ExpenseCategory.other: (LucideIcons.moreHorizontal, 'Other'),
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
    final groups = groupAsync.value ?? [];
    final group = groups.isEmpty ? null : groups.cast<Group?>().firstWhere((g) => g!.id == widget.groupId, orElse: () => null);
    final uid = firebaseService.currentUser?.uid ?? '';
    _paidBy ??= uid;

    final primaryColor = Theme.of(context).colorScheme.primary;
    final onPrimaryColor = Theme.of(context).colorScheme.onPrimary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBorderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textThemeColor = isDark ? Colors.white : AppColors.slate900;
    final inputColor = isDark ? Colors.white : AppColors.slate900;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(LucideIcons.x, color: textThemeColor), 
          onPressed: () => context.pop(),
        ),
        title: const Text('Rapid Entry', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.history, color: isDark ? AppColors.cyan : AppColors.primaryDark), 
            onPressed: () => context.go('/history'),
          ),
        ],
        backgroundColor: Colors.transparent,
      ),
      body: ShootingStarsGrid(
        padding: EdgeInsets.zero,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          // Amount + Paid By
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('TOTAL AMOUNT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: isDark ? AppColors.cyan : AppColors.primaryDark, letterSpacing: 1.5)),
                const SizedBox(height: 6),
                Row(children: [
                  Text(ref.watch(currencySymbolProvider), style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: isDark ? AppColors.cyan : AppColors.primaryDark)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextField(
                      controller: _amount,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      autofocus: true,
                      style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: textThemeColor),
                      decoration: const InputDecoration(
                        hintText: '0.00', 
                        hintStyle: TextStyle(color: AppColors.slate500), 
                        border: InputBorder.none, 
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero, 
                        isDense: true,
                        fillColor: Colors.transparent,
                      ),
                    ),
                  ),
                ]),
              ])),
              Container(width: 1, height: 40, color: primaryColor.withValues(alpha: 0.2)),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('PAID BY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: isDark ? AppColors.cyan : AppColors.primaryDark, letterSpacing: 1.5)),
                const SizedBox(height: 6),
                DropdownButton<String>(
                  isExpanded: true,
                  value: _paidBy,
                  underline: const SizedBox(),
                  dropdownColor: Theme.of(context).colorScheme.surface,
                  style: TextStyle(color: textThemeColor, fontWeight: FontWeight.w700, fontSize: 14),
                  items: [
                    DropdownMenuItem(value: uid, child: const Text('You')),
                    if (group != null) ...group.memberIds.where((m) => m != uid).map((m) => DropdownMenuItem(value: m, child: const Text('Member'))),
                  ],
                  onChanged: (v) => setState(() => _paidBy = v),
                ),
              ])),
            ]),
          ),
          const SizedBox(height: 20),
  
          // Category
          Text('CATEGORY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: isDark ? AppColors.slate300 : AppColors.slate600, letterSpacing: 1.5)),
          const SizedBox(height: 10),
          GridView.extent(
            maxCrossAxisExtent: 90, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 1.1,
            children: _categoryIcons.entries.map((e) {
              final isSelected = _category == e.key;
              final activeText = isDark ? AppColors.cyan : AppColors.primaryDark;
              return GestureDetector(
                onTap: () => setState(() => _category = e.key),
                child: GlassCard(
                  bgColor: isSelected ? primaryColor.withValues(alpha: 0.18) : null,
                  border: Border.all(color: isSelected ? primaryColor : cardBorderColor.withValues(alpha: 0.25), width: isSelected ? 2 : 1),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(e.value.$1, color: isSelected ? activeText : AppColors.slate500, size: 22),
                    const SizedBox(height: 4),
                    Text(e.value.$2, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: isSelected ? activeText : AppColors.slate500)),
                  ]),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
  
          // Description + Date
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('DESCRIPTION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: isDark ? AppColors.slate300 : AppColors.slate600, letterSpacing: 1.5)),
              const SizedBox(height: 8),
              TextField(
                controller: _desc, 
                style: TextStyle(color: inputColor, fontSize: 15, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: 'Dinner, tickets...', 
                  isDense: true,
                  fillColor: isDark ? AppColors.surfaceDark : AppColors.slate100.withValues(alpha: 0.5),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: cardBorderColor.withValues(alpha: 0.25)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primaryColor, width: 2),
                  ),
                ),
              ),
            ])),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('DATE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: isDark ? AppColors.slate300 : AppColors.slate600, letterSpacing: 1.5)),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final d = await showDatePicker(
                    context: context, 
                    initialDate: _date, 
                    firstDate: DateTime(2020), 
                    lastDate: DateTime.now(),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: Theme.of(context).colorScheme.copyWith(
                            primary: primaryColor,
                            onPrimary: Colors.black,
                            surface: Theme.of(context).colorScheme.surface,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (d != null) setState(() => _date = d);
                },
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  border: Border.all(color: cardBorderColor.withValues(alpha: 0.25)),
                  child: Row(children: [
                    Icon(LucideIcons.calendar, size: 16, color: isDark ? AppColors.cyan : AppColors.primaryDark),
                    const SizedBox(width: 8),
                    Text('${_date.day}/${_date.month}', style: TextStyle(color: textThemeColor, fontWeight: FontWeight.w700, fontSize: 14)),
                  ]),
                ),
              ),
            ])),
          ]),
          const SizedBox(height: 20),
  
          // Split Type
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('SPLIT TYPE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: isDark ? AppColors.slate300 : AppColors.slate600, letterSpacing: 1.5)),
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
              child: Text(_splitType.name[0].toUpperCase() + _splitType.name.substring(1), style: TextStyle(color: isDark ? AppColors.cyan : AppColors.primaryDark, fontSize: 11, fontWeight: FontWeight.w800))),
          ]),
          const SizedBox(height: 10),
          Row(children: SplitType.values.map((st) {
            final isSelected = _splitType == st;
            final icons = [LucideIcons.scale, LucideIcons.listOrdered, LucideIcons.percent];
            final labels = ['Equal', 'Unequal', '%'];
            final idx = SplitType.values.indexOf(st);
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: idx < 2 ? 8 : 0),
                child: GestureDetector(
                  onTap: () => setState(() => _splitType = st),
                  child: GlassCard(
                    bgColor: isSelected ? primaryColor : null,
                    border: Border.all(color: isSelected ? primaryColor : cardBorderColor.withValues(alpha: 0.25)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(children: [
                        Icon(icons[idx], size: 18, color: isSelected ? onPrimaryColor : AppColors.slate500),
                        const SizedBox(height: 4),
                        Text(labels[idx], style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: isSelected ? onPrimaryColor : AppColors.slate500)),
                      ]),
                    ),
                  ),
                ),
              ),
            );
          }).toList()),
          const SizedBox(height: 100),
        ]),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: PrimaryButton(label: 'Save Expense', icon: LucideIcons.check, onPressed: _loading ? null : _save, loading: _loading),
        ),
      ),
    );
  }
}
