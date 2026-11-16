import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/models.dart';
import '../../../data/services/auth_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/avatar_widget.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark       = Theme.of(context).brightness == Brightness.dark;
    final profileAsync = ref.watch(profileProvider);

    return profileAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error:   (e, _) => Scaffold(body: Center(child: Text('$e'))),
      data:    (profile) => _ProfileBody(profile: profile, isDark: isDark),
    );
  }
}

class _ProfileBody extends ConsumerWidget {
  final Profile? profile;
  final bool isDark;
  const _ProfileBody({required this.profile, required this.isDark});

  bool get _isRecruiter =>
      profile?.role == UserRole.recruiter || profile?.role == UserRole.admin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const coverHeight  = 180.0;
    const avatarSize   = 88.0;
    const avatarBorder = 4.0;
    const avatarTotal  = avatarSize + avatarBorder * 2; // 96
    const overlap      = avatarTotal / 2;               // 48 — how much avatar dips below cover

    return Scaffold(
      backgroundColor: isDark ? AppColors.surface950 : AppColors.warmBg,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Cover + Avatar Stack ─────────────────────────────────
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Gradient cover — with soft multi-color blobs, clipped so
                // they never bleed past the banner itself.
                ClipRect(
                  child: Container(
                    height: coverHeight,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.purple500, AppColors.accent500],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(top: -34, right: -24,
                          child: _blob(150, Colors.white.withValues(alpha: 0.10))),
                        Positioned(bottom: -56, left: -26,
                          child: _blob(130, AppColors.teal400.withValues(alpha: 0.30))),
                        Positioned(top: 18, left: 130,
                          child: _blob(50, AppColors.warning500.withValues(alpha: 0.28))),
                      ],
                    ),
                  ),
                ),

                // Settings button
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  right: 12,
                  child: IconButton(
                    icon: const Icon(Icons.settings_outlined, color: Colors.white),
                    onPressed: () => context.push('/settings'),
                  ),
                ),

                // Avatar — centred on the cover/content boundary, tap to change photo
                Positioned(
                  bottom: -overlap,
                  left: 20,
                  child: _AvatarPicker(
                    profile: profile,
                    isDark: isDark,
                    isRecruiter: _isRecruiter,
                    avatarSize: avatarSize,
                    avatarBorder: avatarBorder,
                  ),
                ),
              ],
            ),

            // ── Name / Edit row ──────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(20, overlap + 10, 16, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Flexible(
                            child: Text(
                              profile?.fullName ?? 'Your Name',
                              style: TextStyle(
                                fontSize: 22, fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : AppColors.surface900,
                              ),
                            ),
                          ),
                          if (profile?.isVerified == true) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.verified, color: AppColors.accent500, size: 20),
                          ],
                        ]),
                        if (profile?.headline != null && profile!.headline!.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(profile!.headline!,
                            style: TextStyle(fontSize: 14,
                              color: isDark ? AppColors.surface400 : AppColors.surface500)),
                        ],
                        if (profile?.location != null && profile!.location!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(children: [
                            Icon(Icons.location_on_outlined, size: 13,
                              color: isDark ? AppColors.surface500 : AppColors.surface400),
                            const SizedBox(width: 3),
                            Text(profile!.location!,
                              style: TextStyle(fontSize: 13,
                                color: isDark ? AppColors.surface500 : AppColors.surface400)),
                          ]),
                        ],
                        const SizedBox(height: 8),
                        // Role badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _isRecruiter
                                ? AppColors.accent500.withValues(alpha: 0.1)
                                : AppColors.brand600.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _isRecruiter
                                  ? AppColors.accent500.withValues(alpha: 0.3)
                                  : AppColors.brand600.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            _isRecruiter ? '🏢 Recruiter' : '🎓 Job Seeker',
                            style: TextStyle(
                              color: _isRecruiter ? AppColors.accent500 : AppColors.brand600,
                              fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _openEditSheet(context, ref),
                    icon: const Icon(Icons.edit_outlined, size: 15),
                    label: const Text('Edit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brand600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Profile Strength ─────────────────────────────────────
            _Card(isDark: isDark, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Builder(builder: (_) {
                final score = profile?.profileScore ?? 0;
                final scoreColor = score < 40 ? AppColors.danger500
                  : score < 70 ? AppColors.warning500
                  : AppColors.success500;
                return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Profile Strength',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.surface900)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: scoreColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('$score%',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                          color: scoreColor)),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: score / 100,
                      backgroundColor: isDark ? AppColors.surface700 : AppColors.surface100,
                      valueColor: AlwaysStoppedAnimation(scoreColor),
                      minHeight: 8,
                    ),
                  ),
                ]);
              }),
              const SizedBox(height: 8),
              Text(_profileTip(profile?.profileScore ?? 0),
                style: TextStyle(fontSize: 12,
                  color: isDark ? AppColors.surface400 : AppColors.surface500)),
            ])),

            // ── About ────────────────────────────────────────────────
            if (profile?.bio != null && profile!.bio!.isNotEmpty)
              _Card(isDark: isDark, title: 'About',
                child: Text(profile!.bio!,
                  style: TextStyle(fontSize: 14, height: 1.65,
                    color: isDark ? AppColors.surface300 : AppColors.surface600))),

            // ── RECRUITER: HR + Company Details ──────────────────────
            if (_isRecruiter) ...[
              _Card(
                isDark: isDark, title: 'HR Details',
                action: _editBtn(() => _openEditSheet(context, ref)),
                child: Column(children: [
                  _DetailRow(icon: Icons.person_outline,   label: 'HR Name',       value: profile?.fullName, isDark: isDark, color: AppColors.brand600),
                  _DetailRow(icon: Icons.badge_outlined,   label: 'Designation',   value: profile?.headline, isDark: isDark, color: AppColors.accent500),
                  _DetailRow(icon: Icons.phone_outlined,   label: 'Contact',       value: profile?.phone,    isDark: isDark, color: AppColors.teal500),
                  _DetailRow(icon: Icons.location_on_outlined, label: 'Location',  value: profile?.location, isDark: isDark, color: AppColors.warning600, isLast: true),
                ]),
              ),
              _Card(
                isDark: isDark, title: 'Company Details',
                action: _editBtn(() => _openEditSheet(context, ref)),
                child: Column(children: [
                  _DetailRow(icon: Icons.business_outlined,       label: 'Company Name',    value: profile?.username,    isDark: isDark, color: AppColors.purple500),
                  _DetailRow(icon: Icons.language_outlined,        label: 'Website',         value: profile?.website,     isDark: isDark, color: AppColors.accent500),
                  _DetailRow(icon: Icons.business_center_outlined, label: 'LinkedIn',        value: profile?.linkedinUrl, isDark: isDark, color: AppColors.teal500, isLast: true),
                ]),
              ),
            ],

            // ── STUDENT: Personal Details + Resume ───────────────────
            if (!_isRecruiter) ...[
              _Card(
                isDark: isDark, title: 'Personal Details',
                action: _editBtn(() => _openEditSheet(context, ref)),
                child: Column(children: [
                  _DetailRow(icon: Icons.person_outline,           label: 'Full Name', value: profile?.fullName,    isDark: isDark, color: AppColors.brand600),
                  _DetailRow(icon: Icons.work_outline,             label: 'Headline',  value: profile?.headline,    isDark: isDark, color: AppColors.accent500),
                  _DetailRow(icon: Icons.phone_outlined,           label: 'Phone',     value: profile?.phone,       isDark: isDark, color: AppColors.teal500),
                  _DetailRow(icon: Icons.location_on_outlined,     label: 'Location',  value: profile?.location,    isDark: isDark, color: AppColors.warning600),
                  _DetailRow(icon: Icons.language_outlined,         label: 'Website',   value: profile?.website,     isDark: isDark, color: AppColors.purple500),
                  _DetailRow(icon: Icons.code_outlined,            label: 'GitHub',    value: profile?.githubUrl,   isDark: isDark, color: AppColors.brand600),
                  _DetailRow(icon: Icons.business_center_outlined, label: 'LinkedIn',  value: profile?.linkedinUrl, isDark: isDark, color: AppColors.accent500, isLast: true),
                ]),
              ),
              _Card(isDark: isDark, title: 'Resume',
                child: _ResumeSection(profile: profile, isDark: isDark)),

              if (profile?.openToWork == true)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.success50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.success500.withValues(alpha: 0.3)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.check_circle_outline, color: AppColors.success600, size: 20),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text('#OpenToWork — Your badge is visible to recruiters',
                          style: TextStyle(color: AppColors.success600,
                            fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                    ]),
                  ),
                ),
            ],

            // ── Sign Out ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
              child: OutlinedButton.icon(
                onPressed: () async {
                  await ref.read(authServiceProvider).signOut();
                  if (context.mounted) context.go('/login');
                },
                icon: const Icon(Icons.logout, size: 17),
                label: const Text('Sign Out'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  foregroundColor: AppColors.danger500,
                  side: const BorderSide(color: AppColors.danger500),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _blob(double size, Color color) => IgnorePointer(
    child: Container(
      width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    ),
  );

  Widget _editBtn(VoidCallback onTap) => TextButton(
    onPressed: onTap,
    style: TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      minimumSize: Size.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
    child: const Text('Edit', style: TextStyle(fontSize: 13)),
  );

  String _profileTip(int score) {
    if (score == 0)  return 'Add your details to boost your profile';
    if (score < 40)  return 'Add a headline and bio to stand out';
    if (score < 70)  return 'Complete your contact details';
    if (score < 100) return 'Add links to complete your profile';
    return 'Your profile is 100% complete 🎉';
  }

  void _openEditSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditProfileSheet(profile: profile),
    );
  }
}

