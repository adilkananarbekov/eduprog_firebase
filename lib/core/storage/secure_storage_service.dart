import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/auth_response.dart';

/// Service for secure storage of sensitive data like tokens
class SecureStorageService {
  static const _tokenKey = 'auth_token';
  static const _authResponseKey = 'auth_response';
  static const _themeModeKey = 'theme_mode';
  static const _savedEmailKey = 'saved_email';
  static const _savedPasswordKey = 'saved_password';

  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock_this_device,
            ),
          );

  /// Save authentication token
  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  /// Get authentication token
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  /// Delete authentication token
  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  /// Save complete authentication response
  Future<void> saveAuthResponse(AuthResponse authResponse) async {
    final jsonString = json.encode(authResponse.toJson());
    await _storage.write(key: _authResponseKey, value: jsonString);
    await saveToken(authResponse.token);
  }

  /// Get saved authentication response
  Future<AuthResponse?> getAuthResponse() async {
    final jsonString = await _storage.read(key: _authResponseKey);
    if (jsonString == null) return null;

    try {
      final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
      return AuthResponse.fromJson(jsonMap);
    } catch (e) {
      // If parsing fails, clear the whole auth payload so a stale token cannot
      // survive without its matching user context.
      await clearAll();
      return null;
    }
  }

  /// Delete authentication response
  Future<void> deleteAuthResponse() async {
    await _storage.delete(key: _authResponseKey);
  }

  /// Clear all stored data
  Future<void> clearAll() async {
    await deleteAuthResponse();
    await deleteToken();
  }

  Future<void> saveSavedEmail(String email) async {
    await _storage.write(key: _savedEmailKey, value: email);
  }

  Future<void> saveSavedCredentials({
    required String email,
    required String password,
  }) async {
    await saveSavedEmail(email);
    await _storage.write(key: _savedPasswordKey, value: password);
  }

  Future<String?> getSavedEmail() async {
    return await _storage.read(key: _savedEmailKey);
  }

  Future<String?> getSavedPassword() async {
    return await _storage.read(key: _savedPasswordKey);
  }

  Future<void> deleteSavedPassword() async {
    await _storage.delete(key: _savedPasswordKey);
  }

  Future<void> clearSavedCredentials() async {
    await _storage.delete(key: _savedEmailKey);
    await deleteSavedPassword();
  }

  /// Check if user is authenticated (has valid token)
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> saveThemeMode(String themeMode) async {
    await _storage.write(key: _themeModeKey, value: themeMode);
  }

  Future<String?> getThemeMode() async {
    return await _storage.read(key: _themeModeKey);
  }
}
