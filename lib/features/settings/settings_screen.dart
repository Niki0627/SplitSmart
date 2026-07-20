// lib/features/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lucide_icons/lucide_icons.dart';
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
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textThemeColor = isDark ? Colors.white : AppColors.slate900;

    return Scaffold(
      body: CustomScrollView(slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: Colors.transparent,
          automaticallyImplyLeading: false,
          surfaceTintColor: Colors.transparent,
          title: Text(
            'Profile',
            style: TextStyle(
              fontSize: 20, 
              fontWeight: FontWeight.w800,
              color: textThemeColor,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Column(children: [
            // ── Profile hero card ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: GlassCard(
                padding: const EdgeInsets.all(20),
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
                            style: TextStyle(
                                fontSize: 20, 
                                fontWeight: FontWeight.w800,
                                color: textThemeColor,
                            )),
                        const SizedBox(height: 4),
                        Text(u?.email ?? '',
                            style: const TextStyle(
                                color: AppColors.slate500,
                                fontSize: 13,
                                letterSpacing: 0.2,
                                fontWeight: FontWeight.w500)),
                        if (u?.phone?.isNotEmpty == true) ...[
                          const SizedBox(height: 2),
                          Text(u!.phone!, style: const TextStyle(color: AppColors.slate500, fontSize: 13, letterSpacing: 0.2, fontWeight: FontWeight.w500)),
                        ],
                      ]),
                    ),
                    GestureDetector(
                      onTap: () => _showEditProfile(context, u),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: primaryColor.withValues(alpha: 0.3)),
                        ),
                        child: Icon(LucideIcons.edit3,
                            color: isDark ? AppColors.cyan : AppColors.primaryDark, size: 16),
                      ),
                    ),
                  ]),
                  loading: () => const ShimmerBox(height: 68),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Stats row ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                Expanded(
                  child: _StatCard(
                    icon: LucideIcons.users,
                    iconColor: primaryColor,
                    label: 'Groups',
                    value: groups.when(
                      data: (g) => '${g.length}',
                      loading: () => '—',
                      error: (_, __) => '0',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: LucideIcons.fileText,
                    iconColor: AppColors.blue,
                    label: 'Expenses',
                    value: allExpenses.when(
                      data: (e) => '${e.length}',
                      loading: () => '—',
                      error: (_, __) => '0',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: _StatCard(
                    icon: LucideIcons.checkCircle,
                    iconColor: AppColors.emerald,
                    label: 'Settled',
                    value: '0',
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 28),

            // ── Account section ────────────────────────────────────────────
            _buildSection(context, 'ACCOUNT', [
              _SettingsTile(
                icon: LucideIcons.user,
                label: 'Edit Profile',
                onTap: () {
                  _showEditProfile(context, user.value);
                },
              ),
              _SettingsTile(
                icon: LucideIcons.bell,
                label: 'Notification Preferences',
                onTap: () => context.go('/reminders'),
              ),
              _SettingsTile(
                icon: LucideIcons.shield,
                label: 'Privacy & Security',
                onTap: () {},
              ),
            ]),
            const SizedBox(height: 16),

            // ── Preferences section ────────────────────────────────────────
            _buildSection(context, 'PREFERENCES', [
              _SettingsTile(
                icon: LucideIcons.palette,
                label: 'Appearance',
                trailing: Text(
                  ref.watch(themeModeProvider) == ThemeMode.dark ? 'Dark' : 'Light',
                  style: TextStyle(
                      color: isDark ? AppColors.cyan : AppColors.primaryDark,
                      fontWeight: FontWeight.w800,
                      fontSize: 13),
                ),
                onTap: () {
                  final current = ref.read(themeModeProvider);
                  ref.read(themeModeProvider.notifier).state = 
                      current == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
                },
              ),
              _SettingsTile(
                icon: LucideIcons.globe,
                label: 'Currency',
                trailing: Text(
                  '${ref.watch(currencyProvider)} ${ref.watch(currencySymbolProvider)}',
                  style: TextStyle(
                    color: isDark ? AppColors.cyan : AppColors.primaryDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                onTap: () => context.push('/settings/currency'),
              ),
              _SettingsTile(
                icon: LucideIcons.barChart3,
                label: 'View Analytics',
                onTap: () => context.go('/analytics'),
              ),
            ]),
            const SizedBox(height: 16),

            // ── Support section ────────────────────────────────────────────
            _buildSection(context, 'SUPPORT', [
              _SettingsTile(
                  icon: LucideIcons.helpCircle,
                  label: 'Help & FAQ',
                  onTap: () => context.push('/settings/help')),
              _SettingsTile(
                  icon: LucideIcons.star,
                  label: 'Rate SplitSmart',
                  onTap: () => _showRatingDialog(context)),
              _SettingsTile(
                icon: LucideIcons.info,
                label: 'About',
                trailing: const Text('v1.0.0',
                    style: TextStyle(
                        color: AppColors.slate500, fontSize: 13, fontWeight: FontWeight.w700)),
                onTap: () => _showAboutBottomSheet(context),
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
                  icon: const Icon(LucideIcons.logOut,
                      size: 18, color: AppColors.rose),
                  label: const Text('Sign Out',
                      style: TextStyle(
                          color: AppColors.rose,
                          fontWeight: FontWeight.w800,
                          fontSize: 15)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: AppColors.rose.withValues(alpha: 0.4)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
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

  Widget _buildSection(BuildContext context, String title, List<Widget> tiles) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
        GlassCard(
          padding: EdgeInsets.zero,
          child: Column(children: [
            for (int i = 0; i < tiles.length; i++) ...[
              if (i > 0)
                Divider(
                    height: 1,
                    indent: 60,
                    endIndent: 20,
                    color: (isDark ? AppColors.borderDark : AppColors.borderLight).withValues(alpha: 0.25)),
              tiles[i],
            ],
          ]),
        ),
      ]),
    );
  }

  void _showRatingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        int selectedStars = 0;
        final commentController = TextEditingController();
        final primaryColor = Theme.of(context).colorScheme.primary;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final textThemeColor = isDark ? Colors.white : AppColors.slate900;
        final cardBorderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: cardBorderColor),
          ),
          title: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.star,
                  color: isDark ? AppColors.cyan : AppColors.primaryDark,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Rate SplitSmart',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textThemeColor),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'How has your experience been splitting bills with SplitSmart?',
                      style: TextStyle(color: AppColors.slate500, fontSize: 13, fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final starIndex = index + 1;
                        final isFilled = starIndex <= selectedStars;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedStars = starIndex;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: AnimatedScale(
                              scale: isFilled ? 1.15 : 1.0,
                              duration: const Duration(milliseconds: 150),
                              child: Icon(
                                LucideIcons.star,
                                color: isFilled ? AppColors.amber : AppColors.slate500,
                                size: 36,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    if (selectedStars > 0) ...[
                      const SizedBox(height: 20),
                      TextField(
                        controller: commentController,
                        maxLines: 3,
                        style: TextStyle(
                          fontSize: 14, 
                          color: textThemeColor,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          hintText: selectedStars >= 4
                              ? 'What do you love most? (Optional)'
                              : 'What can we improve?',
                          hintStyle: const TextStyle(color: AppColors.slate500, fontSize: 13),
                          fillColor: isDark
                              ? AppColors.backgroundDark
                              : AppColors.slate100.withValues(alpha: 0.5),
                          filled: true,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: cardBorderColor.withValues(alpha: 0.25)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: primaryColor, width: 1.5),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.slate500, fontWeight: FontWeight.w800),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedStars == 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select a star rating first!'),
                      backgroundColor: AppColors.rose,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
                
                Navigator.pop(context);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      selectedStars >= 4
                          ? 'Thank you for your rating! We appreciate your support.'
                          : 'Thank you for your feedback! We will review this to improve our app.',
                    ),
                    backgroundColor: AppColors.emerald,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text(
                'Submit',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAboutBottomSheet(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dividerColor = (isDark ? AppColors.borderDark : AppColors.borderLight).withValues(alpha: 0.25);
    final textThemeColor = isDark ? Colors.white : AppColors.slate900;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(top: BorderSide(color: dividerColor)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top drag indicator
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.slate500.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                // App Icon mockup
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryColor, primaryColor.withValues(alpha: 0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    LucideIcons.coins,
                    color: Colors.black,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'SplitSmart',
                  style: TextStyle(
                    fontSize: 22, 
                    fontWeight: FontWeight.w800, 
                    color: textThemeColor,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Simplifying Shared Expenses',
                  style: TextStyle(color: AppColors.slate500, fontSize: 13, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    'Version 1.0.0 (Build 1)',
                    style: TextStyle(color: isDark ? AppColors.cyan : AppColors.primaryDark, fontSize: 11, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'SplitSmart is a premium expense-sharing application built to make splitting bills and settling debts simple and hassle-free. Keep track of group outings, shared rents, travel budgets, and optimize tallies with our smart simplify-debts algorithms.',
                  style: TextStyle(
                    color: isDark ? AppColors.slate300 : AppColors.slate700, 
                    fontSize: 13, 
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Divider(color: dividerColor),
                const SizedBox(height: 8),
                // Links list
                ListTile(
                  leading: Icon(LucideIcons.globe, color: isDark ? AppColors.cyan : AppColors.primaryDark, size: 20),
                  title: const Text('Visit Website', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  trailing: const Icon(LucideIcons.chevronRight, size: 12, color: AppColors.slate500),
                  onTap: () async {
                    final Uri url = Uri.parse('https://splitsmart.app');
                    try {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Could not open website link')),
                        );
                      }
                    }
                  },
                ),
                ListTile(
                  leading: Icon(LucideIcons.shield, color: isDark ? AppColors.cyan : AppColors.primaryDark, size: 20),
                  title: const Text('Privacy Policy', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  trailing: const Icon(LucideIcons.chevronRight, size: 12, color: AppColors.slate500),
                  onTap: () async {
                    final Uri url = Uri.parse('https://splitsmart.app/privacy');
                    try {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Could not open privacy policy link')),
                        );
                      }
                    }
                  },
                ),
                ListTile(
                  leading: Icon(LucideIcons.fileText, color: isDark ? AppColors.cyan : AppColors.primaryDark, size: 20),
                  title: const Text('Terms of Service', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  trailing: const Icon(LucideIcons.chevronRight, size: 12, color: AppColors.slate500),
                  onTap: () async {
                    final Uri url = Uri.parse('https://splitsmart.app/terms');
                    try {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Could not open terms link')),
                        );
                      }
                    }
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Made with love by Google DeepMind team',
                  style: TextStyle(color: AppColors.slate500, fontSize: 11, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
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
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dividerColor = (isDark ? AppColors.borderDark : AppColors.borderLight).withValues(alpha: 0.25);
    final textThemeColor = isDark ? Colors.white : AppColors.slate900;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: dividerColor)),
      ),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.slate500.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Edit Profile',
            style: TextStyle(
              fontSize: 18, 
              fontWeight: FontWeight.w800,
              color: textThemeColor,
            ),
          ),
          const SizedBox(height: 6),
          const Text('Update your name or phone number',
              style: TextStyle(color: AppColors.slate500, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 24),

          // Email (read-only)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? Colors.black.withValues(alpha: 0.15) : AppColors.slate100.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: dividerColor),
            ),
            child: Row(children: [
              const Icon(LucideIcons.mail, color: AppColors.slate500, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(widget.user.email,
                    style: const TextStyle(
                        color: AppColors.slate500, fontSize: 14, fontWeight: FontWeight.w600)),
              ),
              const Text('Fixed',
                  style: TextStyle(
                      color: AppColors.slate500,
                      fontSize: 11,
                      fontWeight: FontWeight.w800)),
            ]),
          ),
          const SizedBox(height: 12),

          // Name field
          TextField(
            controller: _nameCtrl,
            style: TextStyle(
              color: textThemeColor, 
              fontWeight: FontWeight.w600, 
              fontSize: 15,
            ),
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: 'Your full name',
              prefixIcon: Icon(LucideIcons.user,
                  color: isDark ? AppColors.cyan : AppColors.primaryDark, size: 20),
              labelText: 'Display Name',
              labelStyle:
                  const TextStyle(color: AppColors.slate500, fontSize: 13, fontWeight: FontWeight.w600),
              fillColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: dividerColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: primaryColor, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Phone field
          TextField(
            controller: _phoneCtrl,
            style: TextStyle(
              color: textThemeColor, 
              fontWeight: FontWeight.w600, 
              fontSize: 15,
            ),
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: '+91 98765 43210',
              prefixIcon: Icon(LucideIcons.phone,
                  color: isDark ? AppColors.cyan : AppColors.primaryDark, size: 20),
              labelText: 'Phone (for search)',
              labelStyle:
                  const TextStyle(color: AppColors.slate500, fontSize: 13, fontWeight: FontWeight.w600),
              fillColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: dividerColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: primaryColor, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // UPI ID field
          TextField(
            controller: _upiCtrl,
            style: TextStyle(
              color: textThemeColor, 
              fontWeight: FontWeight.w600, 
              fontSize: 15,
            ),
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: 'john@upi',
              prefixIcon: Icon(LucideIcons.coins,
                  color: isDark ? AppColors.cyan : AppColors.primaryDark, size: 20),
              labelText: 'UPI ID (Optional)',
              labelStyle:
                  const TextStyle(color: AppColors.slate500, fontSize: 13, fontWeight: FontWeight.w600),
              fillColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: dividerColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: primaryColor, width: 2),
              ),
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
                backgroundColor: primaryColor,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.black))
                  : const Text('Save Changes',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 15)),
            ),
          ),
        ]),
      ),
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
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: iconColor.withValues(alpha: 0.25)),
      ),
      child: Column(children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 22, 
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : AppColors.slate900,
          ),
        ),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(fontSize: 11, color: AppColors.slate500, fontWeight: FontWeight.w600)),
      ]),
    );
  }
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
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, color: isDark ? AppColors.cyan : AppColors.primaryDark, size: 18),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w700, 
          fontSize: 14,
          color: isDark ? Colors.white : AppColors.slate800,
        ),
      ),
      trailing: trailing ??
          const Icon(LucideIcons.chevronRight,
              size: 14, color: AppColors.slate500),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }
}
