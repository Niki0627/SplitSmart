// lib/shared/widgets.dart
import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/models.dart';
import 'package:intl/intl.dart';

// ── Amount Badge ──────────────────────────────────────────────────────────────
class BalanceBadge extends StatelessWidget {
  final double amount;
  final bool compact;
  const BalanceBadge({super.key, required this.amount, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final isPositive = amount > 0;
    final isZero = amount.abs() < 0.01;
    final color = isZero ? AppColors.slate500 : (isPositive ? AppColors.emerald : AppColors.rose);
    final label = isZero ? 'Settled' : (isPositive ? 'You Get' : 'You Owe');
    final formatted = '₹${amount.abs().toStringAsFixed(0)}';
    if (compact) {
      return Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text(isZero ? '₹0' : formatted, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 14)),
        Text(label, style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 10, fontWeight: FontWeight.w700)),
      ]);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Text(isZero ? 'Settled' : formatted, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
      if (!isZero) Text(label, style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 10, fontWeight: FontWeight.w700)),
      if (isZero) const Icon(Icons.check_circle, color: AppColors.slate500, size: 14),
    ]);
  }
}

// ── Group Card ────────────────────────────────────────────────────────────────
class GroupCard extends StatelessWidget {
  final String name;
  final String icon;
  final double totalAmount;
  final double userBalance;
  final VoidCallback onTap;
  const GroupCard({super.key, required this.name, required this.icon, required this.totalAmount, required this.userBalance, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final iconData = _iconData(icon);
    final bgColor = userBalance > 0
        ? AppColors.emerald.withValues(alpha: 0.12)
        : userBalance < 0 ? AppColors.rose.withValues(alpha: 0.12) : AppColors.slate800;
    final iconColor = userBalance > 0 ? AppColors.emerald : userBalance < 0 ? AppColors.rose : AppColors.slate400;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A2E2C),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
                child: Icon(iconData, color: iconColor, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 3),
                  Text('Total: ₹${totalAmount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, color: AppColors.slate500)),
                ]),
              ),
              BalanceBadge(amount: userBalance, compact: true),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconData(String name) {
    switch (name) {
      case 'flight': return Icons.flight;
      case 'home': return Icons.home;
      case 'restaurant': return Icons.restaurant;
      case 'movie': return Icons.movie;
      case 'beach': return Icons.beach_access;
      case 'sports': return Icons.sports_soccer;
      case 'shopping': return Icons.shopping_bag;
      default: return Icons.group;
    }
  }
}

// ── Expense Card ──────────────────────────────────────────────────────────────
class ExpenseCard extends StatelessWidget {
  final Expense expense;
  final String currentUserId;
  final VoidCallback? onLongPress;
  const ExpenseCard({super.key, required this.expense, required this.currentUserId, this.onLongPress});

  @override
  Widget build(BuildContext context) {
    final isPayer = expense.paidBy == currentUserId;
    final share = expense.amount / (expense.participants.isEmpty ? 1 : expense.participants.length);
    final myBalance = isPayer
        ? expense.amount - share
        : expense.participants.contains(currentUserId) ? -share : 0.0;

    return GestureDetector(
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2E2C),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(_categoryIcon(expense.category), color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(expense.description, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 3),
                Text(
                  'Paid by ${isPayer ? "You" : expense.paidByName} · ${DateFormat('MMM d').format(expense.date)}',
                  style: const TextStyle(fontSize: 12, color: AppColors.slate500),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.slate800, borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    expense.splitType.name[0].toUpperCase() + expense.splitType.name.substring(1) + ' Split',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.slate400),
                  ),
                ),
              ]),
            ),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('₹${expense.amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              const SizedBox(height: 2),
              BalanceBadge(amount: myBalance),
            ]),
          ],
        ),
      ),
    );
  }

  IconData _categoryIcon(ExpenseCategory cat) {
    switch (cat) {
      case ExpenseCategory.food: return Icons.restaurant;
      case ExpenseCategory.travel: return Icons.flight;
      case ExpenseCategory.movie: return Icons.movie;
      case ExpenseCategory.bills: return Icons.receipt_long;
      case ExpenseCategory.groceries: return Icons.local_grocery_store;
      case ExpenseCategory.utilities: return Icons.lightbulb;
      case ExpenseCategory.other: return Icons.more_horiz;
    }
  }
}

// ── Avatar ────────────────────────────────────────────────────────────────────
class UserAvatar extends StatelessWidget {
  final String? photoUrl;
  final String initials;
  final double size;
  const UserAvatar({super.key, this.photoUrl, required this.initials, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary.withValues(alpha: 0.2),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 2),
        image: photoUrl != null ? DecorationImage(image: NetworkImage(photoUrl!), fit: BoxFit.cover) : null,
      ),
      child: photoUrl == null
          ? Center(child: Text(initials, style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: size * 0.38)))
          : null,
    );
  }
}

// ── Primary Button ────────────────────────────────────────────────────────────
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  const PrimaryButton({super.key, required this.label, this.onPressed, this.loading = false, this.icon});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity, height: 52,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.backgroundDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: loading
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.backgroundDark))
            : Row(mainAxisSize: MainAxisSize.min, children: [
                if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
                Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ]),
      ),
    );
  }
}

// ── Section Header ─────────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  const SectionHeader({super.key, required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            child: Text(actionLabel!, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13)),
          ),
      ],
    );
  }
}

// ── Loading Shimmer ────────────────────────────────────────────────────────────
class ShimmerBox extends StatelessWidget {
  final double height;
  final double? width;
  final double radius;
  const ShimmerBox({super.key, required this.height, this.width, this.radius = 12});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height, width: width,
      decoration: BoxDecoration(
        color: AppColors.slate800.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

// ── Empty State ────────────────────────────────────────────────────────────────
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  const EmptyState({super.key, required this.icon, required this.title, required this.subtitle, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: AppColors.primary, size: 36),
          ),
          const SizedBox(height: 20),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(subtitle, style: const TextStyle(color: AppColors.slate500, fontSize: 14), textAlign: TextAlign.center),
          if (actionLabel != null) ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
          ],
        ]),
      ),
    );
  }
}
