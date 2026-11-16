import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/helpers.dart';
import '../../../data/models/models.dart';
import '../../../data/services/database_service.dart';
import '../../../providers/auth_provider.dart';

final _notifsProvider = FutureProvider.autoDispose<List<AppNotification>>((ref) async {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return [];
  return DatabaseService().fetchNotifications(user.id);
});

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final async   = ref.watch(_notifsProvider);
    final user    = ref.watch(currentUserProvider).value;

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: Material(
            color: Colors.white,
            shape: const CircleBorder(),
            elevation: 2,
            shadowColor: Colors.black.withValues(alpha: 0.1),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => context.go('/profile'),
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.arrow_back, size: 18, color: AppColors.brand600),
              ),
            ),
          ),
        ),
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: user == null ? null : () async {
              await DatabaseService().markAllNotificationsRead(user.id);
              ref.invalidate(_notifsProvider);
            },
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => Center(child: Text('$e')),
        data: (notifs) {
          if (notifs.isEmpty) return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.notifications_none, size: 56, color: isDark ? AppColors.surface600 : AppColors.surface300),
              const SizedBox(height: 12),
              Text('All caught up!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                color: isDark ? AppColors.surface400 : AppColors.surface500)),
            ]),
          );
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(_notifsProvider),
            child: ListView.separated(
              itemCount: notifs.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final n = notifs[i];
                return _NotifTile(
                  notif: n,
                  isDark: isDark,
                  onTap: () async {
                    if (!n.isRead && user != null) {
                      await DatabaseService().markNotificationRead(n.id);
                      ref.invalidate(_notifsProvider);
                    }
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final AppNotification notif;
  final bool isDark;
  final VoidCallback onTap;
  const _NotifTile({required this.notif, required this.isDark, required this.onTap});

  IconData get _icon => switch (notif.type) {
    'application' => Icons.work_outline,
    'message'     => Icons.chat_bubble_outline,
    'job_match'   => Icons.star_outline,
    _             => Icons.notifications_outlined,
  };

  Color get _color => switch (notif.type) {
    'application' => AppColors.brand600,
    'message'     => AppColors.accent500,
    'job_match'   => AppColors.warning500,
    _             => AppColors.success500,
  };

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      color: notif.isRead ? null : _color.withValues(alpha: 0.04),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: _color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(_icon, color: _color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(notif.title, style: TextStyle(fontSize: 14,
            fontWeight: notif.isRead ? FontWeight.w500 : FontWeight.w700,
            color: isDark ? Colors.white : AppColors.surface900)),
          if (notif.body != null) ...[
            const SizedBox(height: 2),
            Text(notif.body!, style: TextStyle(fontSize: 13,
              color: isDark ? AppColors.surface400 : AppColors.surface500),
              maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: 4),
          Text(timeAgo(notif.createdAt), style: TextStyle(fontSize: 11,
            color: isDark ? AppColors.surface500 : AppColors.surface400)),
        ])),
        if (!notif.isRead)
          Container(width: 8, height: 8,
            margin: const EdgeInsets.only(top: 4),
            decoration: const BoxDecoration(color: AppColors.brand600, shape: BoxShape.circle)),
      ]),
    ),
  );
}
