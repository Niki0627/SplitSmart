// lib/features/expenses/settle_up_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme.dart';
import '../../core/providers.dart';
import '../../core/firebase_service.dart';
import '../../shared/widgets.dart';
import '../../shared/shooting_stars_grid.dart';

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
    final settlementsAsync = ref.watch(groupSettlementsProvider(widget.groupId));
    final uid = firebaseService.currentUser?.uid ?? '';

    final memberIds = groupAsync.value?.memberIds ?? [];
    final membersAsync = ref.watch(groupMembersProvider(memberIds));

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textThemeColor = isDark ? Colors.white : AppColors.slate900;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: textThemeColor), 
          onPressed: () => context.pop(),
        ),
        title: const Text('Settle Up', style: TextStyle(fontWeight: FontWeight.w800)),
        surfaceTintColor: Colors.transparent,
      ),
      body: ShootingStarsGrid(
        padding: EdgeInsets.zero,
        child: expensesAsync.when(
          data: (expenses) {
            return settlementsAsync.when(
              data: (settlements) {
                final group = groupAsync.value;
                final ids = group?.memberIds ?? [];
                final balances = firebaseService.calculateBalances(expenses, settlements, ids);

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
                  GlassCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('YOUR SUMMARY', 
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: isDark ? AppColors.cyan : AppColors.primaryDark, letterSpacing: 1.5)),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(child: _SummaryBox(
                          label: 'You Owe', icon: LucideIcons.arrowUp,
                          amount: owes.values.fold(0.0, (s, a) => s + a), color: AppColors.rose)),
                        Container(width: 1.2, height: 48, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)),
                        Expanded(child: _SummaryBox(
                          label: 'You Get', icon: LucideIcons.arrowDown,
                          amount: owed.values.fold(0.0, (s, a) => s + a), color: AppColors.emerald)),
                      ]),
                    ]),
                  ),
                  const SizedBox(height: 24),

                  if (owes.isNotEmpty) ...[
                    Text('YOU OWE', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.rose)),
                    const SizedBox(height: 10),
                    ...owes.entries.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _SettlementCard(
                        memberId: e.key,
                        memberName: resolveName(e.key),
                        memberInitials: resolveInitials(e.key),
                        amount: e.value,
                        isOwed: false,
                        loading: _loading,
                        onPayWithApp: (app) => _payViaUpi(e.key, e.value, app),
                        onPayOtherUpi: () => _payViaUpi(e.key, e.value, null),
                        onSettleCash: () => _settleCashDirect(e.key, uid, e.value),
                      ),
                    )),
                    const SizedBox(height: 16),
                  ],

                  if (owed.isNotEmpty) ...[
                    Text('OWED TO YOU', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.emerald)),
                    const SizedBox(height: 10),
                    ...owed.entries.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _SettlementCard(
                        memberId: e.key,
                        memberName: resolveName(e.key),
                        memberInitials: resolveInitials(e.key),
                        amount: e.value,
                        isOwed: true,
                        loading: _loading,
                        onPayWithApp: (_) {},
                        onPayOtherUpi: () {},
                        onSettleCash: () => _settleCreditorConfirm(uid, e.key, e.value, resolveName(e.key)),
                      ),
                    )),
                  ],

                  if (owes.isEmpty && owed.isEmpty)
                    GlassCard(
                      bgColor: AppColors.emerald.withValues(alpha: 0.12),
                      border: Border.all(color: AppColors.emerald.withValues(alpha: 0.35)),
                      padding: const EdgeInsets.all(24),
                      child: Column(children: [
                        const Icon(LucideIcons.checkCircle, color: AppColors.emerald, size: 44),
                        const SizedBox(height: 14),
                        Text('All settled up!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: textThemeColor)),
                        const SizedBox(height: 6),
                        const Text("You're all even with your group.", style: TextStyle(color: AppColors.slate500, fontWeight: FontWeight.w500)),
                      ]),
                    ),

                  const SizedBox(height: 100),
                ]);
              },
              loading: () => Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)),
              error: (e, _) => Center(child: Text('Error: $e')),
            );
          },
          loading: () => Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }

  Future<void> _payViaUpi(String receiverId, double amount, [UpiAppInfo? app]) async {
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

      if (mounted) {
        await _launchUpiApp(app, receiverId, amount, name, targetUpi);
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

  Future<void> _settleCashDirect(String from, String to, double amount) async {
    setState(() => _loading = true);
    try {
      await firebaseService.settleUp(widget.groupId, from, from, to, to, amount);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cash settlement recorded ✓'), backgroundColor: AppColors.emerald, behavior: SnackBarBehavior.floating));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.rose));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _settleDebtorDirect(String creditorId, double amount) async {
    final uid = firebaseService.currentUser?.uid ?? '';
    setState(() => _loading = true);
    try {
      await firebaseService.settleUp(widget.groupId, uid, uid, creditorId, creditorId, amount);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment recorded and settled! ✓'), backgroundColor: AppColors.emerald, behavior: SnackBarBehavior.floating));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.rose));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _settleCreditorConfirm(String from, String to, double amount, String receiverName) async {
    final currencySymbol = ref.read(currencySymbolProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx2) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Settle Up', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        content: Text('Confirm that you received $currencySymbol${amount.toStringAsFixed(0)} offline/cash from $receiverName?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx2, false), child: const Text('Cancel', style: TextStyle(color: AppColors.slate400))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx2, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.emerald, foregroundColor: Colors.white),
            child: const Text('Confirm & Record'),
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

  Future<void> _launchUpiApp(
    UpiAppInfo? app,
    String receiverId,
    double amount,
    String receiverName,
    String targetUpi,
  ) async {
    const note = 'SplitSmart Settlement';
    Uri uri;

    if (app != null) {
      final String intentUrl =
          'intent://pay?pa=$targetUpi&pn=${Uri.encodeComponent(receiverName)}&am=${amount.toStringAsFixed(2)}&cu=INR&tn=${Uri.encodeComponent(note)}#Intent;scheme=upi;package=${app.packageName};end';
      uri = Uri.parse(intentUrl);
    } else {
      uri = Uri.parse(
          'upi://pay?pa=$targetUpi&pn=${Uri.encodeComponent(receiverName)}&am=${amount.toStringAsFixed(2)}&cu=INR&tn=${Uri.encodeComponent(note)}');
    }

    try {
      final success = await launchUrl(uri, mode: LaunchMode.externalApplication);
      
      if (!success && app != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${app.name} not available. Opening UPI chooser...'),
            backgroundColor: AppColors.amber,
            behavior: SnackBarBehavior.floating,
          ));
        }
        final genericUri = Uri.parse(
            'upi://pay?pa=$targetUpi&pn=${Uri.encodeComponent(receiverName)}&am=${amount.toStringAsFixed(2)}&cu=INR&tn=${Uri.encodeComponent(note)}');
        await launchUrl(genericUri, mode: LaunchMode.externalApplication);
      }

      if (mounted) {
        _showPaymentConfirmation(receiverId, amount, receiverName, app?.name ?? 'your UPI app');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not launch UPI payment: $e'),
          backgroundColor: AppColors.rose,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  void _showPaymentConfirmation(
    String receiverId,
    double amount,
    String receiverName,
    String appName,
  ) {
    final currencySymbol = ref.read(currencySymbolProvider);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text(
            'Verify Payment',
            style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Did you complete the payment of $currencySymbol${amount.toStringAsFixed(0)} to $receiverName via $appName?',
                style: const TextStyle(color: AppColors.slate300, fontSize: 14),
              ),
              const SizedBox(height: 12),
              const Text(
                'Tapping "Mark as Settled" will update the balance in your group.',
                style: TextStyle(color: AppColors.slate500, fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Cancel / Pay Again',
                style: TextStyle(color: AppColors.slate400, fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _settleDebtorDirect(receiverId, amount);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Mark as Settled'),
            ),
          ],
        );
      },
    );
  }
}

