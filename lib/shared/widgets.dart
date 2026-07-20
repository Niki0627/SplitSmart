// lib/shared/widgets.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../core/models.dart';
import '../core/providers.dart';

// ── Glass Card ──────────────────────────────────────────────────────────────
class GlassCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Border? border;
  final Color? bgColor;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 16.0,
    this.border,
    this.bgColor,
  });

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fallbackBgColor = isDark
        ? AppColors.cardDark
        : AppColors.cardLight;
    final accentColor = isDark ? AppColors.cyan : AppColors.primaryDark;

    final Color borderClr = _isHovered
        ? accentColor.withValues(alpha: 0.65)
        : (isDark ? AppColors.borderDark : AppColors.borderLight).withValues(alpha: 0.22);
    final double borderWidth = _isHovered ? 1.5 : 1.2;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: widget.padding,
        decoration: BoxDecoration(
          color: widget.bgColor ?? fallbackBgColor,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: widget.border ?? Border.all(
            color: borderClr,
            width: borderWidth,
          ),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.1),
                    blurRadius: 18,
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: widget.child,
      ),
    );
  }
}

// ── Amount Badge ──────────────────────────────────────────────────────────────
class BalanceBadge extends ConsumerWidget {
  final double amount;
  final bool compact;
  const BalanceBadge({super.key, required this.amount, this.compact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencySymbol = ref.watch(currencySymbolProvider);
    final isPositive = amount > 0;
    final isZero = amount.abs() < 0.01;
    final color = isZero
        ? AppColors.slate500
        : (isPositive ? AppColors.emerald : AppColors.rose);
    final label = isZero ? 'Settled' : (isPositive ? 'You Get' : 'You Owe');
    final formatted = '$currencySymbol${amount.abs().toStringAsFixed(0)}';
    if (compact) {
      return Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text(isZero ? '${currencySymbol}0' : formatted,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w700, fontSize: 14)),
        Text(label,
            style: TextStyle(
                color: color.withValues(alpha: 0.75),
                fontSize: 10,
                fontWeight: FontWeight.w700)),
      ]);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Text(isZero ? 'Settled' : formatted,
          style: TextStyle(
              color: color, fontWeight: FontWeight.w700, fontSize: 13)),
      if (!isZero)
        Text(label,
            style: TextStyle(
                color: color.withValues(alpha: 0.75),
                fontSize: 10,
                fontWeight: FontWeight.w700)),
      if (isZero)
        const Icon(LucideIcons.checkCircle, color: AppColors.slate500, size: 14),
    ]);
  }
}

// ── Group Card ────────────────────────────────────────────────────────────────
class GroupCard extends ConsumerWidget {
  final String name;
  final String icon;
  final double totalAmount;
  final double userBalance;
  final VoidCallback onTap;
  const GroupCard(
      {super.key,
      required this.name,
      required this.icon,
      required this.totalAmount,
      required this.userBalance,
      required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencySymbol = ref.watch(currencySymbolProvider);
    final iconData = _iconData(icon);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = userBalance > 0
        ? AppColors.emerald.withValues(alpha: 0.12)
        : userBalance < 0
            ? AppColors.rose.withValues(alpha: 0.12)
            : (isDark ? AppColors.slate800.withValues(alpha: 0.3) : AppColors.slate100.withValues(alpha: 0.3));

    final iconColor = userBalance > 0
        ? AppColors.emerald
        : userBalance < 0
            ? AppColors.rose
            : (isDark ? AppColors.slate400 : AppColors.slate600);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                      color: bgColor, borderRadius: BorderRadius.circular(12)),
                  child: Icon(iconData, color: iconColor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: isDark
                                ? Colors.white
                                : AppColors.slate900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                            'Total: $currencySymbol${totalAmount.toStringAsFixed(0)}',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.slate500)),
                      ]),
                ),
                BalanceBadge(amount: userBalance, compact: true),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconData(String name) {
    switch (name) {
      case 'flight':
        return LucideIcons.plane;
      case 'home':
        return LucideIcons.home;
      case 'restaurant':
        return LucideIcons.utensils;
      case 'movie':
        return LucideIcons.film;
      case 'beach':
        return LucideIcons.sun;
      case 'sports':
        return LucideIcons.trophy;
      case 'shopping':
        return LucideIcons.shoppingBag;
      default:
        return LucideIcons.users;
    }
  }
}

