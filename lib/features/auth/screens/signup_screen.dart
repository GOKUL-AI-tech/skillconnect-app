import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/models.dart';
import '../../../data/services/database_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/avatar_widget.dart';

// ── Interest categories ──────────────────────────────────────────────────────

class _Interest {
  final String label;
  final String emoji;
  final List<String> jobTypes; // maps to Job.type values
  const _Interest(this.label, this.emoji, this.jobTypes);
}

const _interests = [
  _Interest('Software Dev',    '💻', ['full_time', 'contract', 'freelance']),
  _Interest('Internship',      '🎓', ['internship']),
  _Interest('Design & UX',     '🎨', ['full_time', 'freelance', 'contract']),
  _Interest('Marketing',       '📣', ['full_time', 'part_time', 'freelance']),
  _Interest('Finance',         '💰', ['full_time', 'contract']),
  _Interest('Data Science',    '📊', ['full_time', 'contract']),
  _Interest('Product Mgmt',    '🎯', ['full_time']),
  _Interest('Freelance',       '🧑‍💻', ['freelance']),
  _Interest('Part-time',       '⏰', ['part_time']),
  _Interest('AI & ML',         '🤖', ['full_time', 'contract', 'freelance']),
  _Interest('Mobile Dev',      '📱', ['full_time', 'freelance', 'contract']),
  _Interest('Cybersecurity',   '🔐', ['full_time', 'contract']),
];

// ── Provider for hiring companies based on selected interests ────────────────
// Key is a sorted, joined string to avoid List identity-equality issues with .family

final _hiringCompaniesProvider =
    FutureProvider.autoDispose.family<List<_CompanySnap>, String>(
  (ref, typesKey) async {
    final selectedTypes = typesKey.isEmpty ? <String>[] : typesKey.split(',');
    final db = DatabaseService();
    final Map<String, _CompanySnap> seen = {};

    // Fetch jobs for each selected type and collect unique companies
    for (final type in selectedTypes) {
      final jobs = await db.fetchJobs(type: type);
      for (final job in jobs) {
        if (job.company == null) continue;
        final cid = job.company!.id;
        if (seen.containsKey(cid)) {
          seen[cid] = seen[cid]!.copyWithMore();
        } else {
          seen[cid] = _CompanySnap(company: job.company!, jobCount: 1);
        }
      }
    }

    final list = seen.values.toList()
      ..sort((a, b) => b.jobCount.compareTo(a.jobCount));
    return list.take(20).toList();
  },
);

class _CompanySnap {
  final Company company;
  final int jobCount;
  const _CompanySnap({required this.company, required this.jobCount});
  _CompanySnap copyWithMore() =>
      _CompanySnap(company: company, jobCount: jobCount + 1);
}

// ── Main screen ──────────────────────────────────────────────────────────────

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});
  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  // Step 1
  final _form   = GlobalKey<FormState>();
  final _name   = TextEditingController();
  final _email  = TextEditingController();
  final _pass   = TextEditingController();
  String _role  = 'student';
  bool _loading = false;

  // Step tracking
  int _step = 1; // 1 = form, 2 = interests, 3 = companies

  // Step 2
  final Set<int> _selectedInterests = {};

  @override
  void dispose() {
    _name.dispose(); _email.dispose(); _pass.dispose();
    super.dispose();
  }

  /// Sorted, comma-joined string — stable key for the .family provider
  String get _typesKey {
    final types = _selectedInterests
        .expand((i) => _interests[i].jobTypes)
        .toSet()
        .toList()
      ..sort();
    return types.join(',');
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(authNotifierProvider.notifier).signUp(
        email:    _email.text.trim(),
        password: _pass.text,
        fullName: _name.text.trim(),
        role:     _role,
      );
      if (mounted) {
        if (_role == 'student') {
          setState(() { _step = 2; _loading = false; });
        } else {
          context.go('/dashboard');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()),
            backgroundColor: AppColors.danger500));
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      transitionBuilder: (child, anim) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0), end: Offset.zero).animate(
            CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: child,
      ),
      child: switch (_step) {
        1 => _Step1(key: const ValueKey(1), form: _form, name: _name,
                email: _email, pass: _pass, role: _role, loading: _loading,
                onRoleChange: (r) => setState(() => _role = r),
                onSubmit: _submit),
        2 => _Step2(key: const ValueKey(2),
                selected: _selectedInterests,
                onToggle: (i) => setState(() {
                  _selectedInterests.contains(i)
                      ? _selectedInterests.remove(i)
                      : _selectedInterests.add(i);
                }),
                onNext: () => setState(() => _step = 3),
                onSkip: () => context.go('/dashboard')),
        _ => _Step3(key: const ValueKey(3),
                typesKey: _typesKey,
                onDone: () => context.go('/dashboard')),
      },
    );
  }
}

// ── Step 1: Account form ─────────────────────────────────────────────────────

class _Step1 extends StatelessWidget {
  final GlobalKey<FormState> form;
  final TextEditingController name, email, pass;
  final String role;
  final bool loading;
  final void Function(String) onRoleChange;
  final VoidCallback onSubmit;

