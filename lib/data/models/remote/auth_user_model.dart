import 'package:flutter/widgets.dart';
import 'package:firebase_auth/firebase_auth.dart' show User;

@immutable
class AuthUserModel {
  final String id;
  final String email;
  final bool isEmailVerified;

  const AuthUserModel({
    required this.id,
    required this.email, 
    required this.isEmailVerified
  });

  factory AuthUserModel.fromFirebase(User user) => 
    AuthUserModel(id: user.uid, email: user.email!, isEmailVerified: user.emailVerified);
}
