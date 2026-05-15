import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/auth_gate.dart';
import 'screens/setup/firebase_setup_screen.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final bootstrap = await _initializeFirebase();

  runApp(
    PontualApp(firebaseReady: bootstrap.ready, firebaseError: bootstrap.error),
  );
}

Future<_FirebaseBootstrap> _initializeFirebase() async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    return const _FirebaseBootstrap.ready();
  } on Object catch (error) {
    return _FirebaseBootstrap.failed(error);
  }
}

class PontualApp extends StatelessWidget {
  const PontualApp({
    required this.firebaseReady,
    required this.firebaseError,
    super.key,
  });

  final bool firebaseReady;
  final Object? firebaseError;

  @override
  Widget build(BuildContext context) {
    if (!firebaseReady) {
      return MaterialApp(
        title: 'Pontual',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: FirebaseSetupScreen(error: firebaseError),
      );
    }
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: MaterialApp(
        title: 'Pontual',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const AuthGate(),
      ),
    );
  }
}

class _FirebaseBootstrap {
  const _FirebaseBootstrap.ready() : ready = true, error = null;

  const _FirebaseBootstrap.failed(this.error) : ready = false;

  final bool ready;
  final Object? error;
}