class UpiAppInfo {
  final String id;
  final String name;
  final String packageName;
  final Color color;
  final String initials;

  const UpiAppInfo({
    required this.id,
    required this.name,
    required this.packageName,
    required this.color,
    required this.initials,
  });
}

const List<UpiAppInfo> _supportedUpiApps = [
  UpiAppInfo(
    id: 'gpay',
    name: 'Google Pay',
    packageName: 'com.google.android.apps.nbu.paisa.user',
    color: Color(0xFF4285F4),
    initials: 'G',
  ),
  UpiAppInfo(
    id: 'phonepe',
    name: 'PhonePe',
    packageName: 'com.phonepe.app',
    color: Color(0xFF5F259F),
    initials: 'Pe',
  ),
  UpiAppInfo(
    id: 'paytm',
    name: 'Paytm',
    packageName: 'net.one97.paytm',
    color: Color(0xFF00B9F5),
    initials: 'Py',
  ),
  UpiAppInfo(
    id: 'bhim',
    name: 'BHIM',
    packageName: 'in.org.npci.upiapp',
    color: Color(0xFFE05C15),
    initials: 'B',
  ),
];

class _SettlementCard extends ConsumerWidget {
  final String memberId;
  final String memberName;
  final String memberInitials;
  final double amount;
  final bool isOwed;
  final bool loading;
  final Function(UpiAppInfo app) onPayWithApp;
  final VoidCallback onPayOtherUpi;
  final VoidCallback onSettleCash;

