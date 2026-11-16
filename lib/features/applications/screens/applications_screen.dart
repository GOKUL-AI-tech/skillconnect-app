import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/helpers.dart';
import '../../../data/models/models.dart';
import '../../../data/services/database_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/avatar_widget.dart';

// ── Student providers ──────────────────────────────────────────────────────

final _appsProvider = FutureProvider.autoDispose<List<Application>>((ref) async {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return [];
  return DatabaseService().fetchApplications(user.id);
});

// ── Recruiter providers ────────────────────────────────────────────────────

final _recruiterJobsForAppsProvider = FutureProvider.autoDispose<List<Job>>((ref) async {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return [];
  return DatabaseService().fetchRecruiterJobs(user.id);
});

final _jobApplicantsProvider =
    FutureProvider.autoDispose.family<List<Application>, String>((ref, jobId) {
  return DatabaseService().fetchJobApplications(jobId);
});

// ── Status helpers ─────────────────────────────────────────────────────────

const _statusOptions = ['applied', 'shortlisted', 'interview', 'offer', 'rejected'];
const _studentTabs   = ['All', 'Applied', 'Shortlisted', 'Interview', 'Offer', 'Rejected'];

Color _statusColor(String s) => switch (s) {
  'offer'       => AppColors.success500,
  'interview'   => AppColors.brand600,
  'shortlisted' => AppColors.warning500,
  'rejected'    => AppColors.danger500,
  'applied'     => AppColors.success500,
  'withdrawn'   => AppColors.purple500,
  _             => AppColors.accent500,
};

IconData _statusIcon(String s) => switch (s) {
  'offer'       => Icons.celebration_outlined,
  'interview'   => Icons.event_outlined,
  'shortlisted' => Icons.star_border_rounded,
  'rejected'    => Icons.cancel_outlined,
  'withdrawn'   => Icons.undo_outlined,
  'applied'     => Icons.check_circle_outline,
  _             => Icons.hourglass_empty_outlined,
};

// ── Entry point ────────────────────────────────────────────────────────────

class ApplicationsScreen extends ConsumerWidget {
  const ApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile     = ref.watch(profileProvider).value;
    final isRecruiter = profile?.role == UserRole.recruiter ||
                        profile?.role == UserRole.admin;
    return isRecruiter ? const _RecruiterView() : const _StudentView();
  }
}

// ════════════════════════════════════════════════════════════════════════════
// STUDENT VIEW — tabbed list of own applications
// ════════════════════════════════════════════════════════════════════════════

class _StudentView extends ConsumerStatefulWidget {
  const _StudentView();
  @override
  ConsumerState<_StudentView> createState() => _StudentViewState();
}

class _StudentViewState extends ConsumerState<_StudentView>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  bool _newestFirst = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _studentTabs.length, vsync: this);
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  List<Application> _filter(List<Application> apps, String tab) {
    final matching = tab == 'All'
        ? apps
        : apps.where((a) => a.status.toLowerCase() == tab.toLowerCase()).toList();
    final sorted = [...matching]..sort((a, b) => _newestFirst
        ? b.appliedAt.compareTo(a.appliedAt)
        : a.appliedAt.compareTo(b.appliedAt));
    return sorted;
  }

  void _showSortSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surface800 : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: isDark ? AppColors.surface600 : AppColors.surface200,
              borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),
          Text('Sort applications',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.surface900)),
          const SizedBox(height: 12),
          for (final entry in {'Newest first': true, 'Oldest first': false}.entries)
            ListTile(
              leading: Icon(
                entry.value ? Icons.arrow_downward : Icons.arrow_upward,
                color: AppColors.brand600, size: 20),
              title: Text(entry.key, style: TextStyle(fontWeight: FontWeight.w600,
                color: _newestFirst == entry.value ? AppColors.brand600
                    : (isDark ? Colors.white : AppColors.surface900))),
              trailing: _newestFirst == entry.value
                  ? const Icon(Icons.check_circle, color: AppColors.brand600, size: 20)
                  : null,
              onTap: () {
                Navigator.pop(context);
                setState(() => _newestFirst = entry.value);
              },
            ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appsAsync = ref.watch(_appsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Applications',
          style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Material(
              color: AppColors.brand50,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _showSortSheet,
                child: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.brand200),
                  ),
                  child: const Icon(Icons.filter_alt_outlined, color: AppColors.brand600, size: 19),
                ),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: _studentTabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: appsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => Center(child: Text('$e')),
        data: (apps) => TabBarView(
          controller: _tabCtrl,
          children: _studentTabs.map((tab) {
            final filtered = _filter(apps, tab);
            if (filtered.isEmpty) return _Empty('No $tab applications');
            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(_appsProvider),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filtered.length,
                itemBuilder: (_, i) => _StudentAppCard(app: filtered[i], colorIndex: i),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// RECRUITER VIEW — job list → applicants for job
// ════════════════════════════════════════════════════════════════════════════

class _RecruiterView extends ConsumerStatefulWidget {
  const _RecruiterView();
  @override
  ConsumerState<_RecruiterView> createState() => _RecruiterViewState();
}

class _RecruiterViewState extends ConsumerState<_RecruiterView> {
  Job? _selectedJob;

  @override
  Widget build(BuildContext context) {
    if (_selectedJob != null) {
      return _ApplicantsScreen(
        job: _selectedJob!,
        onBack: () => setState(() => _selectedJob = null),
      );
    }
    return _JobListScreen(
      onSelectJob: (j) => setState(() => _selectedJob = j),
    );
  }
}

// ── Recruiter: job list ───────────────────────────────────────────────────

class _JobListScreen extends ConsumerWidget {
  final void Function(Job) onSelectJob;
  const _JobListScreen({required this.onSelectJob});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final jobsAsync = ref.watch(_recruiterJobsForAppsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Applicants',
          style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Post a job',
            onPressed: () => context.push('/post-job'),
          ),
        ],
      ),
      body: jobsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => Center(child: Text('$e')),
        data: (jobs) {
          if (jobs.isEmpty) {
            return _Empty('No jobs posted yet — post one to receive applicants');
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(_recruiterJobsForAppsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: jobs.length,
              itemBuilder: (_, i) => _JobRow(
                job: jobs[i], isDark: isDark, colorIndex: i,
                onTap: () => onSelectJob(jobs[i])),
            ),
          );
        },
      ),
    );
  }
}

