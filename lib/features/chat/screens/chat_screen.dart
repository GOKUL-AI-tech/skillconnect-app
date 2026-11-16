import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/helpers.dart';
import '../../../data/models/models.dart';
import '../../../data/services/database_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/avatar_widget.dart';

// ── Providers ──────────────────────────────────────────────────────────────

final _dbProvider = Provider((_) => DatabaseService());

/// Student: load all applications (each becomes a conversation)
final _myApplicationsProvider = FutureProvider.autoDispose<List<Application>>((ref) async {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return [];
  return ref.read(_dbProvider).fetchApplications(user.id);
});

/// Recruiter: load all applicants across the recruiter's jobs
final _recruiterApplicantsProvider = FutureProvider.autoDispose<List<Application>>((ref) async {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return [];
  final jobs = await ref.read(_dbProvider).fetchRecruiterJobs(user.id);
  final all = <Application>[];
  for (final job in jobs) {
    final apps = await ref.read(_dbProvider).fetchJobApplications(job.id);
    all.addAll(apps);
  }
  return all;
});

final _messagesProvider =
    FutureProvider.autoDispose.family<List<Message>, String>((ref, convId) {
  return ref.read(_dbProvider).fetchMessages(convId);
});

// ── Main Screen ────────────────────────────────────────────────────────────

class ChatScreen extends ConsumerStatefulWidget {
  /// When provided, the screen auto-opens the conversation for this application id.
  final String? initialAppId;
  const ChatScreen({super.key, this.initialAppId});
  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  Application? _activeApp;
  bool _autoOpenHandled = false;

  bool get _isRecruiter {
    final profile = ref.read(profileProvider).value;
    return profile?.role == UserRole.recruiter || profile?.role == UserRole.admin;
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider).value;
    final isRecruiter = profile?.role == UserRole.recruiter || profile?.role == UserRole.admin;

    final appsAsync = isRecruiter
        ? ref.watch(_recruiterApplicantsProvider)
        : ref.watch(_myApplicationsProvider);

    return appsAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
      data: (apps) {
        // Auto-open a specific conversation when initialAppId is provided (once only)
        if (widget.initialAppId != null && !_autoOpenHandled && _activeApp == null) {
          final match = apps.where((a) => a.id == widget.initialAppId).firstOrNull;
          if (match != null) {
            _autoOpenHandled = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _activeApp = match);
            });
          }
        }

        // No active conversation yet → show list
        if (_activeApp == null) {
          return _ConvListScreen(
            apps: apps,
            isRecruiter: isRecruiter,
            onSelect: (app) => setState(() => _activeApp = app),
          );
        }
        // Active conversation → show chat window
        return _ChatWindow(
          app: _activeApp!,
          isRecruiter: isRecruiter,
          onBack: () => setState(() => _activeApp = null),
        );
      },
    );
  }
}

// ── Conversation List ──────────────────────────────────────────────────────

class _ConvListScreen extends StatelessWidget {
  final List<Application> apps;
  final bool isRecruiter;
  final void Function(Application) onSelect;

