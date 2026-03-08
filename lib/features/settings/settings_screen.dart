// lib/features/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../core/providers.dart';
import '../../core/firebase_service.dart';
import '../../shared/widgets.dart';
import '../../core/models.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final groups = ref.watch(groupsProvider);
    final allExpenses = ref.watch(allExpensesProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: CustomScrollView(slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: AppColors.backgroundDark,
          automaticallyImplyLeading: false,
          surfaceTintColor: Colors.transparent,
          title: const Text('Profile',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        ),
        SliverToBoxAdapter(
          child: Column(children: [
            // ── Profile hero card ──────────────────────────────────────────
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.18),
                    AppColors.primary.withValues(alpha: 0.04),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
              ),
              child: user.when(
                data: (u) => Row(children: [
                  UserAvatar(
                      photoUrl: u?.photoUrl,
                      initials: u?.initials ?? '?',
                      size: 68),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(u?.name ?? 'User',
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(u?.email ?? '',
                          style: const TextStyle(
                              color: AppColors.slate500,
                              fontSize: 13,
                              letterSpacing: 0.2)),
                      if (u?.phone?.isNotEmpty == true) ...[
                        const SizedBox(height: 2),
                        Text(u!.phone!, style: const TextStyle(color: AppColors.slate500, fontSize: 13, letterSpacing: 0.2)),
                      ],
                    ]),
                  ),
                  GestureDetector(
                    onTap: () => _showEditProfile(context, u),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: const Icon(Icons.edit_rounded,
                          color: AppColors.primary, size: 16),
                    ),
                  ),
                ]),
                loading: () => const ShimmerBox(height: 60),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
            const SizedBox(height: 16),

            // ── Stats row ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.group_rounded,
                    iconColor: AppColors.primary,
                    label: 'Groups',
                    value: groups.when(
                        data: (g) => '${g.length}',
                        loading: () => '—',
                        error: (_, __) => '0'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.receipt_long_rounded,
                    iconColor: AppColors.violet,
                    label: 'Expenses',
                    value: allExpenses.when(
                        data: (e) => '${e.length}',
                        loading: () => '—',
                        error: (_, __) => '0'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.check_circle_rounded,
                    iconColor: AppColors.emerald,
                    label: 'Settled',
                    value: '0',
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 28),

            // ── Account section ────────────────────────────────────────────
            _buildSection('ACCOUNT', [
              _SettingsTile(
                icon: Icons.person_outline_rounded,
                label: 'Edit Profile',
                onTap: () {
                  _showEditProfile(context, user.value);
                },
              ),
              _SettingsTile(
                icon: Icons.notifications_outlined,
                label: 'Notification Preferences',
                onTap: () => context.go('/reminders'),
              ),
              _SettingsTile(
                icon: Icons.security_rounded,
                label: 'Privacy & Security',
                onTap: () {},
              ),
            ]),
            const SizedBox(height: 16),

            // ── Preferences section ────────────────────────────────────────
            _buildSection('PREFERENCES', [
              _SettingsTile(
                icon: Icons.palette_outlined,
                label: 'Appearance',
                trailing: const Text('Dark',
                    style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.language_rounded,
                label: 'Currency',
                trailing: const Text('INR ₹',
                    style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.analytics_outlined,
                label: 'View Analytics',
                onTap: () => context.go('/analytics'),
              ),
            ]),
            const SizedBox(height: 16),

            // ── Support section ────────────────────────────────────────────
            _buildSection('SUPPORT', [
              _SettingsTile(
                  icon: Icons.help_outline_rounded,
                  label: 'Help & FAQ',
                  onTap: () {}),
              _SettingsTile(
                  icon: Icons.star_outline_rounded,
                  label: 'Rate SplitSmart',
                  onTap: () {}),
              _SettingsTile(
                icon: Icons.info_outline_rounded,
                label: 'About',
                trailing: const Text('v1.0.0',
                    style: TextStyle(
                        color: AppColors.slate500, fontSize: 13)),
                onTap: () {},
              ),
            ]),
            const SizedBox(height: 28),

            // ── Sign Out ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await firebaseService.signOut();
                    if (context.mounted) context.go('/auth');
                  },
                  icon: const Icon(Icons.logout_rounded,
                      size: 18, color: AppColors.rose),
                  label: const Text('Sign Out',
                      style: TextStyle(
                          color: AppColors.rose,
                          fontWeight: FontWeight.w700,
                          fontSize: 15)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: AppColors.rose.withValues(alpha: 0.4)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 120),
          ]),
        ),
      ]),
    );
  }

  void _showEditProfile(BuildContext context, AppUser? user) {
    if (user == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditProfileSheet(user: user),
    );
  }

  Widget _buildSection(String title, List<Widget> tiles) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.slate500,
                letterSpacing: 1.5)),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A2E2C),
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
          ),
          child: Column(children: [
            for (int i = 0; i < tiles.length; i++) ...[
              if (i > 0)
                const Divider(
                    height: 1,
                    indent: 60,
                    endIndent: 20,
                    color: Color(0xFF243A38)),
              tiles[i],
            ],
          ]),
        ),
      ]),
    );
  }
}