class _JobRow extends StatelessWidget {
  final Job  job;
  final bool isDark;
  final int  colorIndex;
  final VoidCallback onTap;
  const _JobRow({required this.job, required this.isDark, required this.colorIndex, required this.onTap});

  Color get _accent => AppColors.cardPalette[colorIndex % AppColors.cardPalette.length];

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: isDark ? AppColors.surface800 : Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: isDark ? AppColors.surface700 : AppColors.surface100),
      boxShadow: isDark ? [] : [
        BoxShadow(color: AppColors.brand900.withValues(alpha: 0.07), blurRadius: 16, offset: const Offset(0, 6)),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Row(children: [
            Container(width: 4, height: 78, color: _accent),
            Expanded(
              child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 14, 14, 14),
              child: Row(children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(13),
                    boxShadow: [BoxShadow(color: _accent.withValues(alpha: 0.28), blurRadius: 8, offset: const Offset(0, 3))],
                  ),
                  child: AvatarWidget(
                    imageUrl: job.company?.logoUrl,
                    name: job.company?.name ?? job.title,
                    size: 46, radius: 13,
                    color: _accent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(job.title,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.surface900)),
                  const SizedBox(height: 5),
                  Row(children: [
                    _MiniChip(jobTypeLabel(job.type), color: AppColors.accent500, bg: AppColors.accent500.withValues(alpha: 0.1)),
                    const SizedBox(width: 6),
                    _MiniChip(jobModeLabel(job.mode), color: AppColors.success600, bg: AppColors.success500.withValues(alpha: 0.1)),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: job.applicationsCount > 0
                            ? _accent.withValues(alpha: 0.12)
                            : (isDark ? AppColors.surface700 : AppColors.surface100),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.people_outline, size: 12,
                          color: job.applicationsCount > 0 ? _accent
                              : (isDark ? AppColors.surface400 : AppColors.surface500)),
                        const SizedBox(width: 3),
                        Text('${job.applicationsCount} applicant${job.applicationsCount != 1 ? 's' : ''}',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700,
                            color: job.applicationsCount > 0
                                ? _accent
                                : (isDark ? AppColors.surface400 : AppColors.surface500))),
                      ]),
                    ),
                    const Spacer(),
                    Text(timeAgo(job.createdAt),
                      style: TextStyle(fontSize: 11,
                        color: isDark ? AppColors.surface500 : AppColors.surface400)),
                  ]),
                ])),
                const SizedBox(width: 6),
                Icon(Icons.chevron_right,
                  color: isDark ? AppColors.surface600 : AppColors.surface300),
              ]),
              ),
            ),
          ]),
        ),
      ),
    ),
  );
}

// ── Recruiter: applicants for one job ─────────────────────────────────────

