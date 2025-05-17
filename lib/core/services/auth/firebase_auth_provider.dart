import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'
  show FirebaseAuth, FirebaseAuthException;
import 'package:ligne/data/models/remote/auth_user_model.dart';
import 'package:ligne/core/services/auth/auth_provider.dart';
import 'package:ligne/core/errors/auth_exception.dart';
import 'package:ligne/config/firebase/firebase_options.dart';

class FirebaseAuthProvider implements AuthProvider {
  @override
  AuthUserModel? get currentUser {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      return AuthUserModel.fromFirebase(user);
    } else {
      return null;
    }
  }

  @override
  Future<void> initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  @override
  Future<AuthUserModel> register({required String email, required String password}) async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password
      );

      final user = currentUser;

      if (user != null) {
        return user;
      } else {
        throw UserNotLoggedInAuthException();
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        throw WeakPasswordAuthException();
      } else if (e.code == 'email-already-in-use') {
        throw EmailAlreadyInUseAuthException();
      } else if (e.code == 'invalid-email') {
        throw InvalidEmailAuthException();
      } else if (e.code == 'network-request-failed') {
        throw RequestFailedAuthException();
      } else {
        throw UnknownAuthException();
      }
    } catch (e) {
      throw UnknownAuthException();
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      await user.sendEmailVerification();
    } else {
      throw UserNotLoggedInAuthException();
    }
  }

  @override
  Future<AuthUserModel> login({required String email, required String password}) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email, 
        password: password
      );

      final user = currentUser;
      
      if (user != null) {
        return user;
      } else {
        throw UserNotLoggedInAuthException();
      }
    } on FirebaseAuthException catch (e) {
      final loginError = [
        'user-not-found',
        'wrong-password',
        'invalid-email',
        'invalid-credential',
      ];

      if (loginError.any((error) => error == e.code)) {
        throw LoginIncorrectAuthException();
      } else if (e.code == 'network-request-failed') {
        throw RequestFailedAuthException();
      } else {
        throw UnknownAuthException();
      }
    } catch (e) {
      throw UnknownAuthException();
    }
  }

  @override
  Future<void> logout() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      await FirebaseAuth.instance.signOut();
    } else {
      throw UserNotLoggedInAuthException();
    }
  }
  
  @override
  Future<void> sendPasswordReset({required String toEmail}) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: toEmail);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'firebase_auth/invalid-email':
          throw InvalidEmailAuthException();
        case 'firebase_auth/user-not-found':
          throw UserNotFoundAuthException();
        default:
          throw UnknownAuthException();
      }
    } catch (e) {
      throw UnknownAuthException();
    }
  }
}
