import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'features/layout/app_shell.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/signup_screen.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
import 'features/jobs/screens/jobs_screen.dart';
import 'features/notifications/screens/notifications_screen.dart';
import 'features/chat/screens/chat_screen.dart';

// Simple profile + applications screens (inline for brevity)
import 'features/profile/screens/profile_screen.dart';
import 'features/applications/screens/applications_screen.dart';
import 'features/settings/screens/settings_screen.dart';
import 'features/jobs/screens/post_job_screen.dart';
import 'features/jobs/screens/job_detail_screen.dart';

// Notifies GoRouter whenever auth state changes so redirects re-evaluate
class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier(this._ref) {
    _ref.listen<AsyncValue<User?>>(currentUserProvider, (_, __) {
      notifyListeners();
    });
  }
  final Ref _ref;
  bool get isLoggedIn => _ref.read(currentUserProvider).value != null;
}

final _routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = _AuthChangeNotifier(ref);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final isLoggedIn = authNotifier.isLoggedIn;
      final path = state.matchedLocation;
      // /login and /signup redirect an already-logged-in user to /dashboard.
      final authOnly = path.startsWith('/login') || path.startsWith('/signup');
      // /forgot-password is reachable either way — it's reached both from
      // the login screen (logged out) and from Settings > Change Password
      // (logged in) — so it must never bounce a logged-in user away.
      final alwaysAllowed = authOnly || path.startsWith('/forgot');
      if (!isLoggedIn && !alwaysAllowed) return '/login';
      if (isLoggedIn && authOnly)        return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(path: '/login',          builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/signup',         builder: (_, __) => const SignupScreen()),
      GoRoute(path: '/forgot-password',builder: (_, __) => const _ForgotPasswordScreen()),

      ShellRoute(
        builder: (_, __, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/dashboard',    builder: (_, __) => const DashboardScreen()),
          GoRoute(path: '/jobs',         builder: (_, __) => const JobsScreen()),
          GoRoute(path: '/internships',  builder: (_, __) => const JobsScreen(pageType: 'internships')),
          GoRoute(path: '/freelance',    builder: (_, __) => const JobsScreen(pageType: 'freelance')),
          GoRoute(path: '/applications', builder: (_, __) => const ApplicationsScreen()),
          GoRoute(path: '/chat',
            builder: (_, state) => ChatScreen(
              initialAppId: state.uri.queryParameters['appId'])),
          GoRoute(path: '/notifications',builder: (_, __) => const NotificationsScreen()),
          GoRoute(path: '/profile',      builder: (_, __) => const ProfileScreen()),
          GoRoute(path: '/settings',     builder: (_, __) => const SettingsScreen()),
          GoRoute(path: '/post-job',     builder: (_, __) => const PostJobScreen()),
          GoRoute(
            path: '/jobs/:id',
            builder: (_, state) => JobDetailScreen(jobId: state.pathParameters['id']!),
          ),
        ],
      ),
    ],
  );
});

class SkillConnectApp extends ConsumerWidget {
  const SkillConnectApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(_routerProvider);
    // Locked to the light (berry) theme app-wide — dark mode is disabled for now
    // so every screen renders consistently. (themeProvider / AppTheme.dark() are
    // still here if dark mode gets re-enabled later.)
    return MaterialApp.router(
      title: 'SkillConnect',
      debugShowCheckedModeBanner: false,
      theme:      AppTheme.light(),
      themeMode:  ThemeMode.light,
      routerConfig: router,
    );
  }
}

// ── Lightweight placeholder screens ────────────────────────────────────────

class _ForgotPasswordScreen extends ConsumerStatefulWidget {
  const _ForgotPasswordScreen();
  @override
  ConsumerState<_ForgotPasswordScreen> createState() => _ForgotState();
}

class _ForgotState extends ConsumerState<_ForgotPasswordScreen> {
  final _ctrl = TextEditingController();
  bool _sent = false, _loading = false;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: Material(
          color: Colors.white,
          shape: const CircleBorder(),
          elevation: 2,
          shadowColor: Colors.black.withValues(alpha: 0.1),
          child: InkWell(
            customBorder: const CircleBorder(),
            // Reachable both by push (from Login → canPop is true, just pop)
            // and by go (from Settings > Change Password, which clears the
            // stack → canPop is false). In the go case, falling back to
            // /login is wrong while logged in: the router redirect bounces
            // an already-logged-in user straight to /dashboard. So when
            // there's nothing to pop, go home base for whichever state
            // we're in — /settings if logged in, /login otherwise.
            onTap: () => context.canPop()
                ? context.pop()
                : context.go(ref.read(currentUserProvider).value != null ? '/settings' : '/login'),
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.arrow_back, size: 18, color: AppColors.brand600),
            ),
          ),
        ),
      ),
      title: const Text('Reset Password'),
    ),
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: _sent
          ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.mark_email_read_outlined, size: 64, color: AppColors.success500),
              const SizedBox(height: 16),
              const Text('Check your inbox', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text('We sent a reset link to ${_ctrl.text}', textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.surface500)),
              const SizedBox(height: 24),
              TextButton(onPressed: () => context.pop(), child: const Text('Back to login')),
            ])
          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 16),
              const Text('Forgot Password', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text('Enter your email and we will send you a reset link.',
                style: TextStyle(color: AppColors.surface500)),
              const SizedBox(height: 32),
              TextFormField(controller: _ctrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined))),
              const SizedBox(height: 24),
              SizedBox(width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : () async {
                    setState(() => _loading = true);
                    await ref.read(authNotifierProvider.notifier).resetPassword(_ctrl.text.trim());
                    if (mounted) setState(() { _sent = true; _loading = false; });
                  },
                  child: _loading ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Send Reset Link'),
                )),
            ]),
    ),
  );
}
