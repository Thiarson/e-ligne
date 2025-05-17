import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ligne/core/errors/auth_exception.dart';
import 'package:ligne/ui/bloc/auth/auth_bloc.dart';
import 'package:ligne/ui/bloc/auth/auth_event.dart';
import 'package:ligne/ui/bloc/auth/auth_state.dart';
import 'package:ligne/utils/dialogs/error_dialog.dart';
import 'package:ligne/utils/extensions/context/loc.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
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
        if (state is AuthStateRegistering) {
          if (state.exception is WeakPasswordAuthException) {
            await showErrorDialog(context, context.loc.register_error_weak_password);
          } else if (state.exception is EmailAlreadyInUseAuthException) {
            await showErrorDialog(context, context.loc.register_error_email_used);
          } else if (state.exception is InvalidEmailAuthException) {
            await showErrorDialog(context, context.loc.register_error_invalid_email);
          } else if (state.exception is RequestFailedAuthException) {
            await showErrorDialog(context, context.loc.internet_error);
          } else if (state.exception is UnknownAuthException) {
            await showErrorDialog(context, context.loc.register_generic_error);
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.loc.register),
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
                  autofocus: true,
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
                      .add(AuthEventRegister(
                        email: email, 
                        password: password
                      ));
                  },
                  child: Text(context.loc.register),
                ),
                TextButton(
                  onPressed: () {
                    context
                      .read<AuthBloc>()
                      .add(const AuthEventLogout());
                  },
                  child: Text(context.loc.register_to_login)
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
