import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/state/app_state.dart';

/// Cyberpunk-themed sign-up screen matching the circuit-board login page.
///
/// On successful registration, the BKT matrix is initialized server-side
/// and the user is navigated back to login.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

// ── Cyan accent color — shared with login screen ──
const _kCyan = Color(0xFF00BFFF);
const _kBgDark = Color(0xFF060B18);
const _kBgMid = Color(0xFF0B1628);
const _kBgCard = Color(0xFF0D1A2E);

class _SignupScreenState extends State<SignupScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  late final AnimationController _animController;
  late final AnimationController _pulseController;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);

    _fadeIn = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.15, 0.85, curve: Curves.easeOutCubic),
    ));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _pulseController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    final state = context.read<AppState>();
    final success = await state.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      passwordConfirmation: _confirmPasswordController.text,
    );

    if (success && mounted) {
      // Log out so the user stays on the login screen (not auto-navigated)
      await state.logout();

      // Show success modal
      await _showSuccessModal();

      // Pop back to login screen
      if (mounted) Navigator.of(context).pop();
    } else if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.errorMessage ?? 'Registration failed.'),
          backgroundColor: const Color(0xFFFF1744),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _showSuccessModal() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (ctx) => _SuccessDialog(name: _nameController.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // ── Dark gradient background ──
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.3),
                radius: 1.4,
                colors: [
                  Color(0xFF0F1E3A),
                  _kBgMid,
                  _kBgDark,
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // ── Animated circuit board traces ──
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return CustomPaint(
                size: size,
                painter: _CircuitPainter(animValue: _pulseController.value),
              );
            },
          ),

          // ── Content ──
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const SizedBox(height: 16),

                    // ── Back Button ──
                    FadeTransition(
                      opacity: _fadeIn,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          key: const Key('signup-back'),
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: _kBgCard.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _kCyan.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Icon(
                              Icons.arrow_back_rounded,
                              color: _kCyan.withValues(alpha: 0.8),
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Header ──
                    FadeTransition(
                      opacity: _fadeIn,
                      child: Column(
                        children: [
                          // Icon with glow
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              final glow =
                                  0.2 + (_pulseController.value * 0.15);
                              return Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: _kBgCard,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: _kCyan.withValues(alpha: 0.25),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _kCyan.withValues(alpha: glow),
                                      blurRadius: 30,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: child,
                              );
                            },
                            child: Icon(
                              Icons.person_add_rounded,
                              color: _kCyan.withValues(alpha: 0.9),
                              size: 28,
                            ),
                          ),
                          const SizedBox(height: 20),
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [
                                Color(0xFF00E5FF),
                                _kCyan,
                                Color(0xFF80DEEA),
                              ],
                            ).createShader(bounds),
                            child: const Text(
                              'New Player',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 2.0,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'INITIALIZE YOUR TRAINING PROFILE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _kCyan.withValues(alpha: 0.5),
                              letterSpacing: 2.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 36),

                    // ── Registration Form Card ──
                    SlideTransition(
                      position: _slideUp,
                      child: FadeTransition(
                        opacity: _fadeIn,
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: _kBgCard.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _kCyan.withValues(alpha: 0.15),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _kCyan.withValues(alpha: 0.06),
                                blurRadius: 30,
                                spreadRadius: 2,
                              ),
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header row with HUD-style decorator
                                Row(
                                  children: [
                                    Container(
                                      width: 4,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: _kCyan,
                                        borderRadius:
                                            BorderRadius.circular(2),
                                        boxShadow: [
                                          BoxShadow(
                                            color: _kCyan.withValues(
                                                alpha: 0.5),
                                            blurRadius: 8,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'CREDENTIALS',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Set up your secure access',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _kCyan.withValues(alpha: 0.5),
                                    letterSpacing: 0.5,
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // ── Horizontal line separator ──
                                Container(
                                  height: 1,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        _kCyan.withValues(alpha: 0.0),
                                        _kCyan.withValues(alpha: 0.3),
                                        _kCyan.withValues(alpha: 0.0),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // Name
                                _buildCyberTextField(
                                  id: 'signup-name',
                                  controller: _nameController,
                                  label: 'USERNAME',
                                  hint: 'Your full name',
                                  icon: Icons.badge_outlined,
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Name is required';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),

                                // Email
                                _buildCyberTextField(
                                  id: 'signup-email',
                                  controller: _emailController,
                                  label: 'EMAIL',
                                  hint: 'you@example.com',
                                  icon: Icons.alternate_email_rounded,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return 'Email is required';
                                    }
                                    if (!v.contains('@') || !v.contains('.')) {
                                      return 'Enter a valid email';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),

                                // Password
                                _buildCyberTextField(
                                  id: 'signup-password',
                                  controller: _passwordController,
                                  label: 'PASSWORD',
                                  hint: '••••••••',
                                  icon: Icons.lock_outline_rounded,
                                  obscure: _obscurePassword,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_rounded
                                          : Icons.visibility_rounded,
                                      color: _kCyan.withValues(alpha: 0.4),
                                      size: 20,
                                    ),
                                    onPressed: () => setState(() =>
                                        _obscurePassword = !_obscurePassword),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return 'Password is required';
                                    }
                                    if (v.length < 8) {
                                      return 'Must be at least 8 characters';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),

                                // Confirm Password
                                _buildCyberTextField(
                                  id: 'signup-confirm-password',
                                  controller: _confirmPasswordController,
                                  label: 'CONFIRM PASSWORD',
                                  hint: '••••••••',
                                  icon: Icons.shield_outlined,
                                  obscure: _obscureConfirm,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConfirm
                                          ? Icons.visibility_off_rounded
                                          : Icons.visibility_rounded,
                                      color: _kCyan.withValues(alpha: 0.4),
                                      size: 20,
                                    ),
                                    onPressed: () => setState(() =>
                                        _obscureConfirm = !_obscureConfirm),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return 'Please confirm your password';
                                    }
                                    if (v != _passwordController.text) {
                                      return 'Passwords do not match';
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 32),

                                // ── Create Account Button ──
                                AnimatedBuilder(
                                  animation: _pulseController,
                                  builder: (context, child) {
                                    final glow =
                                        0.2 + (_pulseController.value * 0.15);
                                    return Container(
                                      width: double.infinity,
                                      height: 52,
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(14),
                                        boxShadow: [
                                          BoxShadow(
                                            color: _kCyan.withValues(
                                                alpha: state.isLoading
                                                    ? 0.05
                                                    : glow),
                                            blurRadius: 20,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                      child: child,
                                    );
                                  },
                                  child: ElevatedButton(
                                    key: const Key('signup-submit'),
                                    onPressed: state.isLoading
                                        ? null
                                        : _handleSignup,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _kCyan,
                                      foregroundColor: _kBgDark,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(14),
                                      ),
                                      disabledBackgroundColor:
                                          _kCyan.withValues(alpha: 0.3),
                                    ),
                                    child: state.isLoading
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.person_add_rounded,
                                                  size: 20),
                                              SizedBox(width: 8),
                                              Text(
                                                'CREATE ACCOUNT',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w800,
                                                  letterSpacing: 1.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── Already have account ──
                    FadeTransition(
                      opacity: _fadeIn,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already registered? ',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 14,
                            ),
                          ),
                          GestureDetector(
                            key: const Key('go-to-login'),
                            onTap: () => Navigator.of(context).pop(),
                            child: const Text(
                              'Sign In',
                              style: TextStyle(
                                color: _kCyan,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a cyberpunk-styled text input field with cyan neon accents.
  Widget _buildCyberTextField({
    required String id,
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _kCyan.withValues(alpha: 0.6),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _kCyan.withValues(alpha: 0.3),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _kCyan.withValues(alpha: 0.7),
                letterSpacing: 2.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          key: Key(id),
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscure,
          validator: validator,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            letterSpacing: 0.5,
          ),
          cursorColor: _kCyan,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.2),
              fontSize: 14,
            ),
            prefixIcon:
                Icon(icon, color: _kCyan.withValues(alpha: 0.5), size: 20),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: const Color(0xFF0A1222),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _kCyan.withValues(alpha: 0.12),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _kCyan.withValues(alpha: 0.15),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: _kCyan,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFFF1744),
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFFF1744),
                width: 1.5,
              ),
            ),
            errorStyle: const TextStyle(
              color: Color(0xFFFF1744),
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Circuit Board Background Painter ──────────────────────────────────────────

class _CircuitPainter extends CustomPainter {
  final double animValue;

  _CircuitPainter({required this.animValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final nodePaint = Paint()..style = PaintingStyle.fill;

    final rng = Random(77); // Different seed from login for variety

    // Draw circuit traces
    for (int i = 0; i < 18; i++) {
      final startX = rng.nextDouble() * size.width;
      final startY = rng.nextDouble() * size.height;
      final alpha =
          (0.04 + rng.nextDouble() * 0.08) * (0.6 + animValue * 0.4);

      paint.color = _kCyan.withValues(alpha: alpha);
      nodePaint.color = _kCyan.withValues(alpha: alpha * 1.5);

      final path = Path();
      path.moveTo(startX, startY);

      double x = startX;
      double y = startY;

      for (int j = 0; j < 4; j++) {
        final horizontal = rng.nextBool();
        final length = 30 + rng.nextDouble() * 80;

        if (horizontal) {
          x += (rng.nextBool() ? 1 : -1) * length;
        } else {
          y += (rng.nextBool() ? 1 : -1) * length;
        }

        x = x.clamp(0, size.width);
        y = y.clamp(0, size.height);

        path.lineTo(x, y);
        canvas.drawCircle(Offset(x, y), 2.0, nodePaint);
      }

      canvas.drawPath(path, paint);
    }

    // Draw subtle grid
    final gridPaint = Paint()
      ..color = _kCyan.withValues(alpha: 0.02 + animValue * 0.01)
      ..strokeWidth = 0.5;

    for (double x = 0; x < size.width; x += 60) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 60) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CircuitPainter oldDelegate) =>
      oldDelegate.animValue != animValue;
}

// ── Cyberpunk Success Dialog ─────────────────────────────────────────────────

class _SuccessDialog extends StatefulWidget {
  final String name;
  const _SuccessDialog({required this.name});

  @override
  State<_SuccessDialog> createState() => _SuccessDialogState();
}

class _SuccessDialogState extends State<_SuccessDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scale = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _fade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FadeTransition(
        opacity: _fade,
        child: ScaleTransition(
          scale: _scale,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 36),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
            decoration: BoxDecoration(
              color: _kBgCard,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _kCyan.withValues(alpha: 0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: _kCyan.withValues(alpha: 0.1),
                  blurRadius: 40,
                  spreadRadius: 4,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Checkmark with cyan glow
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _kCyan.withValues(alpha: 0.15),
                      border: Border.all(
                        color: _kCyan.withValues(alpha: 0.4),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _kCyan.withValues(alpha: 0.3),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: _kCyan,
                      size: 38,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [
                        Color(0xFF00E5FF),
                        _kCyan,
                        Color(0xFF80DEEA),
                      ],
                    ).createShader(bounds),
                    child: const Text(
                      'ACCOUNT CREATED',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Message
                  Text(
                    'Welcome, ${widget.name}! 🎉\nSign in to begin your training.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.6),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Go to Login button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      key: const Key('success-go-to-login'),
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kCyan,
                        foregroundColor: _kBgDark,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.login_rounded, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'PROCEED TO LOGIN',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
