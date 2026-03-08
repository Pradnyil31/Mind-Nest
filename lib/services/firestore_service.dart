import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/user_model.dart';

class AppDocumentSnapshot {
  final Map<String, dynamic>? _data;

  const AppDocumentSnapshot(this._data);

  bool get exists => _data != null;

  Map<String, dynamic>? data() => _data;
}

class FirestoreService {
  final SupabaseClient _client;

  FirestoreService({SupabaseClient? client, Object? firestore})
    : _client = client ?? SupabaseConfig.client;

  Future<void> createUser(UserModel user) async {
    try {
      await _client.from('profiles').upsert(_toProfileInsert(user));
    } catch (e) {
      throw 'Failed to create user profile: $e';
    }
  }

  Future<UserModel?> getUser(String uid) async {
    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', uid)
          .maybeSingle();
      if (data == null) return null;
      return UserModel.fromMap(_fromProfileRow(data));
    } catch (e) {
      throw 'Failed to get user data: $e';
    }
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    try {
      await _client
          .from('profiles')
          .update(_toProfileUpdate(data))
          .eq('id', uid);
    } catch (e) {
      throw 'Failed to update user: $e';
    }
  }

  Future<void> updateLastLogin(String uid) async {
    try {
      final now = DateTime.now();
      final user = await _client
          .from('profiles')
          .select()
          .eq('id', uid)
          .maybeSingle();

      List<DateTime> currentLoginDates = [];
      if (user != null && user['login_dates'] != null) {
        currentLoginDates = (user['login_dates'] as List<dynamic>)
            .map((e) => DateTime.parse(e.toString()))
            .toList();
      }

      bool alreadyLoggedInToday = false;
      if (currentLoginDates.isNotEmpty) {
        final lastDate = currentLoginDates.last;
        if (lastDate.year == now.year &&
            lastDate.month == now.month &&
            lastDate.day == now.day) {
          alreadyLoggedInToday = true;
        }
      }

      if (!alreadyLoggedInToday) {
        currentLoginDates.add(now);
        if (currentLoginDates.length > 30) {
          currentLoginDates.removeAt(0);
        }
      }

      await _client
          .from('profiles')
          .update({
            'last_login': now.toIso8601String(),
            'login_dates': currentLoginDates
                .map((e) => e.toIso8601String())
                .toList(),
          })
          .eq('id', uid);
    } catch (e) {
      throw 'Failed to update last login: $e';
    }
  }

  Future<void> deleteUser(String uid) async {
    try {
      await _client.from('profiles').delete().eq('id', uid);
    } catch (e) {
      throw 'Failed to delete user: $e';
    }
  }

  Stream<UserModel?> streamUser(String uid) {
    return getUserStream(uid).map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromMap(doc.data()!);
    });
  }

  Future<bool> userExists(String uid) async {
    try {
      final doc = await _client
          .from('profiles')
          .select('id')
          .eq('id', uid)
          .maybeSingle();
      return doc != null;
    } catch (_) {
      return false;
    }
  }

  Stream<AppDocumentSnapshot> getUserStream(String uid) {
    return _client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', uid)
        .asyncMap((rows) async {
          if (rows.isEmpty) {
            final authUser = _client.auth.currentUser;
            if (authUser != null && authUser.id == uid) {
              await _safeCreateProfileFromAuth(authUser);
              final created = await _client
                  .from('profiles')
                  .select()
                  .eq('id', uid)
                  .maybeSingle();
              if (created != null) {
                return AppDocumentSnapshot(_fromProfileRow(created));
              }
            }
            return const AppDocumentSnapshot(null);
          }
          return AppDocumentSnapshot(_fromProfileRow(rows.first));
        });
  }

  Future<void> _safeCreateProfileFromAuth(User authUser) async {
    final profile = {
      'id': authUser.id,
      'email': authUser.email ?? '',
      'display_name':
          (authUser.userMetadata?['display_name'] as String?) ??
          (authUser.email?.split('@').first ?? 'User'),
      'sign_in_method':
          (authUser.appMetadata['provider'] as String?) ?? 'email',
      'created_at': DateTime.now().toIso8601String(),
      'last_login': DateTime.now().toIso8601String(),
    };

    try {
      await _client.from('profiles').upsert(profile);
    } catch (_) {
      // Ignore here: stream will continue and caller handles null profile state.
    }
  }

  Future<void> saveDailyMotive(String uid, String motive) async {
    final today = DateTime.now();
    final date = DateTime(today.year, today.month, today.day);
    await _client.from('daily_motives').upsert({
      'user_id': uid,
      'motive_date': date.toIso8601String().split('T').first,
      'motive': motive,
    });
  }

  Future<String?> getDailyMotive(String uid) async {
    final today = DateTime.now();
    final date = DateTime(
      today.year,
      today.month,
      today.day,
    ).toIso8601String().split('T').first;

    final doc = await _client
        .from('daily_motives')
        .select('motive')
        .eq('user_id', uid)
        .eq('motive_date', date)
        .maybeSingle();

    return doc?['motive'] as String?;
  }

  Future<void> logSleepData(
    String uid,
    DateTime date,
    Map<String, dynamic> data,
  ) async {
    final dateKey =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    try {
      final user = await _client
          .from('profiles')
          .select('sleep_data')
          .eq('id', uid)
          .maybeSingle();
      final currentSleep = Map<String, dynamic>.from(user?['sleep_data'] ?? {});
      currentSleep[dateKey] = data;
      await _client
          .from('profiles')
          .update({'sleep_data': currentSleep})
          .eq('id', uid);
    } catch (e) {
      throw 'Failed to log sleep data: $e';
    }
  }

  Future<Map<String, dynamic>?> getSleepData(String uid, DateTime date) async {
    final dateKey =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    try {
      final user = await _client
          .from('profiles')
          .select('sleep_data')
          .eq('id', uid)
          .maybeSingle();
      if (user == null) return null;
      final sleepMap = Map<String, dynamic>.from(user['sleep_data'] ?? {});
      return sleepMap[dateKey] as Map<String, dynamic>?;
    } catch (e) {
      throw 'Failed to get sleep data: $e';
    }
  }

  Map<String, dynamic> _toProfileInsert(UserModel user) {
    return {
      'id': user.uid,
      'email': user.email,
      'display_name': user.displayName,
      'created_at': user.createdAt.toIso8601String(),
      'last_login': user.lastLogin?.toIso8601String(),
      'photo_url': user.photoURL,
      'sign_in_method': user.signInMethod,
      'login_dates':
          user.loginDates?.map((e) => e.toIso8601String()).toList() ?? [],
      'sleep_data': user.sleepData ?? {},
      'primary_motive': user.primaryMotive,
      'secondary_motives': user.secondaryMotives ?? [],
      'preferred_time': user.preferredTime,
      'daily_commitment': user.dailyCommitment,
    };
  }

  Map<String, dynamic> _toProfileUpdate(Map<String, dynamic> data) {
    final updated = <String, dynamic>{};
    final keyMap = {
      'displayName': 'display_name',
      'createdAt': 'created_at',
      'lastLogin': 'last_login',
      'photoURL': 'photo_url',
      'signInMethod': 'sign_in_method',
      'loginDates': 'login_dates',
      'sleepData': 'sleep_data',
      'primaryMotive': 'primary_motive',
      'secondaryMotives': 'secondary_motives',
      'preferredTime': 'preferred_time',
      'dailyCommitment': 'daily_commitment',
      'supportAreas': 'support_areas',
      'experienceLevel': 'experience_level',
      'onboardingCompleted': 'onboarding_completed',
      'routineActivities': 'routine_activities',
      'routineSchedule': 'routine_schedule',
      'temporarySchedule': 'temporary_schedule',
      'additionalActivities': 'additional_activities',
      'baseRoutine': 'base_routine',
      'lastGeneratedDate': 'last_generated_date',
    };

    data.forEach((key, value) {
      if (key.startsWith('routine.')) {
        final nestedKey = key.replaceFirst('routine.', '');
        updated['routine'] = {
          ...(updated['routine'] as Map<String, dynamic>? ?? {}),
          nestedKey: value,
        };
        return;
      }
      final mappedKey = keyMap[key] ?? key;
      if (mappedKey == 'login_dates' && value is List<DateTime>) {
        updated[mappedKey] = value.map((e) => e.toIso8601String()).toList();
      } else {
        updated[mappedKey] = value;
      }
    });

    return updated;
  }

  Map<String, dynamic> _fromProfileRow(Map<String, dynamic> row) {
    return {
      'uid': row['id'],
      'email': row['email'],
      'displayName': row['display_name'] ?? '',
      'createdAt':
          DateTime.tryParse(row['created_at']?.toString() ?? '') ??
          DateTime.now(),
      'lastLogin': row['last_login'] == null
          ? null
          : DateTime.tryParse(row['last_login'].toString()),
      'photoURL': row['photo_url'],
      'signInMethod': row['sign_in_method'],
      'loginDates': (row['login_dates'] as List<dynamic>? ?? [])
          .map((e) => DateTime.tryParse(e.toString()) ?? DateTime.now())
          .toList(),
      'sleepData': Map<String, dynamic>.from(row['sleep_data'] ?? {}),
      'primaryMotive': row['primary_motive'],
      'secondaryMotives': List<String>.from(row['secondary_motives'] ?? []),
      'supportAreas': List<String>.from(row['support_areas'] ?? []),
      'preferredTime': row['preferred_time'],
      'dailyCommitment': row['daily_commitment'],
      'experienceLevel': row['experience_level'],
      'onboardingCompleted': row['onboarding_completed'] ?? false,
      'routine': Map<String, dynamic>.from(row['routine'] ?? {}),
      'routineActivities': List<String>.from(row['routine_activities'] ?? []),
      'routineSchedule': Map<String, dynamic>.from(
        row['routine_schedule'] ?? {},
      ),
      'temporarySchedule': Map<String, dynamic>.from(
        row['temporary_schedule'] ?? {},
      ),
      'additionalActivities': List<String>.from(
        row['additional_activities'] ?? [],
      ),
      'baseRoutine': List<String>.from(row['base_routine'] ?? []),
      'lastGeneratedDate': row['last_generated_date'] == null
          ? null
          : (row['last_generated_date'] is DateTime
                ? (row['last_generated_date'] as DateTime).toIso8601String()
                : row['last_generated_date'].toString()),
    };
  }
}
