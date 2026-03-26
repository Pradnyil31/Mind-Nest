import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../models/badge.dart';
import '../services/badge_service.dart';
import '../providers/app_providers.dart';

class BadgesScreen extends ConsumerStatefulWidget {
  const BadgesScreen({super.key});

  @override
  ConsumerState<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends ConsumerState<BadgesScreen> {
  List<Badge> _earnedBadges = [];
  Map<String, BadgeProgress> _badgeProgress = {};
  String? _userMotive;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBadges();
  }

  Future<void> _loadBadges() async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;

    try {
      setState(() {
        _isLoading = true;
      });

      final badgeService = ref.read(badgeServiceProvider);
      final earnedBadges = await badgeService.getEarnedBadges(user.uid);

      String? motive;
      try {
        final userDoc = await ref.read(firestoreServiceProvider).getUserOnce(user.uid);
        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>;
          motive = data['primaryMotive'] as String?;
        }
      } catch (_) {}

      final progress = await badgeService.getAllBadgesProgress(user.uid);

      if (mounted) {
        setState(() {
          _earnedBadges = earnedBadges;
          _badgeProgress = progress;
          _userMotive = motive;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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
                                    color: Colors.white.withValues(alpha: 0.9),
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
                      MasonryGridView.count(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _earnedBadges.length,
                        itemBuilder: (context, index) {
                          return _buildBadgeCard(_themeBadge(_earnedBadges[index]), true);
                        },
                      ),
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
                    Builder(builder: (context) {
                      final lockedBadges = Badge.allBadges
                          .where((b) => !_earnedBadges.any((e) => e.id == b.id))
                          .toList();
                          
                      return MasonryGridView.count(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: lockedBadges.length,
                        itemBuilder: (context, index) {
                          return _buildBadgeCard(_themeBadge(lockedBadges[index]), false);
                        },
                      );
                    }),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildBadgeCard(Badge badge, bool isEarned) {
    final progress = _badgeProgress[badge.id];
    final progressPercent = progress?.progressPercentage ?? 0.0;
    final current = progress?.current ?? 0;
    final target = progress?.target ?? 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isEarned
              ? const Color(0xFF6C63FF).withValues(alpha: 0.3)
              : Colors.grey.shade200,
          width: isEarned ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isEarned 
                ? const Color(0xFF6C63FF).withValues(alpha: 0.1) 
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Badge Icon with progress ring
          Stack(
            alignment: Alignment.center,
            children: [
              if (!isEarned && target > 1) 
                SizedBox(
                  width: 72,
                  height: 72,
                  child: CircularProgressIndicator(
                    value: progressPercent,
                    backgroundColor: Colors.grey.shade200,
                    color: const Color(0xFF6C63FF),
                    strokeWidth: 4,
                  ),
                ),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: isEarned
                      ? const Color(0xFF6C63FF).withValues(alpha: 0.1)
                      : Colors.grey.shade50,
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
            ],
          ),
          const SizedBox(height: 16),
          
          // Badge Info
          Text(
            badge.name,
            style: GoogleFonts.lato(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: isEarned
                  ? const Color(0xFF2D2D2D)
                  : Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          
          Text(
            badge.description,
            style: GoogleFonts.lato(
              fontSize: 12,
              color: isEarned ? Colors.grey.shade700 : Colors.grey.shade400,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          
          const SizedBox(height: 12),
          
          // Status/Progress Footer
          if (isEarned)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                badge.earnedDate != null ? _formatDate(badge.earnedDate!) : 'Earned',
                style: GoogleFonts.lato(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF6C63FF),
                ),
              ),
            )
          else if (target > 1)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.track_changes, size: 12, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  '$current / $target',
                  style: GoogleFonts.lato(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            )
          else
            const Icon(
              Icons.lock_outline_rounded,
              color: Colors.grey,
              size: 18,
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