// ── Avatar Picker (tap the avatar or badge to change the photo) ─────────────
class _AvatarPicker extends ConsumerStatefulWidget {
  final Profile? profile;
  final bool isDark;
  final bool isRecruiter;
  final double avatarSize;
  final double avatarBorder;
  const _AvatarPicker({
    required this.profile,
    required this.isDark,
    required this.isRecruiter,
    required this.avatarSize,
    required this.avatarBorder,
  });

  @override
  ConsumerState<_AvatarPicker> createState() => _AvatarPickerState();
}

class _AvatarPickerState extends ConsumerState<_AvatarPicker> {
  bool _uploading = false;

  Future<void> _pick() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image, withData: true);
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) return;
    final ext = (file.extension?.isNotEmpty == true ? file.extension! : 'jpg').toLowerCase();

    setState(() => _uploading = true);
    try {
      final user = ref.read(currentUserProvider).value;
      if (user == null) return;
      await ref.read(authServiceProvider).uploadAvatar(user.id, bytes.toList(), ext);
      ref.invalidate(profileProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Profile photo updated!'), backgroundColor: AppColors.success500));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Upload failed: $e'), backgroundColor: AppColors.danger500));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _uploading ? null : _pick,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: widget.isDark ? AppColors.surface950 : Colors.white,
                width: widget.avatarBorder,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: AvatarWidget(
              imageUrl: widget.profile?.avatarUrl,
              name: widget.profile?.fullName,
              size: widget.avatarSize,
              color: widget.isRecruiter ? AppColors.accent500 : AppColors.brand600,
            ),
          ),
          if (_uploading)
            Positioned.fill(
              child: Container(
                margin: EdgeInsets.all(widget.avatarBorder),
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black45),
                child: const Center(
                  child: SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Material(
              color: AppColors.brand600,
              shape: const CircleBorder(),
              elevation: 2,
              shadowColor: Colors.black.withValues(alpha: 0.2),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _uploading ? null : _pick,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.isDark ? AppColors.surface950 : Colors.white,
                      width: 2,
                    ),
                  ),
                  child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable Card ──────────────────────────────────────────────────────────
class _Card extends StatelessWidget {
  final bool isDark; final String? title; final Widget? action; final Widget child;
  const _Card({required this.isDark, this.title, this.action, required this.child});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: isDark ? AppColors.surface800 : Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: isDark ? [] : [
        BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2)),
      ],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (title != null) ...[
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(title!, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppColors.surface900)),
          if (action != null) action!,
        ]),
        const SizedBox(height: 14),
      ],
      child,
    ]),
  );
}

