// SkillConnect data models — mirrors supabase/schema.sql

enum UserRole { student, recruiter, admin }
enum JobType  { full_time, part_time, internship, freelance, contract }
enum JobMode  { remote, hybrid, onsite }
enum AppStatus { applied, shortlisted, interview, offer, rejected, withdrawn }

class Profile {
  final String  id;
  final UserRole role;
  final String? fullName;
  final String? username;
  final String? avatarUrl;
  final String? headline;
  final String? bio;
  final String? location;
  final String? website;
  final String? githubUrl;
  final String? linkedinUrl;
  final String? resumeUrl;
  final String? phone;
  final bool    isVerified;
  final bool    openToWork;
  final bool    isPublic;
  final int     profileScore;
  final DateTime createdAt;

  const Profile({
    required this.id,
    required this.role,
    this.fullName,
    this.username,
    this.avatarUrl,
    this.headline,
    this.bio,
    this.location,
    this.website,
    this.githubUrl,
    this.linkedinUrl,
    this.resumeUrl,
    this.phone,
    this.isVerified = false,
    this.openToWork = false,
    this.isPublic = true,
    this.profileScore = 0,
    required this.createdAt,
  });

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
    id:           j['id'] as String,
    role:         UserRole.values.firstWhere((e) => e.name == j['role'], orElse: () => UserRole.student),
    fullName:     j['full_name'] as String?,
    username:     j['username'] as String?,
    avatarUrl:    j['avatar_url'] as String?,
    headline:     j['headline'] as String?,
    bio:          j['bio'] as String?,
    location:     j['location'] as String?,
    website:      j['website'] as String?,
    githubUrl:    j['github_url'] as String?,
    linkedinUrl:  j['linkedin_url'] as String?,
    resumeUrl:    j['resume_url'] as String?,
    phone:        j['phone'] as String?,
    isVerified:   j['is_verified'] as bool? ?? false,
    openToWork:   j['open_to_work'] as bool? ?? false,
    isPublic:     j['is_public'] as bool? ?? true,
    profileScore: j['profile_score'] as int? ?? 0,
    createdAt:    DateTime.parse(j['created_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'full_name':    fullName,
    'headline':     headline,
    'bio':          bio,
    'location':     location,
    'website':      website,
    'github_url':   githubUrl,
    'linkedin_url': linkedinUrl,
    'phone':        phone,
    'open_to_work': openToWork,
  };
}

class Company {
  final String  id;
  final String  name;
  final String? logoUrl;
  final String? industry;
  final String? location;
  final String? website;
  final String? description;
  final bool    isVerified;

  const Company({
    required this.id,
    required this.name,
    this.logoUrl,
    this.industry,
    this.location,
    this.website,
    this.description,
    this.isVerified = false,
  });

  factory Company.fromJson(Map<String, dynamic> j) => Company(
    id:          j['id'] as String,
    name:        j['name'] as String,
    logoUrl:     j['logo_url'] as String?,
    industry:    j['industry'] as String?,
    location:    j['location'] as String?,
    website:     j['website'] as String?,
    description: j['description'] as String?,
    isVerified:  j['is_verified'] as bool? ?? false,
  );
}

class Job {
  final String   id;
  final String   title;
  final String   description;
  final String   type;
  final String   mode;
  final String   level;
  final String?  location;
  final int?     salaryMin;
  final int?     salaryMax;
  final String   salaryUnit; // 'lpa' | 'thousands'
  final List<String> skillsRequired;
  final int      openings;
  final bool     isActive;
  final bool     isFeatured;
  final int      views;
  final int      applicationsCount;
  final DateTime createdAt;
  final Company? company;
  final String?  postedBy;

  const Job({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.mode,
    required this.level,
    this.location,
    this.salaryMin,
    this.salaryMax,
    this.salaryUnit = 'lpa',
    required this.skillsRequired,
    this.openings = 1,
    this.isActive = true,
    this.isFeatured = false,
    this.views = 0,
    this.applicationsCount = 0,
    required this.createdAt,
    this.company,
    this.postedBy,
  });

