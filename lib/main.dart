import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'config/app_branding.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/user_provider.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_flow_screen.dart';
import 'screens/welcome_screen.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
// ROLLBACK P1: offline import disabled
// import 'features/calm/application/offline_data_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AppBootstrapper());
}

class AppBootstrapper extends StatefulWidget {
  const AppBootstrapper({super.key});

  @override
  State<AppBootstrapper> createState() => _AppBootstrapperState();
}

class _AppBootstrapperState extends State<AppBootstrapper> {
  bool _initialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() {
      _error = null;
      _initialized = false;
    });

    try {
      await dotenv.load(fileName: ".env");
      await _initializeFirebase().timeout(const Duration(seconds: 15));
      await _initializeNotifications().timeout(const Duration(seconds: 8));
      await _configureFirestore().timeout(const Duration(seconds: 6));
      // ROLLBACK P1: offline service init disabled
      // await _initializeOfflineService().timeout(const Duration(seconds: 5));
      await _configureSystemUi();

      if (!mounted) return;
      setState(() {
        _initialized = true;
      });
    } catch (e, stackTrace) {
      debugPrint('App bootstrap failed: $e');
      debugPrint('Bootstrap stack trace: $stackTrace');
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    }
  }

  Future<void> _initializeFirebase() async {
    if (Firebase.apps.isNotEmpty) {
      debugPrint('Firebase already initialized');
      return;
    }

    try {
      if (kIsWeb) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      } else {
        await Firebase.initializeApp();
      }
    } on FirebaseException catch (e) {
      if (e.code != 'duplicate-app') rethrow;
      debugPrint('Firebase default app already exists; continuing.');
    }
  }

  Future<void> _initializeNotifications() async {
    try {
      await NotificationService().init();
    } catch (e) {
      debugPrint('Notification initialization failed: $e');
    }
  }

  Future<void> _configureFirestore() async {
    try {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
    } catch (e) {
      debugPrint('Firestore settings failed: $e');
    }
  }

  // ROLLBACK P1: _initializeOfflineService disabled
  // Future<void> _initializeOfflineService() async {
  //   try {
  //     final offlineService = OfflineDataService();
  //     await offlineService.initialize();
  //     debugPrint('Offline service initialized successfully');
  //   } catch (e) {
  //     debugPrint('Offline service initialization failed: $e');
  //     // Don't block app startup on offline service failure
  //   }
  // }

  Future<void> _configureSystemUi() async {
    try {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: Colors.transparent,
        ),
      );
    } catch (e) {
      debugPrint('System UI settings failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_initialized) {
      return const ProviderScope(child: MindNestApp());
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: _BrandedBootScreen(error: _error, onRetry: _initialize),
    );
  }
}

class _BrandedBootScreen extends StatelessWidget {
  final String? error;
  final Future<void> Function() onRetry;

  const _BrandedBootScreen({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF9FBFF), Color(0xFFEEF8F6)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 124,
                    height: 124,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x22000000),
                          blurRadius: 18,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      AppBranding.logoAssetPath,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Image.asset(
                        AppBranding.logoAssetPathAlt,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Image.asset(
                          AppBranding.logoAssetPathFallback,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.spa_rounded,
                            size: 66,
                            color: Color(0xFF6A8DFF),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    AppBranding.appName,
                    style: GoogleFonts.lato(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1A2530),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AppBranding.tagline,
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 28),
                  if (error == null) ...[
                    const CircularProgressIndicator(),
                    const SizedBox(height: 12),
                    Text(
                      'Starting app...',
                      style: GoogleFonts.lato(
                        fontSize: 13,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ] else ...[
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 36,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Startup failed',
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF991B1B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lato(
                        fontSize: 12,
                        color: const Color(0xFF7F1D1D),
                      ),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton(
                      onPressed: onRetry,
                      child: const Text('Retry'),
                    ),
                  ],
                ],
              ),
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
      title: AppBranding.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme.copyWith(
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

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return const WelcomeScreen();
        }

        final userProfile = ref.watch(userProfileProvider);

        return userProfile.when(
          data: (profile) {
            if (profile == null) {
              return const WelcomeScreen();
            }

            if (profile.onboardingCompleted) {
              return const HomeScreen();
            }
            return const OnboardingFlowScreen();
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
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
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
                        onPressed: () => ref.invalidate(userProfileProvider),
                        child: const Text('Retry'),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => const WelcomeScreen(),
                            ),
                          );
                        },
                        child: const Text('Go to Welcome'),
                      ),
                    ],
                  ),
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
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
                    onPressed: () => ref.invalidate(authStateProvider),
                    child: const Text('Retry'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => const WelcomeScreen(),
                        ),
                      );
                    },
                    child: const Text('Continue'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