  const _Step1({
    super.key,
    required this.form, required this.name, required this.email,
    required this.pass,  required this.role,  required this.loading,
    required this.onRoleChange, required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: form,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 16),
              IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)),
              const SizedBox(height: 16),

              // Progress dots
              _ProgressDots(current: 1, total: 3, isStudent: role == 'student'),
              const SizedBox(height: 24),

              Text('Create account',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.surface900)),
              const SizedBox(height: 6),
              Text('Join thousands of professionals',
                style: TextStyle(fontSize: 15,
                  color: isDark ? AppColors.surface400 : AppColors.surface500)),
              const SizedBox(height: 32),

              Text('I am a…',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.surface300 : AppColors.surface700)),
              const SizedBox(height: 10),
              Row(children: [
                _RoleCard(value: 'student',   label: 'Job Seeker',
                  icon: Icons.school_outlined,   selected: role == 'student',
                  color: AppColors.brand600,
                  onTap: () => onRoleChange('student')),
                const SizedBox(width: 12),
                _RoleCard(value: 'recruiter', label: 'Recruiter',
                  icon: Icons.business_outlined, selected: role == 'recruiter',
                  color: AppColors.accent500,
                  onTap: () => onRoleChange('recruiter')),
              ]),
              const SizedBox(height: 24),

              AppTextField(
                label: 'Full Name', hint: 'John Doe',
                controller: name, prefixIcon: Icons.person_outlined,
                validator: (v) => v!.isEmpty ? 'Name is required' : null),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Email', hint: 'you@example.com',
                controller: email, keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
                validator: (v) => v!.isEmpty ? 'Email is required' : null),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Password', hint: '••••••••',
                controller: pass, obscureText: true,
                prefixIcon: Icons.lock_outlined,
                validator: (v) => (v?.length ?? 0) < 6 ? 'Min 6 characters' : null),
              const SizedBox(height: 24),

              AppButton(label: 'Create Account', onPressed: onSubmit, loading: loading),
              const SizedBox(height: 20),

              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('Already have an account? ',
                  style: TextStyle(
                    color: isDark ? AppColors.surface400 : AppColors.surface500)),
                GestureDetector(
                  onTap: () => context.go('/login'),
                  child: const Text('Sign in',
                    style: TextStyle(color: AppColors.brand600,
                      fontWeight: FontWeight.w600)),
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}

// ── Step 2: Pick interests ───────────────────────────────────────────────────

