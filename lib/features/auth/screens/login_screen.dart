import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';

/// Local palette for the new SkillConnect look (berry / serif theme).
/// Scoped to the auth screens for now — not yet promoted into AppTheme.
class _Palette {
  static const bg = Color(0xFFFBF9F6);
  static const surface = Color(0xFFFFFFFF);
  static const ink = Color(0xFF1C1613);
  static const ink70 = Color(0xFF4B4340);
  static const ink50 = Color(0xFF867B73);
  static const ink30 = Color(0xFFBBB1A7);
  static const border = Color(0xFFE9E1D6);
  static const berry = Color(0xFF8A1338);
  static const berryInk = Color(0xFF5E0D26);
  static const berryTint = Color(0xFFF2B7C6);
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form  = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass  = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose(); _pass.dispose(); super.dispose();
  }

  /// Converts a plain username (e.g. "user") to a full email for Supabase.
  /// If the user already typed an @, leave it untouched.
  String _toEmail(String input) {
    final v = input.trim();
    return v.contains('@') ? v : '$v@skillconnect.com';
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(authNotifierProvider.notifier).signIn(
        email: _toEmail(_email.text),
        password: _pass.text,
      );
      if (mounted) context.go('/dashboard');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger500),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  InputDecoration _fieldDecoration({required String label, String? hint, required IconData icon}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, size: 20, color: _Palette.berry.withValues(alpha: 0.85)),
      suffixIcon: label == 'Password'
          ? IconButton(
              icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: 20, color: _Palette.ink30),
              onPressed: () => setState(() => _obscure = !_obscure),
            )
          : null,
      filled: true,
      fillColor: _Palette.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      labelStyle: const TextStyle(color: _Palette.ink70, fontSize: 13, fontWeight: FontWeight.w600),
      hintStyle: const TextStyle(color: _Palette.ink30, fontSize: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _Palette.border, width: 1.4),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _Palette.border, width: 1.4),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _Palette.berry, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.danger500, width: 1.4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Palette.bg,
      body: Stack(
        children: [
          // One continuous soft pink-lavender wash for the whole page —
          // concentrated near the top, fading into the warm neutral
          // background — rather than a separate colored hero block.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _Palette.berryTint.withValues(alpha: 0.40),
                    AppColors.purple400.withValues(alpha: 0.10),
                    _Palette.bg,
                  ],
                  stops: const [0.0, 0.28, 0.62],
                ),
              ),
            ),
          ),
          // Decorative dot grid, top-right
          Positioned(top: 54, right: 22, child: _dotGrid()),
          // Decorative soft blobs
          Positioned(right: -70, top: 300, child: _blob(240, _Palette.berry.withValues(alpha: 0.14))),
          Positioned(left: -60, bottom: -50, child: _blob(190, _Palette.berry.withValues(alpha: 0.09))),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 36, 24, 32),
              child: Form(
                key: _form,
                child: Column(
                  children: [
                    Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(
                        color: _Palette.berry,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: _Palette.berry.withValues(alpha: 0.35), blurRadius: 22, offset: const Offset(0, 12)),
                        ],
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Center(child: Icon(Icons.bolt, color: Colors.white, size: 34)),
                          Positioned(
                            top: -3, right: -3,
                            child: Icon(Icons.auto_awesome, color: Colors.white.withValues(alpha: 0.85), size: 15),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.domine(fontSize: 30, fontWeight: FontWeight.w700, color: _Palette.ink),
                        children: const [
                          TextSpan(text: 'SkillConnect'),
                          TextSpan(text: '.', style: TextStyle(color: _Palette.berry)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text('Where talent meets opportunity',
                      style: TextStyle(fontSize: 13.5, color: _Palette.ink50)),
                    const SizedBox(height: 30),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('✦', style: TextStyle(color: _Palette.berry, fontSize: 15)),
                        const SizedBox(width: 8),
                        Text('Welcome back',
                          style: GoogleFonts.domine(fontSize: 21, fontWeight: FontWeight.w700, color: _Palette.ink)),
                        const SizedBox(width: 8),
                        const Text('✦', style: TextStyle(color: _Palette.berry, fontSize: 15)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text('Sign in to continue your search',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: _Palette.ink50)),
                    const SizedBox(height: 24),

                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.text,
                      style: const TextStyle(color: _Palette.ink, fontSize: 14),
                      decoration: _fieldDecoration(
                        label: 'Email or username',
                        hint: 'e.g. priya.sharma@email.com',
                        icon: Icons.mail_outline,
                      ),
                      validator: (v) => v!.trim().isEmpty ? 'Username is required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _pass,
                      obscureText: _obscure,
                      style: const TextStyle(color: _Palette.ink, fontSize: 14),
                      decoration: _fieldDecoration(label: 'Password', hint: '••••••••', icon: Icons.lock_outline),
                      validator: (v) => (v?.length ?? 0) < 6 ? 'Min 6 characters' : null,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => context.push('/forgot-password'),
                        style: TextButton.styleFrom(foregroundColor: _Palette.berry),
                        child: const Text('Forgot password?', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(height: 6),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Material(
                          color: Colors.transparent,
                          child: Ink(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [_Palette.berry, _Palette.berryInk],
                                begin: Alignment.centerLeft, end: Alignment.centerRight,
                              ),
                            ),
                            child: InkWell(
                              onTap: _loading ? null : _submit,
                              child: Center(
                                child: _loading
                                    ? const SizedBox(
                                        width: 18, height: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text('Sign In', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: Colors.white)),
                                          SizedBox(width: 8),
                                          Icon(Icons.arrow_forward, size: 17, color: Colors.white),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Row(children: [
                      const Expanded(child: Divider(color: _Palette.border)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('or continue with', style: TextStyle(color: _Palette.ink30, fontSize: 12)),
                      ),
                      const Expanded(child: Divider(color: _Palette.border)),
                    ]),
                    const SizedBox(height: 20),

                    OutlinedButton(
                      onPressed: () => ref.read(authNotifierProvider.notifier).signInWithGoogle(),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 52),
                        side: const BorderSide(color: _Palette.border, width: 1.4),
                        foregroundColor: _Palette.ink,
                        backgroundColor: _Palette.surface,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          _GoogleG(),
                          SizedBox(width: 10),
                          Text('Continue with Google', style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),

                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Text("Don't have an account? ", style: TextStyle(color: _Palette.ink50, fontSize: 13)),
                      GestureDetector(
                        onTap: () => context.push('/signup'),
                        child: const Text('Sign up',
                          style: TextStyle(color: _Palette.berry, fontWeight: FontWeight.w700, fontSize: 13)),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _blob(double size, Color color) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  Widget _dotGrid() {
    return SizedBox(
      width: 46, height: 46,
      child: Wrap(
        spacing: 8, runSpacing: 8,
        children: List.generate(9, (_) => Container(
          width: 4, height: 4,
          decoration: BoxDecoration(shape: BoxShape.circle, color: _Palette.berry.withValues(alpha: 0.18)),
        )),
      ),
    );
  }
}

/// Small hand-painted approximation of the Google "G" mark — no image
/// asset needed for the "Continue with Google" button.
class _GoogleG extends StatelessWidget {
  const _GoogleG();
  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 20, height: 20,
    child: CustomPaint(painter: _GoogleGPainter()),
  );
}

class _GoogleGPainter extends CustomPainter {
  const _GoogleGPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final center = Offset(r, r);
    final strokeWidth = size.width * 0.24;
    final rect = Rect.fromCircle(center: center, radius: r - strokeWidth / 2);

    void arc(double startDeg, double sweepDeg, Color color) {
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      canvas.drawArc(rect, startDeg * 3.14159265 / 180, sweepDeg * 3.14159265 / 180, false, paint);
    }

    arc(-50, -95, const Color(0xFFEA4335));
    arc(-145, -95, const Color(0xFF4285F4));
    arc(130, -100, const Color(0xFF34A853));
    arc(35, -65, const Color(0xFFFBBC05));

    final barPaint = Paint()..color = const Color(0xFF4285F4);
    canvas.drawRect(
      Rect.fromLTWH(center.dx - 1, center.dy - strokeWidth / 2, r - strokeWidth * 0.1, strokeWidth),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
