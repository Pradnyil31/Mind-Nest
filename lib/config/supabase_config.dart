import 'package:supabase_flutter/supabase_flutter.dart';

/// Centralized Supabase initialization
class SupabaseConfig {
  static const String _url = 'https://yzaqwrrpljkwvhmdkqmd.supabase.co';
  static const String _anonKey =
      'sb_publishable_IJa1X_ZRS1dRQoc0IJFEqw_I4Psmt0B';

  static Future<void> init() async {
    await Supabase.initialize(
      url: _url,
      anonKey: _anonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
