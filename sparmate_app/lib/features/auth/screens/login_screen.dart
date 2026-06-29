import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/state/app_state.dart';
import 'signup_screen.dart';

/// Cyberpunk-themed login screen matching the circuit-board knight logo.
///
/// Implements Laravel Sanctum token authentication via [AppState.login].
/// On success, the auth state change triggers navigation to the main app.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

// ── Cyan accent color used throughout ──
const _kCyan = Color(0xFF00BFFF);
const _kBgDark = Color(0xFF060B18);
const _kBgMid = Color(0xFF0B1628);
const _kBgCard = Color(0xFF0D1A2E);

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  late final AnimationController _animController;
  late final AnimationController _pulseController;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;
  late final Animation<double> _logoScale;

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
    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    ));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _pulseController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final state = context.read<AppState>();
    final success = await state.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.errorMessage ?? 'Login failed.'),
          backgroundColor: const Color(0xFFFF1744),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
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
                center: Alignment(0, -0.4),
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
                painter: _CircuitPainter(
                  animValue: _pulseController.value,
                ),
              );
            },
          ),

          // ── Content ──
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: size.height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),

                      // ── Logo & Branding ──
                      FadeTransition(
                        opacity: _fadeIn,
                        child: ScaleTransition(
                          scale: _logoScale,
                          child: Column(
                            children: [
                              AnimatedBuilder(
                                animation: _pulseController,
                                builder: (context, child) {
                                  final glowOpacity =
                                      0.25 + (_pulseController.value * 0.2);
                                  return Container(
                                    width: 160,
                                    height: 160,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(28),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _kCyan.withValues(
                                              alpha: glowOpacity),
                                          blurRadius: 60,
                                          spreadRadius: 8,
                                        ),
                                        BoxShadow(
                                          color: _kCyan.withValues(alpha: 0.1),
                                          blurRadius: 120,
                                          spreadRadius: 20,
                                        ),
                                      ],
                                    ),
                                    child: child,
                                  );
                                },
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(28),
                                  child: Image.asset(
                                    'assets/sparmate_logo.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              // Cyan-glowing title
                              ShaderMask(
                                shaderCallback: (bounds) =>
                                    const LinearGradient(
                                  colors: [
                                    Color(0xFF00E5FF),
                                    _kCyan,
                                    Color(0xFF80DEEA),
                                  ],
                                ).createShader(bounds),
                                child: const Text(
                                  'SparMate',
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'ADAPTIVE CHESS COACHING',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _kCyan.withValues(alpha: 0.6),
                                  letterSpacing: 3.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 44),

                      // ── Login Form Card ──
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
                                  // Header row with HUD-style decorators
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
                                      const Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'SYSTEM ACCESS',
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.w800,
                                                color: Colors.white,
                                                letterSpacing: 1.0,
                                              ),
                                            ),
                                            SizedBox(height: 2),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Authenticate to resume training',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: _kCyan.withValues(alpha: 0.5),
                                      letterSpacing: 0.5,
                                    ),
                                  ),

                                  const SizedBox(height: 28),

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

                                  // Email
                                  _buildCyberTextField(
                                    id: 'login-email',
                                    controller: _emailController,
                                    label: 'EMAIL',
                                    hint: 'you@example.com',
                                    icon: Icons.alternate_email_rounded,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (v) {
                                      if (v == null || v.isEmpty) {
                                        return 'Email is required';
                                      }
                                      if (!v.contains('@')) {
                                        return 'Enter a valid email';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),

                                  // Password
                                  _buildCyberTextField(
                                    id: 'login-password',
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
                                          _obscurePassword =
                                              !_obscurePassword),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.isEmpty) {
                                        return 'Password is required';
                                      }
                                      return null;
                                    },
                                  ),

                                  const SizedBox(height: 32),

                                  // ── Sign In Button ──
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
                                      key: const Key('login-submit'),
                                      onPressed: state.isLoading
                                          ? null
                                          : _handleLogin,
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
                                              child:
                                                  CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.login_rounded,
                                                    size: 20),
                                                SizedBox(width: 8),
                                                Text(
                                                  'INITIATE LOGIN',
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

                      const SizedBox(height: 20),

                      // ── Demo Hint ──
                      FadeTransition(
                        opacity: _fadeIn,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: _kCyan.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _kCyan.withValues(alpha: 0.15),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.terminal_rounded,
                                  color: _kCyan.withValues(alpha: 0.7),
                                  size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Demo: demo@sparmate.app / password123',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _kCyan.withValues(alpha: 0.65),
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // ── Sign Up Link ──
                      FadeTransition(
                        opacity: _fadeIn,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "New operator? ",
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontSize: 14,
                              ),
                            ),
                            GestureDetector(
                              key: const Key('go-to-signup'),
                              onTap: () {
                                Navigator.of(context).push(
                                  PageRouteBuilder(
                                    pageBuilder: (context, animation,
                                            secondaryAnimation) =>
                                        const SignupScreen(),
                                    transitionsBuilder: (context, animation,
                                        secondaryAnimation, child) {
                                      return SlideTransition(
                                        position: Tween<Offset>(
                                          begin: const Offset(1, 0),
                                          end: Offset.zero,
                                        ).animate(CurvedAnimation(
                                          parent: animation,
                                          curve: Curves.easeOutCubic,
                                        )),
                                        child: child,
                                      );
                                    },
                                    transitionDuration:
                                        const Duration(milliseconds: 400),
                                  ),
                                );
                              },
                              child: const Text(
                                'Create Account',
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

    final rng = Random(42); // Fixed seed for consistent pattern

    // Draw circuit traces
    for (int i = 0; i < 18; i++) {
      final startX = rng.nextDouble() * size.width;
      final startY = rng.nextDouble() * size.height;
      final alpha = (0.04 + rng.nextDouble() * 0.08) *
          (0.6 + animValue * 0.4);

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

        // Draw node at junction
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
