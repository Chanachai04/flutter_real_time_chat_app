import 'package:flutter_real_time_chat_app/models/user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  // สร้าง instance ของ SupabaseClient จาก global instance
  final SupabaseClient _supabase = Supabase.instance.client;

  // getter: เอา id ของ user ที่ login อยู่ตอนนี้
  String? get currentUserId => _supabase.auth.currentUser?.id;

  // getter: เอา object User ของ supabase (ไม่ใช่ UserModel)
  User? get currentUser => _supabase.auth.currentUser;

  // getter: เช็คว่า login อยู่ไหม
  bool get isLoggedIn => _supabase.auth.currentUser != null;

  // function สำหรับสมัครสมาชิก
  Future<UserModel?> signUp({
    required String email,
    required String password,
    required String userName,
    String? fullName,
  }) async {
    try {
      // เรียก Supabase Auth สมัคร user ใหม่
      final AuthResponse response = await _supabase.auth.signUp(
        email: email,
        password: password,
        // data = metadata ที่จะเก็บไปกับ user
        data: {'username': userName, 'full_name': fullName ?? ''},
      );

      // ถ้า signup ไม่ได้ user กลับมา → error
      if (response.user == null) throw Exception('Failed to sign up');

      // ไปดึงข้อมูล profile จาก table 'profiles'
      final profileDate = await _supabase
          .from('profiles')
          .select()
          .eq('id', response.user!.id)
          .single();

      // แปลง JSON ไปให้ UserModel
      return UserModel.fromJson(profileDate);

      // handle error จาก Supabase Auth โดยเฉพาะ
    } on AuthException catch (e) {
      throw Exception('Sign up failed: ${e.message}');
    } catch (e) {
      throw Exception('Sign up failed: $e');
    }
  }

  // function สำหรับ login
  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // เรียก Supabase Auth login
      final AuthResponse response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      // ถ้า login ไม่ได้ user กลับมา → error
      if (response.user == null) throw Exception('Failed to sign in');

      // ไปดึงข้อมูล profile จาก table 'profiles'
      final profileDate = await _supabase
          .from('profiles')
          .select()
          .eq('id', response.user!.id)
          .single();

      // แปลง JSON ไปให้ UserModel
      return UserModel.fromJson(profileDate);

      // handle error จาก Supabase Auth โดยเฉพาะ
    } on AuthException catch (e) {
      throw Exception('Sign in failed: ${e.message}');
    } catch (e) {
      throw Exception('Sign in failed: $e');
    }
  }

  // function สำหรับ logout
  Future<void> signOut() async {
    try {
      // เรียก Supabase Auth logout
      await _supabase.auth.signOut();
      // handle error จาก Supabase Auth โดยเฉพาะ
    } on AuthException catch (e) {
      throw Exception('Sign out failed: ${e.message}');
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  // function สำหรับดึงข้อมูล profile ของ user ที่ login อยู่ตอนนี้
  Future<UserModel?> getCurrentUserProfile() async {
    try {
      // เช็คก่อนว่า user login อยู่ไหม
      final userId = currentUserId;

      // ถ้าไม่ login ให้ return null
      if (userId == null) return null;

      // ไปดึงข้อมูล profile จาก table 'profiles'
      final profileDate = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      // แปลง JSON ไปให้ UserModel
      return UserModel.fromJson(profileDate);
    } catch (e) {
      throw Exception('Failed to fetch user profile: $e');
    }
  }

  // function สำหรับอัพเดทข้อมูล profile ของ user ที่ login อยู่ตอนนี้
  Future<UserModel> updateProfile({
    String? username,
    String? fullname,
    String? bio,
    String? avatarUrl,
  }) async {
    try {
      // เช็คก่อนว่า user login อยู่ไหม
      final userId = currentUserId;

      // ถ้าไม่ login ให้ throw error
      if (userId == null) throw Exception('No authenticated user');

      // สร้าง map สำหรับเก็บข้อมูลที่จะอัพเดท
      final updates = {
        if (username != null) 'username': username,
        if (fullname != null) 'full_name': fullname,
        if (bio != null) 'bio': bio,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // อัพเดทข้อมูลใน table 'profiles'
      final updatedProfile = await _supabase
          .from('profiles')
          .update(updates)
          .eq('id', userId)
          .single();

      // แปลง JSON ไปให้ UserModel
      return UserModel.fromJson(updatedProfile);
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // function สำหรับรีเซ็ตรหัสผ่าน
  Future<void> resetPassword(String email) async {
    try {
      // เรียก Supabase Auth รีเซ็ตรหัสผ่าน
      await _supabase.auth.resetPasswordForEmail(email);
      // handle error จาก Supabase Auth โดยเฉพาะ
    } on AuthException catch (e) {
      throw Exception('Password reset failed: ${e.message}');
    } catch (e) {
      throw Exception('Password reset failed: $e');
    }
  }

  // getter: ใช้ subscribe เพื่อติดตาม "สถานะการ login" แบบ real-time
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}
