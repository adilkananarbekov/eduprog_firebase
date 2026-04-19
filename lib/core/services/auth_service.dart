import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../api/api_exception.dart';
import '../models/auth_response.dart';
import '../models/managed_user.dart';
import '../storage/secure_storage_service.dart';

class AuthService {
  final FirebaseAuth? _firebaseAuthOverride;
  final FirebaseFirestore? _firestoreOverride;
  final SecureStorageService _storageService;

  FirebaseAuth get _firebaseAuth =>
      _firebaseAuthOverride ?? FirebaseAuth.instance;

  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;

  AuthService({
    required SecureStorageService storageService,
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  }) : _firebaseAuthOverride = firebaseAuth,
       _firestoreOverride = firestore,
       _storageService = storageService;

  Future<AuthResponse> login(String email, String password) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final authResponse = await _buildAuthResponse(
        credential.user,
        forceRefresh: true,
      );
      await _storageService.saveAuthResponse(authResponse);
      await _storageService.saveSavedEmail(email.trim());
      await _storageService.deleteSavedPassword();
      return authResponse;
    } on FirebaseAuthException catch (error) {
      throw _mapAuthException(error);
    } on FirebaseException catch (error) {
      throw _mapFirebaseException(error);
    } catch (error) {
      throw UnknownException(
        'Sign in failed. Please try again.',
        originalError: error,
      );
    }
  }

  Future<AuthResponse> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String role,
    int? classGroupId,
  }) async {
    throw ForbiddenException(
      'Self-registration is disabled. Only administrators can create new accounts.',
      statusCode: 403,
    );
  }

  Future<AuthResponse> registerInitial({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    throw ForbiddenException(
      'Initial admin setup must be completed from Firebase Console or the Admin SDK.',
      statusCode: 403,
    );
  }

  Future<void> logout() async {
    await _firebaseAuth.signOut();
    await _storageService.clearAll();
  }

  Future<AuthResponse?> getCurrentUser() async {
    final cached = await _storageService.getAuthResponse();
    if (cached != null) {
      return cached;
    }

    final user = _firebaseAuth.currentUser;
    if (user == null) {
      return null;
    }

    final authResponse = await _buildAuthResponse(user);
    await _storageService.saveAuthResponse(authResponse);
    return authResponse;
  }

  Future<String?> getSavedEmail() async {
    return await _storageService.getSavedEmail();
  }

  Future<String?> getSavedPassword() async {
    return await _storageService.getSavedPassword();
  }

  Future<AuthResponse?> refreshSession() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      return null;
    }

    final refreshed = await _buildAuthResponse(user, forceRefresh: true);
    await _storageService.saveAuthResponse(refreshed);
    return refreshed;
  }

  Future<bool> isAuthenticated() async {
    return _firebaseAuth.currentUser != null;
  }

  Future<void> initialize() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      await _storageService.deleteAuthResponse();
      await _storageService.deleteToken();
      return;
    }

    final authResponse = await _buildAuthResponse(user);
    await _storageService.saveAuthResponse(authResponse);
  }

  Future<AuthResponse> _buildAuthResponse(
    User? user, {
    bool forceRefresh = false,
  }) async {
    if (user == null) {
      throw UnauthorizedException('No active Firebase session found.');
    }

    final profileSnapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .get();
    if (!profileSnapshot.exists) {
      await _firebaseAuth.signOut();
      await _storageService.clearAll();
      throw ForbiddenException(
        'Your account is not provisioned yet. Ask an administrator to create your profile.',
        statusCode: 403,
      );
    }

    final profile = ManagedUser.fromDocument(profileSnapshot);
    if (!profile.isActive) {
      await _firebaseAuth.signOut();
      await _storageService.clearAll();
      throw ForbiddenException(
        'Your account is disabled. Contact an administrator.',
        statusCode: 403,
      );
    }

    final idToken = await user.getIdToken(forceRefresh);
    return AuthResponse(
      token: idToken ?? '',
      type: 'Bearer',
      refreshToken: null,
      userId: profile.id,
      email: profile.email.isNotEmpty ? profile.email : (user.email ?? ''),
      firstName: profile.firstName,
      lastName: profile.lastName,
      role: profile.role,
      profileId: profile.id,
      classGroupId: profile.classGroupId,
    );
  }

  ApiException _mapAuthException(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
      case 'invalid-email':
        return UnauthorizedException(
          'Incorrect email or password.',
          statusCode: 401,
        );
      case 'user-disabled':
        return ForbiddenException(
          'Your account is disabled. Contact an administrator.',
          statusCode: 403,
        );
      case 'network-request-failed':
        return NetworkException(
          'Unable to reach Firebase. Check your internet connection.',
          originalError: error,
        );
      case 'too-many-requests':
        return ValidationException(
          'Too many sign-in attempts. Try again later.',
          statusCode: 429,
        );
      default:
        return UnknownException(
          error.message ?? 'Authentication failed.',
          originalError: error,
        );
    }
  }

  ApiException _mapFirebaseException(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
        return ForbiddenException(
          'You do not have permission to access this data.',
          statusCode: 403,
        );
      case 'unavailable':
        return NetworkException(
          'Firebase is currently unavailable.',
          originalError: error,
        );
      default:
        return UnknownException(
          error.message ?? 'Firebase request failed.',
          originalError: error,
        );
    }
  }
}
