import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'signup_screen.dart';
import 'login_screen.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import 'home_screen.dart';
import 'onboarding_flow_screen.dart';

class AuthOptionsScreen extends ConsumerWidget {
  const AuthOptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/auth_background.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            const Spacer(),
            
            // Bottom Card with Auth Options
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(32, 40, 32, 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Continue with Google Button
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: () async {
                            try {
                              final authService = ref.read(authServiceProvider);
                              final userCredential = await authService.signInWithGoogle();
                              
                              if (userCredential != null && userCredential.user != null) {
                                 final user = userCredential.user!;
                                 
                                 // Check Firestore
                                 final userDoc = await ref.read(firestoreServiceProvider).getUserOnce(user.uid);
                                 
                                 bool onboardingCompleted = false;
                                 
                                 if (!userDoc.exists) {
                                    // Create new user
                                    await ref.read(firestoreServiceProvider).createUser(UserModel(
                                      uid: user.uid,
                                      email: user.email ?? '',
                                      displayName: user.displayName ?? 'New User',
                                      createdAt: DateTime.now(),
                                      lastLogin: DateTime.now(),
                                      signInMethod: 'google',
                                    ));
                                 } else {
                                    final data = userDoc.data();
                                    final mapData =
                                        data is Map<String, dynamic> ? data : <String, dynamic>{};
                                    onboardingCompleted = mapData['onboardingCompleted'] == true;
                                 }
                                 
                                 if (context.mounted) {
                                    Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => onboardingCompleted 
                                            ? const HomeScreen() 
                                            : const OnboardingFlowScreen(),
                                      ),
                                      (route) => false,
                                    );
                                 }
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Sign in failed: $e')),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2D2D2D),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Google Logo in Circle
                              Container(
                                width: 28,
                                height: 28,
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Image.asset(
                                  'assets/images/google_logo.png',
                                  width: 20,
                                  height: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Continue with Google',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Continue with Email Button
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SignUpScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF5F5F5),
                            foregroundColor: const Color(0xFF4A4A4A),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.email_outlined,
                                color: Colors.grey[700],
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Continue with Email',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),

                      // Login Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account?',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const LoginScreen()),
                              );
                            },
                            child: const Text(
                              'Log in',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFA78BFA),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Terms and Conditions
                      Text(
                        'by continuing, you agree with Mindnest\'s\nTerms & Conditions',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

