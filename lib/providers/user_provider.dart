import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';

/// Provider for shared FirebaseFirestore instance
final firebaseFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

/// Provider for FirestoreService instance
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService(firestore: ref.read(firebaseFirestoreProvider));
});

/// Stream provider for user profile data
/// 
/// Automatically streams user profile from Firestore when user is authenticated.
/// Returns null when user is not signed in.
final userProfileProvider = StreamProvider<UserModel?>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  
  if (currentUser == null) {
    // Not signed in, return empty stream
    return Stream.value(null);
  }
  
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.streamUser(currentUser.uid);
});

/// Provider for user display name (convenience)
final userDisplayNameProvider = Provider<String>((ref) {
  final userProfile = ref.watch(userProfileProvider);
  return userProfile.when(
    data: (profile) => profile?.displayName ?? 'User',
    loading: () => 'Loading...',
    error: (_, __) => 'User',
  );
});

/// Provider to check if user has completed onboarding
final hasCompletedOnboardingProvider = Provider<bool>((ref) {
  final userProfile = ref.watch(userProfileProvider);
  return userProfile.when(
    data: (profile) {
      if (profile == null) return false;
      // Check if user has onboarding data
      // You can add more sophisticated checks here
      return profile.displayName.isNotEmpty;
    },
    loading: () => false,
    error: (_, __) => false,
  );
});
