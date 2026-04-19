import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/auth_response.dart';
import '../services/auth_service.dart';

/// State notifier for managing authentication state
class AuthNotifier extends StateNotifier<AsyncValue<AuthResponse?>> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AsyncValue.loading()) {
    _initialize();
  }

  void _log(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  /// Initialize auth state from storage
  Future<void> _initialize() async {
    _log('[AUTH] Session restore started');
    try {
      await _authService.initialize();
      final user = await _authService.getCurrentUser();
      state = AsyncValue.data(user);
      _log(
        user == null
            ? '[AUTH] No persisted session found'
            : '[AUTH] Persisted session restored',
      );
    } catch (e, stack) {
      _log('[AUTH] Session restore failed: $e');
      state = AsyncValue.error(e, stack);
    }
  }

  /// Login with email and password
  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final authResponse = await _authService.login(email, password);
      state = AsyncValue.data(authResponse);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Logout current user
  Future<void> logout() async {
    try {
      await _authService.logout();
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Refresh current user data
  Future<void> refresh() async {
    try {
      final user = await _authService.getCurrentUser();
      state = AsyncValue.data(user);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<bool> refreshSession() async {
    try {
      final authResponse = await _authService.refreshSession();
      if (authResponse == null) {
        return false;
      }

      state = AsyncValue.data(authResponse);
      return true;
    } catch (e) {
      _log('[AUTH] Token refresh failed: $e');
      return false;
    }
  }

  /// Handle global unauthorized responses (e.g. expired JWT)
  Future<void> handleUnauthorized() async {
    await _authService.logout();
    state = const AsyncValue.data(null);
  }
}
