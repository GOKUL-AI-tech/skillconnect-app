import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

class DatabaseService {
  final _db = Supabase.instance.client;

  // ── Jobs ──────────────────────────────────────────────────────────────────
  Future<List<Job>> fetchJobs({
    String? search,
    String? type,
    String? mode,
    String? level,
    bool featuredOnly = false,
    // When set, scopes the results to jobs posted by this recruiter only —
    // used by the recruiter's own "Browse" tab so it never shows postings
    // from other companies/recruiters.
    String? postedBy,
  }) async {
    var q = _db.from('jobs').select('*, companies(*)').eq('is_active', true);

    if (featuredOnly) q = q.eq('is_featured', true);
    if (type != null)  q = q.eq('type', type);
    if (mode != null)  q = q.eq('mode', mode);
    if (level != null) q = q.eq('level', level);
    if (postedBy != null) q = q.eq('posted_by', postedBy);
    if (search != null && search.isNotEmpty) {
      q = q.ilike('title', '%$search%');
    }

    final res = await q.order('created_at', ascending: false).limit(50);
    return (res as List).map((j) => Job.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<Job?> fetchJob(String id) async {
    final res = await _db
        .from('jobs')
        .select('*, companies(*)')
        .eq('id', id)
        .maybeSingle();
    if (res == null) return null;
    await _db.rpc('increment_job_views', params: {'job_id': id});
    return Job.fromJson(res as Map<String, dynamic>);
  }

  // ── Saved Jobs ────────────────────────────────────────────────────────────
  Future<List<String>> fetchSavedJobIds(String profileId) async {
    final res = await _db
        .from('saved_jobs')
        .select('job_id')
        .eq('profile_id', profileId);
    return (res as List).map((r) => r['job_id'] as String).toList();
  }

  Future<void> saveJob(String profileId, String jobId) async {
    await _db.from('saved_jobs').upsert({
      'profile_id': profileId,
      'job_id':     jobId,
    });
  }

  Future<void> unsaveJob(String profileId, String jobId) async {
    await _db.from('saved_jobs')
        .delete()
        .eq('profile_id', profileId)
        .eq('job_id', jobId);
  }

  // ── Applications ──────────────────────────────────────────────────────────
  Future<List<Application>> fetchApplications(String profileId) async {
    final res = await _db
        .from('applications')
        .select('*, jobs(*, companies(*))')
        .eq('applicant_id', profileId)
        .order('applied_at', ascending: false);
    return (res as List)
        .map((a) => Application.fromJson(a as Map<String, dynamic>))
        .toList();
  }

  Future<List<String>> fetchAppliedJobIds(String profileId) async {
    final res = await _db
        .from('applications')
        .select('job_id')
        .eq('applicant_id', profileId);
    return (res as List).map((r) => r['job_id'] as String).toList();
  }

  /// Fetch the specific application a student made for one job.
  Future<Application?> fetchApplicationForJob(String profileId, String jobId) async {
    final res = await _db
        .from('applications')
        .select('*, jobs(*, companies(*))')
        .eq('applicant_id', profileId)
        .eq('job_id', jobId)
        .maybeSingle();
    if (res == null) return null;
    return Application.fromJson(res as Map<String, dynamic>);
  }

  Future<void> applyToJob({
    required String jobId,
    required String applicantId,
    String? coverLetter,
    String? recruiterId,
    String? jobTitle,
    String? applicantName,
  }) async {
    // Insert application and get back its generated id
    final res = await _db.from('applications').insert({
      'job_id':       jobId,
      'applicant_id': applicantId,
      'cover_letter': coverLetter,
      'status':       'applied',
    }).select('id').single();

    final applicationId = res['id'] as String;

    // Create a matching conversation row so the chat FK is satisfied
    await _db.from('conversations').upsert(
      {'id': applicationId},
      onConflict: 'id',
    );

    // Notify the recruiter
    if (recruiterId != null && jobTitle != null) {
      final name = applicantName?.isNotEmpty == true ? applicantName! : 'Someone';
      await createNotification(
        profileId: recruiterId,
        type:      'new_application',
        title:     'New Application Received',
        body:      '$name applied for "$jobTitle"',
      );
    }
  }

  Future<void> createNotification({
    required String profileId,
    required String type,
    required String title,
    String? body,
  }) async {
    await _db.from('notifications').insert({
      'profile_id': profileId,
      'type':       type,
      'title':      title,
      'body':       body,
      'is_read':    false,
    });
  }

  // ── Recruiter — jobs + applicants ─────────────────────────────────────────
  Future<List<Job>> fetchRecruiterJobs(String postedBy) async {
    // Fetch jobs with company info
    final res = await _db
        .from('jobs')
        .select('*, companies(*)')
        .eq('posted_by', postedBy)
        .order('created_at', ascending: false);

    final jobs = (res as List)
        .map((j) => Job.fromJson(j as Map<String, dynamic>))
        .toList();

    if (jobs.isEmpty) return jobs;

    // Fetch live application counts for all these jobs in one query
    final jobIds = jobs.map((j) => j.id).toList();
    final countRes = await _db
        .from('applications')
        .select('job_id')
        .inFilter('job_id', jobIds);

    // Build a count map: jobId → count
    final counts = <String, int>{};
    for (final row in countRes as List) {
      final jid = row['job_id'] as String;
      counts[jid] = (counts[jid] ?? 0) + 1;
    }

    // Inject live counts into each job
    return jobs
        .map((j) => j.copyWith(applicationsCount: counts[j.id] ?? 0))
        .toList();
  }

  Future<List<Application>> fetchJobApplications(String jobId) async {
    final res = await _db
        .from('applications')
        .select('*, profiles(*)')
        .eq('job_id', jobId)
        .order('applied_at', ascending: false);
    return (res as List)
        .map((a) => Application.fromJson(a as Map<String, dynamic>))
        .toList();
  }

  Future<void> postJob(Map<String, dynamic> data) async {
    await _db.from('jobs').insert(data);
  }

  /// Generate a URL-safe slug from a company name.
  /// e.g. "Google LLC" → "google-llc", "Meta Platforms!" → "meta-platforms"
  String _slugify(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '') // remove special chars
        .trim()
        .replaceAll(RegExp(r'\s+'), '-')           // spaces → hyphens
        .replaceAll(RegExp(r'-+'), '-');            // collapse multiple hyphens
  }

  /// Find or create a company by name, returns the full row including id.
  Future<Map<String, dynamic>> upsertCompany(String name, [String? ownerId]) async {
    // Check if company already exists (case-insensitive)
    final existing = await _db
        .from('companies')
        .select()
        .ilike('name', name)
        .maybeSingle();
    if (existing != null) return existing as Map<String, dynamic>;

    // Generate a slug; if it collides, append a short random suffix
    final baseSlug = _slugify(name);
    String slug = baseSlug;

    // Check slug uniqueness
    final slugExists = await _db
        .from('companies')
        .select('id')
        .eq('slug', slug)
        .maybeSingle();
    if (slugExists != null) {
      // Append timestamp suffix to guarantee uniqueness
      slug = '$baseSlug-${DateTime.now().millisecondsSinceEpoch % 100000}';
    }

    // Create new company
    final res = await _db.from('companies').insert({
      'name': name,
      'slug': slug,
    }).select().single();
    return res as Map<String, dynamic>;
  }

  // ── Application status ────────────────────────────────────────────────────
  Future<void> updateApplicationStatus(
    String applicationId,
    String status, {
    String? applicantId,
    String? jobTitle,
  }) async {
    await _db
        .from('applications')
        .update({'status': status})
        .eq('id', applicationId);

    // Notify the applicant about the status change
    if (applicantId != null && jobTitle != null) {
      final title = switch (status) {
        'shortlisted' => 'Application Shortlisted!',
        'interview'   => 'Interview Invitation',
        'offer'       => 'Offer Received! 🎉',
        'rejected'    => 'Application Update',
        _             => 'Application Status Updated',
      };
      final body = switch (status) {
        'shortlisted' => 'You\'ve been shortlisted for "$jobTitle"',
        'interview'   => 'You\'re invited to interview for "$jobTitle"',
        'offer'       => 'Congratulations! You received an offer for "$jobTitle"',
        'rejected'    => 'Your application for "$jobTitle" was not selected this time',
        _             => 'Your application status changed for "$jobTitle"',
      };
      await createNotification(
        profileId: applicantId,
        type:      'status_update',
        title:     title,
        body:      body,
      );
    }
  }

  // ── Notifications ─────────────────────────────────────────────────────────
  Future<List<AppNotification>> fetchNotifications(String profileId) async {
    final res = await _db
        .from('notifications')
        .select()
        .eq('profile_id', profileId)
        .order('created_at', ascending: false)
        .limit(50);
    return (res as List)
        .map((n) => AppNotification.fromJson(n as Map<String, dynamic>))
        .toList();
  }

  Future<void> markNotificationRead(String id) async {
    await _db.from('notifications').update({'is_read': true}).eq('id', id);
  }

  Future<void> markAllNotificationsRead(String profileId) async {
    await _db.from('notifications')
        .update({'is_read': true})
        .eq('profile_id', profileId);
  }

  // ── Messages ──────────────────────────────────────────────────────────────
  Future<List<Message>> fetchMessages(String conversationId) async {
    final res = await _db
        .from('messages')
        .select()
        .eq('conversation_id', conversationId)
        .order('created_at');
    return (res as List)
        .map((m) => Message.fromJson(m as Map<String, dynamic>))
        .toList();
  }

  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String content,
  }) async {
    // Ensure conversation row exists before inserting message (FK guard).
    // Handles applications created before the auto-create logic was added.
    await _db.from('conversations').upsert(
      {'id': conversationId},
      onConflict: 'id',
    );

    await _db.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id':       senderId,
      'content':         content,
    });
  }

  // ── Realtime ──────────────────────────────────────────────────────────────
  RealtimeChannel subscribeToMessages(
    String conversationId,
    void Function(Message) onMessage,
  ) {
    return _db
        .channel('messages:$conversationId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (payload) {
            final msg = Message.fromJson(payload.newRecord);
            onMessage(msg);
          },
        )
        .subscribe();
  }
}