class _ApplicantsScreen extends ConsumerWidget {
  final Job job;
  final VoidCallback onBack;
  const _ApplicantsScreen({required this.job, required this.onBack});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final appsAsync = ref.watch(_jobApplicantsProvider(job.id));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack,
        ),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(job.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            overflow: TextOverflow.ellipsis),
          Text('${job.applicationsCount} applicant${job.applicationsCount != 1 ? 's' : ''}',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400,
              color: isDark ? AppColors.surface400 : AppColors.surface500)),
        ]),
      ),
      body: appsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => Center(child: Text('$e')),
        data: (apps) {
          if (apps.isEmpty) {
            return _Empty('No applications yet for this role');
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(_jobApplicantsProvider(job.id)),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: apps.length,
              itemBuilder: (_, i) => _ApplicantCard(
                app: apps[i], job: job, isDark: isDark,
                onStatusChanged: () => ref.invalidate(_jobApplicantsProvider(job.id)),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ApplicantCard extends StatefulWidget {
  final Application app;
  final Job         job;
  final bool        isDark;
  final VoidCallback onStatusChanged;
  const _ApplicantCard({
    required this.app,
    required this.job,
    required this.isDark,
    required this.onStatusChanged,
  });

  @override
  State<_ApplicantCard> createState() => _ApplicantCardState();
}

class _ApplicantCardState extends State<_ApplicantCard> {
  bool _updating = false;

  Future<void> _updateStatus(String newStatus) async {
    if (_updating) return;
    setState(() => _updating = true);
    try {
      await DatabaseService().updateApplicationStatus(
        widget.app.id,
        newStatus,
        applicantId: widget.app.applicantId,
        jobTitle:    widget.job.title,
      );
      widget.onStatusChanged();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'),
            backgroundColor: AppColors.danger500));
      }
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  void _showStatusPicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surface800 : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: isDark ? AppColors.surface600 : AppColors.surface200,
              borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),
          Text('Update Status for\n${widget.app.applicant?.fullName ?? 'Applicant'}',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.surface900)),
          const SizedBox(height: 16),
          ..._statusOptions.map((s) {
            final isActive = s == widget.app.status;
            final c = _statusColor(s);
            return ListTile(
              leading: CircleAvatar(
                radius: 18,
                backgroundColor: c.withValues(alpha: 0.15),
                child: Icon(_statusIcon(s), size: 18, color: c),
              ),
              title: Text(appStatusLabel(s),
                style: TextStyle(fontWeight: FontWeight.w600,
                  color: isActive ? c : (isDark ? Colors.white : AppColors.surface900))),
              trailing: isActive
                  ? Icon(Icons.check_circle, color: c, size: 20)
                  : null,
              onTap: () {
                Navigator.pop(context);
                if (!isActive) _updateStatus(s);
              },
            );
          }),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app     = widget.app;
    final isDark  = widget.isDark;
    final profile = app.applicant;
    final c       = _statusColor(app.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface800 : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.surface700 : AppColors.surface100),
        boxShadow: isDark ? [] : [
          BoxShadow(color: AppColors.brand900.withValues(alpha: 0.07), blurRadius: 18, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Header row ───────────────────────────────────────────────
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Stack(clipBehavior: Clip.none, children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: c.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: AvatarWidget(
                  imageUrl: profile?.avatarUrl,
                  name: profile?.fullName,
                  size: 54,
                  color: c,
                ),
              ),
              Positioned(
                bottom: 0, right: 0,
                child: Container(
                  width: 14, height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.success500,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? AppColors.surface800 : Colors.white, width: 2),
                  ),
                ),
              ),
            ]),
            const SizedBox(width: 13),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(profile?.fullName ?? 'Applicant',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.surface900)),
              if (profile?.headline != null && profile!.headline!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(profile.headline!,
                  style: TextStyle(fontSize: 12,
                    color: isDark ? AppColors.surface400 : AppColors.surface500),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
              if (profile?.location != null && profile!.location!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Row(children: [
                  Icon(Icons.location_on_outlined, size: 11,
                    color: isDark ? AppColors.surface500 : AppColors.surface400),
                  const SizedBox(width: 2),
                  Text(profile.location!,
                    style: TextStyle(fontSize: 11,
                      color: isDark ? AppColors.surface500 : AppColors.surface400)),
                ]),
              ],
              const SizedBox(height: 8),
              // Status label pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: c.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.mail_outline, size: 12, color: c),
                  const SizedBox(width: 4),
                  Text(appStatusLabel(app.status),
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c)),
                ]),
              ),
            ])),
            const SizedBox(width: 8),
            // Status dropdown badge
            GestureDetector(
              onTap: _showStatusPicker,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: c.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(appStatusLabel(app.status),
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c)),
                  const SizedBox(width: 3),
                  _updating
                      ? SizedBox(width: 10, height: 10,
                          child: CircularProgressIndicator(strokeWidth: 1.5, color: c))
                      : Icon(Icons.expand_more, size: 13, color: c),
                ]),
              ),
            ),
          ]),

          const SizedBox(height: 14),

          // ── Meta row ─────────────────────────────────────────────────
          Row(children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surface700 : AppColors.surface50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.schedule_outlined, size: 13, color: AppColors.accent500),
                  const SizedBox(width: 5),
                  Flexible(child: Text('Applied ${timeAgo(app.appliedAt)}',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.surface300 : AppColors.surface600),
                    overflow: TextOverflow.ellipsis)),
                ]),
              ),
            ),
            // Resume — tappable to open
            if (profile?.resumeUrl != null) ...[
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () async {
                  final url = Uri.parse(profile!.resumeUrl!);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.success500.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.success500.withValues(alpha: 0.3)),
                  ),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.description_outlined, size: 13, color: AppColors.success600),
                    SizedBox(width: 5),
                    Text('View Resume', style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700,
                      color: AppColors.success600)),
                  ]),
                ),
              ),
            ],
          ]),

          // ── Cover letter preview ──────────────────────────────────────
          if (app.coverLetter != null && app.coverLetter!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surface700 : AppColors.surface50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? AppColors.surface600 : AppColors.surface200),
              ),
              child: Text(app.coverLetter!,
                style: TextStyle(fontSize: 12, height: 1.5,
                  color: isDark ? AppColors.surface300 : AppColors.surface600),
                maxLines: 3, overflow: TextOverflow.ellipsis),
            ),
          ],

          const SizedBox(height: 12),

          // ── Action buttons ────────────────────────────────────────────
          Row(children: [
            // Change status
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _showStatusPicker,
                icon: const Icon(Icons.edit_outlined, size: 15),
                label: const Text('Update Status',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: c),
                  foregroundColor: c,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Chat with applicant — gradient fill to match the app's
            // berry/purple accent instead of a flat single color.
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Material(
                  color: Colors.transparent,
                  child: Ink(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.purple500, AppColors.brand600],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                    child: InkWell(
                      onTap: () => context.go('/chat?appId=${app.id}'),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Icon(Icons.chat_bubble_outline, size: 15, color: Colors.white),
                          const SizedBox(width: 6),
                          const Text('Message',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                        ]),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ]),
        ]),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// SHARED STUDENT CARD
