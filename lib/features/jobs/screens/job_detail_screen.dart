import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/helpers.dart';
import '../../../data/models/models.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/database_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/avatar_widget.dart';

// ── Providers ──────────────────────────────────────────────────────────────

final _jobDetailProvider = FutureProvider.autoDispose.family<Job?, String>((ref, id) {
  return DatabaseService().fetchJob(id);
});

final _savedJobIdsProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return [];
  return DatabaseService().fetchSavedJobIds(user.id);
});

final _appliedJobIdsProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return [];
  return DatabaseService().fetchAppliedJobIds(user.id);
});

/// Fetches the specific Application this user made for this job (null if not applied).
/// Uses empty string for userId when unauthenticated so ref.watch is always unconditional.
final _myApplicationForJobProvider = FutureProvider.autoDispose
    .family<Application?, ({String userId, String jobId})>((ref, params) async {
  if (params.userId.isEmpty) return null;
  return DatabaseService().fetchApplicationForJob(params.userId, params.jobId);
});

// ── Screen ──────────────────────────────────────────────────────────────────

class JobDetailScreen extends ConsumerStatefulWidget {
  final String jobId;
  const JobDetailScreen({super.key, required this.jobId});

  @override
  ConsumerState<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends ConsumerState<JobDetailScreen> {
  bool _savingToggle = false;

  Future<void> _toggleSave(String userId, bool isSaved) async {
    if (_savingToggle) return;
    setState(() => _savingToggle = true);
    try {
      final db = DatabaseService();
      if (isSaved) {
        await db.unsaveJob(userId, widget.jobId);
      } else {
        await db.saveJob(userId, widget.jobId);
      }
      ref.invalidate(_savedJobIdsProvider);
    } finally {
      if (mounted) setState(() => _savingToggle = false);
    }
  }

  void _showApplyDialog(Job job) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ApplySheet(job: job, jobId: widget.jobId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark      = Theme.of(context).brightness == Brightness.dark;
    final jobAsync    = ref.watch(_jobDetailProvider(widget.jobId));
    final userId      = ref.watch(currentUserProvider).value?.id;
    final profile     = ref.watch(profileProvider).value;
    final isRecruiter = profile?.role == UserRole.recruiter || profile?.role == UserRole.admin;

    return jobAsync.when(
      loading: () => Scaffold(
        backgroundColor: isDark ? AppColors.surface950 : AppColors.warmBg,
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('$e')),
      ),
      data: (job) {
        if (job == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Job Not Found')),
            body: const Center(child: Text('This job listing is no longer available.')),
          );
        }

        final savedAsync   = ref.watch(_savedJobIdsProvider);
        final appliedAsync = ref.watch(_appliedJobIdsProvider);
        final myAppAsync   = ref.watch(_myApplicationForJobProvider(
          (userId: userId ?? '', jobId: widget.jobId)));

        final isSaved   = savedAsync.value?.contains(widget.jobId) ?? false;
        final isApplied = appliedAsync.value?.contains(widget.jobId) ?? false;
        // Same rotating accent used on the Jobs Browse card for this job,
        // so the color stays consistent wherever this listing appears.
        final accent = AppColors.cardPalette[job.id.hashCode.abs() % AppColors.cardPalette.length];

        return Scaffold(
          backgroundColor: isDark ? AppColors.surface950 : AppColors.warmBg,
          body: CustomScrollView(
            slivers: [
              // ── App Bar ────────────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 0,
                floating: true,
                snap: true,
                backgroundColor: isDark ? AppColors.surface900 : Colors.white,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                actions: [
                  if (userId != null && !isRecruiter)
                    _savingToggle
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2)),
                          )
                        : IconButton(
                            icon: Icon(
                              isSaved ? Icons.bookmark : Icons.bookmark_border,
                              color: isSaved ? AppColors.brand600 : null,
                            ),
                            onPressed: () => _toggleSave(userId, isSaved),
                          ),
                  IconButton(
                    icon: const Icon(Icons.share_outlined),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Share link copied!')));
                    },
                  ),
                ],
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // ── Company Header Card ──────────────────────────
                      _Card(isDark: isDark, child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.28),
                                  blurRadius: 12, offset: const Offset(0, 5))],
                              ),
                              child: AvatarWidget(
                                imageUrl: job.company?.logoUrl,
                                name: job.company?.name ?? job.title,
                                size: 56,
                                radius: 16,
                                color: accent,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(job.title,
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                                    color: isDark ? Colors.white : AppColors.surface900)),
                                const SizedBox(height: 4),
                                if (job.company != null)
                                  Text(job.company!.name,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                                      color: AppColors.accent500)),
                                const SizedBox(height: 8),
                                Wrap(spacing: 6, runSpacing: 6, children: [
                                  _Tag(jobTypeLabel(job.type), color: AppColors.accent500),
                                  _Tag(jobModeLabel(job.mode), color: AppColors.purple500),
                                  _Tag(job.level[0].toUpperCase() + job.level.substring(1), color: AppColors.success500),
                                ]),
                              ],
                            )),
                          ]),
                          const SizedBox(height: 16),
                          Divider(color: isDark ? AppColors.surface700 : AppColors.surface100),
                          const SizedBox(height: 12),

                          // Quick stats row
                          Row(children: [
                            _Stat(Icons.location_on_outlined,
                              job.location ?? (job.mode == 'remote' ? 'Remote' : 'Not specified'),
                              isDark),
                            const SizedBox(width: 20),
                            _Stat(Icons.people_outline,
                              '${job.applicationsCount} applied', isDark),
                            const SizedBox(width: 20),
                            _Stat(Icons.work_history_outlined,
                              '${job.openings} opening${job.openings > 1 ? 's' : ''}', isDark),
                          ]),

                          if (job.salaryMin != null || job.salaryMax != null) ...[
                            const SizedBox(height: 12),
                            Row(children: [
                              const Icon(Icons.payments_outlined, size: 16, color: AppColors.success500),
                              const SizedBox(width: 6),
                              Text(formatSalary(job.salaryMin, job.salaryMax, unit: job.salaryUnit),
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                                  color: AppColors.success600)),
                            ]),
                          ],

                          const SizedBox(height: 12),
                          Row(children: [
                            Icon(Icons.schedule_outlined, size: 13,
                              color: isDark ? AppColors.surface500 : AppColors.surface400),
                            const SizedBox(width: 4),
                            Text('Posted ${timeAgo(job.createdAt)}',
                              style: TextStyle(fontSize: 12,
                                color: isDark ? AppColors.surface500 : AppColors.surface400)),
                          ]),
                        ],
                      )),

                      const SizedBox(height: 12),

                      // ── Description ──────────────────────────────────
                      _Card(isDark: isDark, child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _CardHeader('Job Description', Icons.description_outlined,
                            AppColors.brand600, isDark),
                          const SizedBox(height: 12),
                          Text(job.description,
                            style: TextStyle(fontSize: 14, height: 1.7,
                              color: isDark ? AppColors.surface300 : AppColors.surface700)),
                        ],
                      )),

                      const SizedBox(height: 12),

                      // ── Required Skills ───────────────────────────────
                      if (job.skillsRequired.isNotEmpty) ...[
                        _Card(isDark: isDark, child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _CardHeader('Required Skills', Icons.sell_outlined,
                              AppColors.success500, isDark),
                            const SizedBox(height: 14),
                            Wrap(spacing: 8, runSpacing: 8,
                              children: job.skillsRequired.map((s) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                decoration: BoxDecoration(
                                  color: AppColors.success500.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppColors.success500.withValues(alpha: 0.3)),
                                ),
                                child: Text(s, style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600,
                                  color: AppColors.success600)),
                              )).toList(),
                            ),
                          ],
                        )),
                        const SizedBox(height: 12),
                      ],

                      // ── Company Info ──────────────────────────────────
                      if (job.company != null) ...[
                        _Card(isDark: isDark, child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _CardHeader('About the Company', Icons.apartment_outlined,
                              AppColors.accent500, isDark),
                            const SizedBox(height: 14),
                            Row(children: [
                              AvatarWidget(
                                imageUrl: job.company!.logoUrl,
                                name: job.company!.name,
                                size: 44,
                                radius: 12,
                                color: AppColors.purple500,
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(job.company!.name,
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white : AppColors.surface900)),
                                  if (job.company!.industry != null)
                                    Text(job.company!.industry!,
                                      style: TextStyle(fontSize: 13,
                                        color: isDark ? AppColors.surface400 : AppColors.surface500)),
                                ],
                              )),
                              if (job.company!.isVerified)
                                const Icon(Icons.verified, size: 18, color: AppColors.accent500),
                            ]),
                            if (job.company!.description != null) ...[
                              const SizedBox(height: 12),
                              Text(job.company!.description!,
                                style: TextStyle(fontSize: 13, height: 1.6,
                                  color: isDark ? AppColors.surface400 : AppColors.surface500)),
                            ],
                            if (job.company!.location != null || job.company!.website != null) ...[
                              const SizedBox(height: 12),
                              if (job.company!.location != null)
                                _InfoRow(Icons.location_on_outlined, job.company!.location!, isDark),
                              if (job.company!.website != null)
                                _InfoRow(Icons.language_outlined, job.company!.website!, isDark),
                            ],
                          ],
                        )),
                        const SizedBox(height: 12),
                      ],

                      // bottom spacing for FAB
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ── Bottom Apply Bar ────────────────────────────────────────
          bottomNavigationBar: !isRecruiter && userId != null
              ? Container(
                  padding: EdgeInsets.fromLTRB(
                    16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surface900 : Colors.white,
                    border: Border(top: BorderSide(
                      color: isDark ? AppColors.surface700 : AppColors.surface100)),
                    boxShadow: isDark ? [] : [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 10, offset: const Offset(0, -4)),
                    ],
                  ),
                  child: isApplied
                      ? _AppliedBanner(
                          isDark: isDark,
                          application: myAppAsync.value)
                      : ElevatedButton.icon(
                          onPressed: () => _showApplyDialog(job),
                          icon: const Icon(Icons.send_outlined, size: 18),
                          label: const Text('Apply Now',
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
                )
              : null,
        );
      },
    );
  }
}

