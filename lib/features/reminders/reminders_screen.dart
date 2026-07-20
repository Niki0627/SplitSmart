// lib/features/reminders/reminders_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../core/providers.dart';
import '../../core/firebase_service.dart';
import '../../shared/widgets.dart';

class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remindersAsync = ref.watch(remindersProvider);
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(slivers: [
        SliverAppBar(
          pinned: true, 
          backgroundColor: Theme.of(context).scaffoldBackgroundColor, 
          automaticallyImplyLeading: false,
          title: Text(
            'Notifications', 
            style: TextStyle(
              fontSize: 19, 
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.slate900,
            ),
          ),
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: isDark ? Colors.white : AppColors.slate900),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        remindersAsync.when(
          data: (reminders) {
            if (reminders.isEmpty) {
              return const SliverFillRemaining(child: EmptyState(
                icon: Icons.notifications_outlined,
                title: 'No notifications',
                subtitle: 'Payment reminders and alerts will appear here',
              ));
            }
            final unread = reminders.where((r) => !r.isRead).toList();
            final read = reminders.where((r) => r.isRead).toList();
            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              sliver: SliverList(delegate: SliverChildListDelegate([
                if (unread.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10), 
                    child: Text(
                      'NEW', 
                      style: TextStyle(
                        fontSize: 11, 
                        fontWeight: FontWeight.w700, 
                        color: primaryColor, 
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  ...unread.map((r) => _ReminderCard(reminder: r, onTap: () => firebaseService.markReminderRead(r.id))),
                  const SizedBox(height: 16),
                ],
                if (read.isNotEmpty) ...[
                  const Padding(
                    padding: const EdgeInsets.only(bottom: 10), 
                    child: Text(
                      'EARLIER', 
                      style: TextStyle(
                        fontSize: 11, 
                        fontWeight: FontWeight.w700, 
                        color: AppColors.slate500, 
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  ...read.map((r) => _ReminderCard(reminder: r, onTap: null)),
                ],
              ])),
            );
          },
          loading: () => SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(delegate: SliverChildBuilderDelegate(
              (_, i) => const Padding(padding: EdgeInsets.only(bottom: 10), child: ShimmerBox(height: 70)),
              childCount: 4,
            )),
          ),
          error: (e, _) => SliverToBoxAdapter(child: Center(child: Text('Error: $e'))),
        ),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddReminderDialog(context, ref),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_alarm_rounded, color: Colors.white),
        label: const Text('New Reminder', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  void _showAddReminderDialog(BuildContext context, WidgetRef ref) {
    final groups = ref.read(groupsProvider).value ?? [];
    String? selectedGroup;
    final msgCtrl = TextEditingController();
    DateTime dueDate = DateTime.now().add(const Duration(days: 3));
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dropdownColor = Theme.of(context).colorScheme.surface;

    showModalBottomSheet(
      context: context, 
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(
            child: Container(
              width: 36, 
              height: 4, 
              decoration: BoxDecoration(
                color: AppColors.slate500.withValues(alpha: 0.3), 
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'New Reminder', 
            style: TextStyle(
              fontSize: 18, 
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.slate900,
            ),
          ),
          const SizedBox(height: 16),
          const Text('Group', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.slate500)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: selectedGroup,
            dropdownColor: dropdownColor,
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.slate900,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              fillColor: isDark ? AppColors.surfaceDark : AppColors.slate100.withValues(alpha: 0.5),
              filled: true,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: primaryColor, width: 1.5),
              ),
            ),
            hint: const Text('Select group', style: TextStyle(color: AppColors.slate500)),
            items: groups.map((g) => DropdownMenuItem(value: g.id, child: Text(g.name))).toList(),
            onChanged: (v) => setS(() => selectedGroup = v),
          ),
          const SizedBox(height: 14),
          const Text('Message', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.slate500)),
          const SizedBox(height: 6),
          TextField(
            controller: msgCtrl, 
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.slate900,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ), 
            decoration: InputDecoration(
              hintText: 'Pay by Friday!',
              fillColor: isDark ? AppColors.surfaceDark : AppColors.slate100.withValues(alpha: 0.5),
              filled: true,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: primaryColor, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextButton.icon(
            onPressed: () async {
              final d = await showDatePicker(
                context: ctx, 
                initialDate: dueDate, 
                firstDate: DateTime.now(), 
                lastDate: DateTime.now().add(const Duration(days: 365)),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: Theme.of(context).colorScheme.copyWith(
                        primary: primaryColor,
                        onPrimary: Colors.white,
                        surface: Theme.of(context).colorScheme.surface,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (d != null) setS(() => dueDate = d);
            },
            icon: Icon(Icons.calendar_today_rounded, size: 16, color: primaryColor),
            label: Text('Due: ${DateFormat('MMM d, yyyy').format(dueDate)}', style: TextStyle(color: primaryColor, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, height: 50,
            child: ElevatedButton(
              onPressed: () async {
                if (selectedGroup == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a group')),
                  );
                  return;
                }
                final g = groups.firstWhere((g) => g.id == selectedGroup, orElse: () => groups[0]);
                await firebaseService.addReminder(
                  userId: firebaseService.currentUser!.uid, groupId: g.id,
                  groupName: g.name, message: msgCtrl.text.isNotEmpty ? msgCtrl.text : 'Payment due',
                  dueDate: dueDate,
                );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Set Reminder', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            ),
          ),
        ]),
      )),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final dynamic reminder;
  final VoidCallback? onTap;
  const _ReminderCard({required this.reminder, this.onTap});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dividerColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    
    final cardBg = reminder.isRead 
        ? Theme.of(context).colorScheme.surface
        : primaryColor.withValues(alpha: 0.08);
        
    final cardBorder = reminder.isRead 
        ? dividerColor 
        : primaryColor.withValues(alpha: 0.3);
        
    final iconBg = reminder.isRead 
        ? (isDark ? AppColors.slate800 : AppColors.slate100) 
        : primaryColor.withValues(alpha: 0.2);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cardBorder),
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44, 
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ), 
            child: Icon(Icons.notifications_rounded, color: reminder.isRead ? AppColors.slate500 : primaryColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              reminder.groupName, 
              style: TextStyle(
                fontWeight: FontWeight.w700, 
                fontSize: 13,
                color: isDark ? Colors.white : AppColors.slate900,
              ),
            ),
            const SizedBox(height: 2),
            Text(reminder.message, style: const TextStyle(color: AppColors.slate500, fontSize: 13)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(DateFormat('MMM d').format(reminder.dueDate), style: const TextStyle(color: AppColors.slate500, fontSize: 11, fontWeight: FontWeight.w700)),
            if (!reminder.isRead) Container(width: 8, height: 8, margin: const EdgeInsets.only(top: 6, right: 2), decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle)),
          ]),
        ]),
      ),
    );
  }
}