// ── Edit Profile Bottom Sheet ─────────────────────────────────────────────────
class _EditProfileSheet extends ConsumerStatefulWidget {
  final AppUser user;
  const _EditProfileSheet({required this.user});

  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _upiCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user.name);
    _phoneCtrl = TextEditingController(text: widget.user.phone ?? '');
    _upiCtrl = TextEditingController(text: widget.user.upiId ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _upiCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Name cannot be empty'),
        backgroundColor: AppColors.rose,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    setState(() => _saving = true);
    try {
      final uid = firebaseService.currentUser?.uid;
      if (uid != null) {
        await firebaseService.updateUserProfile(
          uid: uid,
          name: name,
          phone: _phoneCtrl.text.trim().isNotEmpty ? _phoneCtrl.text.trim() : null,
          upiId: _upiCtrl.text.trim().isNotEmpty ? _upiCtrl.text.trim() : null,
        );
      }
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Profile updated!'),
          backgroundColor: AppColors.emerald,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed: $e'),
          backgroundColor: AppColors.rose,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      decoration: const BoxDecoration(
        color: Color(0xFF1A2E2C),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Handle
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.slate700,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 20),
        const Text('Edit Profile',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        const Text('Update your name or phone number',
            style: TextStyle(color: AppColors.slate500, fontSize: 13)),
        const SizedBox(height: 24),

        // Email (read-only)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.backgroundDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.slate700),
          ),
          child: Row(children: [
            const Icon(Icons.email_outlined, color: AppColors.slate500, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(widget.user.email,
                  style: const TextStyle(
                      color: AppColors.slate500, fontSize: 14)),
            ),
            const Text('Fixed',
                style: TextStyle(
                    color: AppColors.slate600,
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ]),
        ),
        const SizedBox(height: 12),

        // Name field
        TextField(
          controller: _nameCtrl,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: 'Your full name',
            prefixIcon: const Icon(Icons.person_rounded,
                color: AppColors.primary, size: 20),
            labelText: 'Display Name',
            labelStyle:
                const TextStyle(color: AppColors.slate400, fontSize: 13),
          ),
        ),
        const SizedBox(height: 12),

        // Phone field
        TextField(
          controller: _phoneCtrl,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            hintText: '+91 98765 43210',
            prefixIcon: const Icon(Icons.phone_rounded,
                color: AppColors.primary, size: 20),
            labelText: 'Phone (for search)',
            labelStyle:
                const TextStyle(color: AppColors.slate400, fontSize: 13),
          ),
        ),
        const SizedBox(height: 12),

        // UPI ID field
        TextField(
          controller: _upiCtrl,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: 'john@upi',
            prefixIcon: const Icon(Icons.account_balance_wallet_rounded,
                color: AppColors.primary, size: 20),
            labelText: 'UPI ID (Optional)',
            labelStyle:
                const TextStyle(color: AppColors.slate400, fontSize: 13),
          ),
        ),
        const SizedBox(height: 24),

        // Save button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black87,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: _saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.black87))
                : const Text('Save Changes',
                    style: TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15)),
          ),
        ),
      ]),
    );
  }
}

// ── Stat Card ─────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label, value;
  const _StatCard(
      {required this.icon,
      required this.iconColor,
      required this.label,
      required this.value});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: iconColor.withValues(alpha: 0.2)),
        ),
        child: Column(children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 8),
          Text(value,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label,
              style:
                  const TextStyle(fontSize: 11, color: AppColors.slate500)),
        ]),
      );
}

// ── Settings Tile ─────────────────────────────────────────────────────────────
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback onTap;
  const _SettingsTile(
      {required this.icon,
      required this.label,
      this.trailing,
      required this.onTap});

  @override
  Widget build(BuildContext context) => ListTile(
        onTap: onTap,
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        title: Text(label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        trailing: trailing ??
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: AppColors.slate500),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      );
}
