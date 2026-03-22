import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final DateTime createdAt;
  final DateTime? lastLogin;
  final String? photoURL;
  final String? signInMethod;
  final List<DateTime>? loginDates;
  final Map<String, dynamic>? sleepData;
  final String? primaryMotive; // Sleep, Stress, Anxiety, Focus, Habit Building
  final List<String>? secondaryMotives; // Additional goals
  final List<String>? supportAreas; // Distractions/challenges selected in onboarding
  final String? experienceLevel; // 'New Beginner', 'Tried a little', 'Long ago', 'Never tried'
  final String? preferredTime; // Morning, Afternoon, Evening, Before Bed
  final String? dailyCommitment; // 5min, 10min, 15min, 30+min
  final bool onboardingCompleted;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.createdAt,
    this.lastLogin,
    this.photoURL,
    this.signInMethod,
    this.loginDates,
    this.sleepData,
    this.primaryMotive,
    this.secondaryMotives,
    this.supportAreas,
    this.experienceLevel,
    this.preferredTime,
    this.dailyCommitment,
    this.onboardingCompleted = false,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLogin': lastLogin != null ? Timestamp.fromDate(lastLogin!) : null,
      'photoURL': photoURL,
      'signInMethod': signInMethod,
      'loginDates': loginDates?.map((e) => Timestamp.fromDate(e)).toList(),
      'sleepData': sleepData,
      'primaryMotive': primaryMotive,
      'secondaryMotives': secondaryMotives,
      'supportAreas': supportAreas,
      'experienceLevel': experienceLevel,
      'preferredTime': preferredTime,
      'dailyCommitment': dailyCommitment,
      'onboardingCompleted': onboardingCompleted,
    };
  }

  // Create from Firestore document
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      lastLogin: map['lastLogin'] != null 
          ? (map['lastLogin'] as Timestamp).toDate() 
          : null,
      photoURL: map['photoURL'],
      signInMethod: map['signInMethod'],
      loginDates: map['loginDates'] != null
          ? (map['loginDates'] as List<dynamic>)
              .map((e) => (e as Timestamp).toDate())
              .toList()
          : [],
      sleepData: map['sleepData'] as Map<String, dynamic>?,
      primaryMotive: map['primaryMotive'] as String?,
      secondaryMotives: map['secondaryMotives'] != null
          ? List<String>.from(map['secondaryMotives'])
          : null,
      supportAreas: map['supportAreas'] != null
          ? List<String>.from(map['supportAreas'])
          : null,
      experienceLevel: map['experienceLevel'] as String?,
      preferredTime: map['preferredTime'] as String?,
      dailyCommitment: map['dailyCommitment'] as String?,
      onboardingCompleted: map['onboardingCompleted'] ?? false,
    );
  }

  // Copy with method for updating fields
  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    DateTime? createdAt,
    DateTime? lastLogin,
    String? photoURL,
    String? signInMethod,
    List<DateTime>? loginDates,
    Map<String, dynamic>? sleepData,
    String? primaryMotive,
    List<String>? secondaryMotives,
    List<String>? supportAreas,
    String? experienceLevel,
    String? preferredTime,
    String? dailyCommitment,
    bool? onboardingCompleted,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      photoURL: photoURL ?? this.photoURL,
      signInMethod: signInMethod ?? this.signInMethod,
      loginDates: loginDates ?? this.loginDates,
      sleepData: sleepData ?? this.sleepData,
      primaryMotive: primaryMotive ?? this.primaryMotive,
      secondaryMotives: secondaryMotives ?? this.secondaryMotives,
      supportAreas: supportAreas ?? this.supportAreas,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      preferredTime: preferredTime ?? this.preferredTime,
      dailyCommitment: dailyCommitment ?? this.dailyCommitment,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }
}
