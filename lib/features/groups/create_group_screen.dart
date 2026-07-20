// lib/features/groups/create_group_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../core/firebase_service.dart';
import '../../shared/widgets.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});
  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _name = TextEditingController();
  final _emailCtrl = TextEditingController();
  String _selectedIcon = 'group';
  final List<String> _memberIds = [];
  final List<String> _memberNames = [];
  bool _loading = false;

  final _icons = ['group', 'flight', 'home', 'restaurant', 'movie', 'beach', 'sports', 'shopping'];
  final _iconData = {
    'group': Icons.group_rounded, 'flight': Icons.flight_rounded,
    'home': Icons.home_rounded, 'restaurant': Icons.restaurant_rounded,
    'movie': Icons.movie_rounded, 'beach': Icons.beach_access_rounded,
    'sports': Icons.sports_soccer_rounded, 'shopping': Icons.shopping_bag_rounded,
  };

  @override
  void dispose() { _name.dispose(); _emailCtrl.dispose(); super.dispose(); }

  Future<void> _addMember() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) return;
    setState(() => _loading = true);
    try {
      final user = await firebaseService.findUserByEmail(email);
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not found. Make sure they have a SplitSmart account.'), backgroundColor: AppColors.rose, behavior: SnackBarBehavior.floating));
        }
      } else if (_memberIds.contains(user.uid)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Already added'), backgroundColor: AppColors.amber, behavior: SnackBarBehavior.floating));
        }
      } else {
        setState(() { _memberIds.add(user.uid); _memberNames.add(user.name); });
        _emailCtrl.clear();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.rose));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _create() async {
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a group name'), backgroundColor: AppColors.rose, behavior: SnackBarBehavior.floating));
      return;
    }
    setState(() => _loading = true);
    try {
      final gid = await firebaseService.createGroup(_name.text.trim(), _selectedIcon, _memberIds);
      if (mounted) context.go('/groups/$gid');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.rose));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final onPrimaryColor = Theme.of(context).colorScheme.onPrimary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBorderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final inputColor = isDark ? Colors.white : AppColors.slate900;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: isDark ? Colors.white : AppColors.slate900), 
          onPressed: () => context.pop(),
        ),
        title: const Text('Create Group'),
      ),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        // Group Icon Picker
        const Text('Group Icon', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.slate500)),
        const SizedBox(height: 12),
        SizedBox(
          height: 70,
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
                  width: 60, height: 60,
                  decoration: BoxDecoration(
                    color: isSelected ? primaryColor.withValues(alpha: 0.15) : Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isSelected ? primaryColor : cardBorderColor, width: isSelected ? 2 : 1),
                  ),
                  child: Icon(_iconData[ic], color: isSelected ? primaryColor : AppColors.slate500, size: 26),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        // Group Name
        const Text('Group Name', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.slate500)),
        const SizedBox(height: 8),
        TextField(
          controller: _name,
          style: TextStyle(color: inputColor, fontWeight: FontWeight.w600, fontSize: 15),
          decoration: InputDecoration(
            hintText: 'e.g. Trip to Goa, Flatmates', 
            prefixIcon: const Icon(Icons.group_rounded, color: AppColors.slate500),
            fillColor: isDark ? AppColors.surfaceDark : AppColors.slate100.withValues(alpha: 0.5),
            filled: true,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: cardBorderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Add Members
        const Text('Add Members', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.slate500)),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              style: TextStyle(color: inputColor, fontSize: 15, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: 'Enter email address', 
                prefixIcon: const Icon(Icons.email_outlined, color: AppColors.slate500),
                fillColor: isDark ? AppColors.surfaceDark : AppColors.slate100.withValues(alpha: 0.5),
                filled: true,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: cardBorderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primaryColor, width: 2),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: _loading ? null : _addMember,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor, 
              foregroundColor: onPrimaryColor, 
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), 
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            ),
            child: _loading 
                ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: onPrimaryColor)) 
                : const Text('Add', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ]),
        // Member chips
        if (_memberNames.isNotEmpty) ...[
          const SizedBox(height: 16),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (int i = 0; i < _memberNames.length; i++)
              Chip(
                backgroundColor: primaryColor.withValues(alpha: 0.15),
                side: BorderSide(color: primaryColor.withValues(alpha: 0.3)),
                label: Text(_memberNames[i], style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600)),
                deleteIcon: Icon(Icons.close, size: 16, color: primaryColor),
                onDeleted: () => setState(() { _memberIds.removeAt(i); _memberNames.removeAt(i); }),
              ),
          ]),
        ],
        const SizedBox(height: 40),
        PrimaryButton(label: 'Create Group', icon: Icons.check_rounded, onPressed: _loading ? null : _create, loading: _loading),
        const SizedBox(height: 20),
        const Text('You will be automatically added to the group.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.slate500, fontSize: 12)),
      ]),
    );
  }
}
