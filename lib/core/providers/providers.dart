import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../storage/secure_storage_service.dart';
import '../services/auth_service.dart';
import '../services/admin_service.dart';
import '../services/attendance_service.dart';
import '../services/grade_service.dart';
import '../services/schedule_service.dart';
import '../services/announcement_service.dart';
import '../models/auth_response.dart';
import 'auth_notifier.dart';
import 'theme_mode_notifier.dart';

// Core infrastructure providers
final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient();
  ref.onDispose(client.dispose);
  return client;
});

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

// Service providers
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(storageService: ref.watch(secureStorageProvider));
});

final adminServiceProvider = Provider<AdminService>((ref) {
  return AdminService();
});

final attendanceServiceProvider = Provider<AttendanceService>((ref) {
  return AttendanceService();
});

final gradeServiceProvider = Provider<GradeService>((ref) {
  return GradeService();
});

final scheduleServiceProvider = Provider<ScheduleService>((ref) {
  return ScheduleService();
});

final announcementServiceProvider = Provider<AnnouncementService>((ref) {
  return AnnouncementService();
});

// Auth state management
final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<AuthResponse?>>((ref) {
      final notifier = AuthNotifier(ref.watch(authServiceProvider));
      final apiClient = ref.read(apiClientProvider);
      apiClient.setUnauthorizedHandler(notifier.handleUnauthorized);
      apiClient.setRefreshHandler(notifier.refreshSession);
      return notifier;
    });

// Current user provider
final currentUserProvider = Provider<AuthResponse?>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.value;
});

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((
  ref,
) {
  return ThemeModeNotifier(ref.watch(secureStorageProvider));
});

// Is authenticated provider
final isAuthenticatedProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user != null;
});