  const _SettlementCard({
    required this.memberId,
    required this.memberName,
    required this.memberInitials,
    required this.amount,
    required this.isOwed,
    required this.loading,
    required this.onPayWithApp,
    required this.onPayOtherUpi,
    required this.onSettleCash,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencySymbol = ref.watch(currencySymbolProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textThemeColor = isDark ? Colors.white : AppColors.slate900;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              UserAvatar(initials: memberInitials, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      memberName,
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: textThemeColor),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isOwed ? 'Owes you' : 'You owe them',
                      style: const TextStyle(color: AppColors.slate500, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              Text(
                '$currencySymbol${amount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: isOwed ? AppColors.emerald : AppColors.rose,
                ),
              ),
            ],
          ),
          if (isOwed) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 40,
              child: ElevatedButton.icon(
                onPressed: loading ? null : onSettleCash,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.emerald,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: loading ? const SizedBox.shrink() : const Icon(LucideIcons.checkCircle, size: 16),
                label: loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      )
                    : const Text('Confirm Cash Received', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
              ),
            ),
          ],
          if (!isOwed) ...[
            const Divider(height: 24),
            Text(
              'PAY DIRECTLY VIA',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.cyan : AppColors.primaryDark,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 3.2,
              children: [
                _FlatButton(
                  color: const Color(0xFF4285F4),
                  onTap: loading ? null : () => onPayWithApp(_supportedUpiApps[0]),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('G', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white)),
                      SizedBox(width: 6),
                      Text('Google Pay', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Colors.white)),
                    ],
                  ),
                ),
                _FlatButton(
                  color: const Color(0xFF5F259F),
                  onTap: loading ? null : () => onPayWithApp(_supportedUpiApps[1]),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Pe', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.white)),
                      SizedBox(width: 6),
                      Text('PhonePe', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Colors.white)),
                    ],
                  ),
                ),
                _FlatButton(
                  color: const Color(0xFF00B9F5),
                  onTap: loading ? null : () => onPayWithApp(_supportedUpiApps[2]),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Py', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.white)),
                      SizedBox(width: 6),
                      Text('Paytm', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Colors.white)),
                    ],
                  ),
                ),
                _FlatButton(
                  color: const Color(0xFFE05C15),
                  onTap: loading ? null : () => onPayWithApp(_supportedUpiApps[3]),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('B', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white)),
                      SizedBox(width: 6),
                      Text('BHIM UPI', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Colors.white)),
                    ],
                  ),
                ),
                _FlatButton(
                  color: const Color(0xFF475569),
                  onTap: loading ? null : onPayOtherUpi,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.grid, size: 14, color: Colors.white),
                      SizedBox(width: 6),
                      Text('Other UPI', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Colors.white)),
                    ],
                  ),
                ),
                _FlatButton(
                  color: isDark ? const Color(0xFF333333) : const Color(0xFF1A1A1A),
                  onTap: loading ? null : onSettleCash,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.banknote, size: 14, color: Colors.white),
                      SizedBox(width: 6),
                      Text('Record Cash', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Colors.white)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryBox extends ConsumerWidget {
  final String label;
  final IconData icon;
  final double amount;
  final Color color;
  const _SummaryBox({required this.label, required this.icon, required this.amount, required this.color});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencySymbol = ref.watch(currencySymbolProvider);
    return Column(children: [
      Icon(icon, color: color, size: 22),
      const SizedBox(height: 4),
      Text('$currencySymbol${amount.toStringAsFixed(0)}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(fontSize: 11, color: AppColors.slate500, fontWeight: FontWeight.w600)),
    ]);
  }
}

class _FlatButton extends StatelessWidget {
  final Widget child;
  final Color color;
  final VoidCallback? onTap;
  const _FlatButton({required this.child, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;
    return Container(
      height: 42,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
      ),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1),
          ),
        ),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: isEnabled ? 1.0 : 0.6,
          child: child,
        ),
      ),
    );
  }
}
