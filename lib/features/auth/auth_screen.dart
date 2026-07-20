// lib/features/auth/auth_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme.dart';
import '../../core/firebase_service.dart';
import '../../shared/widgets.dart';
import '../../shared/shooting_stars_grid.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  bool _isLogin = true;
  bool _loading = false;
  bool _googleLoading = false;
  bool _obscure = true;
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _form = GlobalKey<FormState>();
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _email.dispose();
    _password.dispose();
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(LucideIcons.alertTriangle, color: isDark ? Colors.black : Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: TextStyle(color: isDark ? Colors.black : Colors.white))),
          ],
        ),
        backgroundColor: isDark ? Colors.white : Colors.black,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(LucideIcons.checkCircle,
                color: isDark ? Colors.black : Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: TextStyle(color: isDark ? Colors.black : Colors.white))),
          ],
        ),
        backgroundColor: isDark ? Colors.white : Colors.black,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      if (_isLogin) {
        await firebaseService.signInWithEmail(
          _email.text.trim(),
          _password.text,
        );
      } else {
        await firebaseService.signUpWithEmail(
          _email.text.trim(),
          _password.text,
          _name.text.trim(),
          phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        );
      }
      if (mounted) context.go('/home');
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _googleSignIn() async {
    setState(() => _googleLoading = true);
    try {
      final cred = await firebaseService.signInWithGoogle();
      if (cred != null && mounted) {
        context.go('/home');
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  Future<void> _showForgotPasswordDialog() async {
    final emailCtrl = TextEditingController(text: _email.text);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBorderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textThemeColor = isDark ? Colors.white : AppColors.slate900;

    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: cardBorderColor),
        ),
        title: Row(
          children: [
            Icon(LucideIcons.key, color: isDark ? Colors.white : Colors.black),
            const SizedBox(width: 10),
            const Text('Reset Password',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter your email to receive a password reset link.',
              style: TextStyle(color: isDark ? AppColors.slate300 : AppColors.slate600, fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              autofocus: true,
              style: TextStyle(color: textThemeColor, fontWeight: FontWeight.w600),
              decoration: const InputDecoration(
                hintText: 'hello@example.com',
                prefixIcon:
                    Icon(LucideIcons.mail, color: AppColors.slate500),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.slate400, fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final email = emailCtrl.text.trim();
              if (email.isEmpty) return;
              Navigator.pop(ctx);
              try {
                await firebaseService.sendPasswordReset(email);
                _showSuccess('Password reset email sent! Check your inbox.');
              } catch (e) {
                _showError(e.toString());
              }
            },
            child: const Text('Send',
                style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textThemeColor = isDark ? Colors.white : AppColors.slate900;
    
    return Scaffold(
      body: ShootingStarsGrid(
        padding: EdgeInsets.zero,
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 440),
                child: GlassCard(
                  borderRadius: 32,
                  padding: const EdgeInsets.all(28),
                  child: Form(
                    key: _form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Logo header
                        Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primary,
                                    AppColors.primary
                                        .withValues(alpha: 0.7),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                LucideIcons.coins,
                                color: Colors.black,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'SplitSmart',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 19,
                                letterSpacing: -0.3,
                                color: textThemeColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                        Text(
                          _isLogin ? 'Welcome back' : 'Create account',
                          style: TextStyle(
                            fontSize: 27,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: textThemeColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _isLogin
                              ? 'Sign in to continue splitting bills easily'
                              : 'Start splitting bills with your friends',
                          style: const TextStyle(
                            color: AppColors.slate500,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Google Sign-In button
                        _GoogleSignInButton(
                          loading: _googleLoading,
                          onTap: _googleSignIn,
                        ),

                        const SizedBox(height: 22),
                        const _DividerRow(),
                        const SizedBox(height: 22),

                        // Full Name (sign-up only)
                        if (!_isLogin) ...[
                          const _FieldLabel('Full Name'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _name,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              hintText: 'Arjun Sharma',
                              prefixIcon: Icon(
                                LucideIcons.user,
                                color: AppColors.slate500,
                              ),
                            ),
                            validator: (v) =>
                                (!_isLogin && (v?.isEmpty ?? true))
                                    ? 'Please enter your name'
                                    : null,
                            style: TextStyle(color: textThemeColor, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 16),
                          const _FieldLabel('Phone Number (Optional)'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _phone,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              hintText: '+91 9876543210',
                              prefixIcon: Icon(
                                LucideIcons.phone,
                                color: AppColors.slate500,
                              ),
                            ),
                            style: TextStyle(color: textThemeColor, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 16),
                        ],

                        const _FieldLabel('Email Address'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          decoration: const InputDecoration(
                            hintText: 'hello@example.com',
                            prefixIcon: Icon(
                              LucideIcons.mail,
                              color: AppColors.slate500,
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Email is required';
                            }
                            if (!v.contains('@') || !v.contains('.')) {
                              return 'Enter a valid email address';
                            }
                            return null;
                          },
                          style: TextStyle(color: textThemeColor, fontWeight: FontWeight.w600),
                        ),

                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const _FieldLabel('Password'),
                            if (_isLogin)
                              TextButton(
                                onPressed: _showForgotPasswordDialog,
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'Forgot password?',
                                  style: TextStyle(
                                    color: isDark ? Colors.white : Colors.black,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _password,
                          obscureText: _obscure,
                          autofillHints: _isLogin
                              ? const [AutofillHints.password]
                              : const [AutofillHints.newPassword],
                          decoration: InputDecoration(
                            hintText: '••••••••',
                            prefixIcon: const Icon(
                              LucideIcons.lock,
                              color: AppColors.slate500,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscure
                                    ? LucideIcons.eye
                                    : LucideIcons.eyeOff,
                                color: AppColors.slate500,
                              ),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                          style: TextStyle(color: textThemeColor, fontWeight: FontWeight.w600),
                        ),

                        const SizedBox(height: 26),
                        PrimaryButton(
                          label: _isLogin ? 'Sign In' : 'Create Account',
                          icon: _isLogin
                              ? LucideIcons.arrowRight
                              : LucideIcons.check,
                          onPressed: _submit,
                          loading: _loading,
                        ),

                        const SizedBox(height: 20),
                        Center(
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _isLogin = !_isLogin;
                              _ctrl.reset();
                              _ctrl.forward();
                            }),
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.slate500,
                                  fontWeight: FontWeight.w600,
                                ),
                                children: [
                                  TextSpan(
                                    text: _isLogin
                                        ? "Don't have an account? "
                                        : 'Already have an account? ',
                                  ),
                                  TextSpan(
                                    text: 'Click here',
                                    style: TextStyle(
                                      color: isDark ? Colors.white : Colors.black,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: isDark ? AppColors.slate300 : AppColors.slate600,
      ),
    );
  }
}

class _DividerRow extends StatelessWidget {
  const _DividerRow();
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dividerColor = isDark ? AppColors.borderDark.withValues(alpha: 0.25) : AppColors.borderLight.withValues(alpha: 0.25);
    return Row(
      children: [
        Expanded(child: Divider(color: dividerColor)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'or continue with email',
            style: TextStyle(
              color: AppColors.slate500,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Expanded(child: Divider(color: dividerColor)),
      ],
    );
  }
}

class _GoogleSignInButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;
  const _GoogleSignInButton({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textThemeColor = isDark ? Colors.white : AppColors.slate900;
    final cardBgColor = isDark 
        ? Colors.black.withValues(alpha: 0.15) 
        : Colors.white.withValues(alpha: 0.35);

    return InkWell(
      onTap: loading ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: GlassCard(
        bgColor: cardBgColor,
        borderRadius: 12,
        child: Container(
          height: 52,
          alignment: Alignment.center,
          child: loading
              ? const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.primary,
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: CustomPaint(painter: _GoogleLogoPainter()),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Continue with Google',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        letterSpacing: 0.1,
                        color: textThemeColor,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double r = size.width / 2;
    final double strokeWidth = r * 0.45;
    final rect = Rect.fromCircle(center: Offset(r, r), radius: r - strokeWidth / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    // Red arc (top)
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, -2.35, 1.57, false, paint);

    // Yellow arc (left)
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, -3.92, 1.57, false, paint);

    // Green arc (bottom)
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(rect, 0.78, 1.57, false, paint);

    // Blue arc (right)
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, -0.78, 1.56, false, paint);

    // Horizontal bar of G
    final fillPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTRB(r, r - strokeWidth / 2, size.width - strokeWidth / 4, r + strokeWidth / 2),
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}