// ── Apply Sheet ─────────────────────────────────────────────────────────────

class _ApplySheet extends ConsumerStatefulWidget {
  final Job job;
  final String jobId;
  const _ApplySheet({required this.job, required this.jobId});

  @override
  ConsumerState<_ApplySheet> createState() => _ApplySheetState();
}

class _ApplySheetState extends ConsumerState<_ApplySheet> {
  final _coverCtrl  = TextEditingController();
  bool  _submitting = false;
  bool  _uploading  = false;
  // Holds a newly picked resume file (bytes + name) before upload
  PlatformFile? _pickedResume;

  @override
  void dispose() { _coverCtrl.dispose(); super.dispose(); }

  // ── Pick a resume from device ────────────────────────────────────────────
  Future<void> _pickResume() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    // The picker dialog can stay open a while — bail out if the screen was
    // closed in the meantime instead of calling setState on a disposed State.
    if (!mounted) return;
    setState(() => _pickedResume = result.files.first);
  }

  // ── Upload resume then submit application ────────────────────────────────
  Future<void> _apply() async {
    final user    = ref.read(currentUserProvider).value;
    final profile = ref.read(profileProvider).value;
    if (user == null) return;

    setState(() => _submitting = true);
    try {
      // 1. Upload new resume if user picked one
      if (_pickedResume != null && _pickedResume!.bytes != null) {
        setState(() => _uploading = true);
        await ref.read(authServiceProvider).uploadResume(
          user.id,
          _pickedResume!.bytes!.toList(),
          _pickedResume!.name,
        );
        // Upload can take a moment — the screen may have closed by now.
        if (!mounted) return;
        ref.invalidate(profileProvider);
        setState(() => _uploading = false);
      }

      // 2. Submit application
      await DatabaseService().applyToJob(
        jobId:         widget.jobId,
        applicantId:   user.id,
        coverLetter:   _coverCtrl.text.trim().isEmpty ? null : _coverCtrl.text.trim(),
        recruiterId:   widget.job.postedBy,
        jobTitle:      widget.job.title,
        applicantName: profile?.fullName,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ref.invalidate(_appliedJobIdsProvider);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Application submitted! 🎉'),
          backgroundColor: AppColors.success500));
      }
    } catch (e) {
      setState(() => _uploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'), backgroundColor: AppColors.danger500));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final profile  = ref.watch(profileProvider).value;
    final hasResume = _pickedResume != null || profile?.resumeUrl != null;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface800 : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Handle
          Center(child: Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: isDark ? AppColors.surface600 : AppColors.surface200,
              borderRadius: BorderRadius.circular(2)),
          )),
          const SizedBox(height: 16),

          // ── Job header ─────────────────────────────────────────────
          Row(children: [
            AvatarWidget(
              imageUrl: widget.job.company?.logoUrl,
              name: widget.job.company?.name ?? widget.job.title,
              size: 42, radius: 10,
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.job.title,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.surface900),
                overflow: TextOverflow.ellipsis),
              Text(widget.job.company?.name ?? '',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                  color: AppColors.accent500)),
            ])),
          ]),

          const SizedBox(height: 16),
          Divider(color: isDark ? AppColors.surface700 : AppColors.surface100),
          const SizedBox(height: 16),

          // ── Applicant profile card ──────────────────────────────────
          _label('Your Profile', isDark),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surface700 : AppColors.surface50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppColors.surface600 : AppColors.surface200),
            ),
            child: Row(children: [
              AvatarWidget(
                imageUrl: profile?.avatarUrl,
                name: profile?.fullName,
                size: 44,
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(profile?.fullName ?? 'Your Name',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.surface900)),
                if (profile?.headline != null && profile!.headline!.isNotEmpty)
                  Text(profile.headline!,
                    style: TextStyle(fontSize: 12,
                      color: isDark ? AppColors.surface400 : AppColors.surface500),
                    overflow: TextOverflow.ellipsis),
                if (profile?.location != null && profile!.location!.isNotEmpty)
                  Row(children: [
                    Icon(Icons.location_on_outlined, size: 11,
                      color: isDark ? AppColors.surface500 : AppColors.surface400),
                    const SizedBox(width: 2),
                    Text(profile.location!,
                      style: TextStyle(fontSize: 11,
                        color: isDark ? AppColors.surface500 : AppColors.surface400)),
                  ]),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.success500.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Ready', style: TextStyle(fontSize: 10,
                  fontWeight: FontWeight.w700, color: AppColors.success600)),
              ),
            ]),
          ),

          const SizedBox(height: 16),

          // ── Resume section ──────────────────────────────────────────
          _label('Resume', isDark),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _submitting ? null : _pickResume,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: hasResume
                    ? AppColors.brand600.withValues(alpha: 0.08)
                    : (isDark ? AppColors.surface700 : AppColors.surface50),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: hasResume ? AppColors.brand600.withValues(alpha: 0.4)
                      : (isDark ? AppColors.surface600 : AppColors.surface200),
                  width: hasResume ? 1.5 : 1,
                ),
              ),
              child: Row(children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: hasResume
                        ? AppColors.brand600.withValues(alpha: 0.12)
                        : (isDark ? AppColors.surface600 : AppColors.surface200),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    hasResume ? Icons.description : Icons.upload_file_outlined,
                    size: 20,
                    color: hasResume ? AppColors.brand600 : AppColors.surface400,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    _pickedResume != null
                        ? _pickedResume!.name
                        : (profile?.resumeUrl != null
                            ? 'Resume on file ✓'
                            : 'Upload your resume'),
                    style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: hasResume
                          ? AppColors.brand600
                          : (isDark ? AppColors.surface400 : AppColors.surface500)),
                  ),
                  Text(
                    _pickedResume != null
                        ? 'Tap to change'
                        : (profile?.resumeUrl != null
                            ? 'Tap to upload a different one'
                            : 'PDF, DOC or DOCX'),
                    style: TextStyle(fontSize: 11,
                      color: isDark ? AppColors.surface500 : AppColors.surface400)),
                ])),
                if (_uploading)
                  const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2,
                      color: AppColors.brand600))
                else
                  Icon(Icons.chevron_right,
                    color: isDark ? AppColors.surface500 : AppColors.surface400),
              ]),
            ),
          ),

          // Warning if no resume at all
          if (!hasResume) ...[
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.info_outline, size: 13, color: AppColors.warning500),
              const SizedBox(width: 4),
              Text('A resume greatly improves your chances!',
                style: const TextStyle(fontSize: 11,
                  color: AppColors.warning500, fontWeight: FontWeight.w500)),
            ]),
          ],

          const SizedBox(height: 16),

          // ── Cover letter ────────────────────────────────────────────
          _label('Cover Letter (optional)', isDark),
          const SizedBox(height: 8),
          TextFormField(
            controller: _coverCtrl,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Tell them why you\'re a great fit for this role…',
              hintStyle: TextStyle(
                color: isDark ? AppColors.surface500 : AppColors.surface400,
                fontSize: 13),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark ? AppColors.surface600 : AppColors.surface200)),
              filled: true,
              fillColor: isDark ? AppColors.surface700 : AppColors.surface50,
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
          const SizedBox(height: 20),

          // ── Submit ──────────────────────────────────────────────────
          ElevatedButton.icon(
            onPressed: _submitting ? null : _apply,
            icon: _submitting
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.send_rounded, size: 18),
            label: Text(
              _uploading ? 'Uploading resume…'
                  : _submitting ? 'Submitting…'
                  : 'Submit Application',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brand600,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
          ),
        ]),
      ),
    );
  }

  Widget _label(String text, bool isDark) => Text(text,
    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
      color: isDark ? AppColors.surface300 : AppColors.surface600));
}

