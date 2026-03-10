// lib/features/groups/edit_group_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../core/firebase_service.dart';
import '../../core/models.dart';

class EditGroupScreen extends StatefulWidget {
  final String groupId;

  const EditGroupScreen({
    super.key,
    required this.groupId,
  });

  @override
  State<EditGroupScreen> createState() => _EditGroupScreenState();
}

class _EditGroupScreenState extends State<EditGroupScreen> {
  late final TextEditingController _nameCtrl;
  String _selectedIcon = 'group';
  bool _loading = false;
  bool _initialLoading = true;
  bool _membersLoading = true;
  List<AppUser> _members = [];
  List<String> _memberIds = [];
  String? _errorMsg;

  final _icons = ['group', 'flight', 'home', 'restaurant', 'movie', 'beach', 'sports', 'shopping'];
  final _iconData = {
    'group': Icons.group_rounded,
    'flight': Icons.flight_rounded,
    'home': Icons.home_rounded,
    'restaurant': Icons.restaurant_rounded,
    'movie': Icons.movie_rounded,
    'beach': Icons.beach_access_rounded,
    'sports': Icons.sports_soccer_rounded,
    'shopping': Icons.shopping_bag_rounded,
  };

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _loadGroup();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadGroup() async {
    try {
      final group = await firebaseService.getGroup(widget.groupId);
      if (!mounted) return;
      if (group == null) {
        setState(() { _initialLoading = false; _errorMsg = 'Group not found.'; });
        return;
      }
      _nameCtrl.text = group.name;
      _selectedIcon = group.icon;
      _memberIds = group.memberIds;
      setState(() => _initialLoading = false);
      _loadMembers(group.memberIds);
    } catch (e) {
      if (mounted) setState(() { _initialLoading = false; _errorMsg = 'Failed to load group: $e'; });
    }
  }

  Future<void> _loadMembers(List<String> ids) async {
    try {
      final members = await firebaseService.getGroupMembers(ids);
      if (mounted) setState(() { _members = members; _membersLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _membersLoading = false);
    }
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Group name cannot be empty'),
        backgroundColor: AppColors.rose,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    setState(() => _loading = true);
    try {
      await firebaseService.updateGroup(
        widget.groupId,
        name: _nameCtrl.text.trim(),
        icon: _selectedIcon,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Group updated!'),
          backgroundColor: AppColors.emerald,
          behavior: SnackBarBehavior.floating,
        ));
        context.pop();
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
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _removeMember(AppUser member) async {
    final self = firebaseService.currentUser;
    if (self?.uid == member.uid) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("You can't remove yourself from the group."),
        backgroundColor: AppColors.amber,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A2E2C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Remove ${member.name}?'),
        content: Text('${member.name} will be removed from this group.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.slate400)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.rose,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Remove', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await firebaseService.removeMemberFromGroup(widget.groupId, member.uid);
      if (mounted) {
        setState(() {
          _members.removeWhere((m) => m.uid == member.uid);
          _memberIds.removeWhere((id) => id == member.uid);
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${member.name} removed.'),
          backgroundColor: AppColors.emerald,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.rose,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  void _goToAddMember() {
    context.push('/groups/${widget.groupId}/add-member').then((_) {
      // Reload members after returning from add-member screen
      setState(() => _membersLoading = true);
      _loadGroup();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_initialLoading) {
      return Scaffold(
        backgroundColor: AppColors.backgroundDark,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundDark,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => context.pop(),
          ),
          title: const Text('Edit Group', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_errorMsg != null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundDark,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundDark,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => context.pop(),
          ),
          title: const Text('Edit Group', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
        body: Center(child: Text(_errorMsg!, style: const TextStyle(color: AppColors.rose))),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Edit Group', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  )
                : TextButton(
                    onPressed: _save,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Save',
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Group icon ─────────────────────────────────────────────────────
          const Text(
            'Group Icon',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.slate300),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _icons.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final ic = _icons[i];
                final isSelected = _selectedIcon == ic;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIcon = ic),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.2)
                          : const Color(0xFF1A2E2C),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.primary.withValues(alpha: 0.15),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Icon(
                      _iconData[ic],
                      color: isSelected ? AppColors.primary : AppColors.slate500,
                      size: 26,
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 26),

          // ── Group name ──────────────────────────────────────────────────────
          const Text(
            'Group Name',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.slate300),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameCtrl,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: 'Group name',
              prefixIcon: Icon(
                _iconData[_selectedIcon] ?? Icons.group_rounded,
                color: AppColors.primary,
              ),
            ),
          ),

          const SizedBox(height: 30),

          // ── Members ─────────────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Members (${_members.length})',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.slate300),
              ),
              // Add Member button
              GestureDetector(
                onTap: _goToAddMember,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person_add_rounded, size: 14, color: AppColors.primary),
                      SizedBox(width: 5),
                      Text(
                        'Add Member',
                        style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_membersLoading)
            const Center(child: CircularProgressIndicator(color: AppColors.primary))
          else if (_members.isEmpty)
            const Text('No members found', style: TextStyle(color: AppColors.slate400))
          else
            ...(_members.map((member) {
              final isMe = firebaseService.currentUser?.uid == member.uid;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2E2C),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
                ),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            isMe ? AppColors.primary : const Color(0xFF2C3E50),
                            isMe ? AppColors.primary.withValues(alpha: 0.6) : const Color(0xFF34495E),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          member.initials,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: isMe ? Colors.black87 : Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                member.name,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                              ),
                              if (isMe)
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'You',
                                    style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w700),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            member.email,
                            style: const TextStyle(color: AppColors.slate400, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    if (!isMe)
                      IconButton(
                        onPressed: () => _removeMember(member),
                        icon: const Icon(Icons.person_remove_rounded, color: AppColors.rose, size: 22),
                        tooltip: 'Remove member',
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.rose.withValues(alpha: 0.1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                  ],
                ),
              );
            })),

          const SizedBox(height: 40),

          // Delete group
          OutlinedButton.icon(
            onPressed: _showDeleteConfirm,
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.rose),
            label: const Text(
              'Delete Group',
              style: TextStyle(color: AppColors.rose, fontWeight: FontWeight.w700),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.rose),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  void _showDeleteConfirm() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A2E2C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Delete Group?'),
        content: const Text(
          'This will permanently delete the group and all its expenses. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.slate400)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await firebaseService.deleteGroup(widget.groupId);
              if (mounted) context.go('/home');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.rose,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
