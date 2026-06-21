import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:globalshop/notifications/fcm_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';
import 'firebase_options.dart';
import 'auth/screens/animated_welcome_screen.dart';
import 'home/modern_home_page.dart';
import 'providers/providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🎨 Load saved theme before app starts
  final prefs = await SharedPreferences.getInstance();
  final savedTheme = prefs.getString('theme_mode');
  final initialTheme = savedTheme == 'dark' ? ThemeMode.dark : ThemeMode.light;

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Initialize FCM without awaiting so it doesn't block runApp
    FCMService.init().catchError((e) {
      debugPrint("FCM Init Error: $e");
    });
  } catch (e) {
    debugPrint("Firebase Init Error: $e");
  }

  runApp(
    ProviderScope(
      overrides: [
        // Inject saved theme as initial value
        themeModeProvider.overrideWith((ref) => ThemeModeNotifier(initialTheme)),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'GlobalShop',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,

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

      // 🌌 FUTURISTIC INDUSTRIAL DARK THEME
      darkTheme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFF0F1016),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5B9BD5),
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
        ),
      ),

      home: const AuthWrapper(),
    );
  }
}

/// 🔐 AUTH WRAPPER
/// NOT LOGGED IN → WelcomeScreen
/// LOGGED IN → ModernHomePage
class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(authStateChangesProvider).when(
      loading: () => Scaffold(
        body: Center(
          child: Lottie.asset(
            'assets/animations/loader.json',
            width: 160,
            height: 160,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const CircularProgressIndicator(
                color: Color(0xFF5B9BD5),
              );
            },
          ),
        ),
      ),
      error: (err, stack) => const AnimatedWelcomeScreen(),
      data: (user) {
        if (user == null) {
          return const AnimatedWelcomeScreen();
        }
        return const ModernHomePage();
      },
    );
  }
}  