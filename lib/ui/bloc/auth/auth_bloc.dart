import 'package:bloc/bloc.dart';
import 'package:ligne/core/services/auth/auth_provider.dart';
import 'package:ligne/ui/bloc/auth/auth_event.dart';
import 'package:ligne/ui/bloc/auth/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(AuthProvider provider) : 
    super(const AuthStateUninitialized (isLoading: true)) {

    // Initialize
    on<AuthEventInitialize>((event, emit) async {
      await provider.initialize();

      final user = provider.currentUser;  
      if (user == null) {
        emit(const AuthStateLoggedOut(
          exception: null, 
          isLoading: false,
        ));
      } else if (!user.isEmailVerified) {
        emit(const AuthStateNeedsVerification(isLoading: false));
      } else {
        emit(AuthStateLoggedIn(
          user: user, 
          isLoading: false,
        ));
      }
    });

    // Register
    on<AuthEventRegister>((event, emit) async {
      final email = event.email;
      final password = event.password;

      try {
        await provider.register(
          email: email, 
          password: password
        );

        await provider.sendEmailVerification();
        emit(const AuthStateNeedsVerification(isLoading: false));
      } on Exception catch (e) {
        emit(AuthStateRegistering(
          exception: e, 
          isLoading: false
        ));
      } 
    });

    // Should Register
    on<AuthEventShouldRegister>((event, emit) async {
      emit(const AuthStateRegistering(
        exception: null,
        isLoading: false,
      ));
    });

    // Send Emai Verification
    on<AuthEventSendEmailVerification>((event, emit) async {
      await provider.sendEmailVerification();
      emit(state);
    });

    // Login
    on<AuthEventLogin>((event, emit) async {
      emit(const AuthStateLoggedOut(
        exception: null, 
        isLoading: true,
        loadingText: 'Please wait while login...',
      ));

      final email = event.email;
      final password = event.password;

      try {
        final user = await provider.login(
          email: email, 
          password: password
        );

        if (!user.isEmailVerified) {
          emit(const AuthStateLoggedOut(
            exception: null, 
            isLoading: false
          ));
          emit(const AuthStateNeedsVerification(isLoading: false));
        } else {
          emit(const AuthStateLoggedOut(
            exception: null, 
            isLoading: false
          ));
          emit(AuthStateLoggedIn(
            user: user, 
            isLoading: false,
          ));
        }
      } on Exception catch (e) {
        emit(AuthStateLoggedOut(
          exception: e,
          isLoading: false,
        ));
      }
    });

    // Logout
    on<AuthEventLogout>((event, emit) async {
      try {
        await provider.logout();
        emit(const AuthStateLoggedOut(
          exception: null,
          isLoading: false,
        ));
      } on Exception catch (e) {
        emit(AuthStateLoggedOut(
          exception: e, 
          isLoading: false
        ));
      }
    });

    // Forgot Password
    on<AuthEventForgotPassword>((event, emit) async {
      emit(const AuthStateForgotPassword(
        exception: null, 
        hasSentEmail: false, 
        isLoading: false,
      ));

      final email = event.email;
      if (email == null) return; // Just go to the forgot-password screen

      // User send a forgot-password email
      emit(const AuthStateForgotPassword(
        exception: null, 
        hasSentEmail: false, 
        isLoading: true,
      ));

      bool didSendEmail;
      Exception? exception; 
      try {
        await provider.sendPasswordReset(toEmail: email);
        didSendEmail = true;
        exception = null;
      } on Exception catch (e) {
        didSendEmail = false;
        exception = e;
      }

       emit(AuthStateForgotPassword(
        exception: exception, 
        hasSentEmail: didSendEmail, 
        isLoading: false,
      ));
    });
  }
}
