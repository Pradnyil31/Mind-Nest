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
  final String? preferredTime; // Morning, Afternoon, Evening, Before Bed
  final String? dailyCommitment; // 5min, 10min, 15min, 30+min

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
    this.preferredTime,
    this.dailyCommitment,
  });

  // Convert to Map for Supabase
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
      'photoURL': photoURL,
      'signInMethod': signInMethod,
      'loginDates': loginDates?.map((e) => e.toIso8601String()).toList(),
      'sleepData': sleepData,
      'primaryMotive': primaryMotive,
      'secondaryMotives': secondaryMotives,
      'preferredTime': preferredTime,
      'dailyCommitment': dailyCommitment,
    };
  }

  // Create from Supabase document
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      createdAt: map['createdAt'] is DateTime
          ? map['createdAt']
          : DateTime.parse(map['createdAt'] as String),
      lastLogin: map['lastLogin'] != null
          ? (map['lastLogin'] is DateTime
                ? map['lastLogin']
                : DateTime.parse(map['lastLogin'] as String))
          : null,
      photoURL: map['photoURL'],
      signInMethod: map['signInMethod'],
      loginDates: map['loginDates'] != null
          ? (map['loginDates'] as List<dynamic>)
                .map((e) => e is DateTime ? e : DateTime.parse(e as String))
                .toList()
          : [],
      sleepData: map['sleepData'] as Map<String, dynamic>?,
      primaryMotive: map['primaryMotive'] as String?,
      secondaryMotives: map['secondaryMotives'] != null
          ? List<String>.from(map['secondaryMotives'])
          : null,
      preferredTime: map['preferredTime'] as String?,
      dailyCommitment: map['dailyCommitment'] as String?,
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
    String? preferredTime,
    String? dailyCommitment,
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
      preferredTime: preferredTime ?? this.preferredTime,
      dailyCommitment: dailyCommitment ?? this.dailyCommitment,
    );
  }
}
