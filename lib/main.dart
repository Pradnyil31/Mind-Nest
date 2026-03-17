import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'screens/welcome_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_flow_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/user_provider.dart';
import 'services/notification_service.dart';

void main() async {
  try {
    // Force rebuild timestamp 2
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize Firebase with proper configuration.
    //
    // In rare cases (hot restart / plugin pre-init), the native layer may have
    // already created the default app even if `Firebase.apps` is not yet
    // populated on the Dart side. Treat duplicate-app as a no-op.
    if (Firebase.apps.isEmpty) {
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      } on FirebaseException catch (e) {
        if (e.code != 'duplicate-app') rethrow;
        debugPrint('Firebase default app already exists; continuing.');
      }
    } else {
      debugPrint('Firebase already initialized');
    }

    // Initialize Notifications
    try {
      await NotificationService().init();
    } catch (e) {
      // Notification initialization failure shouldn't block app startup
      debugPrint('Notification initialization failed: $e');
    }

    // Enable Firestore offline persistence
    try {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
    } catch (e) {
      // Firestore settings failure shouldn't block app startup
      debugPrint('Firestore settings failed: $e');
    }

    // Set edge-to-edge display
    try {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: Colors.transparent,
        ),
      );
    } catch (e) {
      // UI settings failure shouldn't block app startup
      debugPrint('System UI settings failed: $e');
    }

    runApp(
      // Wrap the entire app with ProviderScope to enable Riverpod
      const ProviderScope(child: MindNestApp()),
    );
  } catch (e, stackTrace) {
    // If Firebase initialization fails, show error screen
    debugPrint('App initialization failed: $e');
    debugPrint('Stack trace: $stackTrace');

    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'App Initialization Failed',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Error: $e',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Restart the app
                    main();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MindNestApp extends StatelessWidget {
  const MindNestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MindNest',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFA78BFA),
          primary: const Color(0xFFA78BFA),
          secondary: const Color(0xFFF5C9D6),
        ),
        useMaterial3: true,
        fontFamily: 'Inter',
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: ZoomPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

// Authentication wrapper using Riverpod
class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch auth state using Riverpod
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          // User not signed in -> show welcome screen
          return const WelcomeScreen();
        }

        // User signed in -> check onboarding status
        final userProfile = ref.watch(userProfileProvider);

        return userProfile.when(
          data: (profile) {
            if (profile == null) {
              // Profile doesn't exist yet (shouldn't happen, but handle gracefully)
              return const WelcomeScreen();
            }

            // Check if user has completed onboarding
            // For now, we check if displayName is set (set during onboarding)
            final hasCompletedOnboarding = profile.displayName.isNotEmpty;

            if (hasCompletedOnboarding) {
              return const HomeScreen();
            } else {
              return const OnboardingFlowScreen();
            }
          },
          loading: () => const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading profile...'),
                ],
              ),
            ),
          ),
          error: (error, stack) {
            debugPrint('User profile error: $error');
            debugPrint('Stack trace: $stack');
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    const Text('Error loading profile'),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        // Retry by invalidating the provider
                        ref.invalidate(userProfileProvider);
                      },
                      child: const Text('Retry'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        // Fallback to welcome screen
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => const WelcomeScreen(),
                          ),
                        );
                      },
                      child: const Text('Go to Welcome'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Initializing...'),
            ],
          ),
        ),
      ),
      error: (error, stack) {
        debugPrint('Auth state error: $error');
        debugPrint('Stack trace: $stack');
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                const Text('Authentication Error'),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Retry by invalidating the provider
                    ref.invalidate(authStateProvider);
                  },
                  child: const Text('Retry'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    // Fallback to welcome screen
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const WelcomeScreen(),
                      ),
                    );
                  },
                  child: const Text('Continue Offline'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
