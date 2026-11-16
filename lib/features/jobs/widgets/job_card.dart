import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/helpers.dart';
import '../../../data/models/models.dart';
import '../../../shared/widgets/avatar_widget.dart';

class JobCard extends StatelessWidget {
  final Job job;
  final bool saved;
  final bool applied;
  final VoidCallback? onSaveToggle;
  /// Position of this card in its list — when provided, the accent color
  /// rotates strictly by position so consecutive cards never collide, even
  /// when job ids hash close together (e.g. seed/test data). Falls back to
  /// a hash of the job id when not provided (e.g. a lone card).
  final int? colorIndex;

  const JobCard({
    super.key,
    required this.job,
    this.saved = false,
    this.applied = false,
    this.onSaveToggle,
    this.colorIndex,
  });

  Color get _accent => AppColors.cardPalette[
      (colorIndex ?? job.id.hashCode.abs()) % AppColors.cardPalette.length];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary   = isDark ? Colors.white : AppColors.surface900;
    final textSecondary = isDark ? AppColors.surface400 : AppColors.surface500;
    final accent = _accent;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface800 : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.surface700 : AppColors.surface100),
        boxShadow: isDark ? [] : [
          BoxShadow(color: AppColors.brand900.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 8)),
          BoxShadow(color: AppColors.brand900.withValues(alpha: 0.04), blurRadius: 4,  offset: const Offset(0, 1)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.push('/jobs/${job.id}'),
            // IntrinsicHeight gives the Row below a finite height to stretch
            // against — without it, a Row with CrossAxisAlignment.stretch
            // inside a ListView.builder item (unbounded height) throws a
            // layout exception that renders as a silent blank list.
            child: IntrinsicHeight(
              child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left accent bar — color-codes each card at a glance
                Container(width: 4, color: accent),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 16, 12, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header row
                        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(color: accent.withValues(alpha: 0.28),
                                  blurRadius: 10, offset: const Offset(0, 4)),
                              ],
                            ),
                            child: AvatarWidget(
                              imageUrl: job.company?.logoUrl,
                              name: job.company?.name ?? job.title,
                              size: 50,
                              radius: 15,
                              color: accent,
                            ),
                          ),
                          const SizedBox(width: 13),
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(job.title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 3),
                              Row(children: [
                                Icon(Icons.business_outlined, size: 13, color: AppColors.accent500),
                                const SizedBox(width: 3),
                                Flexible(child: Text(job.company?.name ?? '', style: const TextStyle(fontSize: 13, color: AppColors.accent500,
                                  fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
                              ]),
                            ],
                          )),
                          // Save button
                          InkWell(
                            borderRadius: BorderRadius.circular(11),
                            onTap: onSaveToggle,
                            child: Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(
                                color: saved ? accent : (isDark ? AppColors.surface700 : AppColors.surface100),
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: Icon(saved ? Icons.bookmark : Icons.bookmark_border,
                                color: saved ? Colors.white : textSecondary, size: 19),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 13),

                        // Tags row
                        Wrap(spacing: 6, runSpacing: 6, children: [
                          _Tag(jobTypeLabel(job.type), color: AppColors.accent500, icon: Icons.work_outline),
                          _Tag(jobModeLabel(job.mode), color: AppColors.success500, icon: Icons.laptop_mac_outlined),
                          if (job.location != null) _Tag(job.location!, icon: Icons.location_on_outlined),
                        ]),

                        // Skills
                        if (job.skillsRequired.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Wrap(spacing: 6, runSpacing: 4,
                            children: job.skillsRequired.take(4).map((s) =>
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.surface700 : AppColors.surface100,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(s, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.surface300 : AppColors.surface600)),
                              )
                            ).toList(),
                          ),
                        ],

                        const SizedBox(height: 14),
                        Divider(height: 1, color: isDark ? AppColors.surface700 : AppColors.surface100),
                        const SizedBox(height: 12),

                        // Footer
                        Row(children: [
                          if (job.salaryMin != null || job.salaryMax != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                Icon(Icons.payments_outlined, size: 13, color: accent),
                                const SizedBox(width: 4),
                                Text(formatSalary(job.salaryMin, job.salaryMax, unit: job.salaryUnit),
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: accent)),
                              ]),
                            ),
                          const SizedBox(width: 10),
                          Icon(Icons.people_outline, size: 14, color: textSecondary),
                          const SizedBox(width: 3),
                          Text('${job.applicationsCount} applied',
                            style: TextStyle(fontSize: 12, color: textSecondary)),
                          const Spacer(),
                          if (applied)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.success50,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Text('Applied', style: TextStyle(fontSize: 11,
                                color: AppColors.success600, fontWeight: FontWeight.w600)),
                            ),
                          if (!applied)
                            Text(timeAgo(job.createdAt), style: TextStyle(fontSize: 11.5, color: textSecondary)),
                        ]),
                      ],
                    ),
                  ),
                ),
              ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color? color;
  final IconData? icon;
  const _Tag(this.label, {this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = color ?? (isDark ? AppColors.surface500 : AppColors.surface600);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: (color ?? AppColors.surface500).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 12, color: c), const SizedBox(width: 4)],
        Text(label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: c)),
      ]),
    );
  }
}
