// lib/features/groups/add_member_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/theme.dart';
import '../../core/firebase_service.dart';
import '../../core/models.dart';

class AddMemberScreen extends StatefulWidget {
  final String groupId;

  const AddMemberScreen({
    super.key,
    required this.groupId,
  });

  @override
  State<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends State<AddMemberScreen> {
  final _searchCtrl = TextEditingController();
  final _focusNode = FocusNode();

  AppUser? _foundUser;
  bool _searching = false;
  bool _adding = false;
  bool _loadingGroup = true;
  String _lastQuery = '';
  Timer? _debounce;
  List<String> _existingMemberIds = [];
  bool _searchByPhone = false; // toggle email vs phone mode

  // Members already staged for adding
  final List<AppUser> _pendingMembers = [];

  @override
  void initState() {
    super.initState();
    _loadExistingMembers();
    _searchCtrl.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadExistingMembers() async {
    try {
      final group = await firebaseService.getGroup(widget.groupId);
      if (mounted) {
        setState(() {
          _existingMemberIds = group?.memberIds ?? [];
          _loadingGroup = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingGroup = false);
    }
  }

  void _onSearchChanged() {
    final q = _searchCtrl.text.trim();
    _debounce?.cancel();
    // Reset result when query changes
    if (q != _lastQuery) {
      setState(() { _foundUser = null; });
    }
    if (q.length < 3) {
      setState(() { _searching = false; });
      return;
    }
    // Auto-search after debounce
    _debounce = Timer(const Duration(milliseconds: 800), () => _runSearch());
  }

  void _runSearch() {
    final q = _searchCtrl.text.trim();
    if (q == _lastQuery && _foundUser != null) return; // already have result
    if (q.length < 3) return;
    _lastQuery = q;
    setState(() { _searching = true; _foundUser = null; });
    _search(q);
  }

  Future<void> _search(String q) async {
    try {
      final user = await firebaseService.findUserByEmailOrPhone(q);
      if (!mounted) return;
      setState(() { _foundUser = user; _searching = false; });
    } catch (_) {
      if (mounted) setState(() { _searching = false; });
    }
  }

  void _stageUser(AppUser user) {
    final alreadyMember = _existingMemberIds.contains(user.uid);
    final alreadyPending = _pendingMembers.any((m) => m.uid == user.uid);
    final isCurrentUser = firebaseService.currentUser?.uid == user.uid;

    if (alreadyMember || alreadyPending || isCurrentUser) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isCurrentUser
              ? "That's you! You're already in this group."
              : alreadyMember
                  ? '${user.name} is already a member.'
                  : '${user.name} is already added.'),
          backgroundColor: AppColors.amber,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }
    setState(() {
      _pendingMembers.add(user);
      _foundUser = null;
      _searchCtrl.clear();
      _lastQuery = '';
    });
    _focusNode.requestFocus();
  }

  Future<void> _confirmAdd() async {
    if (_pendingMembers.isEmpty) return;
    setState(() => _adding = true);
    try {
      for (final member in _pendingMembers) {
        await firebaseService.addMemberToGroup(widget.groupId, member.uid);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_pendingMembers.length == 1
                ? '${_pendingMembers[0].name} added to group!'
                : '${_pendingMembers.length} members added!'),
            backgroundColor: AppColors.emerald,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.rose),
        );
      }
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  Future<void> _pickContact() async {
    final status = await Permission.contacts.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Contacts permission denied'),
          backgroundColor: AppColors.rose,
        ));
      }
      return;
    }

    try {
      final contact = await FlutterContacts.openExternalPick();
      if (contact == null) return;
      
      String pickedValue = '';
      if (_searchByPhone && contact.phones.isNotEmpty) {
        pickedValue = contact.phones.first.number;
      } else if (!_searchByPhone && contact.emails.isNotEmpty) {
        pickedValue = contact.emails.first.address;
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(_searchByPhone ? 'No phone number found' : 'No email found'),
            backgroundColor: AppColors.rose,
        ));
        }
        return;
      }

      setState(() {
        _searchCtrl.text = pickedValue;
      });
      _runSearch();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to pick contact: $e'),
          backgroundColor: AppColors.rose,
        ));
      }
    }
  }

  void _showInviteSheet(String query) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A2E2C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _InviteSheet(query: query),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Add Member',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          if (_pendingMembers.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _adding
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  : TextButton(
                      onPressed: _confirmAdd,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Add ${_pendingMembers.length}',
                          style: const TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
            ),
        ],
      ),
      body: _loadingGroup
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                // ── Mode toggle (Email / Phone) ───────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(children: [
                    _ModeTab(
                      label: 'Email',
                      icon: Icons.email_outlined,
                      selected: !_searchByPhone,
                      onTap: () {
                        setState(() { _searchByPhone = false; _foundUser = null; _searchCtrl.clear(); _lastQuery = ''; });
                        _focusNode.requestFocus();
                      },
                    ),
                    const SizedBox(width: 8),
                    _ModeTab(
                      label: 'Phone',
                      icon: Icons.phone_outlined,
                      selected: _searchByPhone,
                      onTap: () {
                        setState(() { _searchByPhone = true; _foundUser = null; _searchCtrl.clear(); _lastQuery = ''; });
                        _focusNode.requestFocus();
                      },
                    ),
                  ]),
                ),

                // ── Search bar ───────────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: Row(children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A2E2C),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                        ),
                        child: TextField(
                          controller: _searchCtrl,
                          focusNode: _focusNode,
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                          keyboardType: _searchByPhone
                              ? TextInputType.phone
                              : TextInputType.emailAddress,
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) => _runSearch(),
                          decoration: InputDecoration(
                            hintText: _searchByPhone
                                ? 'e.g. 9876543210 or +91...'
                                : 'e.g. friend@gmail.com',
                            hintStyle: const TextStyle(color: AppColors.slate500, fontSize: 15),
                            prefixIcon: _searching
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: SizedBox(
                                      width: 18, height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2, color: AppColors.primary,
                                      ),
                                    ),
                                  )
                                : Icon(
                                    _searchByPhone ? Icons.phone_rounded : Icons.email_rounded,
                                    color: AppColors.slate500,
                                  ),
                            suffixIcon: _searchCtrl.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.close_rounded, color: AppColors.slate500),
                                    onPressed: () {
                                      _searchCtrl.clear();
                                      setState(() { _foundUser = null; _searching = false; _lastQuery = ''; });
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Explicit Search button
                    GestureDetector(
                      onTap: _runSearch,
                      child: Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.search_rounded, color: Colors.black87, size: 22),
                      ),
                    ),
                  ]),
                ),

                // ── Import from contacts button ──────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _pickContact,
                      icon: const Icon(Icons.contacts_rounded, size: 16, color: AppColors.primary),
                      label: const Text(
                        'Import from Contacts',
                        style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // ── Pending members chips ───────────────────────────────────────────
                if (_pendingMembers.isNotEmpty)
                  Container(
                    height: 52,
                    color: AppColors.backgroundDark,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _pendingMembers.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final m = _pendingMembers[i];
                        return Chip(
                          backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
                          avatar: CircleAvatar(
                            backgroundColor: AppColors.primary,
                            radius: 11,
                            child: Text(
                              m.initials,
                              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.black87),
                            ),
                          ),
                          label: Text(
                            m.name,
                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          deleteIcon: const Icon(Icons.close_rounded, size: 15, color: AppColors.primary),
                          onDeleted: () => setState(() => _pendingMembers.removeAt(i)),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        );
                      },
                    ),
                  ),

                const Divider(height: 1, color: Color(0xFF1A2E2C)),

                // ── Results area ────────────────────────────────────────────────────
                Expanded(
                  child: _buildBody(),
                ),
              ],
            ),
    );
  }

  Widget _buildBody() {
    final query = _searchCtrl.text.trim();

    // Found user result
    if (_foundUser != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: _UserResultCard(
          user: _foundUser!,
          alreadyInGroup: _existingMemberIds.contains(_foundUser!.uid),
          alreadyPending: _pendingMembers.any((m) => m.uid == _foundUser!.uid),
          isCurrentUser: firebaseService.currentUser?.uid == _foundUser!.uid,
          onAdd: () => _stageUser(_foundUser!),
        ),
      );
    }

    // No result found for a long-enough query
    if (query.length >= 3 && !_searching) {
      return _NotFoundView(
        query: query,
        onInvite: () => _showInviteSheet(query),
      );
    }

    // Default: tips
    return _SearchTipsView();
  }
}

