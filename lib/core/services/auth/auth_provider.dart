import 'package:ligne/data/models/remote/auth_user_model.dart';

abstract class AuthProvider {
  AuthUserModel? get currentUser;

  Future<void> initialize();

  Future<AuthUserModel> login({
    required String email,
    required String password
  });
  
  Future<AuthUserModel> register({
    required String email,
    required String password
  });

  Future<void> logout();
  
  Future<void> sendEmailVerification();

  Future<void> sendPasswordReset({required String toEmail});
}