  const _ConvListScreen({
    required this.apps,
    required this.isRecruiter,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (apps.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Messages',
          style: TextStyle(fontWeight: FontWeight.w800))),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 88, height: 88,
                decoration: BoxDecoration(
                  color: AppColors.brand600.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.chat_bubble_outline,
                  size: 40, color: AppColors.brand600),
              ),
              const SizedBox(height: 20),
              Text(
                isRecruiter ? 'No applicants yet' : 'No conversations yet',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.surface900),
              ),
              const SizedBox(height: 10),
              Text(
                isRecruiter
                    ? 'Once candidates apply to your job postings, you can chat with them here.'
                    : 'Apply to jobs to start chatting with recruiters. Your conversations will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, height: 1.6,
                  color: isDark ? AppColors.surface400 : AppColors.surface500),
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: () => context.go(isRecruiter ? '/post-job' : '/jobs'),
                icon: Icon(isRecruiter ? Icons.add : Icons.search, size: 18),
                label: Text(isRecruiter ? 'Post a Job' : 'Browse Jobs'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brand600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ]),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages', style: TextStyle(fontWeight: FontWeight.w800)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1,
            color: isDark ? AppColors.surface700 : AppColors.surface100),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        itemCount: apps.length,
        itemBuilder: (_, i) {
          final app = apps[i];
          final title  = isRecruiter
              ? (app.applicant?.fullName ?? 'Applicant')
              : (app.job?.company?.name ?? app.job?.title ?? 'Company');
          final sub    = app.job?.title ?? 'Applied';
          // Rotating accent, keyed off POSITION (not the id's hash) — with
          // similarly-generated ids (seed/test data especially) a hash can
          // collide and every row lands on the same bucket. Position always
          // rotates cleanly through the palette.
          final accent = AppColors.cardPalette[i % AppColors.cardPalette.length];

          return Container(
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
                  onTap: () => onSelect(app),
                  // IntrinsicHeight gives the Row below a finite height to
                  // stretch against — see job_card.dart for why this matters.
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Left accent bar — color-codes each row at a glance
                        Container(width: 4, color: accent),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.28), blurRadius: 8, offset: const Offset(0, 3))],
                                ),
                                child: AvatarWidget(
                                  imageUrl: isRecruiter
                                      ? app.applicant?.avatarUrl
                                      : app.job?.company?.logoUrl,
                                  name: title,
                                  size: 48,
                                  color: accent,
                                ),
                              ),
                              const SizedBox(width: 13),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(title,
                                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15,
                                    color: isDark ? Colors.white : AppColors.surface900),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 3),
                                Text(sub,
                                  style: TextStyle(fontSize: 12,
                                    color: isDark ? AppColors.surface400 : AppColors.surface500),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 7),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: accent.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                                    Icon(Icons.mail_outline, size: 12, color: accent),
                                    const SizedBox(width: 4),
                                    Text(appStatusLabel(app.status),
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                                        color: accent)),
                                  ]),
                                ),
                              ])),
                              const SizedBox(width: 6),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(timeAgo(app.appliedAt),
                                    style: TextStyle(fontSize: 11,
                                      color: isDark ? AppColors.surface500 : AppColors.surface400)),
                                  const SizedBox(height: 12),
                                  Icon(Icons.chevron_right, color: accent),
                                ],
                              ),
                            ]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Chat Window ────────────────────────────────────────────────────────────

class _ChatWindow extends ConsumerStatefulWidget {
  final Application app;
  final bool isRecruiter;
  final VoidCallback onBack;

  const _ChatWindow({
    required this.app,
    required this.isRecruiter,
    required this.onBack,
  });

  @override
  ConsumerState<_ChatWindow> createState() => _ChatWindowState();
}

class _ChatWindowState extends ConsumerState<_ChatWindow> {
  final _msgCtrl    = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<Message> _messages = [];
  bool _loading = true;
  bool _sending = false;

  String get _convId => widget.app.id; // application ID = conversation ID

  String get _otherName => widget.isRecruiter
      ? (widget.app.applicant?.fullName ?? 'Applicant')
      : (widget.app.job?.company?.name ?? widget.app.job?.title ?? 'Company');

  String get _otherSub => widget.isRecruiter
      ? (widget.app.job?.title ?? '')
      : 'Recruiter · ${widget.app.job?.company?.name ?? ''}';

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() => _loading = true);
    try {
      final msgs = await DatabaseService().fetchMessages(_convId);
      if (mounted) setState(() { _messages
        ..clear()
        ..addAll(msgs); });
      _scrollToBottom();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _sending) return;

    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    setState(() => _sending = true);
    _msgCtrl.clear();

    try {
      await DatabaseService().sendMessage(
        conversationId: _convId,
        senderId: user.id,
        content: text,
      );
      await _loadMessages();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to send: $e'),
          backgroundColor: AppColors.danger500));
        _msgCtrl.text = text; // restore
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final userId  = ref.watch(currentUserProvider).value?.id;
    final accent  = _statusColor(widget.app.status);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
        titleSpacing: 0,
        title: Row(children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: AvatarWidget(
              imageUrl: widget.isRecruiter
                  ? widget.app.applicant?.avatarUrl
                  : widget.app.job?.company?.logoUrl,
              name: _otherName,
              size: 38,
              color: accent,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_otherName,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis),
              Text(appStatusLabel(widget.app.status),
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: accent),
                overflow: TextOverflow.ellipsis),
            ]),
          ),
        ]),
        actions: [
          // Application status badge
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.mail_outline, size: 12, color: accent),
              const SizedBox(width: 4),
              Text(appStatusLabel(widget.app.status),
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: accent)),
            ]),
          ),
        ],
      ),

      body: Column(children: [
        // Application info banner
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(children: [
              Icon(Icons.work_outline, size: 15, color: accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Re: ${widget.app.job?.title ?? 'Job Application'}',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: accent),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ]),
          ),
        ),

        // Messages
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _messages.isEmpty
                  ? _EmptyChat(isDark: isDark, otherName: _otherName)
                  : ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      itemCount: _messages.length,
                      itemBuilder: (_, i) {
                        final m   = _messages[i];
                        final isMe = m.senderId == userId;
                        return _MessageBubble(
                          message: m, isMe: isMe, isDark: isDark);
                      },
                    ),
        ),

        // Input bar
        Container(
          padding: EdgeInsets.fromLTRB(
            12, 10, 12, MediaQuery.of(context).viewInsets.bottom + 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surface900 : Colors.white,
            border: Border(top: BorderSide(
              color: isDark ? AppColors.surface700 : AppColors.surface100)),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surface800 : AppColors.surface50,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: isDark ? AppColors.surface700 : AppColors.surface100),
                ),
                child: Row(children: [
                  Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent.withValues(alpha: 0.12),
                    ),
                    child: Icon(Icons.add, size: 18, color: accent),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _msgCtrl,
                      onSubmitted: (_) => _send(),
                      textInputAction: TextInputAction.send,
                      decoration: InputDecoration(
                        hintText: 'Type a message…',
                        hintStyle: TextStyle(
                          color: isDark ? AppColors.surface500 : AppColors.surface400),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
            const SizedBox(width: 10),
            ValueListenableBuilder(
              valueListenable: _msgCtrl,
              builder: (_, val, __) {
                final active = val.text.trim().isNotEmpty;
                return GestureDetector(
                  onTap: _send,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: active ? accent : (isDark ? AppColors.surface700 : AppColors.surface200),
                      boxShadow: active ? [
                        BoxShadow(color: accent.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 5)),
                      ] : [],
                    ),
                    child: _sending
                        ? const Padding(padding: EdgeInsets.all(14),
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Icon(Icons.send_rounded, size: 20,
                            color: active ? Colors.white : (isDark ? AppColors.surface500 : AppColors.surface400)),
                  ),
                );
              },
            ),
          ]),
        ),
      ]),
    );
  }

  Color _statusColor(String s) => switch (s) {
    'offer'       => AppColors.success500,
    'interview'   => AppColors.brand600,
    'shortlisted' => AppColors.warning500,
    'rejected'    => AppColors.danger500,
    'applied'     => AppColors.success500,
    'withdrawn'   => AppColors.purple500,
    _             => AppColors.accent500,
  };
}

