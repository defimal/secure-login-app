import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/dashboard_screen.dart';
import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  bool showLogin = true;

  void toggleAuthScreen() {
    setState(() => showLogin = !showLogin);
  }

  void loadDashboard(String name, String role) {
    navigatorKey.currentState!.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => DashboardScreen(
          name: name,
          role: role,
          onLogout: loadLoginScreen,
        ),
      ),
      (_) => false,
    );
  }

  void loadLoginScreen() {
    FirebaseAuth.instance.signOut();
    navigatorKey.currentState!.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => AuthScreenSwitcher(
          showLogin: true,
          onToggle: toggleAuthScreen,
          onLoginSuccess: loadDashboard,
        ),
      ),
      (_) => false,
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.emailVerified) {
        loadLoginScreen(); // triggers the screen that will fetch Firestore user data
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: themeMode,
      home: AuthScreenSwitcher(
        showLogin: showLogin,
        onToggle: toggleAuthScreen,
        onLoginSuccess: loadDashboard,
      ),
    );
  }
}

class AuthScreenSwitcher extends StatelessWidget {
  final bool showLogin;
  final VoidCallback onToggle;
  final void Function(String name, String role) onLoginSuccess;

  const AuthScreenSwitcher({
    super.key,
    required this.showLogin,
    required this.onToggle,
    required this.onLoginSuccess,
  });

  @override
  Widget build(BuildContext context) {
    return showLogin
        ? LoginScreen(
            onToggle: onToggle,
            onLoginSuccess: onLoginSuccess,
          )
        : SignupScreen(onToggle: onToggle);
  }
}
