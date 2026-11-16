import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/models.dart';
import '../../../data/services/database_service.dart';
import '../../../providers/auth_provider.dart';
import '../widgets/job_card.dart';

final _dbProvider = Provider((ref) => DatabaseService());

final jobsProvider = FutureProvider.autoDispose.family<List<Job>, Map<String, String?>>((ref, filters) {
  return ref.read(_dbProvider).fetchJobs(
    search:   filters['search'],
    type:     filters['type'],
    mode:     filters['mode'],
    // Scopes a recruiter's own "Browse" tab to just their own postings —
    // null for students, who browse every active job.
    postedBy: filters['postedBy'],
  );
});

final savedIdsProvider = FutureProvider.autoDispose<Set<String>>((ref) async {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return {};
  final ids = await ref.read(_dbProvider).fetchSavedJobIds(user.id);
  return ids.toSet();
});

final appliedIdsProvider = FutureProvider.autoDispose<Set<String>>((ref) async {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return {};
  final ids = await ref.read(_dbProvider).fetchAppliedJobIds(user.id);
  return ids.toSet();
});

class JobsScreen extends ConsumerStatefulWidget {
  final String pageType; // 'jobs' | 'internships' | 'freelance'
  const JobsScreen({super.key, this.pageType = 'jobs'});
  @override
  ConsumerState<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends ConsumerState<JobsScreen> {
  final _searchCtrl = TextEditingController();
  String? _selType, _selMode;

  // Recruiters only ever browse their own postings here — resolved once at
  // init (the profile is already loaded by the time this screen is reached
  // from the bottom nav) and carried into every filter rebuild below.
  bool _isRecruiter = false;
  String? _postedBy;

  // Store filters as a field so the same Map object is reused between builds.
  // FutureProvider.family uses the argument as a cache key — a new Map every
  // build would create a new provider key and restart the fetch endlessly.
  late Map<String, String?> _filters;

  void _updateFilters() {
    setState(() {
      _filters = {
        'search':   _searchCtrl.text.isEmpty ? null : _searchCtrl.text,
        'type':     _selType ?? (widget.pageType == 'internships'
                      ? 'internship'
                      : widget.pageType == 'freelance' ? 'freelance' : null),
        'mode':     _selMode,
        'postedBy': _postedBy,
      };
    });
  }

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider).value;
    _isRecruiter = profile?.role == UserRole.recruiter || profile?.role == UserRole.admin;
    _postedBy = _isRecruiter ? profile?.id : null;
    _filters = {
      'search':   null,
      'type':     widget.pageType == 'internships'
                  ? 'internship'
                  : widget.pageType == 'freelance' ? 'freelance' : null,
      'mode':     null,
      'postedBy': _postedBy,
    };
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  String get _title {
    if (_isRecruiter) return 'My Postings';
    return switch (widget.pageType) {
      'internships' => 'Internships',
      'freelance'   => 'Freelance',
      _             => 'Jobs',
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final jobsAsync    = ref.watch(jobsProvider(_filters));
    final savedAsync   = ref.watch(savedIdsProvider);
    final appliedAsync = ref.watch(appliedIdsProvider);
    final user         = ref.watch(currentUserProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        actions: [
          if (_isRecruiter)
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              tooltip: 'Post a job',
              onPressed: () => context.push('/post-job'),
            ),
          IconButton(icon: const Icon(Icons.tune_outlined), onPressed: _showFilters),
        ],
      ),
      body: Column(children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (_) => _updateFilters(),
            decoration: InputDecoration(
              hintText: 'Search $_title…',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () { _searchCtrl.clear(); _updateFilters(); })
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),

        // Active filters
        if (_selType != null || _selMode != null)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(children: [
              if (_selType != null) _FilterChip(label: _selType!, onRemove: () { _selType = null; _updateFilters(); }),
              if (_selMode != null) _FilterChip(label: _selMode!, onRemove: () { _selMode = null; _updateFilters(); }),
            ]),
          ),

        // Job list
        Expanded(
          child: jobsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (jobs) {
              if (jobs.isEmpty) return Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.work_outline, size: 56, color: isDark ? AppColors.surface600 : AppColors.surface300),
                  const SizedBox(height: 12),
                  Text(_isRecruiter ? 'You haven\'t posted any jobs yet' : 'No jobs found',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.surface400 : AppColors.surface500)),
                  if (_isRecruiter) ...[
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => context.push('/post-job'),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Post a Job'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brand600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ],
                ]),
              );
              final savedIds   = savedAsync.value   ?? {};
              final appliedIds = appliedAsync.value ?? {};
              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(jobsProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: jobs.length,
                  itemBuilder: (_, i) {
                    final job = jobs[i];
                    return JobCard(
                      job: job,
                      colorIndex: i,
                      saved:   savedIds.contains(job.id),
                      applied: appliedIds.contains(job.id),
                      onSaveToggle: user == null ? null : () async {
                        final db = ref.read(_dbProvider);
                        if (savedIds.contains(job.id)) {
                          await db.unsaveJob(user.id, job.id);
                        } else {
                          await db.saveJob(user.id, job.id);
                        }
                        ref.invalidate(savedIdsProvider);
                      },
                    );
                  },
                ),
              );
            },
          ),
        ),
      ]),
    );
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FilterSheet(
        selType: _selType, selMode: _selMode,
        onApply: (type, mode) {
          _selType = type; _selMode = mode; _updateFilters();
          Navigator.pop(context);
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  const _FilterChip({required this.label, required this.onRemove});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(right: 8),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: AppColors.brand100, borderRadius: BorderRadius.circular(20),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(label, style: const TextStyle(fontSize: 12, color: AppColors.brand700, fontWeight: FontWeight.w600)),
      const SizedBox(width: 4),
      GestureDetector(onTap: onRemove, child: const Icon(Icons.close, size: 14, color: AppColors.brand600)),
    ]),
  );
}

class _FilterSheet extends StatefulWidget {
  final String? selType, selMode;
  final void Function(String?, String?) onApply;
  const _FilterSheet({this.selType, this.selMode, required this.onApply});
  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  String? _type, _mode;
  @override
  void initState() { super.initState(); _type = widget.selType; _mode = widget.selMode; }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
    child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('Filters', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        TextButton(onPressed: () { setState(() { _type = null; _mode = null; }); }, child: const Text('Clear all')),
      ]),
      const SizedBox(height: 16),
      const Text('Job Type', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      Wrap(spacing: 8, children: ['full_time','part_time','contract','internship','freelance'].map((t) =>
        ChoiceChip(label: Text(t.replaceAll('_', ' ')), selected: _type == t,
          onSelected: (_) => setState(() => _type = _type == t ? null : t)),
      ).toList()),
      const SizedBox(height: 16),
      const Text('Work Mode', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      Wrap(spacing: 8, children: ['remote','hybrid','onsite'].map((m) =>
        ChoiceChip(label: Text(m), selected: _mode == m,
          onSelected: (_) => setState(() => _mode = _mode == m ? null : m)),
      ).toList()),
      const SizedBox(height: 24),
      SizedBox(width: double.infinity,
        child: ElevatedButton(onPressed: () => widget.onApply(_type, _mode), child: const Text('Apply Filters'))),
    ]),
  );
}
