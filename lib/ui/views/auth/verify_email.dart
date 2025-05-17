import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ligne/ui/bloc/auth/auth_bloc.dart';
import 'package:ligne/ui/bloc/auth/auth_event.dart';
import 'package:ligne/utils/extensions/context/loc.dart';

class VerifyEmailView extends StatefulWidget {
  const VerifyEmailView({super.key});

  @override
  State<VerifyEmailView> createState() => _VerifyEmailViewState();
}

class _VerifyEmailViewState extends State<VerifyEmailView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.loc.verify_email),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Text(context.loc.verify_email_sent_email_verif),
              Text(context.loc.verify_email_click_link),
              TextButton(
                onPressed: () {
                  context
                    .read<AuthBloc>()
                    .add(const AuthEventSendEmailVerification());
                },
                child: Text(context.loc.verify_email_send_verification)
              ),
              TextButton(
                onPressed: () {
                  context
                    .read<AuthBloc>()
                    .add(const AuthEventLogout());
                },
                child: Text(context.loc.verify_email_restart_registration)
              ),
            ],
          ),
        ),
      ),
    );
  }
}
