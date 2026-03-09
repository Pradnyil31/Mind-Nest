import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/guided_meditation.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/meditation_analytics_service.dart';
import 'meditation_player_screen.dart';
import 'meditation_timer_screen.dart';

class MeditationLibraryScreen extends StatefulWidget {
  const MeditationLibraryScreen({super.key});

  @override
  State<MeditationLibraryScreen> createState() => _MeditationLibraryScreenState();
}

class _MeditationLibraryScreenState extends State<MeditationLibraryScreen> {
  MeditationCategory? _selectedCategory;
  String? _userMotive;
  int _currentStreak = 0;
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMeditationData();
  }

  Future<void> _loadMeditationData() async {
    final user = AuthService().currentUser;
    if (user != null) {
      final analyticsService = MeditationAnalyticsService();
      final firestoreService = FirestoreService();
      
      final streak = await analyticsService.getCurrentStreak(user.uid);
      final stats = await analyticsService.getStats(user.uid);
      
      // Get user's motive
      final userDoc = await firestoreService.getUserStream(user.uid).first;
      String? motive;
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        motive = data['primaryMotive'] as String?;
      }
      
      setState(() {
        _currentStreak = streak;
        _stats = stats;
        _userMotive = motive;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F9),
      appBar: AppBar(
        title: Text(
          'Meditation',
          style: GoogleFonts.lato(
            color: const Color(0xFF2D2D2D),
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF2D2D2D)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Progress Card
                  if (_currentStreak > 0 || (_stats['totalSessions'] ?? 0) > 0)
                    _buildProgressCard(),

                  const SizedBox(height: 24),

                  // Quick Actions
                  _buildQuickActions(),

                  const SizedBox(height: 32),

                  // Category Filter
                  Text(
                    'Browse Meditations',
                    style: GoogleFonts.lato(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2D2D2D),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildCategoryFilter(),

                  const SizedBox(height: 24),

                  // Meditation Grid
                  _buildMeditationGrid(),
                ],
              ),
            ),
    );
  }

  Widget _buildProgressCard() {
    final totalSessions = _stats['totalSessions'] ?? 0;
    final totalMinutes = _stats['totalMinutes'] ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF9575CD), Color(0xFF7E57C2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9575CD).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          if (_currentStreak > 0)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '🔥',
                  style: TextStyle(fontSize: 32),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$_currentStreak Day Streak',
                      style: GoogleFonts.lato(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Keep going!',
                      style: GoogleFonts.lato(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          
          if (_currentStreak > 0 && totalSessions > 0)
            const SizedBox(height: 20),
          
          if (totalSessions > 0)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem(totalSessions.toString(), 'Sessions', Icons.self_improvement),
                Container(
                  height: 40,
                  width: 1,
                  color: Colors.white30,
                ),
                _buildStatItem('$totalMinutes min', 'Total Time', Icons.access_time),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.lato(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.lato(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _buildQuickActionCard(
            title: 'Quick 5-Min',
            subtitle: 'Meditation',
            icon: Icons.timer,
            color: const Color(0xFF64B5F6),
            onTap: () {
              // Find a 5-minute meditation
              final quickMeditation = GuidedMeditation.defaults.firstWhere(
                (m) => m.durationMinutes == 5,
                orElse: () => GuidedMeditation.defaults.first,
              );
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MeditationPlayerScreen(meditation: quickMeditation),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildQuickActionCard(
            title: 'Free Timer',
            subtitle: 'Your Way',
            icon: Icons.self_improvement,
            color: const Color(0xFF81C784),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MeditationTimerScreen()),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.lato(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2D2D2D),
              ),
            ),
            Text(
              subtitle,
              style: GoogleFonts.lato(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildCategoryChip('All', null),
          ...MeditationCategory.values.map((category) {
            return _buildCategoryChip(
              _getCategoryName(category),
              category,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, MeditationCategory? category) {
    final isSelected = _selectedCategory == category;
    
    return GestureDetector(
      onTap: () {
        setState(() => _selectedCategory = category);
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF9575CD) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF9575CD) : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.lato(
            color: isSelected ? Colors.white : const Color(0xFF2D2D2D),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildMeditationGrid() {
    List<GuidedMeditation> meditations;
    
    if (_selectedCategory != null) {
      // Filter by selected category
      meditations = GuidedMeditation.getByCategory(_selectedCategory!);
    } else if (_userMotive != null) {
      // Filter by user motive (prioritize relevant meditations)
      meditations = GuidedMeditation.getByMotive(_userMotive);
    } else {
      // Show all
      meditations = GuidedMeditation.defaults;
    }

    return Column(
      children: meditations.map((meditation) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildMeditationCard(meditation),
        );
      }).toList(),
    );
  }

  Widget _buildMeditationCard(GuidedMeditation meditation) {
    final categoryColor = _getCategoryColor(meditation.category);
    final isRelevantForMotive = GuidedMeditation.isRelevantForMotive(meditation, _userMotive);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MeditationPlayerScreen(meditation: meditation),
          ),
        ).then((_) => _loadMeditationData()); // Refresh data when returning
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: categoryColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                _getCategoryIcon(meditation.category),
                color: categoryColor,
                size: 32,
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meditation.title,
                    style: GoogleFonts.lato(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2D2D2D),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    meditation.description,
                    style: GoogleFonts.lato(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      _buildBadge('${meditation.durationMinutes} min', Icons.access_time, Colors.grey.shade600),
                      _buildBadge(meditation.difficulty, Icons.bar_chart, categoryColor),
                      if (_selectedCategory == null && isRelevantForMotive)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6C63FF).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            '⭐ For You',
                            style: TextStyle(fontSize: 10, color: Color(0xFF6C63FF), fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Play button
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: categoryColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow, color: Colors.white, size: 24),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text, IconData icon, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.lato(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _getCategoryName(MeditationCategory category) {
    switch (category) {
      case MeditationCategory.sleep:
        return 'Sleep';
      case MeditationCategory.stress:
        return 'Stress Relief';
      case MeditationCategory.focus:
        return 'Focus';
      case MeditationCategory.anxiety:
        return 'Anxiety';
      case MeditationCategory.mindfulness:
        return 'Mindfulness';
      case MeditationCategory.compassion:
        return 'Self-Love';
    }
  }

  Color _getCategoryColor(MeditationCategory category) {
    switch (category) {
      case MeditationCategory.sleep:
        return const Color(0xFF7986CB);
      case MeditationCategory.stress:
        return const Color(0xFF4DB6AC);
      case MeditationCategory.focus:
        return const Color(0xFF64B5F6);
      case MeditationCategory.anxiety:
        return const Color(0xFFFFB74D);
      case MeditationCategory.mindfulness:
        return const Color(0xFF9575CD);
      case MeditationCategory.compassion:
        return const Color(0xFFE57373);
    }
  }

  IconData _getCategoryIcon(MeditationCategory category) {
    switch (category) {
      case MeditationCategory.sleep:
        return Icons.nightlight_round;
      case MeditationCategory.stress:
        return Icons.spa;
      case MeditationCategory.focus:
        return Icons.center_focus_strong;
      case MeditationCategory.anxiety:
        return Icons.waves;
      case MeditationCategory.mindfulness:
        return Icons.self_improvement;
      case MeditationCategory.compassion:
        return Icons.favorite;
    }
  }
}