// ── Detail Row ─────────────────────────────────────────────────────────────
class _DetailRow extends StatelessWidget {
  final IconData icon; final String label; final String? value;
  final bool isDark; final bool isLast; final Color color;
  const _DetailRow({required this.icon, required this.label,
    required this.value, required this.isDark, this.isLast = false,
    this.color = AppColors.brand600});

  bool get _hasValue => value != null && value!.isNotEmpty;

  @override
  Widget build(BuildContext context) => Column(children: [
    Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.18 : 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 17, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
            color: isDark ? AppColors.surface500 : AppColors.surface400, letterSpacing: 0.3)),
          const SizedBox(height: 2),
          Text(_hasValue ? value! : 'Not added',
            style: TextStyle(fontSize: 14,
              color: _hasValue
                ? (isDark ? Colors.white : AppColors.surface800)
                : (isDark ? AppColors.surface600 : AppColors.surface300))),
        ])),
      ]),
    ),
    if (!isLast) Divider(height: 1, color: isDark ? AppColors.surface700 : AppColors.surface100),
  ]);
}

// ── Resume Section ─────────────────────────────────────────────────────────
class _ResumeSection extends ConsumerStatefulWidget {
  final Profile? profile; final bool isDark;
  const _ResumeSection({required this.profile, required this.isDark});
  @override
  ConsumerState<_ResumeSection> createState() => _ResumeSectionState();
}

