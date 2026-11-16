import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

class AuthService {
  final _client = Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;
  Session? get currentSession => _client.auth.currentSession;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // ── Sign Up ──────────────────────────────────────────────────────────────
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role,
  }) async {
    return _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName, 'role': role},
    );
  }

  // ── Sign In ──────────────────────────────────────────────────────────────
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // ── Google OAuth ─────────────────────────────────────────────────────────
  Future<bool> signInWithGoogle() async {
    return _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.skillconnect.app://login-callback',
    );
  }

  // ── Sign Out ─────────────────────────────────────────────────────────────
  Future<void> signOut() => _client.auth.signOut();

  // ── Password Reset ───────────────────────────────────────────────────────
  Future<void> resetPassword(String email) =>
      _client.auth.resetPasswordForEmail(email);

  // ── Fetch Profile ─────────────────────────────────────────────────────────
  Future<Profile?> fetchProfile(String userId) async {
    final res = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (res == null) return null;
    return Profile.fromJson(res as Map<String, dynamic>);
  }

  // ── Update Profile ────────────────────────────────────────────────────────
  Future<void> updateProfile(String userId, Map<String, dynamic> data) async {
    await _client.from('profiles').update(data).eq('id', userId);
  }

  // ── Upload Avatar ─────────────────────────────────────────────────────────
  Future<String?> uploadAvatar(String userId, List<int> bytes, String ext) async {
    final path = '$userId/avatar.$ext';
    await _client.storage
        .from('avatars')
        .uploadBinary(path, Uint8List.fromList(bytes), fileOptions: FileOptions(upsert: true));
    final base = _client.storage.from('avatars').getPublicUrl(path);
    // Cache-bust: the storage path is stable (avatar.$ext, upsert:true), so
    // without a changing query param a cached image would keep showing the
    // old photo after a replace.
    final url = '$base?v=${DateTime.now().millisecondsSinceEpoch}';
    // Save avatar_url back to profile
    await _client.from('profiles').update({'avatar_url': url}).eq('id', userId);
    return url;
  }

  // ── Upload Resume ─────────────────────────────────────────────────────────
  Future<String?> uploadResume(String userId, List<int> bytes, String fileName) async {
    final path = '$userId/$fileName';
    await _client.storage
        .from('resumes')
        .uploadBinary(path, Uint8List.fromList(bytes), fileOptions: FileOptions(upsert: true));
    final url = _client.storage.from('resumes').getPublicUrl(path);
    // Save resume_url back to profile
    await _client.from('profiles').update({'resume_url': url}).eq('id', userId);
    return url;
  }
}