class _Step2 extends StatelessWidget {
  final Set<int> selected;
  final void Function(int) onToggle;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const _Step2({
    super.key,
    required this.selected, required this.onToggle,
    required this.onNext,   required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.surface950 : AppColors.warmBg,
      body: SafeArea(
        child: Column(children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _ProgressDots(current: 2, total: 3, isStudent: true),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('What are you looking for?',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppColors.surface900)),
                  const SizedBox(height: 6),
                  Text('Pick your interests — we\'ll show companies hiring for them.',
                    style: TextStyle(fontSize: 14, height: 1.5,
                      color: isDark ? AppColors.surface400 : AppColors.surface500)),
                ])),
              ]),
              const SizedBox(height: 24),
            ]),
          ),

          // Interest grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.0,
              ),
              itemCount: _interests.length,
              itemBuilder: (_, i) {
                final isSelected = selected.contains(i);
                final interest   = _interests[i];
                return GestureDetector(
                  onTap: () => onToggle(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.brand600
                          : (isDark ? AppColors.surface800 : Colors.white),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.brand600
                            : (isDark ? AppColors.surface700 : AppColors.surface200),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected || isDark ? [] : [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(interest.emoji, style: const TextStyle(fontSize: 28)),
                        const SizedBox(height: 6),
                        Text(interest.label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? AppColors.surface300 : AppColors.surface700),
                          )),
                        if (isSelected)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Icon(Icons.check_circle,
                              size: 14, color: Colors.white.withValues(alpha: 0.8)),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom bar
          Container(
            padding: EdgeInsets.fromLTRB(
              24, 12, 24, MediaQuery.of(context).padding.bottom + 16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surface900 : Colors.white,
              border: Border(top: BorderSide(
                color: isDark ? AppColors.surface700 : AppColors.surface100)),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              if (selected.isNotEmpty)
                Text('${selected.length} interest${selected.length > 1 ? 's' : ''} selected',
                  style: const TextStyle(fontSize: 12, color: AppColors.brand600,
                    fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: selected.isNotEmpty ? onNext : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brand600,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      isDark ? AppColors.surface700 : AppColors.surface200,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text(
                  selected.isEmpty ? 'Select at least one' : 'Show matching companies →',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: onSkip,
                child: Text('Skip for now',
                  style: TextStyle(fontSize: 13,
                    color: isDark ? AppColors.surface400 : AppColors.surface500)),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ── Step 3: Hiring companies ─────────────────────────────────────────────────

class _Step3 extends ConsumerWidget {
  final String typesKey; // sorted, comma-joined job types string
  final VoidCallback onDone;

  const _Step3({super.key, required this.typesKey, required this.onDone});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark     = Theme.of(context).brightness == Brightness.dark;
    final snapAsync  = ref.watch(_hiringCompaniesProvider(typesKey));

    return Scaffold(
      backgroundColor: isDark ? AppColors.surface950 : AppColors.warmBg,
      body: SafeArea(
        child: Column(children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _ProgressDots(current: 3, total: 3, isStudent: true),
              const SizedBox(height: 24),
              Text('Companies hiring now 🚀',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.surface900)),
              const SizedBox(height: 6),
              Text('These companies have open roles matching your interests.',
                style: TextStyle(fontSize: 14, height: 1.5,
                  color: isDark ? AppColors.surface400 : AppColors.surface500)),
            ]),
          ),

          // Company list
          Expanded(
            child: snapAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (snaps) {
                if (snaps.isEmpty) {
                  return Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Text('🏢', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 12),
                      Text('No companies found yet',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.surface400 : AppColors.surface500)),
                      const SizedBox(height: 6),
                      Text('Check back soon — more companies join every day!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13,
                          color: isDark ? AppColors.surface500 : AppColors.surface400)),
                    ]),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  itemCount: snaps.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _CompanyCard(snap: snaps[i], isDark: isDark),
                );
              },
            ),
          ),

          // Bottom CTA
          Container(
            padding: EdgeInsets.fromLTRB(
              24, 12, 24, MediaQuery.of(context).padding.bottom + 16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surface900 : Colors.white,
              border: Border(top: BorderSide(
                color: isDark ? AppColors.surface700 : AppColors.surface100)),
            ),
            child: ElevatedButton.icon(
              onPressed: onDone,
              icon: const Icon(Icons.rocket_launch_outlined, size: 18),
              label: const Text('Get Started →',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brand600,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Company card ─────────────────────────────────────────────────────────────

class _CompanyCard extends StatelessWidget {
  final _CompanySnap snap;
  final bool isDark;
  const _CompanyCard({super.key, required this.snap, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final c = snap.company;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface800 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark ? [] : [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(children: [
        AvatarWidget(
          imageUrl: c.logoUrl,
          name: c.name,
          size: 52,
          radius: 12,
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(c.name,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.surface900),
              overflow: TextOverflow.ellipsis)),
            if (c.isVerified)
              const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Icon(Icons.verified, size: 16, color: AppColors.accent500),
              ),
          ]),
          if (c.industry != null) ...[
            const SizedBox(height: 2),
            Text(c.industry!,
              style: TextStyle(fontSize: 12,
                color: isDark ? AppColors.surface400 : AppColors.surface500)),
          ],
          const SizedBox(height: 8),
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success500.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.work_outline,
                  size: 12, color: AppColors.success600),
                const SizedBox(width: 4),
                Text('${snap.jobCount} open role${snap.jobCount > 1 ? 's' : ''}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                    color: AppColors.success600)),
              ]),
            ),
            if (c.location != null) ...[
              const SizedBox(width: 8),
              Icon(Icons.location_on_outlined, size: 12,
                color: isDark ? AppColors.surface500 : AppColors.surface400),
              const SizedBox(width: 2),
              Flexible(child: Text(c.location!,
                style: TextStyle(fontSize: 11,
                  color: isDark ? AppColors.surface500 : AppColors.surface400),
                overflow: TextOverflow.ellipsis)),
            ],
          ]),
        ])),
        Icon(Icons.chevron_right,
          color: isDark ? AppColors.surface600 : AppColors.surface300),
      ]),
    );
  }
}

// ── Progress dots ─────────────────────────────────────────────────────────────

class _ProgressDots extends StatelessWidget {
  final int current;
  final int total;
  final bool isStudent;
  const _ProgressDots({required this.current, required this.total, required this.isStudent});

  @override
  Widget build(BuildContext context) {
    // Recruiters only have step 1
    final effectiveTotal = isStudent ? total : 1;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      for (int i = 1; i <= effectiveTotal; i++) ...[
        if (i > 1) const SizedBox(width: 6),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: i == current ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: i <= current ? AppColors.brand600 : AppColors.surface300,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    ]);
  }
}

// ── Role card ─────────────────────────────────────────────────────────────────

class _RoleCard extends StatelessWidget {
  final String value, label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _RoleCard({required this.value, required this.label, required this.icon,
    required this.selected, this.color = AppColors.brand600, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: selected
                ? (isDark ? color.withValues(alpha: 0.22) : color.withValues(alpha: 0.08))
                : (isDark ? AppColors.surface800 : Colors.white),
            border: Border.all(
              color: selected ? color
                  : (isDark ? AppColors.surface700 : AppColors.surface200),
              width: selected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(children: [
            Icon(icon, size: 28,
              color: selected ? color
                  : (isDark ? AppColors.surface400 : AppColors.surface500)),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600,
              color: selected ? color
                  : (isDark ? AppColors.surface300 : AppColors.surface700))),
          ]),
        ),
      ),
    );
  }
}
