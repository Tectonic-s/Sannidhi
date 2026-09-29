import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/models/user_model.dart';
import '../core/services/firebase_service.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasSkippedLogin = false;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null && (_currentUser!.token?.isNotEmpty ?? false);
  bool get hasSkippedLogin => _hasSkippedLogin;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void skipLogin() {
    _hasSkippedLogin = true;
    notifyListeners();
  }

  bool get isDevotee => _currentUser?.isDevotee ?? true;
  bool get isStaff => _currentUser?.isStaff ?? false;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  String get token => _currentUser?.token ?? '';

  static String get backendUrl {
    const defined = String.fromEnvironment('BACKEND_BASE_URL');
    if (defined.isNotEmpty) return defined;
    if (kIsWeb) return 'http://localhost:3000';
    if (Platform.isAndroid) return 'http://10.0.2.2:3000';
    return 'http://127.0.0.1:3000';
  }

  // ── Restore saved session from SharedPreferences ────────────────────────────
  Future<void> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('sannidhi_user');
      final token = prefs.getString('sannidhi_token');

      if (userJson != null && token != null) {
        final map = jsonDecode(userJson) as Map<String, dynamic>;
        _currentUser = UserModel.fromJson(map, token: token);
        notifyListeners();
        // Background verify / refresh
        _verifyTokenWithBackend();
      }
    } catch (e) {
      debugPrint('[Auth] Error restoring session: $e');
    }
  }

  Future<void> _verifyTokenWithBackend() async {
    if (_currentUser?.token == null) return;
    try {
      final response = await http.get(
        Uri.parse('$backendUrl/api/auth/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_currentUser!.token}',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final user = body['user'] as Map<String, dynamic>;
        _currentUser = UserModel.fromJson(user, token: _currentUser!.token);
        _saveToPrefs();
        notifyListeners();
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        // Token expired
        logout();
      }
    } catch (_) {
      // Offline mode: keep local cached session
    }
  }

  // ── Login ───────────────────────────────────────────────────────────────────
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // 1. Try Firebase Authentication first
    try {
      final fbUser = await FirebaseService.instance.login(
        email: email,
        password: password,
      );
      if (fbUser != null) {
        _currentUser = fbUser;
        await _saveToPrefs();
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (fbError) {
      debugPrint('[Auth] Firebase login skipped/error: $fbError');
    }

    // 2. Fallback to Express backend or demo accounts
    try {
      final response = await http.post(
        Uri.parse('$backendUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim().toLowerCase(),
          'password': password,
        }),
      ).timeout(const Duration(seconds: 2));

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        final token = body['token'] as String;
        final userMap = body['user'] as Map<String, dynamic>;
        _currentUser = UserModel.fromJson(userMap, token: token);
        await _saveToPrefs();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = body['error'] as String? ?? 'Login failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      // 3. Demo / offline account fallback if backend is offline
      final clean = email.trim().toLowerCase();
      final role = clean.contains('admin')
          ? UserRole.admin
          : (clean.contains('staff') ? UserRole.staff : UserRole.devotee);
      _currentUser = UserModel(
        id: 'user_${role.toDbString()}_${DateTime.now().millisecondsSinceEpoch}',
        name: role == UserRole.devotee
            ? (clean.split('@').first.toUpperCase())
            : role.displayName,
        email: clean,
        phone: '9876543210',
        role: role,
        token: 'token_${DateTime.now().millisecondsSinceEpoch}',
      );
      await _saveToPrefs();
      _isLoading = false;
      notifyListeners();
      return true;
    }
  }

  // ── Register ────────────────────────────────────────────────────────────────
  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    String role = 'devotee',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // 1. Try Firebase Auth + Firestore
    try {
      final fbUser = await FirebaseService.instance.register(
        name: name,
        email: email,
        phone: phone,
        password: password,
        role: role,
      );
      if (fbUser != null) {
        _currentUser = fbUser;
        await _saveToPrefs();
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (fbError) {
      debugPrint('[Auth] Firebase register error: $fbError');
    }

    // 2. Fallback to Express backend
    try {
      final response = await http.post(
        Uri.parse('$backendUrl/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name.trim(),
          'email': email.trim().toLowerCase(),
          'phone': phone.trim(),
          'password': password,
          'role': role,
        }),
      ).timeout(const Duration(seconds: 8));

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 201) {
        final token = body['token'] as String;
        final userMap = body['user'] as Map<String, dynamic>;
        _currentUser = UserModel.fromJson(userMap, token: token);
        await _saveToPrefs();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = body['error'] as String? ?? 'Registration failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      // Local fallback
      final userRole = UserRole.fromString(role);
      _currentUser = UserModel(
        id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        email: email,
        phone: phone,
        role: userRole,
        token: 'token_${DateTime.now().millisecondsSinceEpoch}',
      );
      await _saveToPrefs();
      _isLoading = false;
      notifyListeners();
      return true;
    }
  }

  // ── Logout ──────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    _currentUser = null;
    _errorMessage = null;
    _hasSkippedLogin = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('sannidhi_user');
      await prefs.remove('sannidhi_token');
    } catch (_) {}
    notifyListeners();
  }

  Future<void> _saveToPrefs() async {
    if (_currentUser == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('sannidhi_user', jsonEncode(_currentUser!.toJson()));
      if (_currentUser!.token != null) {
        await prefs.setString('sannidhi_token', _currentUser!.token!);
      }
    } catch (e) {
      debugPrint('[Auth] Error saving to prefs: $e');
    }
  }
}
