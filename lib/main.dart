import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'auth/screens/animated_welcome_screen.dart';
import 'auth/screens/login_screen.dart';
import 'home/modern_home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Final Year Project',
      debugShowCheckedModeBanner: false,

      // 🎨 MODERN LIGHT THEME (Attractive & Clean)
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFF0F4F8),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5B9BD5), // Soft Blue
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.black,
        ),
      ),

      home: const AuthWrapper(),
    );
  }
}

/// 🔐 AUTH WRAPPER
/// NOT LOGGED IN → WelcomeScreen
/// LOGGED IN → ModernHomePage
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // ⏳ Loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF5B9BD5),
              ),
            ),
          );
        }

        // ❌ NOT LOGGED IN
        if (!snapshot.hasData) {
          return const AnimatedWelcomeScreen();
        }

        // ✅ LOGGED IN
        return const ModernHomePage();
      },
    );
  }
}
