import 'package:flutter/foundation.dart' show immutable;
import 'package:equatable/equatable.dart';
import 'package:ligne/data/models/remote/auth_user_model.dart';

@immutable
abstract class AuthState {
  final bool isLoading;
  final String? loadingText;
  final String? errorMessage;

  const AuthState({
    required this.isLoading, 
    this.loadingText = 'Please wait a moment',
    this.errorMessage,
  });

  /// Creates a copy of this state with the given fields replaced by the new values
  AuthState copyWith({
    bool? isLoading,
    String? loadingText,
    String? errorMessage,
  });
}

class AuthStateUninitialized extends AuthState {
  const AuthStateUninitialized({
    required super.isLoading,
    super.errorMessage,
  });

  @override
  AuthState copyWith({
    bool? isLoading,
    String? loadingText,
    String? errorMessage,
  }) {
    return AuthStateUninitialized(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class AuthStateRegistering extends AuthState {
  final Exception? exception;

  const AuthStateRegistering({
    required this.exception, 
    required super.isLoading,
    super.errorMessage,
  });

  @override
  AuthState copyWith({
    bool? isLoading,
    String? loadingText,
    String? errorMessage,
    Exception? exception,
  }) {
    return AuthStateRegistering(
      isLoading: isLoading ?? this.isLoading,
      exception: exception ?? this.exception,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class AuthStateLoggedIn extends AuthState {
  final AuthUserModel user;

  const AuthStateLoggedIn({
    required this.user, 
    required super.isLoading,
    super.errorMessage,
  });

  @override
  AuthState copyWith({
    bool? isLoading,
    String? loadingText,
    String? errorMessage,
  }) {
    return AuthStateLoggedIn(
      user: user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class AuthStateNeedsVerification extends AuthState {
  const AuthStateNeedsVerification({
    required super.isLoading,
    super.errorMessage,
  });

  @override
  AuthState copyWith({
    bool? isLoading,
    String? loadingText,
    String? errorMessage,
  }) {
    return AuthStateNeedsVerification(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class AuthStateLoggedOut extends AuthState with EquatableMixin {
  final Exception? exception;

  const AuthStateLoggedOut({
    required this.exception, 
    required super.isLoading,
    super.loadingText,
    super.errorMessage,
  });
  
  @override
  List<Object?> get props => [exception, isLoading, errorMessage];

  @override
  AuthState copyWith({
    bool? isLoading,
    String? loadingText,
    String? errorMessage,
    Exception? exception,
  }) {
    return AuthStateLoggedOut(
      exception: exception ?? this.exception,
      isLoading: isLoading ?? this.isLoading,
      loadingText: loadingText ?? this.loadingText,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class AuthStateForgotPassword extends AuthState {
  final Exception? exception;
  final bool hasSentEmail;

  const AuthStateForgotPassword({
    required this.exception, 
    required this.hasSentEmail, 
    required super.isLoading,
    super.errorMessage,
  });

  @override
  AuthState copyWith({
    bool? isLoading,
    String? loadingText,
    String? errorMessage,
    Exception? exception,
    bool? hasSentEmail,
  }) {
    return AuthStateForgotPassword(
      exception: exception ?? this.exception,
      hasSentEmail: hasSentEmail ?? this.hasSentEmail,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
