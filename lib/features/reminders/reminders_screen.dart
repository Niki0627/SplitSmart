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

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: CustomScrollView(slivers: [
        SliverAppBar(
          pinned: true, backgroundColor: AppColors.backgroundDark, automaticallyImplyLeading: false,
          title: const Text('Notifications', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
          surfaceTintColor: Colors.transparent,
        ),
        remindersAsync.when(
          data: (reminders) {
            if (reminders.isEmpty) {
              return SliverFillRemaining(child: EmptyState(
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
                  Padding(padding: const EdgeInsets.only(bottom: 10), child: Text('NEW', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary, letterSpacing: 1.5))),
                  ...unread.map((r) => _ReminderCard(reminder: r, onTap: () => firebaseService.markReminderRead(r.id))),
                  const SizedBox(height: 16),
                ],
                if (read.isNotEmpty) ...[
                  Padding(padding: const EdgeInsets.only(bottom: 10), child: Text('EARLIER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.slate500, letterSpacing: 1.5))),
                  ...read.map((r) => _ReminderCard(reminder: r, onTap: null)),
                ],
              ])),
            );
          },
          loading: () => SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(delegate: SliverChildBuilderDelegate(
              (_, i) => Padding(padding: const EdgeInsets.only(bottom: 10), child: ShimmerBox(height: 70)),
              childCount: 4,
            )),
          ),
          error: (e, _) => SliverToBoxAdapter(child: Center(child: Text('Error: $e'))),
        ),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddReminderDialog(context, ref),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.backgroundDark,
        icon: const Icon(Icons.add_alarm_rounded),
        label: const Text('New Reminder', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  void _showAddReminderDialog(BuildContext context, WidgetRef ref) {
    final groups = ref.read(groupsProvider).value ?? [];
    String? selectedGroup;
    final msgCtrl = TextEditingController();
    DateTime dueDate = DateTime.now().add(const Duration(days: 3));

    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: const Color(0xFF1A2E2C),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.slate700, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          const Text('New Reminder', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          const Text('Group', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.slate300)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: selectedGroup,
            dropdownColor: const Color(0xFF1A2E2C),
            decoration: const InputDecoration(),
            hint: const Text('Select group'),
            items: groups.map((g) => DropdownMenuItem(value: g.id, child: Text(g.name))).toList(),
            onChanged: (v) => setS(() => selectedGroup = v),
          ),
          const SizedBox(height: 14),
          const Text('Message', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.slate300)),
          const SizedBox(height: 6),
          TextField(controller: msgCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: 'Pay by Friday!')),
          const SizedBox(height: 14),
          TextButton.icon(
            onPressed: () async {
              final d = await showDatePicker(context: ctx, initialDate: dueDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
              if (d != null) setS(() => dueDate = d);
            },
            icon: const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.primary),
            label: Text('Due: ${DateFormat('MMM d, yyyy').format(dueDate)}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, height: 50,
            child: ElevatedButton(
              onPressed: () async {
                final g = groups.firstWhere((g) => g.id == selectedGroup, orElse: () => groups[0]);
                await firebaseService.addReminder(
                  userId: firebaseService.currentUser!.uid, groupId: g.id,
                  groupName: g.name, message: msgCtrl.text.isNotEmpty ? msgCtrl.text : 'Payment due',
                  dueDate: dueDate,
                );
                Navigator.pop(ctx);
              },
              child: const Text('Set Reminder', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      )),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final reminder;
  final VoidCallback? onTap;
  const _ReminderCard({required this.reminder, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: reminder.isRead ? const Color(0xFF1A2E2C) : AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: reminder.isRead ? AppColors.primary.withValues(alpha: 0.08) : AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Row(children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(
            color: reminder.isRead ? AppColors.slate800 : AppColors.primary.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ), child: Icon(Icons.notifications_rounded, color: reminder.isRead ? AppColors.slate500 : AppColors.primary, size: 22)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(reminder.groupName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 2),
            Text(reminder.message, style: const TextStyle(color: AppColors.slate400, fontSize: 13)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(DateFormat('MMM d').format(reminder.dueDate), style: const TextStyle(color: AppColors.slate500, fontSize: 11, fontWeight: FontWeight.w700)),
            if (!reminder.isRead) Container(width: 8, height: 8, margin: const EdgeInsets.only(top: 6, right: 2), decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
          ]),
        ]),
      ),
    );
  }
}
