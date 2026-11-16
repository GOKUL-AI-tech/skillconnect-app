import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/helpers.dart';
import '../../../data/models/models.dart';
import '../../../data/services/database_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/avatar_widget.dart';
import '../../../shared/widgets/stat_card.dart';

final _dbProvider = Provider((ref) => DatabaseService());

final _studentAppsProvider = FutureProvider.autoDispose<List<Application>>((ref) async {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return [];
  return ref.read(_dbProvider).fetchApplications(user.id);
});

final _recommendedJobsProvider = FutureProvider.autoDispose<List<Job>>((ref) {
  return ref.read(_dbProvider).fetchJobs(featuredOnly: true);
});

class StudentDashboard extends ConsumerWidget {
  final Profile? profile;
  const StudentDashboard({super.key, this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final appsAsync = ref.watch(_studentAppsProvider);
    final jobsAsync = ref.watch(_recommendedJobsProvider);
    final name = profile?.fullName ?? 'there';

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(_studentAppsProvider);
          ref.invalidate(_recommendedJobsProvider);
        },
        child: CustomScrollView(
          slivers: [
            // App bar with greeting
            SliverAppBar(
              floating: true,
              title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Good morning 👋', style: TextStyle(fontSize: 12,
                  color: isDark ? AppColors.surface400 : AppColors.surface500,
                  fontWeight: FontWeight.w400)),
                Text(name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.surface900)),
              ]),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: GestureDetector(
                    onTap: () => context.push('/notifications'),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surface800 : Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: isDark ? [] : [
                          BoxShadow(color: AppColors.brand900.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 3)),
                        ],
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Center(
                            child: Icon(Icons.notifications_outlined, size: 20,
                              color: isDark ? Colors.white : AppColors.surface700),
                          ),
                          Positioned(
                            top: 6, right: 8,
                            child: Container(
                              width: 8, height: 8,
                              decoration: BoxDecoration(
                                color: AppColors.danger500,
                                shape: BoxShape.circle,
                                border: Border.all(color: isDark ? AppColors.surface800 : Colors.white, width: 1.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                // Profile completeness
                if (profile != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.purple500, AppColors.accent500],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          const Text('Profile Strength', style: TextStyle(color: Colors.white70, fontSize: 13)),
                          Text('${profile!.profileScore}%',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                        ]),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: profile!.profileScore / 100,
                            backgroundColor: Colors.white24,
                            valueColor: const AlwaysStoppedAnimation(Colors.white),
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text('Complete your profile to get more visibility',
                          style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ])),
                      const SizedBox(width: 14),
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.22),
                        ),
                        child: const Icon(Icons.person_outline, color: Colors.white, size: 22),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 20),
                ],

                // Stats grid
                appsAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error:   (_, __) => const SizedBox.shrink(),
                  data: (apps) {
                    final applied     = apps.length;
                    final shortlisted = apps.where((a) => a.status == 'shortlisted').length;
                    final interviews  = apps.where((a) => a.status == 'interview').length;
                    final offers      = apps.where((a) => a.status == 'offer').length;
                    return GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.1,
                      children: [
                        StatCard(label: 'Applied',     value: '$applied',     icon: Icons.send_outlined,      color: AppColors.brand600,
                          onTap: () => context.push('/applications')),
                        StatCard(label: 'Shortlisted', value: '$shortlisted', icon: Icons.bookmark_outlined,  color: AppColors.warning500,
                          onTap: () => context.push('/applications')),
                        StatCard(label: 'Interviews',  value: '$interviews',  icon: Icons.calendar_today_outlined, color: AppColors.accent500,
                          onTap: () => context.push('/applications')),
                        StatCard(label: 'Offers',      value: '$offers',      icon: Icons.bolt, color: AppColors.success500,
                          onTap: () => context.push('/applications')),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Recent applications
                appsAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error:   (_, __) => const SizedBox.shrink(),
                  data: (apps) {
                    if (apps.isEmpty) return const SizedBox.shrink();
                    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('Recent Applications',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppColors.surface900)),
                        TextButton(onPressed: () => context.push('/applications'), child: const Text('See all')),
                      ]),
                      ...apps.take(3).toList().asMap().entries.map(
                        (e) => _AppRow(app: e.value, isDark: isDark, colorIndex: e.key)),
                    ]);
                  },
                ),
                const SizedBox(height: 24),

                // Recommended jobs
                jobsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error:   (_, __) => const SizedBox.shrink(),
                  data: (jobs) {
                    if (jobs.isEmpty) return const SizedBox.shrink();
                    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('Recommended for You',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppColors.surface900)),
                        TextButton(onPressed: () => context.push('/jobs'), child: const Text('See all')),
                      ]),
                      const SizedBox(height: 8),
                      ...jobs.take(3).map((j) => _JobRow(job: j, isDark: isDark)),
                    ]);
                  },
                ),
              ]),
            )),
          ],
        ),
      ),
    );
  }
}

class _AppRow extends StatelessWidget {
  final Application app;
  final bool isDark;
  final int colorIndex;
  const _AppRow({required this.app, required this.isDark, required this.colorIndex});

  Color get _accent => AppColors.cardPalette[colorIndex % AppColors.cardPalette.length];

  Color _statusColor(String s) => switch (s) {
    'offer'      => AppColors.success500,
    'interview'  => AppColors.brand600,
    'shortlisted'=> AppColors.warning500,
    'rejected'   => AppColors.danger500,
    'applied'    => AppColors.success500,
    'withdrawn'  => AppColors.purple500,
    _            => AppColors.accent500,
  };

  @override
  Widget build(BuildContext context) {
    final companyName = app.job?.company?.name ?? '';
    final c = _statusColor(app.status);
    return GestureDetector(
      onTap: () => context.push('/applications'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surface800 : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? AppColors.surface700 : AppColors.surface100),
        ),
        child: Row(children: [
          AvatarWidget(
            name: companyName.isNotEmpty ? companyName : app.job?.title,
            imageUrl: app.job?.company?.logoUrl,
            size: 42, color: _accent,
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(app.job?.title ?? 'Job',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.surface900), maxLines: 1, overflow: TextOverflow.ellipsis),
            if (companyName.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(companyName,
                style: const TextStyle(fontSize: 12, color: AppColors.accent500, fontWeight: FontWeight.w500)),
            ],
          ])),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(appStatusLabel(app.status),
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c)),
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right, size: 16,
            color: isDark ? AppColors.surface600 : AppColors.surface300),
        ]),
      ),
    );
  }
}

class _JobRow extends StatelessWidget {
  final Job job;
  final bool isDark;
  const _JobRow({required this.job, required this.isDark});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => context.push('/jobs/${job.id}'),
    child: Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: AvatarWidget(name: job.company?.name ?? job.title, imageUrl: job.company?.logoUrl, size: 40),
        title: Text(job.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : AppColors.surface900), maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text('${job.company?.name ?? ''} · ${jobModeLabel(job.mode)}',
          style: TextStyle(fontSize: 12, color: isDark ? AppColors.surface400 : AppColors.surface500)),
        trailing: const Icon(Icons.chevron_right, size: 18),
      ),
    ),
  );
}
