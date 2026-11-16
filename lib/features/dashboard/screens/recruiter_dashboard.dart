import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/helpers.dart';
import '../../../data/models/models.dart';
import '../../../data/services/database_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/stat_card.dart';

final _recruiterJobsProvider = FutureProvider.autoDispose<List<Job>>((ref) async {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return [];
  return DatabaseService().fetchRecruiterJobs(user.id);
});

class RecruiterDashboard extends ConsumerWidget {
  final Profile profile;
  const RecruiterDashboard({super.key, required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final jobsAsync = ref.watch(_recruiterJobsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Recruiter Dashboard', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : AppColors.surface900)),
          Text(profile.fullName ?? '', style: TextStyle(fontSize: 12,
            color: isDark ? AppColors.surface400 : AppColors.surface500, fontWeight: FontWeight.w400)),
        ]),
        actions: [
          ElevatedButton.icon(
            onPressed: () => context.push('/post-job'),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Post Job'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(_recruiterJobsProvider),
        child: jobsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (jobs) {
            final totalApps = jobs.fold(0, (s, j) => s + j.applicationsCount);
            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(delegate: SliverChildListDelegate([
                    // Stats
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 12, crossAxisSpacing: 12,
                      childAspectRatio: 1.1,
                      children: [
                        StatCard(label: 'Active Jobs',   value: '${jobs.where((j) => j.isActive).length}', icon: Icons.work_outline,    color: AppColors.brand600),
                        StatCard(label: 'Total Applications', value: '$totalApps', icon: Icons.people_outline, color: AppColors.accent500),
                        StatCard(label: 'Total Views',   value: '${jobs.fold(0, (s, j) => s + j.views)}',   icon: Icons.visibility_outlined, color: AppColors.warning500),
                        StatCard(label: 'Positions',     value: '${jobs.fold(0, (s, j) => s + j.openings)}', icon: Icons.chair_outlined,  color: AppColors.success500),
                      ],
                    ),
                    const SizedBox(height: 24),

                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('Your Job Postings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.surface900)),
                      Text('${jobs.length} total', style: TextStyle(fontSize: 13,
                        color: isDark ? AppColors.surface400 : AppColors.surface500)),
                    ]),
                    const SizedBox(height: 12),

                    if (jobs.isEmpty) Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.work_outline, size: 56, color: isDark ? AppColors.surface600 : AppColors.surface300),
                          const SizedBox(height: 12),
                          Text('No jobs posted yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.surface400 : AppColors.surface500)),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () => context.push('/post-job'),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Post your first job'),
                          ),
                        ]),
                      ),
                    ),

                    ...jobs.map((j) => _JobPostingCard(
                      job: j, isDark: isDark,
                      onTap: () => context.go('/applications'),
                    )),
                  ])),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _JobPostingCard extends StatelessWidget {
  final Job          job;
  final bool         isDark;
  final VoidCallback onTap;
  const _JobPostingCard({required this.job, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(job.title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.surface900)),
              const SizedBox(height: 2),
              Text(jobTypeLabel(job.type), style: TextStyle(fontSize: 12,
                color: isDark ? AppColors.surface400 : AppColors.surface500)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: job.isActive ? AppColors.success50 : AppColors.surface100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(job.isActive ? 'Active' : 'Closed',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                  color: job.isActive ? AppColors.success600 : AppColors.surface500)),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 18,
              color: isDark ? AppColors.surface600 : AppColors.surface300),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            _Metric(Icons.people_outline, '${job.applicationsCount} applicants',
              highlight: job.applicationsCount > 0),
            const SizedBox(width: 16),
            _Metric(Icons.visibility_outlined, '${job.views} views'),
            const SizedBox(width: 16),
            _Metric(Icons.schedule_outlined, timeAgo(job.createdAt)),
          ]),
        ]),
      ),
    ),
  );
}

class _Metric extends StatelessWidget {
  final IconData icon;
  final String   label;
  final bool     highlight;
  const _Metric(this.icon, this.label, {this.highlight = false});
  @override
  Widget build(BuildContext context) {
    final color = highlight ? AppColors.brand600 : AppColors.surface400;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: color),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 12, color: color,
        fontWeight: highlight ? FontWeight.w600 : FontWeight.w400)),
    ]);
  }
}
