import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/models.dart';
import '../../../providers/auth_provider.dart';
import 'student_dashboard.dart';
import 'recruiter_dashboard.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    return profileAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error:   (e, _) => Scaffold(body: Center(child: Text('$e'))),
      data: (profile) {
        if (profile == null) return const StudentDashboard();
        return switch (profile.role) {
          UserRole.recruiter => RecruiterDashboard(profile: profile),
          UserRole.admin     => RecruiterDashboard(profile: profile), // admin uses recruiter layout
          _                  => StudentDashboard(profile: profile),
        };
      },
    );
  }
}
