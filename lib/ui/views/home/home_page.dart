import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ligne/ui/bloc/auth/auth_bloc.dart';
import 'package:ligne/ui/bloc/auth/auth_event.dart';
import 'package:ligne/ui/bloc/auth/auth_state.dart';
import 'package:ligne/ui/views/admin/admin_view.dart';
import 'package:ligne/ui/views/auth/forgot_password_view.dart';
import 'package:ligne/ui/views/auth/login_view.dart';
import 'package:ligne/ui/views/auth/register_view.dart';
import 'package:ligne/ui/views/auth/verify_email.dart';
import 'package:ligne/ui/widgets/circular_loading.dart';
import 'package:ligne/utils/extensions/context/loc.dart';
import 'package:ligne/utils/helpers/loading_screen.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    context
      .read<AuthBloc>()
      .add(const AuthEventInitialize());

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.isLoading) {
          LoadingScreen().show(
            context: context, 
            content: state.loadingText ?? context.loc.loading,
          );
        } else {
          LoadingScreen().hide();
        }
      },
      builder: (context, state) {
        if (state is AuthStateLoggedIn) {
          return const AdminView();
        } else if (state is AuthStateRegistering) {
          return const RegisterView();
        } else if (state is AuthStateNeedsVerification) {
          return const VerifyEmailView();
        } else if (state is AuthStateLoggedOut) {
          return const LoginView();
        } else if (state is AuthStateForgotPassword) {
          return const ForgotPasswordView();
        } else {
          return const Scaffold(
            body: CircularLoading(),
          );
        }
      },
    );
  }
}