// ════════════════════════════════════════════════════════════════════════════

class _StudentAppCard extends StatelessWidget {
  final Application app;
  final int colorIndex;
  const _StudentAppCard({required this.app, required this.colorIndex});

  Color get _accent => AppColors.cardPalette[colorIndex % AppColors.cardPalette.length];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = _statusColor(app.status);
    final companyName = app.job?.company?.name ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface800 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.surface700 : AppColors.surface100),
        boxShadow: isDark ? [] : [
          BoxShadow(color: AppColors.brand900.withValues(alpha: 0.06), blurRadius: 14, offset: const Offset(0, 5)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        // The colored left bar sits in a Row with CrossAxisAlignment.stretch
        // so it fills the row's full height — that needs a bounded height
        // from the parent, which a ListView.builder item does not provide
        // on its own. IntrinsicHeight supplies it.
        child: IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Container(width: 4, color: _accent),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: _accent.withValues(alpha: 0.28), blurRadius: 8, offset: const Offset(0, 3))],
                    ),
                    child: AvatarWidget(
                      name: companyName.isNotEmpty ? companyName : app.job?.title,
                      imageUrl: app.job?.company?.logoUrl,
                      size: 46, radius: 12,
                      color: _accent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(app.job?.title ?? 'Position',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.surface900)),
                    if (companyName.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(companyName,
                        style: const TextStyle(fontSize: 13, color: AppColors.accent500,
                          fontWeight: FontWeight.w500)),
                    ],
                    const SizedBox(height: 6),
                    Row(children: [
                      Icon(Icons.schedule_outlined, size: 12,
                        color: isDark ? AppColors.surface500 : AppColors.surface400),
                      const SizedBox(width: 4),
                      Text('Applied ${timeAgo(app.appliedAt)}',
                        style: TextStyle(fontSize: 12,
                          color: isDark ? AppColors.surface500 : AppColors.surface400)),
                    ]),
                  ])),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: c.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(_statusIcon(app.status), size: 13, color: c),
                      const SizedBox(width: 4),
                      Text(appStatusLabel(app.status),
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c)),
                    ]),
                  ),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// SHARED HELPERS
// ════════════════════════════════════════════════════════════════════════════

class _Empty extends StatelessWidget {
  final String message;
  const _Empty(this.message);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.description_outlined, size: 56,
            color: isDark ? AppColors.surface600 : AppColors.surface300),
          const SizedBox(height: 12),
          Text(message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
              color: isDark ? AppColors.surface400 : AppColors.surface500)),
        ]),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  final Color? color;
  final Color? bg;
  const _MiniChip(this.label, {this.color, this.bg});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = color ?? (isDark ? AppColors.surface400 : AppColors.surface500);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg ?? (isDark ? AppColors.surface700 : AppColors.surface100),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: TextStyle(
        fontSize: 11, fontWeight: FontWeight.w700, color: c)),
    );
  }
}
