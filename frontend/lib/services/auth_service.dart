// lib/services/auth_service.dart
import 'package:freelancer_platform/utils/token_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';
import 'api_service.dart';

class AuthService {
  final supabase = Supabase.instance.client;

Future<Map<String, dynamic>> login(String email, String password) async {
  try {
    final apiResponse = await ApiService.login(email, password);

    if (apiResponse['token'] != null) {
      AuthResponse supabaseResponse;
      try {
        supabaseResponse = await supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );
        print('✅ Supabase login successful');
      } catch (e) {
        print('⚠️ User not in Supabase, signing up...');
        supabaseResponse = await supabase.auth.signUp(
          email: email,
          password: password,
        );
        
        if (supabaseResponse.user != null) {
          print('✅ User signed up, logging in automatically...');
          supabaseResponse = await supabase.auth.signInWithPassword(
            email: email,
            password: password,
          );
        }
      }

      final userData = apiResponse['user'];
      await _syncUserWithSupabase(userData);

      await TokenStorage.saveSupabaseUserId(supabaseResponse.user!.id);
      
      print('✅ Current Supabase user: ${supabase.auth.currentUser?.id}');
      print('✅ Session exists: ${supabase.auth.currentSession != null}');
    }

    return apiResponse;
  } catch (e) {
    print('❌ Login error: $e');
    return {'message': 'فشل تسجيل الدخول: $e'};
  }
}
  Future<void> _syncUserWithSupabase(Map<String, dynamic> userData) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await supabase.from('profiles').upsert({
        'id': userId,
        'full_name': userData['name'],
        'role': userData['role'],
        'avatar_url': userData['avatar'] != null 
            ? 'https://freelancer-app-h6os.onrender.com${userData['avatar']}'
            : null,
        'updated_at': DateTime.now().toIso8601String(),
      });
      print('✅ User synced with Supabase');
    } catch (e) {
      print('❌ Error syncing user: $e');
    }
  }

  bool get isLoggedIn => supabase.auth.currentUser != null;

  User? get currentUser => supabase.auth.currentUser;

  Future<Profile?> getCurrentProfile() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final response = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      return Profile.fromJson(response);
    } catch (e) {
      print('❌ Error getting profile: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await supabase.auth.signOut();
      await ApiService.logout();
      print('✅ Signed out successfully');
    } catch (e) {
      print('❌ Error signing out: $e');
    }
  }

  Stream<AuthState> get authStateChange => supabase.auth.onAuthStateChange;
}