// lib/features/expenses/settle_up_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme.dart';
import '../../core/providers.dart';
import '../../core/firebase_service.dart';
import '../../shared/widgets.dart';

class SettleUpScreen extends ConsumerStatefulWidget {
  final String groupId;
  const SettleUpScreen({super.key, required this.groupId});
  @override
  ConsumerState<SettleUpScreen> createState() => _SettleUpScreenState();
}

class _SettleUpScreenState extends ConsumerState<SettleUpScreen> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(groupExpensesProvider(widget.groupId));
    final groupAsync = ref.watch(groupsProvider).whenData(
        (gs) => gs.firstWhere((g) => g.id == widget.groupId, orElse: () => gs.first));
    final uid = firebaseService.currentUser?.uid ?? '';

    final memberIds = groupAsync.value?.memberIds ?? [];
    final membersAsync = ref.watch(groupMembersProvider(memberIds));

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
        title: const Text('Settle Up'),
        surfaceTintColor: Colors.transparent,
      ),
      body: expensesAsync.when(
        data: (expenses) {
          final group = groupAsync.value;
          final ids = group?.memberIds ?? [];
          final balances = firebaseService.calculateBalances(expenses, ids);

          // Build a name lookup map from resolved members
          final nameMap = <String, String>{};
          final initialsMap = <String, String>{};
          membersAsync.whenData((members) {
            for (final m in members) {
              nameMap[m.uid] = m.name;
              initialsMap[m.uid] = m.initials;
            }
          });

          String resolveName(String id) {
            if (id == uid) return 'You';
            return nameMap[id] ?? 'Member';
          }

          String resolveInitials(String id) {
            return initialsMap[id] ?? (id.isNotEmpty ? id[0].toUpperCase() : '?');
          }

          // Amounts current user owes others
          final owes = <String, double>{};
          for (final who in ids) {
            final amt = balances[uid]?[who] ?? 0;
            if (amt > 0.01) owes[who] = amt;
          }

          // Amounts others owe to current user
          final owed = <String, double>{};
          for (final who in ids) {
            final amt = balances[who]?[uid] ?? 0;
            if (amt > 0.01) owed[who] = amt;
          }

          return ListView(padding: const EdgeInsets.all(20), children: [
            // Overview Banner
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [AppColors.primary.withValues(alpha: 0.15), AppColors.primary.withValues(alpha: 0.05)]),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('YOUR SUMMARY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary, letterSpacing: 1.5)),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _SummaryBox(
                    label: 'You Owe', icon: Icons.arrow_upward_rounded,
                    amount: owes.values.fold(0.0, (s, a) => s + a), color: AppColors.rose)),
                  Container(width: 1, height: 48, color: AppColors.primary.withValues(alpha: 0.2)),
                  Expanded(child: _SummaryBox(
                    label: 'You Get', icon: Icons.arrow_downward_rounded,
                    amount: owed.values.fold(0.0, (s, a) => s + a), color: AppColors.emerald)),
                ]),
              ]),
            ),
            const SizedBox(height: 24),

            if (owes.isNotEmpty) ...[
              const Text('YOU OWE', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.rose)),
              const SizedBox(height: 10),
              ...owes.entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _SettlementCard(
                  memberId: e.key,
                  memberName: resolveName(e.key),
                  memberInitials: resolveInitials(e.key),
                  amount: e.value,
                  isOwed: false,
                  loading: _loading,
                  onSettle: () => _settle(context, e.key, uid, e.value),
                  onPayViaGPay: () => _payViaUpi(e.key, e.value),
                ),
              )),
              const SizedBox(height: 16),
            ],

            if (owed.isNotEmpty) ...[
              const Text('OWED TO YOU', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.emerald)),
              const SizedBox(height: 10),
              ...owed.entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _SettlementCard(
                  memberId: e.key,
                  memberName: resolveName(e.key),
                  memberInitials: resolveInitials(e.key),
                  amount: e.value,
                  isOwed: true,
                  loading: _loading,
                  onSettle: () => _settle(context, uid, e.key, e.value),
                ),
              )),
            ],

            if (owes.isEmpty && owed.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: AppColors.emerald.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.emerald.withValues(alpha: 0.3))),
                child: const Column(children: [
                  Icon(Icons.check_circle_rounded, color: AppColors.emerald, size: 48),
                  SizedBox(height: 12),
                  Text('All settled up!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                  SizedBox(height: 6),
                  Text("You're all even with your group.", style: TextStyle(color: AppColors.slate500)),
                ]),
              ),

            const SizedBox(height: 100),
          ]);
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Future<void> _settle(BuildContext ctx, String from, String to, double amount) async {
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (ctx2) => AlertDialog(
        backgroundColor: const Color(0xFF1A2E2C),
        title: const Text('Mark as Settled?'),
        content: Text('Record payment of ₹${amount.toStringAsFixed(0)}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx2, false), child: const Text('Cancel', style: TextStyle(color: AppColors.slate400))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx2, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.emerald, foregroundColor: Colors.white),
            child: const Text('Settle'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      setState(() => _loading = true);
      try {
        await firebaseService.settleUp(widget.groupId, from, from, to, to, amount);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Settlement recorded ✓'), backgroundColor: AppColors.emerald, behavior: SnackBarBehavior.floating));
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.rose));
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    }
  }

  Future<void> _payViaUpi(String receiverId, double amount) async {
    try {
      final doc = await firebaseService.db.collection('users').doc(receiverId).get();
      if (!doc.exists) throw Exception('User not found');
      final data = doc.data()!;
      final upiId = data['upiId']?.toString().trim() ?? '';
      final name = data['name']?.toString() ?? 'User';
      final phone = data['phone']?.toString() ?? '';

      String targetUpi = upiId;
      if (targetUpi.isEmpty && phone.isNotEmpty) {
        final bare = phone.replaceAll(RegExp(r'[^\d]'), '');
        final digits = bare.length >= 10 ? bare.substring(bare.length - 10) : bare;
        targetUpi = '$digits@paytm';
      }

      if (targetUpi.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('This user has not set up a UPI ID or phone number.'),
            backgroundColor: AppColors.rose, behavior: SnackBarBehavior.floating,
          ));
        }
        return;
      }

      final uri = Uri.parse(
          'upi://pay?pa=$targetUpi&pn=${Uri.encodeComponent(name)}&am=${amount.toStringAsFixed(2)}&cu=INR');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('No UPI app found (GPay, PhonePe, etc.)'),
            backgroundColor: AppColors.rose, behavior: SnackBarBehavior.floating,
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to launch UPI: $e'),
          backgroundColor: AppColors.rose, behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }
}

