import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/models.dart';
import '../data/services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

// Current Supabase user
final currentUserProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges.map((s) => s.session?.user);
});

// Loaded profile from DB
final profileProvider = FutureProvider.autoDispose<Profile?>((ref) async {
  final userAsync = ref.watch(currentUserProvider);
  final user = userAsync.value;
  if (user == null) return null;
  return ref.watch(authServiceProvider).fetchProfile(user.id);
});

// Auth state notifier for login/signup/logout actions
class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  AuthNotifier(this._service) : super(const AsyncValue.loading()) {
    _service.authStateChanges.listen((state) {
      this.state = AsyncValue.data(state.session?.user);
    });
  }

  final AuthService _service;

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _service.signUp(
        email: email, password: password,
        fullName: fullName, role: role,
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncValue.loading();
    try {
      await _service.signIn(email: email, password: password);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      await _service.signInWithGoogle();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signOut() => _service.signOut();

  Future<void> resetPassword(String email) => _service.resetPassword(email);
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<User?>>(
  (ref) => AuthNotifier(ref.watch(authServiceProvider)),
);
