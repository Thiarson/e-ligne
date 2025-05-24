import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ligne/l10n/gen/app_localizations.dart';
// import 'package:ligne/core/router/routes.dart';
import 'package:ligne/core/services/auth/firebase_auth_provider.dart';
import 'package:ligne/ui/bloc/auth/auth_bloc.dart';
import 'package:ligne/ui/views/home/home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      title: 'E-ligne',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: BlocProvider<AuthBloc>(
        create: (context) => AuthBloc(FirebaseAuthProvider()),
        child: const HomePage(),
      ),
      routes: {
        // editNoteRoute: (context) => const EditNoteView(),
      },
    );
  }
}