class _ResumeSectionState extends ConsumerState<_ResumeSection> {
  bool _uploading = false;

  Future<void> _pick() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom, allowedExtensions: ['pdf', 'doc', 'docx'], withData: true);
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) return;

    setState(() => _uploading = true);
    try {
      final user = ref.read(currentUserProvider).value;
      if (user == null) return;
      await ref.read(authServiceProvider).uploadResume(user.id, bytes.toList(), file.name);
      ref.invalidate(profileProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Resume uploaded!'), backgroundColor: AppColors.success500));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Upload failed: $e'), backgroundColor: AppColors.danger500));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasResume = widget.profile?.resumeUrl?.isNotEmpty == true;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (hasResume) ...[
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.isDark ? AppColors.surface700 : AppColors.surface50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: widget.isDark ? AppColors.surface600 : AppColors.surface200)),
          child: Row(children: [
            Container(width: 44, height: 44,
              decoration: BoxDecoration(color: AppColors.danger500.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.picture_as_pdf, color: AppColors.danger500, size: 24)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Resume uploaded', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                color: widget.isDark ? Colors.white : AppColors.surface900)),
              Text('Tap to view', style: TextStyle(fontSize: 12,
                color: widget.isDark ? AppColors.surface400 : AppColors.surface500)),
            ])),
            IconButton(
              icon: Icon(Icons.open_in_new, size: 18,
                color: widget.isDark ? AppColors.surface400 : AppColors.surface500),
              onPressed: () async {
                final url = Uri.parse(widget.profile!.resumeUrl!);
                if (await canLaunchUrl(url)) launchUrl(url, mode: LaunchMode.externalApplication);
              }),
          ]),
        ),
        const SizedBox(height: 12),
      ] else ...[
        Container(
          width: double.infinity, padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: widget.isDark ? AppColors.surface700 : AppColors.surface50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: widget.isDark ? AppColors.surface600 : AppColors.surface200)),
          child: Column(children: [
            Icon(Icons.upload_file_outlined, size: 36,
              color: widget.isDark ? AppColors.surface500 : AppColors.surface400),
            const SizedBox(height: 8),
            Text('No resume uploaded', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
              color: widget.isDark ? AppColors.surface400 : AppColors.surface500)),
            const SizedBox(height: 2),
            Text('PDF, DOC or DOCX supported', style: TextStyle(fontSize: 12,
              color: widget.isDark ? AppColors.surface600 : AppColors.surface400)),
          ]),
        ),
        const SizedBox(height: 12),
      ],
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _uploading ? null : _pick,
          icon: _uploading
              ? const SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Icon(hasResume ? Icons.refresh_outlined : Icons.upload_file_outlined, size: 18),
          label: Text(_uploading ? 'Uploading…' : hasResume ? 'Replace Resume' : 'Upload Resume'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brand600, foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
        ),
      ),
    ]);
  }
}

