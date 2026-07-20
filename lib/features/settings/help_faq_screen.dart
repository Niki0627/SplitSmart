// lib/features/settings/help_faq_screen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme.dart';
import '../../shared/widgets.dart';

class HelpFaqScreen extends StatefulWidget {
  const HelpFaqScreen({super.key});

  @override
  State<HelpFaqScreen> createState() => _HelpFaqScreenState();
}

class _HelpFaqScreenState extends State<HelpFaqScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedCategory = 'All';
  String _searchQuery = '';

  final List<Map<String, String>> _faqs = [
    {
      'question': 'What is SplitSmart?',
      'answer': 'SplitSmart is a smart expense-sharing app designed to help you track group expenses, calculate tallies, and settle debts easily with friends, family, or housemates without any hassle.',
      'category': 'General'
    },
    {
      'question': 'How do I create a new group?',
      'answer': 'Navigate to the home dashboard and tap the "+" button or "Create Group" button. Choose an appropriate category (e.g. Flight, Home, Restaurant), enter a group name, and select members to add to the group.',
      'category': 'Groups'
    },
    {
      'question': 'Can I add members who don\'t have a SplitSmart account?',
      'answer': 'Yes, absolutely! You can add custom members to your group by typing their names. They will be registered as group members and you can allocate expenses to them. They can link their actual email or phone account later to claim their profile and view the details.',
      'category': 'Groups'
    },
    {
      'question': 'How do I add a new expense?',
      'answer': 'Open your group, tap the "+" button or "Add Expense" at the bottom of the screen. Enter the description (e.g., "Dinner"), the total amount, choose who paid, and select how the amount should be split among the group members.',
      'category': 'Expenses'
    },
    {
      'question': 'What split types are supported in SplitSmart?',
      'answer': 'We support multiple flexible split types:\n• Equal: Divides the expense evenly among all selected participants.\n• Unequal: Allows you to specify exact monetary amounts for each member.\n• Percentage: Splits the total amount by custom percentages (total must equal 100%).\n• Shares: Distributes the expense based on shares or ratios (e.g., 2 shares for Alice, 1 share for Bob).',
      'category': 'Expenses'
    },
    {
      'question': 'How does the "Settle Up" feature work?',
      'answer': 'When you are ready to pay back a debt, open the group and tap "Settle Up". Select who is paying and who is receiving the payment, enter the amount, and select the payment method (like Cash or UPI). Saving the settlement will instantly update everyone\'s balances.',
      'category': 'Settlement'
    },
    {
      'question': 'What is "Calculate Tally" or Simplify Debts?',
      'answer': 'SplitSmart contains an advanced optimization algorithm that automatically simplifies debts. Instead of multiple back-and-forth payments, it calculates the minimum number of transactions needed to settle all debts in the group, saving everyone time and bank transfer fees.',
      'category': 'Settlement'
    },
    {
      'question': 'Can I edit or delete an expense after adding it?',
      'answer': 'Yes. In the group details page, scroll to the "Expenses History" list. Press and hold on the expense you wish to modify or remove. Select "Edit" to adjust values or "Delete" to remove it. All balances will automatically recalculate in real-time.',
      'category': 'Expenses'
    },
    {
      'question': 'How do I link my UPI ID for easier settlements?',
      'answer': 'Go to the Profile tab, tap "Edit Profile" or the pencil icon next to your name, and enter your UPI ID in the designated field. When other members tap "Settle Up" to pay you, your UPI ID will be visible, making direct mobile payments extremely simple.',
      'category': 'Settlement'
    },
    {
      'question': 'Is my data synced across devices?',
      'answer': 'Yes, all your data is securely synchronized in real-time using Firebase. As long as you log in with the same account credentials (Google, email/phone), your groups, expenses, and transaction history will be available on any device.',
      'category': 'General'
    },
    {
      'question': 'How do notifications work in SplitSmart?',
      'answer': 'You can customize your alerts under Profile -> Notification Preferences. You will receive notifications when someone adds you to a group, logs an expense you are split in, or registers a payment to you.',
      'category': 'General'
    },
  ];

  final List<String> _categories = ['All', 'General', 'Groups', 'Expenses', 'Settlement'];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@splitsmart.app',
      queryParameters: {
        'subject': 'SplitSmart Support Request',
      },
    );
    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri);
      } else {
        throw 'Could not launch email client';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not open email app. Please email support@splitsmart.app directly.'),
            backgroundColor: AppColors.rose,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _launchWebsite() async {
    final Uri url = Uri.parse('https://splitsmart.app');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not launch website link.'),
            backgroundColor: AppColors.rose,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter FAQs based on category and search query
    final filteredFaqs = _faqs.where((faq) {
      final matchesCategory = _selectedCategory == 'All' || faq['category'] == _selectedCategory;
      final query = _searchQuery.toLowerCase();
      final matchesSearch = query.isEmpty ||
          faq['question']!.toLowerCase().contains(query) ||
          faq['answer']!.toLowerCase().contains(query);
      return matchesCategory && matchesSearch;
    }).toList();

    final primaryColor = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dividerColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Help & FAQ',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // ── Search & Header Section ─────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primaryColor.withValues(alpha: 0.1),
                  Colors.transparent,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How can we help you?',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.slate900,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchCtrl,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.slate900, 
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search questions, keywords...',
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: primaryColor,
                      size: 22,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, color: AppColors.slate400, size: 20),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    fillColor: Theme.of(context).colorScheme.surface,
                    filled: true,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: primaryColor, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Categories Tabs/Chips ──────────────────────────────────────
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    selectedColor: primaryColor,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : (isDark ? Colors.white70 : AppColors.slate700),
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected 
                            ? primaryColor 
                            : (isDark ? AppColors.borderDark : AppColors.borderLight),
                        width: 1,
                      ),
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedCategory = category;
                        });
                      }
                    },
                    showCheckmark: false,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // ── FAQ Accordion List ──────────────────────────────────────────
          Expanded(
            child: filteredFaqs.isEmpty
                ? SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 40.0),
                      child: EmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'No FAQ Found',
                        subtitle: 'No results match your search keywords or filter category. Try another query!',
                        actionLabel: 'Reset Filters',
                        onAction: () {
                          _searchCtrl.clear();
                          setState(() {
                            _searchQuery = '';
                            _selectedCategory = 'All';
                          });
                        },
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: filteredFaqs.length,
                    itemBuilder: (context, index) {
                      final faq = filteredFaqs[index];
                      return FaqCard(
                        question: faq['question']!,
                        answer: faq['answer']!,
                      );
                    },
                  ),
          ),

          // ── Still Have Questions? Card ──────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
              gradient: LinearGradient(
                colors: [
                  primaryColor.withValues(alpha: 0.05),
                  Colors.transparent,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.support_agent_rounded, color: primaryColor, size: 24),
                    const SizedBox(width: 10),
                    Text(
                      'Still have questions?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppColors.slate900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Can\'t find what you are looking for? Contact our customer support team. We are available to help you.',
                  style: TextStyle(
                    color: AppColors.slate500,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _launchEmail,
                        icon: Icon(Icons.email_outlined, size: 16, color: primaryColor),
                        label: Text(
                          'Email Support',
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: primaryColor.withValues(alpha: 0.3)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _launchWebsite,
                        icon: const Icon(Icons.open_in_new_rounded, size: 16, color: Colors.white),
                        label: const Text(
                          'Visit Website',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Custom FAQ Accordion Card ────────────────────────────────────────────────
class FaqCard extends StatefulWidget {
  final String question;
  final String answer;

  const FaqCard({super.key, required this.question, required this.answer});

  @override
  State<FaqCard> createState() => _FaqCardState();
}

class _FaqCardState extends State<FaqCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isExpanded 
              ? primaryColor.withValues(alpha: 0.3) 
              : (isDark ? AppColors.borderDark : AppColors.borderLight),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _isExpanded = !_isExpanded;
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      widget.question,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _isExpanded ? primaryColor : (isDark ? Colors.white : AppColors.slate800),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.25 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: _isExpanded ? primaryColor : AppColors.slate500,
                    ),
                  ),
                ],
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                child: _isExpanded
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          Divider(
                            color: isDark ? AppColors.borderDark : AppColors.borderLight, 
                            height: 1,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.answer,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              color: isDark ? AppColors.slate300 : AppColors.slate700,
                            ),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