// ─── User result card ─────────────────────────────────────────────────────────

class _UserResultCard extends StatelessWidget {
  final AppUser user;
  final bool alreadyInGroup;
  final bool alreadyPending;
  final bool isCurrentUser;
  final VoidCallback onAdd;

  const _UserResultCard({
    required this.user,
    required this.alreadyInGroup,
    required this.alreadyPending,
    required this.isCurrentUser,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final blocked = alreadyInGroup || alreadyPending || isCurrentUser;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2E2C),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                user.initials,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  style: const TextStyle(color: AppColors.slate400, fontSize: 13),
                ),
                if (blocked)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      isCurrentUser
                          ? "That's you"
                          : alreadyInGroup
                              ? 'Already a member'
                              : 'Already added',
                      style: const TextStyle(color: AppColors.amber, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
          ),
          if (!blocked)
            GestureDetector(
              onTap: onAdd,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFF2DD4BF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Text(
                  'Add',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          if (blocked)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.slate700,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.check_rounded, size: 18, color: AppColors.slate400),
            ),
        ],
      ),
    );
  }
}

// ─── Not Found View ───────────────────────────────────────────────────────────

class _NotFoundView extends StatelessWidget {
  final String query;
  final VoidCallback onInvite;

  const _NotFoundView({required this.query, required this.onInvite});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.rose.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_search_rounded, size: 38, color: AppColors.rose),
          ),
          const SizedBox(height: 20),
          const Text(
            'No user found',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            '"$query" doesn\'t match any SplitSmart account.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.slate400, fontSize: 14),
          ),
          const SizedBox(height: 32),
          // Invite card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2E2C),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.send_rounded, color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Invite to SplitSmart',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                          SizedBox(height: 2),
                          Text(
                            "They'll get a link to download the app",
                            style: TextStyle(color: AppColors.slate400, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onInvite,
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: const Text(
                      'Send Invite',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Search Tips View ─────────────────────────────────────────────────────────

class _SearchTipsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.group_add_rounded, size: 38, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          const Text(
            'Find people on SplitSmart',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'Search using their registered email or phone number.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.slate400, fontSize: 14),
          ),
          const SizedBox(height: 32),
          // Tip cards
          _tipCard(
            icon: Icons.email_outlined,
            title: 'Search by Email',
            subtitle: 'e.g. friend@gmail.com',
          ),
          const SizedBox(height: 12),
          _tipCard(
            icon: Icons.phone_outlined,
            title: 'Search by Phone',
            subtitle: 'e.g. +91 98765 43210',
          ),
          const SizedBox(height: 12),
          _tipCard(
            icon: Icons.send_rounded,
            title: 'Not on SplitSmart yet?',
            subtitle: "Search their contact and we'll send an invite",
          ),
        ],
      ),
    );
  }

  Widget _tipCard({required IconData icon, required String title, required String subtitle}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2E2C),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(color: AppColors.slate400, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Invite Bottom Sheet ──────────────────────────────────────────────────────

class _InviteSheet extends StatelessWidget {
  final String query;
  const _InviteSheet({required this.query});

  @override
  Widget build(BuildContext context) {
    const appLink = 'https://splitsmart.app/invite';
    const message = 'Hey! I\'m using SplitSmart to split bills easily. Join me: $appLink';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.slate700,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 20),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Invite to SplitSmart',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Share a link with $query to join SplitSmart',
            style: const TextStyle(color: AppColors.slate400, fontSize: 14),
          ),
        ),
        const SizedBox(height: 24),
        // Share link tile
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.backgroundDark,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.link_rounded, color: AppColors.primary),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    appLink,
                    style: TextStyle(color: AppColors.slate300, fontSize: 13),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Clipboard.setData(const ClipboardData(text: appLink));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Link copied!'),
                        backgroundColor: AppColors.emerald,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                  ),
                  child: const Text(
                    'Copy',
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Send via message
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Clipboard.setData(const ClipboardData(text: message));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Invite message copied! Paste and send it.'),
                    backgroundColor: AppColors.emerald,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: const Text('Copy Invite Message', style: TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }
}

// ─── Mode Tab ─────────────────────────────────────────────────────────────────

class _ModeTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _ModeTab({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : const Color(0xFF1A2E2C),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: selected ? Colors.black87 : AppColors.slate400),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.black87 : AppColors.slate400,
            ),
          ),
        ]),
      ),
    );
  }
}
