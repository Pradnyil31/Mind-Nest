// One-time test script: sets meditation completionCount to 14 for the current user
// Run with: flutter run -t tools/set_meditation_count.dart -d <your_device>

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    debugPrint('❌ No user signed in. Please sign into the app first.');
    return;
  }

  debugPrint('✅ Found user: ${user.uid}');

  await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('activity_stats')
      .doc('meditation')
      .set({
        'completionCount': 14,
        'lastCompleted': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  debugPrint('✅ Done! meditation completionCount set to 14.');
  debugPrint('Now complete 1 meditation in the app to trigger the badge!');
}