  Job copyWith({int? applicationsCount, int? views}) => Job(
    id:                id,
    title:             title,
    description:       description,
    type:              type,
    mode:              mode,
    level:             level,
    location:          location,
    salaryMin:         salaryMin,
    salaryMax:         salaryMax,
    salaryUnit:        salaryUnit,
    skillsRequired:    skillsRequired,
    openings:          openings,
    isActive:          isActive,
    isFeatured:        isFeatured,
    views:             views ?? this.views,
    applicationsCount: applicationsCount ?? this.applicationsCount,
    createdAt:         createdAt,
    company:           company,
    postedBy:          postedBy,
  );

  factory Job.fromJson(Map<String, dynamic> j) => Job(
    id:                j['id'] as String,
    title:             j['title'] as String,
    description:       j['description'] as String,
    type:              j['type'] as String,
    mode:              j['mode'] as String,
    level:             j['level'] as String,
    location:          j['location'] as String?,
    salaryMin:         j['salary_min'] as int?,
    salaryMax:         j['salary_max'] as int?,
    salaryUnit:        j['salary_unit'] as String? ?? 'lpa',
    skillsRequired:    (j['skills_required'] as List<dynamic>?)
                           ?.map((e) => e as String).toList() ?? [],
    openings:          j['openings'] as int? ?? 1,
    isActive:          j['is_active'] as bool? ?? true,
    isFeatured:        j['is_featured'] as bool? ?? false,
    views:             j['views'] as int? ?? 0,
    applicationsCount: j['applications_count'] as int? ?? 0,
    createdAt:         DateTime.parse(j['created_at'] as String),
    company:           j['companies'] != null
        ? Company.fromJson(j['companies'] as Map<String, dynamic>)
        : null,
    postedBy:          j['posted_by'] as String?,
  );
}

class Application {
  final String    id;
  final String    jobId;
  final String    applicantId;
  final String    status;
  final String?   coverLetter;
  final DateTime  appliedAt;
  final Job?      job;
  final Profile?  applicant;

  const Application({
    required this.id,
    required this.jobId,
    required this.applicantId,
    required this.status,
    this.coverLetter,
    required this.appliedAt,
    this.job,
    this.applicant,
  });

  factory Application.fromJson(Map<String, dynamic> j) => Application(
    id:           j['id'] as String,
    jobId:        j['job_id'] as String,
    applicantId:  j['applicant_id'] as String,
    status:       j['status'] as String,
    coverLetter:  j['cover_letter'] as String?,
    appliedAt:    DateTime.parse(j['applied_at'] as String),
    job: j['jobs'] != null ? Job.fromJson(j['jobs'] as Map<String, dynamic>) : null,
    applicant: j['profiles'] != null ? Profile.fromJson(j['profiles'] as Map<String, dynamic>) : null,
  );
}

class SavedJob {
  final String profileId;
  final String jobId;
  final DateTime savedAt;
  final Job? job;

  const SavedJob({
    required this.profileId,
    required this.jobId,
    required this.savedAt,
    this.job,
  });

  factory SavedJob.fromJson(Map<String, dynamic> j) => SavedJob(
    profileId: j['profile_id'] as String,
    jobId:     j['job_id'] as String,
    savedAt:   DateTime.parse(j['saved_at'] as String),
    job: j['jobs'] != null ? Job.fromJson(j['jobs'] as Map<String, dynamic>) : null,
  );
}

class AppNotification {
  final String  id;
  final String  type;
  final String  title;
  final String? body;
  final bool    isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    this.body,
    this.isRead = false,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
    id:        j['id'] as String,
    type:      j['type'] as String,
    title:     j['title'] as String,
    body:      j['body'] as String?,
    isRead:    j['is_read'] as bool? ?? false,
    createdAt: DateTime.parse(j['created_at'] as String),
  );
}

class Message {
  final String  id;
  final String  conversationId;
  final String? senderId;
  final String  content;
  final bool    isRead;
  final DateTime createdAt;

  const Message({
    required this.id,
    required this.conversationId,
    this.senderId,
    required this.content,
    this.isRead = false,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> j) => Message(
    id:             j['id'] as String,
    conversationId: j['conversation_id'] as String,
    senderId:       j['sender_id'] as String?,
    content:        j['content'] as String,
    isRead:         j['is_read'] as bool? ?? false,
    createdAt:      DateTime.parse(j['created_at'] as String),
  );
}
