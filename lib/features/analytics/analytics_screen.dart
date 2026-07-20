// lib/features/analytics/analytics_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme.dart';
import '../../core/providers.dart';
import '../../core/models.dart';
import '../../core/firebase_service.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});
  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  int _touchedIndex = -1;
  int _monthRange = 3;

  @override
  Widget build(BuildContext context) {
    final allExpenses = ref.watch(allExpensesProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(slivers: [
        SliverAppBar(
          pinned: true,
          floating: false,
          expandedHeight: 0,
          backgroundColor: theme.scaffoldBackgroundColor,
          automaticallyImplyLeading: false,
          title: const Text(
            'Analytics',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          actions: [
            PopupMenuButton<int>(
              initialValue: _monthRange,
              onSelected: (v) => setState(() => _monthRange = v),
              color: theme.colorScheme.surface,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: primaryColor.withValues(alpha: 0.3)),
                ),
                child: Row(children: [
                  Text(
                    '$_monthRange mo',
                    style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 13),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_down_rounded,
                      color: primaryColor, size: 16),
                ]),
              ),
              itemBuilder: (_) => [3, 6, 12]
                  .map((m) => PopupMenuItem(
                        value: m,
                        child: Text('Last $m months',
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                      ))
                  .toList(),
            ),
          ],
        ),
        allExpenses.when(
          data: (expenses) {
            if (expenses.isEmpty) {
              return SliverFillRemaining(
                child: Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.analytics_rounded,
                          color: primaryColor, size: 44),
                    ),
                    const SizedBox(height: 20),
                    const Text('No expense data yet',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    const Text('Add expenses to see insights here',
                        style:
                            TextStyle(color: AppColors.slate500, fontSize: 14)),
                  ]),
                ),
              );
            }

            final now = DateTime.now();
            final filtered = expenses
                .where((e) => e.date
                    .isAfter(now.subtract(Duration(days: _monthRange * 30))))
                .toList();
            final monthlyData = _buildMonthlyData(filtered);
            final categoryData = _buildCategoryData(filtered);
            final totalSpent = filtered.fold(0.0, (s, e) => s + e.amount);
            final uid = firebaseService.currentUser?.uid ?? '';
            final mySpend = filtered
                .where((e) => e.participants.contains(uid))
                .fold(
                    0.0,
                    (s, e) =>
                        s +
                        (e.amount /
                            (e.participants.isEmpty
                                ? 1
                                : e.participants.length)));
            final topContributor = _findTopContributor(filtered);
            final maxMonthly = monthlyData.values.isEmpty
                ? 1.0
                : monthlyData.values.reduce((a, b) => a > b ? a : b);

            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── Summary row ──────────────────────────────────────────────
                  Row(children: [
                    Expanded(
                        child: _SummaryCard(
                      label: 'TOTAL SPENT',
                      value: '$currencySymbol${totalSpent.toStringAsFixed(0)}',
                      subtitle: '${filtered.length} transactions',
                      color: AppColors.primary,
                      icon: Icons.payments_rounded,
                    )),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _SummaryCard(
                      label: 'YOUR SHARE',
                      value: '$currencySymbol${mySpend.toStringAsFixed(0)}',
                      subtitle: 'in $_monthRange months',
                      color: AppColors.violet,
                      icon: Icons.person_rounded,
                    )),
                  ]),
                  const SizedBox(height: 20),

                  // ── Bar chart ────────────────────────────────────────────────
                  _ChartSection(
                    title: 'MONTHLY TREND',
                    child: BarChart(BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxMonthly * 1.25,
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (_) => AppColors.surfaceDark,
                          tooltipRoundedRadius: 10,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final keys = monthlyData.keys.toList();
                            return BarTooltipItem(
                              '${keys[group.x]}\n',
                              const TextStyle(
                                  color: AppColors.slate300,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600),
                              children: [
                                TextSpan(
                                  text:
                                      '$currencySymbol${rod.toY.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            getTitlesWidget: (v, _) {
                              final keys = monthlyData.keys.toList();
                              if (v.toInt() < keys.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(keys[v.toInt()],
                                      style: const TextStyle(
                                          color: AppColors.slate500,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600)),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 44,
                            getTitlesWidget: (v, _) {
                              if (v == 0) return const SizedBox.shrink();
                              return Text(
                                v >= 1000
                                    ? '${(v / 1000).toStringAsFixed(0)}k'
                                    : v.toStringAsFixed(0),
                                style: const TextStyle(
                                    color: AppColors.slate600, fontSize: 10),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (_) => const FlLine(
                            color: Color(0xFF333333), strokeWidth: 1),
                      ),
                      barGroups:
                          monthlyData.entries.toList().asMap().entries.map((e) {
                        return BarChartGroupData(
                          x: e.key,
                          barRods: [
                            BarChartRodData(
                              toY: e.value.value,
                              width: 22,
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary,
                                  AppColors.primary.withValues(alpha: 0.5),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(6)),
                            ),
                          ],
                        );
                      }).toList(),
                    )),
                  ),
                  const SizedBox(height: 20),

                  // ── Pie chart ────────────────────────────────────────────────
                  if (categoryData.isNotEmpty) ...[
                    _ChartSection(
                      title: 'CATEGORY BREAKDOWN',
                      height: null,
                      child: Column(children: [
                        SizedBox(
                          height: 200,
                          child: PieChart(PieChartData(
                            pieTouchData: PieTouchData(touchCallback: (e, r) {
                              setState(() => _touchedIndex =
                                  r?.touchedSection?.touchedSectionIndex ?? -1);
                            }),
                            sections: categoryData.asMap().entries.map((e) {
                              final isTouched = e.key == _touchedIndex;
                              final pct = totalSpent > 0
                                  ? (e.value.value / totalSpent * 100)
                                  : 0.0;
                              return PieChartSectionData(
                                color: _catColor(e.value.key),
                                value: e.value.value,
                                radius: isTouched ? 92 : 80,
                                title: isTouched
                                    ? '${pct.toStringAsFixed(0)}%'
                                    : '',
                                titleStyle: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white),
                                borderSide: isTouched
                                    ? const BorderSide(
                                        color: Colors.white, width: 2)
                                    : BorderSide.none,
                              );
                            }).toList(),
                            centerSpaceRadius: 46,
                          )),
                        ),
                        const SizedBox(height: 16),
                        // Legend grid
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: categoryData.map((e) {
                            final pct = totalSpent > 0
                                ? (e.value / totalSpent * 100)
                                : 0.0;
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: _catColor(e.key).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: _catColor(e.key)
                                        .withValues(alpha: 0.25)),
                              ),
                              child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                            color: _catColor(e.key),
                                            shape: BoxShape.circle)),
                                    const SizedBox(width: 6),
                                    Text(
                                      _catLabel(e.key),
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: _catColor(e.key)),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${pct.toStringAsFixed(0)}%',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.slate400,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ]),
                            );
                          }).toList(),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ── Category ranking ─────────────────────────────────────────
                  if (categoryData.isNotEmpty) ...[
                    _sectionLabel('SPENDING BY CATEGORY'),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDark,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.15)),
                      ),
                      child: Column(
                        children: categoryData.asMap().entries.map((entry) {
                          final e = entry.value;
                          final pct =
                              totalSpent > 0 ? (e.value / totalSpent) : 0.0;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: _catColor(e.key)
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(_catIcon(e.key),
                                        color: _catColor(e.key), size: 16),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _catLabel(e.key),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13),
                                    ),
                                  ),
                                  Text(
                                    '$currencySymbol${e.value.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14),
                                  ),
                                ]),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: pct,
                                    backgroundColor: AppColors.slate800
                                        .withValues(alpha: 0.5),
                                    valueColor: AlwaysStoppedAnimation(
                                        _catColor(e.key)),
                                    minHeight: 5,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ── Top contributor ──────────────────────────────────────────
                  if (topContributor != null) ...[
                    _sectionLabel('TOP PAYER'),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.amber.withValues(alpha: 0.15),
                            AppColors.amber.withValues(alpha: 0.04),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: AppColors.amber.withValues(alpha: 0.3)),
                      ),
                      child: Row(children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: const BoxDecoration(
                              color: AppColors.amber, shape: BoxShape.circle),
                          child: const Icon(Icons.emoji_events_rounded,
                              color: Colors.white, size: 26),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(topContributor.$1,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16)),
                              const Text('Most expenses paid',
                                  style: TextStyle(
                                      color: AppColors.slate500, fontSize: 12)),
                            ])),
                        Text(
                          '$currencySymbol${topContributor.$2.toStringAsFixed(0)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 22,
                              color: AppColors.amber),
                        ),
                      ]),
                    ),
                  ],
                ]),
              ),
            );
          },
          loading: () => const SliverFillRemaining(
            child: Center(
                child: CircularProgressIndicator(color: AppColors.primary)),
          ),
          error: (e, _) => SliverFillRemaining(
            child: Center(child: Text('Error: $e')),
          ),
        ),
      ]),
    );
  }

  Widget _sectionLabel(String text) => Text(text,
      style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppColors.slate500,
          letterSpacing: 1.5));

  // Returns Map<monthLabel, totalAmount>
  Map<String, double> _buildMonthlyData(List<Expense> expenses) {
    final now = DateTime.now();
    final result = <String, double>{};
    for (int i = _monthRange - 1; i >= 0; i--) {
      final d = DateTime(now.year, now.month - i, 1);
      final key = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ][d.month - 1];
      result[key] = 0.0;
    }
    for (final e in expenses) {
      final key = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ][e.date.month - 1];
      if (result.containsKey(key))
        result[key] = (result[key] ?? 0.0) + e.amount;
    }
    return result;
  }

  List<MapEntry<ExpenseCategory, double>> _buildCategoryData(
      List<Expense> expenses) {
    final map = <ExpenseCategory, double>{};
    for (final e in expenses) {
      map[e.category] = (map[e.category] ?? 0.0) + e.amount;
    }
    return map.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
  }

  (String, double)? _findTopContributor(List<Expense> expenses) {
    final map = <String, double>{};
    for (final e in expenses) {
      map[e.paidByName] = (map[e.paidByName] ?? 0) + e.amount;
    }
    if (map.isEmpty) return null;
    final top = map.entries.reduce((a, b) => a.value > b.value ? a : b);
    return (top.key, top.value);
  }

  Color _catColor(ExpenseCategory cat) {
    switch (cat) {
      case ExpenseCategory.food:
        return AppColors.primary;
      case ExpenseCategory.travel:
        return AppColors.blue;
      case ExpenseCategory.movie:
        return AppColors.violet;
      case ExpenseCategory.bills:
        return AppColors.rose;
      case ExpenseCategory.groceries:
        return AppColors.emerald;
      case ExpenseCategory.utilities:
        return AppColors.amber;
      case ExpenseCategory.other:
        return AppColors.slate500;
    }
  }

  IconData _catIcon(ExpenseCategory cat) {
    switch (cat) {
      case ExpenseCategory.food:
        return Icons.restaurant_rounded;
      case ExpenseCategory.travel:
        return Icons.flight_rounded;
      case ExpenseCategory.movie:
        return Icons.movie_rounded;
      case ExpenseCategory.bills:
        return Icons.receipt_long_rounded;
      case ExpenseCategory.groceries:
        return Icons.local_grocery_store_rounded;
      case ExpenseCategory.utilities:
        return Icons.lightbulb_rounded;
      case ExpenseCategory.other:
        return Icons.more_horiz_rounded;
    }
  }

  String _catLabel(ExpenseCategory cat) {
    final n = cat.name;
    return n[0].toUpperCase() + n.substring(1);
  }
}

// ── Summary Card ──────────────────────────────────────────────────────────────
class _SummaryCard extends StatelessWidget {
  final String label, value, subtitle;
  final Color color;
  final IconData icon;
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: 1.2)),
        ]),
        const SizedBox(height: 10),
        Text(value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(subtitle,
            style: const TextStyle(fontSize: 12, color: AppColors.slate500)),
      ]),
    );
  }
}

// ── Chart Section Wrapper ─────────────────────────────────────────────────────
class _ChartSection extends StatelessWidget {
  final String title;
  final Widget child;
  final double? height;
  const _ChartSection(
      {required this.title, required this.child, this.height = 200});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.slate500,
              letterSpacing: 1.5)),
      const SizedBox(height: 10),
      Container(
        height: height,
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
        ),
        child: child,
      ),
    ]);
  }
}
