import '../models/focus_session.dart';

class FocusService {
  // TODO: Implement Supabase integration
  // Services should use FirestoreService for data access

  Future<void> saveSession(FocusSession session) async {
    // Stub
  }

  Stream<List<FocusSession>> getRecentSessions(String userId) {
    // Stub - return empty stream
    return Stream.value([]);
  }
}
