import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  Future<void>? _googleInitialization;

  Stream<User?> get authStateChanges =>
      _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final result = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    await result.user?.updateDisplayName(name.trim());

    return result;
  }

  Future<UserCredential> login({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> loginWithGoogle() async {
    if (kIsWeb) {
      return _auth.signInWithPopup(
        GoogleAuthProvider(),
      );
    }

    // Google Sign-In 7.x cho Android
    _googleInitialization ??=
        GoogleSignIn.instance.initialize();

    await _googleInitialization;

    final googleUser =
        await GoogleSignIn.instance.authenticate();

    final idToken = googleUser.authentication.idToken;

    if (idToken == null) {
      throw StateError(
        'Không nhận được Google ID Token. '
        'Hãy kiểm tra cấu hình SHA và google-services.json.',
      );
    }

    final credential = GoogleAuthProvider.credential(
      idToken: idToken,
    );

    return _auth.signInWithCredential(credential);
  }

  Future<void> resetPassword(String email) {
    return _auth.sendPasswordResetEmail(
      email: email.trim(),
    );
  }

  Future<void> logout() async {
    if (!kIsWeb && _googleInitialization != null) {
      try {
        await _googleInitialization;
        await GoogleSignIn.instance.signOut();
      } catch (error) {
        debugPrint('Google sign out error: $error');
      }
    }

    await _auth.signOut();
  }

  static String errorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'Địa chỉ Email không hợp lệ.';
      case 'email-already-in-use':
        return 'Email đã được sử dụng.';
      case 'weak-password':
        return 'Mật khẩu quá yếu.';
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Email hoặc mật khẩu không chính xác.';
      case 'network-request-failed':
        return 'Không có kết nối Internet.';
      case 'too-many-requests':
        return 'Bạn thao tác quá nhiều lần. Hãy thử lại sau.';
      case 'operation-not-allowed':
        return 'Phương thức đăng nhập chưa được kích hoạt.';
      default:
        return error.message ??
            'Không thể xác thực tài khoản (${error.code}).';
    }
  }
}