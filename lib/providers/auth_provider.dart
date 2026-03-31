import 'package:flutter/foundation.dart';
import 'package:flutter_real_time_chat_app/models/user_model.dart';
import 'package:flutter_real_time_chat_app/services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  // service สำหรับจัดการ auth (login, register, etc.)
  final AuthService _authService = AuthService();
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ใช้เช็คว่า user login อยู่หรือไม่
  bool get isAuthenticated => _currentUser != null;

  // constructor: เรียก init ทันทีเมื่อ provider ถูกสร้าง
  AuthProvider() {
    _initAuth();
  }

  // ใช้สำหรับตรวจสอบ session ตอนเริ่มแอป
  Future<void> _initAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      // ถ้ามี session อยู่แล้ว (user เคย login)
      if (_authService.isLoggedIn) {
        // โหลด profile ของ user มาเก็บใน state
        _currentUser = await _authService.getCurrentUserProfile();
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // สมัครสมาชิก
  Future<bool> signUp({
    required String email,
    required String password,
    required String username,
    String? fullName,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      // เรียก service เพื่อสมัคร + ได้ user กลับมา
      _currentUser = await _authService.signUp(
        email: email,
        password: password,
        userName: username,
        fullName: fullName,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // เข้าสู่ระบบ
  Future<bool> signIn({required String email, required String password}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      // เรียก service เพื่อเข้าสู่ระบบ + ได้ user กลับมา
      _currentUser = await _authService.signIn(
        email: email,
        password: password,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ออกจากระบบ
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();
    // เรียก service เพื่อออกจากระบบ
    await _authService.signOut();
    // เคลียร์ข้อมูล user ใน state
    _currentUser = null;
    _isLoading = false;
    notifyListeners();
  }

  // อัปเดต profile user
  Future<bool> updateProfile({
    String? userName,
    String? fullName,
    String? bio,
    String? avatarUrl,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      // update profile ผ่าน service แล้ว replace state
      _currentUser = await _authService.updateProfile(
        username: userName,
        fullname: fullName,
        bio: bio,
        avatarUrl: avatarUrl,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // reset password (ส่ง email)
  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      // เรียก service เพื่อรีเซ็ตรหัสผ่าน
      await _authService.resetPassword(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // refresh ข้อมูล user จาก server
  Future<void> refreshUser() async {
    try {
      // ดึงข้อมูล profile ใหม่จาก server มาเก็บใน state
      _currentUser = await _authService.getCurrentUserProfile();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // ล้าง error (เช่น หลังจาก UI แสดง snackbar แล้ว)
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
