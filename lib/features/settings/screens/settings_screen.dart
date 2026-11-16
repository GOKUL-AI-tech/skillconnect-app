import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/models.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/avatar_widget.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final profile   = ref.watch(profileProvider).value;

    return Scaffold(
      backgroundColor: isDark ? AppColors.surface950 : AppColors.warmBg,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: Material(
            color: isDark ? AppColors.surface800 : Colors.white,
            shape: const CircleBorder(),
            elevation: isDark ? 0 : 2,
            shadowColor: Colors.black.withValues(alpha: 0.1),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.maybePop(context),
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.arrow_back, size: 18, color: AppColors.brand600),
              ),
            ),
          ),
        ),
        title: const Text('Settings',
          style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: ListView(children: [

        // ── Profile summary tile ───────────────────────────────────────
        if (profile != null)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surface800 : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: isDark ? AppColors.surface700 : AppColors.surface100),
              boxShadow: isDark ? [] : [
                BoxShadow(color: AppColors.brand900.withValues(alpha: 0.06), blurRadius: 14, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(children: [
              Stack(clipBehavior: Clip.none, children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: AppColors.brand600.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 3))],
                  ),
                  child: AvatarWidget(imageUrl: profile.avatarUrl, name: profile.fullName, size: 52),
                ),
                Positioned(
                  bottom: 0, right: 0,
                  child: Container(
                    width: 13, height: 13,
                    decoration: BoxDecoration(
                      color: AppColors.success500,
                      shape: BoxShape.circle,
                      border: Border.all(color: isDark ? AppColors.surface800 : Colors.white, width: 2),
                    ),
                  ),
                ),
              ]),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(profile.fullName ?? 'User',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.surface900)),
                const SizedBox(height: 2),
                Text(profile.headline ?? (profile.role.name == 'recruiter' ? 'Recruiter' : 'Job Seeker'),
                  style: TextStyle(fontSize: 13,
                    color: isDark ? AppColors.surface400 : AppColors.surface500)),
              ])),
              GestureDetector(
                onTap: () => context.go('/profile'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.brand600.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.visibility_outlined, size: 13, color: AppColors.brand600),
                    const SizedBox(width: 4),
                    const Text('View', style: TextStyle(color: AppColors.brand600,
                      fontSize: 12.5, fontWeight: FontWeight.w700)),
                  ]),
                ),
              ),
            ]),
          ),

        _SectionHeader('Account'),
        _SettingsCard(children: [
          _SettingsRow(
            icon: Icons.person_outlined, color: AppColors.brand600,
            title: 'Edit Profile', onTap: () => context.go('/profile'),
          ),
          _SettingsRow(
            icon: Icons.lock_outlined, color: AppColors.accent500,
            title: 'Change Password', onTap: () => context.go('/forgot-password'),
          ),
          _SettingsRow(
            icon: Icons.notifications_outlined, color: AppColors.warning500,
            title: 'Notifications', onTap: () => context.go('/notifications'),
          ),
        ]),

        _SectionHeader('Privacy'),
        if (profile != null)
          _SettingsCard(children: [_VisibilityRow(profile: profile)]),

        _SectionHeader('About'),
        _SettingsCard(children: [
          _SettingsRow(
            icon: Icons.info_outlined, color: AppColors.purple500,
            title: 'Version', showChevron: false,
            trailing: const Text('1.0.0', style: TextStyle(
              color: AppColors.surface400,
              fontWeight: FontWeight.w600)),
          ),
          _SettingsRow(
            icon: Icons.privacy_tip_outlined, color: AppColors.teal500,
            title: 'Privacy Policy',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const _LegalScreen(
                title: 'Privacy Policy', body: _privacyPolicyText))),
          ),
          _SettingsRow(
            icon: Icons.description_outlined, color: AppColors.warning600,
            title: 'Terms of Service',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const _LegalScreen(
                title: 'Terms of Service', body: _termsOfServiceText))),
          ),
        ]),

        // ── Sign out ───────────────────────────────────────────────────
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: OutlinedButton.icon(
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) context.go('/login');
            },
            icon: const Icon(Icons.logout, size: 18, color: AppColors.danger500),
            label: const Text('Sign Out',
              style: TextStyle(color: AppColors.danger500, fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.danger500),
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            ),
          ),
        ),
        const SizedBox(height: 32),
      ]),
    );
  }
}

// ── Settings row + card ───────────────────────────────────────────────────
class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface800 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.surface700 : AppColors.surface100),
        boxShadow: isDark ? [] : [
          BoxShadow(color: AppColors.brand900.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(children: [
        for (int i = 0; i < children.length; i++) ...[
          children[i],
          if (i != children.length - 1)
            Divider(height: 1, indent: 62,
              color: isDark ? AppColors.surface700 : AppColors.surface100),
        ],
      ]),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool showChevron;
  final VoidCallback? onTap;
  const _SettingsRow({
    required this.icon, required this.color, required this.title,
    this.subtitle, this.trailing, this.showChevron = true, this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.18 : 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColors.surface900)),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(subtitle!, style: TextStyle(fontSize: 12,
                color: isDark ? AppColors.surface400 : AppColors.surface500)),
            ],
          ])),
          const SizedBox(width: 8),
          if (trailing != null)
            trailing!
          else if (showChevron)
            Icon(Icons.chevron_right, size: 18,
              color: isDark ? AppColors.surface600 : AppColors.surface300),
        ]),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(title.toUpperCase(),
        style: TextStyle(
          fontSize: 11, fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: isDark ? AppColors.surface500 : AppColors.surface400,
        )),
    );
  }
}