// ── Applied Banner ───────────────────────────────────────────────────────────

class _AppliedBanner extends StatelessWidget {
  final bool isDark;
  final Application? application;
  const _AppliedBanner({required this.isDark, this.application});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      // "Already applied" pill
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.success500.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.success500.withValues(alpha: 0.3)),
          ),
          child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.check_circle_outline, color: AppColors.success500, size: 18),
            SizedBox(width: 6),
            Text('Applied',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                color: AppColors.success600)),
          ]),
        ),
      ),

      // "Chat with Recruiter" button — only shown once we have the application id
      if (application != null) ...[
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () =>
                context.go('/chat?appId=${application!.id}'),
            icon: const Icon(Icons.chat_bubble_outline, size: 16),
            label: const Text('Chat',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brand600,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
          ),
        ),
      ],
    ]);
  }
}

// ── Small helpers ─────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final bool isDark;
  final Widget child;
  const _Card({required this.isDark, required this.child});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: isDark ? AppColors.surface800 : Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.brand900.withValues(alpha: 0.05)),
      boxShadow: isDark ? [] : [
        BoxShadow(color: AppColors.brand900.withValues(alpha: 0.08),
          blurRadius: 16, offset: const Offset(0, 5)),
      ],
    ),
    child: child,
  );
}

class _SectionTitle extends StatelessWidget {
  final String text;
  final bool isDark;
  const _SectionTitle(this.text, this.isDark);