// ── Edit Profile Sheet ─────────────────────────────────────────────────────
class _EditProfileSheet extends ConsumerStatefulWidget {
  final Profile? profile;
  const _EditProfileSheet({required this.profile});
  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name, _headline, _bio,
      _phone, _location, _website, _company, _linkedin, _github;
  bool _openToWork = false, _saving = false;

  bool get _isRecruiter =>
      widget.profile?.role == UserRole.recruiter || widget.profile?.role == UserRole.admin;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _name     = TextEditingController(text: p?.fullName    ?? '');
    _headline = TextEditingController(text: p?.headline    ?? '');
    _bio      = TextEditingController(text: p?.bio         ?? '');
    _phone    = TextEditingController(text: p?.phone       ?? '');
    _location = TextEditingController(text: p?.location    ?? '');
    _website  = TextEditingController(text: p?.website     ?? '');
    _company  = TextEditingController(text: p?.username    ?? '');
    _linkedin = TextEditingController(text: p?.linkedinUrl ?? '');
    _github   = TextEditingController(text: p?.githubUrl   ?? '');
    _openToWork = p?.openToWork ?? false;
  }

  @override
  void dispose() {
    for (final c in [_name, _headline, _bio, _phone, _location, _website, _company, _linkedin, _github]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final user = ref.read(currentUserProvider).value;
      if (user == null) return;
      final data = <String, dynamic>{
        'full_name': _name.text.trim(), 'headline': _headline.text.trim(),
        'bio': _bio.text.trim(), 'phone': _phone.text.trim(),
        'location': _location.text.trim(), 'website': _website.text.trim(),
        'linkedin_url': _linkedin.text.trim(),
      };
      if (_isRecruiter) {
        data['username'] = _company.text.trim();
      } else {
        data['github_url'] = _github.text.trim();
        data['open_to_work'] = _openToWork;
      }
      await ref.read(authServiceProvider).updateProfile(user.id, data);
      ref.invalidate(profileProvider);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Profile updated!'), backgroundColor: AppColors.success500));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'), backgroundColor: AppColors.danger500));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DraggableScrollableSheet(
      initialChildSize: 0.93, maxChildSize: 0.97, minChildSize: 0.5,
      builder: (_, sc) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surface900 : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(children: [
          Container(margin: const EdgeInsets.only(top: 10), width: 36, height: 4,
            decoration: BoxDecoration(
              color: isDark ? AppColors.surface600 : AppColors.surface300,
              borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 12, 0),
            child: Row(children: [
              Expanded(child: Text('Edit Profile',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.surface900))),
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              const SizedBox(width: 4),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brand600, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0),
                child: _saving
                    ? const SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ]),
          ),
          Divider(height: 20, color: isDark ? AppColors.surface700 : AppColors.surface100),
          Expanded(
            child: SingleChildScrollView(
              controller: sc,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              child: Form(
                key: _form,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (_isRecruiter) ...[
                    _sectionHeader('HR Details', isDark),
                    _field(_name,     'HR Full Name *',   Icons.person_outline,   required: true),
                    _field(_headline, 'Designation',      Icons.badge_outlined,
                      hint: 'e.g. HR Manager, Talent Acquisition'),
                    _field(_phone,    'Contact Number',   Icons.phone_outlined,   keyboard: TextInputType.phone),
                    _field(_location, 'Office Location',  Icons.location_on_outlined, hint: 'City, Country'),
                    _sectionHeader('Company Details', isDark),
                    _field(_company,  'Company Name',     Icons.business_outlined, hint: 'e.g. Google India'),
                    _field(_website,  'Company Website',  Icons.language_outlined, keyboard: TextInputType.url),
                    _field(_linkedin, 'LinkedIn Profile', Icons.business_center_outlined, keyboard: TextInputType.url),
                    _sectionHeader('About', isDark),
                    _field(_bio, 'Company / HR Bio', Icons.notes_outlined, maxLines: 4,
                      hint: 'Describe your company or role…'),
                  ] else ...[
                    _sectionHeader('Basic Info', isDark),
                    _field(_name,     'Full Name *',  Icons.person_outline, required: true),
                    _field(_headline, 'Headline',     Icons.work_outline,
                      hint: 'e.g. Flutter Developer | Open to Work'),
                    _field(_bio,      'About / Bio',  Icons.notes_outlined, maxLines: 4,
                      hint: 'Tell recruiters about yourself…'),
                    _sectionHeader('Contact', isDark),
                    _field(_phone,    'Phone Number', Icons.phone_outlined, keyboard: TextInputType.phone),
                    _field(_location, 'Location',     Icons.location_on_outlined, hint: 'City, Country'),
                    _sectionHeader('Links', isDark),
                    _field(_website,  'Website / Portfolio', Icons.language_outlined, keyboard: TextInputType.url),
                    _field(_github,   'GitHub URL',   Icons.code_outlined, keyboard: TextInputType.url),
                    _field(_linkedin, 'LinkedIn URL', Icons.business_center_outlined, keyboard: TextInputType.url),
                    _sectionHeader('Job Preferences', isDark),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surface800 : AppColors.surface50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? AppColors.surface700 : AppColors.surface200)),
                      child: SwitchListTile(
                        value: _openToWork,
                        onChanged: (v) => setState(() => _openToWork = v),
                        title: Text('Open to Work', style: TextStyle(fontWeight: FontWeight.w600,
                          fontSize: 14, color: isDark ? Colors.white : AppColors.surface900)),
                        subtitle: Text('Show the #OpenToWork badge on your profile',
                          style: TextStyle(fontSize: 12,
                            color: isDark ? AppColors.surface400 : AppColors.surface500)),
                        activeColor: AppColors.brand600,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _sectionHeader(String label, bool isDark) => Padding(
    padding: const EdgeInsets.only(top: 4, bottom: 12),
    child: Text(label.toUpperCase(),
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1,
        color: isDark ? AppColors.surface500 : AppColors.surface400)));

  Widget _field(TextEditingController ctrl, String label, IconData icon, {
    bool required = false, String? hint, int maxLines = 1,
    TextInputType keyboard = TextInputType.text,
  }) =>
    Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: ctrl, maxLines: maxLines, keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label, hintText: hint, prefixIcon: Icon(icon, size: 18),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.surface700 : AppColors.surface200)),
          filled: true,
          fillColor: Theme.of(context).brightness == Brightness.dark
              ? AppColors.surface800 : AppColors.surface50,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
            : null,
      ),
    );
}