// ── Expense Card ──────────────────────────────────────────────────────────────
class ExpenseCard extends ConsumerWidget {
  final Expense expense;
  final String currentUserId;
  final VoidCallback? onLongPress;
  const ExpenseCard(
      {super.key,
      required this.expense,
      required this.currentUserId,
      this.onLongPress});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencySymbol = ref.watch(currencySymbolProvider);
    final isPayer = expense.paidBy == currentUserId;
    final share = expense.amount /
        (expense.participants.isEmpty ? 1 : expense.participants.length);
    final myBalance = isPayer
        ? expense.amount - share
        : expense.participants.contains(currentUserId)
            ? -share
            : 0.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onLongPress: onLongPress,
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_categoryIcon(expense.category),
                    color: isDark ? AppColors.cyan : AppColors.primaryDark, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.description,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: isDark ? Colors.white : AppColors.slate900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Paid by ${isPayer ? "You" : expense.paidByName} · ${DateFormat('MMM d').format(expense.date)}',
                        style: const TextStyle(
                          fontSize: 12, color: AppColors.slate500, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark 
                              ? AppColors.slate800.withValues(alpha: 0.3) 
                              : AppColors.slate100.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: isDark 
                                  ? AppColors.borderDark.withValues(alpha: 0.1) 
                                  : AppColors.borderLight.withValues(alpha: 0.1)),
                        ),
                        child: Text(
                          '${expense.splitType.name[0].toUpperCase()}${expense.splitType.name.substring(1)} Split',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color:
                                isDark ? AppColors.slate400 : AppColors.slate600,
                          ),
                        ),
                      ),
                    ]),
              ),
              const SizedBox(width: 8),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(
                  '$currencySymbol${expense.amount.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: isDark ? Colors.white : AppColors.slate900,
                  ),
                ),
                const SizedBox(height: 2),
                BalanceBadge(amount: myBalance),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  IconData _categoryIcon(ExpenseCategory cat) {
    switch (cat) {
      case ExpenseCategory.food:
        return LucideIcons.utensils;
      case ExpenseCategory.travel:
        return LucideIcons.plane;
      case ExpenseCategory.movie:
        return LucideIcons.film;
      case ExpenseCategory.bills:
        return LucideIcons.fileText;
      case ExpenseCategory.groceries:
        return LucideIcons.shoppingCart;
      case ExpenseCategory.utilities:
        return LucideIcons.zap;
      case ExpenseCategory.other:
        return LucideIcons.moreHorizontal;
    }
  }
}

// ── Avatar ────────────────────────────────────────────────────────────────────
class UserAvatar extends StatelessWidget {
  final String? photoUrl;
  final String initials;
  final double size;
  const UserAvatar(
      {super.key, this.photoUrl, required this.initials, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: photoUrl == null ? Colors.transparent : null,
        image: photoUrl != null
            ? DecorationImage(image: NetworkImage(photoUrl!), fit: BoxFit.cover)
            : null,
      ),
      child: photoUrl == null
          ? Center(
              child: Text(
                initials,
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.slate900,
                  fontWeight: FontWeight.w800,
                  fontSize: size * 0.42,
                  letterSpacing: -0.5,
                ),
              ),
            )
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
  const PrimaryButton(
      {super.key,
      required this.label,
      this.onPressed,
      this.loading = false,
      this.icon});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final onPrimaryColor = Theme.of(context).colorScheme.onPrimary;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: onPrimaryColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: loading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: onPrimaryColor))
            : Row(mainAxisSize: MainAxisSize.min, children: [
                if (icon != null) ...[
                  Icon(icon, size: 18),
                  const SizedBox(width: 8)
                ],
                Text(label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15)),
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
  const SectionHeader(
      {super.key, required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: TextStyle(
                fontSize: 16, 
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppColors.slate900)),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            child: Text(actionLabel!,
                style: TextStyle(
                    color: isDark ? AppColors.cyan : AppColors.primaryDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 13)),
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
  const ShimmerBox(
      {super.key, required this.height, this.width, this.radius = 12});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: (isDark ? AppColors.slate800 : AppColors.slate100)
            .withValues(alpha: 0.35),
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
  const EmptyState(
      {super.key,
      required this.icon,
      required this.title,
      required this.subtitle,
      this.actionLabel,
      this.onAction});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.12),
                shape: BoxShape.circle),
            child: Icon(icon, color: isDark ? AppColors.cyan : AppColors.primaryDark, size: 32),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.slate900,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(subtitle,
              style: const TextStyle(color: AppColors.slate500, fontSize: 13, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center),
          if (actionLabel != null) ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: Text(actionLabel!),
            ),
          ],
        ]),
      ),
    );
  }
}