  @override
  Widget build(BuildContext context) => Text(text,
    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
      color: isDark ? Colors.white : AppColors.surface900));
}

// Card header with the title on the left and a color-coded icon square on
// the right — one accent per section, so the page reads as a spread of
// color rather than identical gray headers.
class _CardHeader extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;
  final bool isDark;
  const _CardHeader(this.text, this.icon, this.color, this.isDark);

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Expanded(child: _SectionTitle(text, isDark)),
      const SizedBox(width: 10),
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.18 : 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    ],
  );
}

class _Tag extends StatelessWidget {
  final String label;
  final Color? color;
  const _Tag(this.label, {this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.surface500;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c)),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isDark;
  const _Stat(this.icon, this.text, this.isDark);

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 14, color: isDark ? AppColors.surface400 : AppColors.surface500),
    const SizedBox(width: 4),
    Flexible(child: Text(text, style: TextStyle(fontSize: 12,
      color: isDark ? AppColors.surface400 : AppColors.surface500),
      overflow: TextOverflow.ellipsis)),
  ]);
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isDark;
  const _InfoRow(this.icon, this.text, this.isDark);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(children: [
      Icon(icon, size: 14, color: isDark ? AppColors.surface400 : AppColors.surface500),
      const SizedBox(width: 6),
      Flexible(child: Text(text, style: TextStyle(fontSize: 13,
        color: isDark ? AppColors.surface400 : AppColors.surface500))),
    ]),
  );
}
