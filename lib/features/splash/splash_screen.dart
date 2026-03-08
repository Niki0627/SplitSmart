// lib/features/splash/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _progress;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _progress = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    _fadeIn = CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.5, curve: Curves.easeIn));
    _ctrl.forward();
    Timer(const Duration(milliseconds: 2500), () {
      if (mounted) context.go('/auth');
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1121),
      body: Stack(
        children: [
          // Glow blobs
          Positioned(bottom: -80, left: -80,
            child: Container(width: 320, height: 320,
              decoration: BoxDecoration(shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.05),
                boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.08), blurRadius: 120, spreadRadius: 60)])),
          ),
          Positioned(bottom: -80, right: -80,
            child: Container(width: 320, height: 320,
              decoration: BoxDecoration(shape: BoxShape.circle,
                color: AppColors.blue.withValues(alpha: 0.05),
                boxShadow: [BoxShadow(color: AppColors.blue.withValues(alpha: 0.08), blurRadius: 120, spreadRadius: 60)])),
          ),
          // Main content
          Center(
            child: FadeTransition(
              opacity: _fadeIn,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                // Logo
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 96, height: 96,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 30, spreadRadius: 5)],
                      ),
                      child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 52),
                    ),
                    Positioned(
                      top: -8, right: -8,
                      child: Container(
                        width: 30, height: 30,
                        decoration: BoxDecoration(
                          color: Colors.white, shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 2),
                        ),
                        child: const Icon(Icons.call_split, color: AppColors.primary, size: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                // Title
                RichText(
                  text: const TextSpan(
                    style: TextStyle(fontSize: 44, fontWeight: FontWeight.w800, letterSpacing: -1.5),
                    children: [
                      TextSpan(text: 'Split', style: TextStyle(color: AppColors.primary)),
                      TextSpan(text: 'Smart', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                const Text('Split Smart. Settle Easy.', style: TextStyle(color: AppColors.slate400, fontSize: 15, fontWeight: FontWeight.w500, letterSpacing: 0.3)),
                const SizedBox(height: 64),
                // Loading bar
                AnimatedBuilder(
                  animation: _progress,
                  builder: (_, __) => Column(children: [
                    SizedBox(
                      width: 180,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: _progress.value,
                          backgroundColor: AppColors.slate800,
                          valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text('INITIALIZING...', style: TextStyle(color: AppColors.slate600, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2)),
                  ]),
                ),
              ]),
            ),
          ),
          // Footer
          Positioned(
            bottom: 32, left: 0, right: 0,
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
              Icon(Icons.verified_user_rounded, color: AppColors.slate700, size: 14),
              SizedBox(width: 6),
              Text('SECURE PAYMENTS', style: TextStyle(color: AppColors.slate700, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 2)),
            ]),
          ),
        ],
      ),
    );
  }
}
