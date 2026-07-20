// lib/features/settings/currency_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/providers.dart';
import '../../core/firebase_service.dart';

class CurrencySettingsScreen extends ConsumerStatefulWidget {
  const CurrencySettingsScreen({super.key});

  @override
  ConsumerState<CurrencySettingsScreen> createState() => _CurrencySettingsScreenState();
}

class _CurrencySettingsScreenState extends ConsumerState<CurrencySettingsScreen> {
  bool _saving = false;

  final List<Map<String, String>> _currencies = [
    {'code': 'INR', 'symbol': '₹', 'name': 'Indian Rupee'},
    {'code': 'USD', 'symbol': r'$', 'name': 'US Dollar'},
    {'code': 'EUR', 'symbol': '€', 'name': 'Euro'},
    {'code': 'GBP', 'symbol': '£', 'name': 'British Pound'},
  ];

  Future<void> _selectCurrency(String code) async {
    final uid = firebaseService.currentUser?.uid;
    if (uid == null) return;

    setState(() => _saving = true);
    try {
      await firebaseService.updateUserProfile(
        uid: uid,
        currency: code,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Currency updated to $code!'),
            backgroundColor: AppColors.emerald,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update currency: $e'),
            backgroundColor: AppColors.rose,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeCurrency = ref.watch(currencyProvider);
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dividerColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Currency Settings',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Choose Default Currency',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.slate900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Select the preferred currency symbol to format and display all expense amounts across groups and tallies.',
                style: TextStyle(
                  color: AppColors.slate500,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _currencies.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: dividerColor,
                    indent: 72,
                    endIndent: 20,
                  ),
                  itemBuilder: (context, index) {
                    final curr = _currencies[index];
                    final code = curr['code']!;
                    final symbol = curr['symbol']!;
                    final name = curr['name']!;
                    final isSelected = activeCurrency == code;

                    return InkWell(
                      onTap: _saving ? null : () => _selectCurrency(code),
                      borderRadius: BorderRadius.vertical(
                        top: index == 0 ? const Radius.circular(20) : Radius.zero,
                        bottom: index == _currencies.length - 1
                            ? const Radius.circular(20)
                            : Radius.zero,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        child: Row(
                          children: [
                            // Symbol container
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? primaryColor.withValues(alpha: 0.15)
                                    : (isDark ? AppColors.slate800 : AppColors.slate100),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? primaryColor.withValues(alpha: 0.3)
                                      : Colors.transparent,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  symbol,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: isSelected ? primaryColor : AppColors.slate500,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            // Name & Code
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: isDark ? Colors.white : AppColors.slate900,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    code,
                                    style: const TextStyle(
                                      color: AppColors.slate500,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Selection Indicator
                            AnimatedScale(
                              scale: isSelected ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 150),
                              curve: Curves.easeOutBack,
                              child: Icon(
                                Icons.check_circle_rounded,
                                color: primaryColor,
                                size: 24,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              // Hint Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Updating the default currency is a profile preference and will automatically sync. When linking a UPI ID, payments will still be processed in Indian Rupees (INR) as UPI is limited to India.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.slate500,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_saving)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