class _SettlementCard extends StatelessWidget {
  final String memberId;
  final String memberName;
  final String memberInitials;
  final double amount;
  final bool isOwed;
  final bool loading;
  final VoidCallback onSettle;
  final VoidCallback? onPayViaGPay;

  const _SettlementCard({
    required this.memberId,
    required this.memberName,
    required this.memberInitials,
    required this.amount,
    required this.isOwed,
    required this.loading,
    required this.onSettle,
    this.onPayViaGPay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2E2C),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Row(children: [
            UserAvatar(initials: memberInitials, size: 44),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(memberName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              Text(isOwed ? 'Owes you' : 'You owe them',
                style: const TextStyle(color: AppColors.slate500, fontSize: 12)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('₹${amount.toStringAsFixed(0)}',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18,
                  color: isOwed ? AppColors.emerald : AppColors.rose)),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: loading ? null : onSettle,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: loading ? AppColors.slate700 : AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Settle',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.backgroundDark)),
                ),
              ),
            ]),
          ]),
          if (!isOwed && onPayViaGPay != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onPayViaGPay,
                icon: const Icon(Icons.account_balance_wallet_rounded, size: 16),
                label: const Text('Pay via GPay / UPI',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }
}

class _SummaryBox extends StatelessWidget {
  final String label;
  final IconData icon;
  final double amount;
  final Color color;
  const _SummaryBox({required this.label, required this.icon, required this.amount, required this.color});
  @override
  Widget build(BuildContext context) => Column(children: [
    Icon(icon, color: color, size: 22),
    const SizedBox(height: 4),
    Text('₹${amount.toStringAsFixed(0)}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
    const SizedBox(height: 2),
    Text(label, style: const TextStyle(fontSize: 11, color: AppColors.slate500)),
  ]);
}
