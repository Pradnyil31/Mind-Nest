import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/welcome_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_flow_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/user_provider.dart';
import 'services/notification_service.dart';
import 'config/supabase_config.dart';

void main() async {
  // Force rebuild timestamp 2
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Notifications
  await NotificationService().init();

  // Initialize Supabase backend
  await SupabaseConfig.init();

  // Set edge-to-edge display
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );

  runApp(
    // Wrap the entire app with ProviderScope to enable Riverpod
    const ProviderScope(child: MindNestApp()),
  );
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

            // Check if user has completed onboarding by checking the onboardingCompleted field
            // This is set during onboarding flow, not automatically populated
            final onboardingCompleted = profile.onboardingCompleted ?? false;

            if (onboardingCompleted) {
              return const HomeScreen();
            } else {
              return const OnboardingFlowScreen();
            }
          },
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (error, stack) => Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error loading profile: $error'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Retry by invalidating the provider
                      ref.invalidate(userProfileProvider);
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Authentication error: $error'),
            ],
          ),
        ),
      ),
    );
  }
}