// ── Message Bubble ─────────────────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final bool isDark;
  const _MessageBubble({required this.message, required this.isMe, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final time = TimeOfDay.fromDateTime(message.createdAt.toLocal());
    final timeStr =
        '${time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod}:${time.minute.toString().padLeft(2, '0')} ${time.period.name.toUpperCase()}';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72),
        margin: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? AppColors.brand600
                    : (isDark ? AppColors.surface700 : Colors.white),
                borderRadius: BorderRadius.only(
                  topLeft:     const Radius.circular(18),
                  topRight:    const Radius.circular(18),
                  bottomLeft:  Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
                boxShadow: isMe ? null : [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6, offset: const Offset(0, 2)),
                ],
              ),
              child: Text(message.content,
                style: TextStyle(fontSize: 14, height: 1.4,
                  color: isMe ? Colors.white
                      : (isDark ? Colors.white : AppColors.surface800))),
            ),
            const SizedBox(height: 3),
            Text(timeStr,
              style: TextStyle(fontSize: 10,
                color: isDark ? AppColors.surface500 : AppColors.surface400)),
          ],
        ),
      ),
    );
  }
}

// ── Empty Chat ─────────────────────────────────────────────────────────────
class _EmptyChat extends StatelessWidget {
  final bool isDark;
  final String otherName;
  const _EmptyChat({required this.isDark, required this.otherName});

  Widget _dot(Color color, double size) => Container(
    width: size, height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Decorative ring with scattered multi-color accent dots —
          // matches the app's illustrated-empty-state style elsewhere.
          SizedBox(
            width: 150, height: 150,
            child: Stack(alignment: Alignment.center, children: [
              Container(
                width: 140, height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.brand600.withValues(alpha: 0.06),
                ),
              ),
              Container(
                width: 92, height: 92,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.brand600.withValues(alpha: 0.12),
                ),
                child: const Icon(Icons.forum_outlined,
                  size: 36, color: AppColors.brand600),
              ),
              Positioned(top: 8,  left: 26, child: _dot(AppColors.accent500, 8)),
              Positioned(top: 22, right: 14, child: _dot(AppColors.warning500, 7)),
              Positioned(bottom: 18, left: 10, child: _dot(AppColors.teal500, 8)),
              Positioned(bottom: 28, right: 18, child: _dot(AppColors.purple500, 6)),
              Positioned(top: 60, left: 2, child: _dot(AppColors.brand600, 5)),
            ]),
          ),
          const SizedBox(height: 16),
          Text('Start the conversation!',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.surface900)),
          const SizedBox(height: 8),
          Text('Say hello to $otherName. Messages are private between you and them.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, height: 1.6,
              color: isDark ? AppColors.surface400 : AppColors.surface500)),
        ]),
      ),
    );
  }
}
