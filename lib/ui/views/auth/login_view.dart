import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ligne/core/errors/auth_exception.dart';
import 'package:ligne/ui/bloc/auth/auth_bloc.dart';
import 'package:ligne/ui/bloc/auth/auth_event.dart';
import 'package:ligne/ui/bloc/auth/auth_state.dart';
import 'package:ligne/utils/dialogs/error_dialog.dart';
import 'package:ligne/utils/extensions/context/loc.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  late final TextEditingController _email;
  late final TextEditingController _password;

  @override
  void initState() {
    _email = TextEditingController();
    _password = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) async {
        if (state is AuthStateLoggedOut) {
          if (state.exception is LoginIncorrectAuthException) {
            await showErrorDialog(context, context.loc.login_error_wrong_credentials);
          } else if (state.exception is RequestFailedAuthException) {
            await showErrorDialog(context, context.loc.internet_error);
          } else if (state.exception is UnknownAuthException) {
            await showErrorDialog(context, context.loc.login_generic_error);
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.loc.login),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: Padding(
          padding: const EdgeInsets.all(10.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: InputDecoration(
                    hintText: 'Email'
                  ),
                ),
                TextField(
                  controller: _password,
                  obscureText: true,
                  enableSuggestions: false,
                  autocorrect: false,
                  decoration: InputDecoration(
                    hintText: 'Password'
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final email = _email.text;
                    final password = _password.text;
                      
                    context
                      .read<AuthBloc>()
                      .add(AuthEventLogin(
                        email: email, 
                        password: password
                      ));
                  },
                  child: Text(context.loc.login),
                ),
                TextButton(
                  onPressed: () {
                    context
                      .read<AuthBloc>()
                      .add(const AuthEventForgotPassword());
                  },
                  child: Text(context.loc.login_forgot_password)
                ),
                TextButton(
                  onPressed: () {
                    context
                      .read<AuthBloc>()
                      .add(const AuthEventShouldRegister());
                  },
                  child: Text(context.loc.login_not_register_yet)
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
