import 'package:flutter/material.dart' hide Badge;
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/badge.dart';
import '../services/progress_insights_service.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../config/motive_config.dart';

class BadgesScreen extends StatefulWidget {
  const BadgesScreen({Key? key}) : super(key: key);

  @override
  State<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends State<BadgesScreen> {
  final ProgressInsightsService _insightsService = ProgressInsightsService();
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  List<Badge> _earnedBadges = [];
  String? _userMotive;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBadges();
  }

  Future<void> _loadBadges() async {
    final user = _authService.currentUser;
    if (user != null) {
      try {
        setState(() {
          _isLoading = true;
        });
        
        print('🔍 Loading badges for user: ${user.uid}');
        
        // Get earned badge IDs from Firestore
        final earnedSnapshot = await FirebaseFirestore.instance
            .collection('badges')
            .doc(user.uid)
            .collection('earned')
            .get();
        
        final earnedBadgeIds = earnedSnapshot.docs.map((doc) => doc.id).toSet();
        print('📝 Earned badge IDs from Firestore: $earnedBadgeIds');
        
        // Map to full Badge objects with earned dates
        final earnedBadges = <Badge>[];
        for (final doc in earnedSnapshot.docs) {
          final data = doc.data();
          final badge = Badge.allBadges.firstWhere((b) => b.id == doc.id);
          earnedBadges.add(badge.copyWith(
            earnedDate: (data['earnedDate'] as Timestamp?)?.toDate(),
          ));
        }
        
        print('✅ Loaded ${earnedBadges.length} earned badges');

        // Get user motive
        String? motive;
        try {
          final userDoc = await _firestoreService.getUserStream(user.uid).first;
          if (userDoc.exists) {
            final data = userDoc.data() as Map<String, dynamic>;
            motive = data['primaryMotive'] as String?;
          }
        } catch (e) {
          print('Error loading user motive: $e');
        }
        
        if (mounted) {
          setState(() {
            _earnedBadges = earnedBadges;
            _userMotive = motive;
            _isLoading = false;
          });
        }
      } catch (e) {
        print('⛔ Error loading badges: $e');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2D2D2D)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'My Badges',
          style: GoogleFonts.lato(
            color: const Color(0xFF2D2D2D),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadBadges,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6C63FF), Color(0xFF5B54CC)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Text('🏆', style: TextStyle(fontSize: 48)),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Achievements',
                                  style: GoogleFonts.lato(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'You\'ve earned ${_earnedBadges.length} of ${Badge.allBadges.length} badges!',
                                  style: GoogleFonts.lato(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Earned Badges Section
                    if (_earnedBadges.isNotEmpty) ...[
                      Text(
                        'Earned Badges',
                        style: GoogleFonts.lato(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2D2D2D),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...(_earnedBadges.map((badge) => _buildBadgeCard(_themeBadge(badge), true))),
                      const SizedBox(height: 32),
                    ],
                    
                    // Locked Badges Section
                    Text(
                      _earnedBadges.isEmpty ? 'Available Badges' : 'Locked Badges',
                      style: GoogleFonts.lato(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2D2D2D),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...(Badge.allBadges
                        .where((b) => !_earnedBadges.any((e) => e.id == b.id))
                        .map((badge) => _buildBadgeCard(_themeBadge(badge), false))),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildBadgeCard(Badge badge, bool isEarned) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEarned
              ? const Color(0xFF4CAF50).withOpacity(0.3)
              : Colors.grey.shade300,
          width: isEarned ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Badge Icon
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isEarned
                  ? const Color(0xFF4CAF50).withOpacity(0.1)
                  : Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                badge.emoji,
                style: TextStyle(
                  fontSize: 32,
                  color: isEarned ? null : Colors.grey.shade400,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // Badge Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        badge.name,
                        style: GoogleFonts.lato(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isEarned
                              ? const Color(0xFF2D2D2D)
                              : Colors.grey.shade500,
                        ),
                      ),
                    ),
                    if (isEarned)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Earned',
                          style: GoogleFonts.lato(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      )
                    else
                      const Icon(
                        Icons.lock_outline,
                        color: Colors.grey,
                        size: 20,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  badge.description,
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    color: isEarned ? Colors.grey.shade700 : Colors.grey.shade400,
                  ),
                ),
                if (isEarned && badge.earnedDate != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Earned on ${_formatDate(badge.earnedDate!)}',
                      style: GoogleFonts.lato(
                        fontSize: 12,
                        color: const Color(0xFF4CAF50),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  /// Theme a badge based on the user's primary motive
  Badge _themeBadge(Badge badge) {
    if (_userMotive == null) return badge;

    // Motive-specific badge name/emoji overrides
    final Map<String, Map<String, Map<String, String>>> motiveThemes = {
      'Sleep': {
        'week_warrior': {'name': 'Sleep Warrior', 'emoji': '🌙'},
        'meditation_master': {'name': 'Rest Master', 'emoji': '😴'},
        'perfect_week': {'name': 'Perfect Rest', 'emoji': '✨'},
      },
      'Stress': {
        'week_warrior': {'name': 'Calm Warrior', 'emoji': '🌊'},
        'meditation_master': {'name': 'Zen Master', 'emoji': '🧘'},
        'perfect_week': {'name': 'Peace Week', 'emoji': '☮️'},
      },
      'Anxiety': {
        'week_warrior': {'name': 'Peace Warrior', 'emoji': '🕊️'},
        'goal_crusher': {'name': 'Worry Crusher', 'emoji': '🛡️'},
        'meditation_master': {'name': 'Calm Master', 'emoji': '⚓'},
      },
      'Focus': {
        'week_warrior': {'name': 'Focus Warrior', 'emoji': '🎯'},
        'perfect_week': {'name': 'Deep Work Week', 'emoji': '🧠'},
        'meditation_master': {'name': 'Clarity Master', 'emoji': '💡'},
      },
      'Habit Building': {
        'week_warrior': {'name': 'Habit Hero', 'emoji': '🚀'},
        'perfect_week': {'name': 'Consistency King', 'emoji': '👑'},
        'first_step': {'name': 'Habit Starter', 'emoji': '🌱'},
      },
    };

    final overrides = motiveThemes[_userMotive]?[badge.id];
    if (overrides == null) return badge;

    return badge.copyWith(
      name: overrides['name'],
      emoji: overrides['emoji'],
    );
  }
}
