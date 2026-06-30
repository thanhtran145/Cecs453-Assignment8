import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/note_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Required exactly once before any GoogleSignIn.instance call (v7+ API).
  // Throws UnimplementedError on platforms without a google_sign_in plugin
  // implementation (e.g. Windows/Linux desktop) — ignore it there so the
  // rest of the app (email/password auth) still works.
  try {
    await GoogleSignIn.instance.initialize(
      serverClientId:
          '725956001596-sqvna8eiq0rn43d88adgvnb91u8iffq9.apps.googleusercontent.com',
    );
  } on UnimplementedError {
    // No native Google Sign-In support on this platform.
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        // Notes are (re)loaded automatically per-account via the Firebase
        // auth-state listener inside NoteProvider — see note_provider.dart.
        ChangeNotifierProvider(create: (_) => NoteProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Authentication Lab',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

/// Watches global auth state and automatically switches between the
/// LoginScreen and HomeScreen — no manual navigation calls needed anywhere
/// else in the app. This is the "demonstrate global login" requirement.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().user;
    return user == null ? const LoginScreen() : const HomeScreen();
  }
}
