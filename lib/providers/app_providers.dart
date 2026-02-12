import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/routine_tracking_service.dart';
import '../services/checkin_service.dart';
import '../services/progress_insights_service.dart';

// Export existing providers
export 'auth_provider.dart';
export 'user_provider.dart';

// Service Providers (New)
final routineServiceProvider = Provider<RoutineTrackingService>((ref) => RoutineTrackingService());
final checkInServiceProvider = Provider<CheckInService>((ref) => CheckInService());
final insightsServiceProvider = Provider<ProgressInsightsService>((ref) => ProgressInsightsService());
