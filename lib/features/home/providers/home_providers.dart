import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/firestore_service.dart';
import '../../../services/routine_tracking_service.dart';

/// Re-exports for Home feature so the controller can depend on
/// stable, feature-scoped providers instead of importing from
/// the global `app_providers.dart`.
///
/// This is a thin wrapper to avoid large-scale changes in one step.

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

final routineServiceProvider = Provider<RoutineTrackingService>((ref) {
  return RoutineTrackingService();
});

