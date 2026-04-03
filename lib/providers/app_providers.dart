import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/routine_tracking_service.dart';
import '../services/checkin_service.dart';
import '../services/progress_insights_service.dart';
import '../services/focus_service.dart';
import '../services/notification_service.dart';
import '../services/badge_service.dart';
import '../services/chat_service.dart';
import '../services/voice_service.dart';
import '../features/calm/application/calm_recommendation_service.dart';
import '../features/calm/application/navigation_integration_service.dart';
import '../features/calm/application/ecosystem_integration_service.dart';
import '../features/calm/application/calm_progress_service.dart';
import '../features/calm/application/mood_tracking_service.dart';
import '../features/calm/application/sound_preset_service.dart';
import '../features/calm/application/complete_integration_workflow.dart';
import 'user_provider.dart';
import 'journal_provider.dart';
import 'meditation_provider.dart';

// Export existing providers
export 'auth_provider.dart';
export 'user_provider.dart';

// Service Providers (New)
final routineServiceProvider = Provider<RoutineTrackingService>((ref) {
  return RoutineTrackingService(firestore: ref.read(firebaseFirestoreProvider));
});
final checkInServiceProvider = Provider<CheckInService>((ref) {
  return CheckInService(
    firestore: ref.read(firebaseFirestoreProvider),
    firestoreService: ref.read(firestoreServiceProvider),
  );
});

final insightsServiceProvider = Provider<ProgressInsightsService>((ref) {
  return ProgressInsightsService(
    routineService: ref.read(routineServiceProvider),
    firestoreService: ref.read(firestoreServiceProvider),
  );
});

final focusServiceProvider = Provider<FocusService>((ref) {
  return FocusService(
    firestore: ref.read(firebaseFirestoreProvider),
    firestoreService: ref.read(firestoreServiceProvider),
  );
});
final notificationServiceProvider = Provider<NotificationService>((ref) => NotificationService());
final badgeServiceProvider = Provider<BadgeService>((ref) => BadgeService());
final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService();
});
final voiceServiceProvider = Provider<VoiceService>((ref) => VoiceService());
final moodTrackingServiceProvider = Provider<MoodTrackingService>((ref) {
  return MoodTrackingService(firestore: ref.read(firebaseFirestoreProvider));
});

final calmProgressServiceProvider = Provider<CalmProgressService>((ref) {
  return CalmProgressService(
    firestore: ref.read(firebaseFirestoreProvider),
    firestoreService: ref.read(firestoreServiceProvider),
    moodTrackingService: ref.read(moodTrackingServiceProvider),
  );
});

final calmRecommendationServiceProvider = Provider<CalmRecommendationService>((ref) {
  return CalmRecommendationService(
    progressService: ref.read(calmProgressServiceProvider),
  );
});

final navigationIntegrationServiceProvider = Provider<NavigationIntegrationService>((ref) {
  return NavigationIntegrationService(
    meditationAnalytics: ref.read(meditationAnalyticsProvider),
  );
});

final ecosystemIntegrationServiceProvider = Provider<EcosystemIntegrationService>((ref) {
  return EcosystemIntegrationService(
    firestore: ref.read(firebaseFirestoreProvider),
    firestoreService: ref.read(firestoreServiceProvider),
    meditationAnalytics: ref.read(meditationAnalyticsProvider),
    journalService: ref.read(journalServiceProvider),
    calmProgressService: ref.read(calmProgressServiceProvider),
    moodTrackingService: ref.read(moodTrackingServiceProvider),
  );
});

final soundPresetServiceProvider = Provider<SoundPresetService>((ref) {
  return SoundPresetService(firestoreService: ref.read(firestoreServiceProvider));
});


final completeIntegrationWorkflowProvider = Provider<CompleteIntegrationWorkflow>((ref) {
  return CompleteIntegrationWorkflow(
    firestore: ref.read(firebaseFirestoreProvider),
    ecosystemService: ref.read(ecosystemIntegrationServiceProvider),
    calmProgressService: ref.read(calmProgressServiceProvider),
  );
});
