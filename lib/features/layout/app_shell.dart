import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../data/models/models.dart';

class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final Color color;
  const _NavItem({required this.icon, required this.selectedIcon, required this.label, required this.color});
}

class AppShell extends ConsumerStatefulWidget {
  final Widget child;
  const AppShell({super.key, required this.child});
  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  static const _routes = ['/dashboard', '/jobs', '/applications', '/chat', '/profile'];

  bool _isRecruiter(UserRole? role) =>
      role == UserRole.recruiter || role == UserRole.admin;

  // Pages reachable outside the five tab roots still need a "closest tab"
  // so the bar doesn't silently default to Dashboard/Home.
  static const _tabOverrides = {
    '/internships':   1, // Browse
    '/freelance':     1, // Browse
    '/notifications': 4, // Profile
    '/settings':      4, // Profile
    '/post-job':      2, // Applicants (recruiter's own postings)
  };

  // Derive current tab index from the actual current route
  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    for (final entry in _tabOverrides.entries) {
      if (location.startsWith(entry.key)) return entry.value;
    }
    for (int i = 0; i < _routes.length; i++) {
      if (location.startsWith(_routes[i])) return i;
    }
    return 0;
  }

  // Each tab gets its own color from the app palette, so the bar reads as
  // a spread of color the way the reference nav does — just in our theme.
  List<_NavItem> _destinations(UserRole? role) {
    if (_isRecruiter(role)) {
      return const [
        _NavItem(icon: Icons.dashboard_outlined,   selectedIcon: Icons.dashboard,   label: 'Dashboard',  color: AppColors.purple500),
        _NavItem(icon: Icons.search_outlined,       selectedIcon: Icons.search,      label: 'Browse',     color: AppColors.accent500),
        _NavItem(icon: Icons.people_outline,        selectedIcon: Icons.people,      label: 'Applicants', color: AppColors.teal500),
        _NavItem(icon: Icons.chat_bubble_outline,   selectedIcon: Icons.chat_bubble, label: 'Chat',       color: AppColors.warning600),
        _NavItem(icon: Icons.person_outline,        selectedIcon: Icons.person,      label: 'Profile',    color: AppColors.brand600),
      ];
    }
    return const [
      _NavItem(icon: Icons.dashboard_outlined,    selectedIcon: Icons.dashboard,   label: 'Home',    color: AppColors.purple500),
      _NavItem(icon: Icons.search_outlined,        selectedIcon: Icons.search,      label: 'Jobs',    color: AppColors.accent500),
      _NavItem(icon: Icons.description_outlined,   selectedIcon: Icons.description, label: 'Applied', color: AppColors.teal500),
      _NavItem(icon: Icons.chat_bubble_outline,    selectedIcon: Icons.chat_bubble, label: 'Chat',    color: AppColors.warning600),
      _NavItem(icon: Icons.person_outline,         selectedIcon: Icons.person,      label: 'Profile', color: AppColors.brand600),
    ];
  }

  Future<void> _handleBackPress(BuildContext context) async {
    // A screen was pushed on top of the current tab (job detail, settings,
    // post-job, notifications, etc.) → step back to that respective screen
    // instead of jumping anywhere else. Gate this on actually being off
    // one of the 5 tab roots first — go_router's canPop() reflects the
    // WHOLE router's location history, not just this tab, so trusting it
    // alone at an exact tab root (e.g. Browse reached via context.go) could
    // pop past the shell entirely and exit the app instead of switching
    // tabs like it should.
    final location = GoRouterState.of(context).matchedLocation;
    final atTabRoot = _routes.contains(location);
    if (!atTabRoot && context.canPop()) {
      context.pop();
      return;
    }

    final index = _currentIndex(context);

    // At a tab root that isn't Home (Browse, Applicants, Chat, Profile) →
    // go to Home instead of exiting.
    if (index != 0) {
      context.go('/dashboard');
      return;
    }

    // At the Home tab root → confirm before actually exiting the app
    final shouldExit = await _confirmExit(context);
    if (shouldExit) SystemNavigator.pop();
  }

  Future<bool> _confirmExit(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 32),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surface800 : Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 54, height: 54,
              decoration: BoxDecoration(
                color: AppColors.danger500.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout_rounded, color: AppColors.danger500, size: 24),
            ),
            const SizedBox(height: 16),
            Text('Exit SkillConnect?',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppColors.surface900)),
            const SizedBox(height: 6),
            Text('Are you sure you want to close the app?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13,
                color: isDark ? AppColors.surface400 : AppColors.surface500)),
            const SizedBox(height: 22),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: BorderSide(color: isDark ? AppColors.surface600 : AppColors.surface200),
                  ),
                  child: Text('No',
                    style: TextStyle(fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.surface900)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger500,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Yes', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final profile  = ref.watch(profileProvider).value;
    final index    = _currentIndex(context);
    final items    = _destinations(profile?.role);
    final isDark   = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, __) => _handleBackPress(context),
      child: Scaffold(
        body: widget.child,
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(14, 0, 14, 10),
          child: Container(
            height: 82,
            decoration: BoxDecoration(
              color: isDark ? AppColors.surface800 : Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: isDark ? [] : [
                BoxShadow(color: AppColors.brand900.withValues(alpha: 0.12), blurRadius: 24, offset: const Offset(0, 10)),
              ],
            ),
            child: Row(
              children: List.generate(items.length, (i) {
                final item = items[i];
                final selected = i == index;
                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => context.go(_routes[i]),
                    child: _NavTabIcon(item: item, selected: selected, isDark: isDark),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavTabIcon extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final bool isDark;
  const _NavTabIcon({required this.item, required this.selected, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: selected ? 44 : 32,
              height: selected ? 44 : 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? item.color : item.color.withValues(alpha: 0.12),
                boxShadow: selected ? [
                  BoxShadow(color: item.color.withValues(alpha: 0.35), blurRadius: 14, offset: const Offset(0, 5)),
                ] : [],
              ),
              child: Icon(
                selected ? item.selectedIcon : item.icon,
                size: selected ? 22 : 18,
                color: selected ? Colors.white : item.color,
              ),
            ),
            const SizedBox(height: 6),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: selected ? 11.5 : 10.5,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? item.color : (isDark ? AppColors.surface500 : AppColors.surface400),
              ),
              child: Text(item.label),
            ),
            const SizedBox(height: 3),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: selected ? 16 : 0,
              height: 3,
              decoration: BoxDecoration(
                color: item.color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
        // Soft glow behind the active tab's icon
        if (selected)
          Positioned(
            top: -6, left: 0, right: 0,
            child: IgnorePointer(
              child: Center(
                child: Container(
                  width: 70, height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [item.color.withValues(alpha: 0.18), item.color.withValues(alpha: 0.0)],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
