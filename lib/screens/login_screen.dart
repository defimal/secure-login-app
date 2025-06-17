import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onToggle;
  final void Function(String name, String role) onLoginSuccess;

  const LoginScreen({
    super.key,
    required this.onToggle,
    required this.onLoginSuccess,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  String message = '';

  Future<void> signIn() async {
    try {
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      final user = userCredential.user;

      if (user != null && user.emailVerified) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (!doc.exists) {
          setState(() => message = '⚠️ No user data found in Firestore.');
          return;
        }

        final data = doc.data();
        final name = data?['name'] ?? 'User';
        final role = data?['role'] ?? 'user';

        widget.onLoginSuccess(name, role);
      } else {
        await FirebaseAuth.instance.signOut();
        setState(() => message = '⚠️ Please verify your email before signing in.');
      }
    } catch (e) {
      setState(() => message = '❌ ${e.toString()}');
    }
  }

  Future<void> signInWithGoogle() async {
    final userCredential = await AuthService.signInWithGoogle();
    final user = userCredential?.user;

    if (user != null) {
      final name = user.displayName ?? 'Google User';

      // Save user to Firestore if not exists
      final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final doc = await docRef.get();

      if (!doc.exists) {
        await docRef.set({
          'name': name,
          'email': user.email,
          'role': 'google_user',
          'createdAt': Timestamp.now(),
        });
      }

      widget.onLoginSuccess(name, 'google_user');
    } else {
      setState(() => message = '❌ Google sign-in canceled or failed.');
    }
  }

  Future<void> resendVerificationEmail() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        setState(() => message = '📧 Verification email resent.');
      } else {
        setState(() => message = '✅ Email is already verified.');
      }
    } catch (e) {
      setState(() => message = '❌ ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Login', style: TextStyle(fontSize: 32)),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: signIn, child: const Text('Sign In')),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.login),
              label: const Text('Sign in with Google'),
              onPressed: signInWithGoogle,
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: widget.onToggle,
              child: const Text("Don't have an account? Sign Up"),
            ),
            TextButton(
              onPressed: resendVerificationEmail,
              child: const Text("Resend Verification Email"),
            ),
            const SizedBox(height: 10),
            Text(message),
          ],
        ),
      ),
    );
  }
}