// ── Profile Visibility row — live toggle, persisted to Supabase ────────────
// Requires the `is_public` column (see add_profile_visibility.sql).
class _VisibilityRow extends ConsumerStatefulWidget {
  final Profile profile;
  const _VisibilityRow({required this.profile});
  @override
  ConsumerState<_VisibilityRow> createState() => _VisibilityRowState();
}

class _VisibilityRowState extends ConsumerState<_VisibilityRow> {
  late bool _public;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _public = widget.profile.isPublic;
  }

  @override
  void didUpdateWidget(covariant _VisibilityRow old) {
    super.didUpdateWidget(old);
    if (!_saving) _public = widget.profile.isPublic;
  }

  Future<void> _toggle(bool value) async {
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;
    setState(() { _public = value; _saving = true; });
    try {
      await ref.read(authServiceProvider).updateProfile(user.id, {'is_public': value});
      ref.invalidate(profileProvider);
    } catch (e) {
      if (mounted) {
        setState(() => _public = !value); // revert on failure
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not update visibility: $e'),
          backgroundColor: AppColors.danger500));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: AppColors.success500.withValues(alpha: isDark ? 0.18 : 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.visibility_outlined, size: 18, color: AppColors.success500),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Profile Visibility', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : AppColors.surface900)),
          const SizedBox(height: 2),
          Text(
            _public ? 'Public — visible to all recruiters' : 'Private — hidden from recruiter search',
            style: TextStyle(fontSize: 12,
              color: isDark ? AppColors.surface400 : AppColors.surface500)),
        ])),
        const SizedBox(width: 8),
        _saving
            ? const SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2))
            : Switch(
                value: _public,
                onChanged: _toggle,
                activeColor: AppColors.success500,
              ),
      ]),
    );
  }
}

// ── Legal content screen (Privacy Policy / Terms of Service) ───────────────
class _LegalScreen extends StatelessWidget {
  final String title;
  final String body;
  const _LegalScreen({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.surface950 : AppColors.warmBg,
      appBar: AppBar(title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Text(body,
          style: TextStyle(fontSize: 14, height: 1.7,
            color: isDark ? AppColors.surface300 : AppColors.surface700)),
      ),
    );
  }
}

// Placeholder legal copy — replace with reviewed text before shipping.
const _privacyPolicyText = '''
Last updated: 2026

SkillConnect ("we", "us") connects job seekers and recruiters. This policy explains what we collect and how we use it.

Information We Collect
We collect the details you provide when you create a profile — name, contact information, work history, resume, and any photos or links you add. If you're a recruiter, we also collect your company details. We automatically collect basic usage data (device type, app version, crash logs) to keep the app working.

How We Use It
We use your information to operate your account, match job seekers with relevant postings, let recruiters review applicants, and send you notifications about your applications or job postings. We do not sell your personal data.

Sharing
Your profile is visible to recruiters (or job seekers, if you're a recruiter posting a job) only while set to Public in Settings. Switching your profile to Private removes it from search and browse results.

Data Retention & Your Rights
You can edit or delete most of your profile information at any time from the Profile screen. You can request full account deletion by contacting support. We retain data only as long as needed to provide the service.

Contact
Questions about this policy can be sent to privacy@skillconnect.app.
''';

const _termsOfServiceText = '''
Last updated: 2026

By creating an account on SkillConnect, you agree to these terms.

Your Account
You're responsible for keeping your login credentials secure and for the accuracy of the information on your profile. You must be legally eligible to work (as a job seeker) or to hire (as a recruiter) in the jurisdictions where you use the app.

Acceptable Use
Don't post false, misleading, or discriminatory job listings or profile information. Don't use the app to harass other users, scrape data, or attempt to bypass its security. We may suspend or terminate accounts that violate these terms.

Job Postings & Applications
Recruiters are solely responsible for the accuracy and legality of the jobs they post. SkillConnect does not guarantee employment outcomes and is not a party to any employment relationship formed between users.

Content
You keep ownership of the content you upload (resumes, photos, job descriptions), but you grant us a license to display it within the app to the relevant audience (recruiters or job seekers) as part of the service.

Termination
You may stop using SkillConnect at any time by signing out and requesting account deletion. We may suspend accounts that violate these terms or applicable law.

Disclaimer
The app is provided "as is" without warranties of any kind. We are not liable for indirect or consequential damages arising from your use of the app.

Contact
Questions about these terms can be sent to legal@skillconnect.app.
''';
