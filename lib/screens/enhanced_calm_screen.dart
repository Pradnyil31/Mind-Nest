import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/motive_config.dart';
import '../models/calm_technique.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/calm/interactive_soundscape_widget.dart';
import 'grounding_exercise_screen.dart';
import 'affirmations_screen.dart';
import 'calm_technique_screen.dart';
import 'breathing_screen.dart';

class EnhancedCalmScreen extends ConsumerStatefulWidget {
  const EnhancedCalmScreen({super.key});

  @override
  ConsumerState<EnhancedCalmScreen> createState() => _EnhancedCalmScreenState();
}

class _EnhancedCalmScreenState extends ConsumerState<EnhancedCalmScreen>
    with TickerProviderStateMixin {
  String? _userMotive;
  bool _isLoading = true;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _loadUserMotive();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadUserMotive() async {
    final user = AuthService().currentUser;
    if (user != null) {
      try {
        final userDoc = await FirestoreService().getUserStream(user.uid).first;
        if (userDoc.exists && mounted) {
          final data = userDoc.data() as Map<String, dynamic>;
          setState(() {
            _userMotive = data['primaryMotive'] as String?;
            _isLoading = false;
          });
          _fadeController.forward();
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          _fadeController.forward();
        }
      }
    } else {
      setState(() {
        _isLoading = false;
      });
      _fadeController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _getMotiveBackgroundColor(),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4DB6AC)),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _getMotiveBackgroundColor(),
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Motive-specific welcome header
              _buildMotiveWelcomeHeader(),
              const SizedBox(height: 24),

              // Quick Access Emergency Panel
              _buildQuickAccessPanel(),
              const SizedBox(height: 32),

              // Personalized Techniques Section
              _buildPersonalizedTechniquesSection(),
              const SizedBox(height: 32),

              // Ambient Soundscapes Section
              _buildAmbientSoundscapesSection(),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final profile = MotiveConfig.getProfile(_userMotive);
    final emoji = profile?.emoji ?? '🧘';

    return AppBar(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 8),
          Text(
            'Calm',
            style: GoogleFonts.lato(
              color: const Color(0xFF2D2D2D),
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
        ],
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      iconTheme: const IconThemeData(color: Color(0xFF2D2D2D)),
    );
  }

  Widget _buildMotiveWelcomeHeader() {
    final profile = MotiveConfig.getProfile(_userMotive);
    final displayName = profile?.displayName ?? 'Wellness';
    final emoji = profile?.emoji ?? '🧘';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: _getMotiveGradient(),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _getMotivePrimaryColor().withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your $displayName Journey',
                      style: GoogleFonts.lato(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getMotiveWelcomeMessage(),
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
        ],
      ),
    );
  }

  Widget _buildQuickAccessPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.emergency,
                  color: Colors.red.shade600,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Quick Relief',
                style: GoogleFonts.lato(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D2D2D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Immediate techniques for when you need them most',
            style: GoogleFonts.lato(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          _buildQuickAccessButtons(),
        ],
      ),
    );
  }

  Widget _buildQuickAccessButtons() {
    final quickTechniques = _getMotiveQuickTechniques();

    return Row(
      children: quickTechniques.asMap().entries.map((entry) {
        final index = entry.key;
        final technique = entry.value;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: index < quickTechniques.length - 1 ? 12 : 0,
            ),
            child: _buildQuickAccessButton(technique),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildQuickAccessButton(Map<String, dynamic> technique) {
    return GestureDetector(
      onTap: () => _handleQuickTechniqueNavigation(technique),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: _getMotivePrimaryColor().withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getMotivePrimaryColor().withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          children: [
            Text(
              technique['icon'] as String,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 8),
            Text(
              technique['name'] as String,
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _getMotivePrimaryColor(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalizedTechniquesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'Personalized Techniques',
          'Curated for your ${MotiveConfig.getProfile(_userMotive)?.displayName ?? 'wellness'} journey',
        ),
        const SizedBox(height: 16),
        _buildPersonalizedTechniquesList(),
      ],
    );
  }

  Widget _buildPersonalizedTechniquesList() {
    final prioritizedTechniques = _getPrioritizedTechniques();

    return Column(
      children: prioritizedTechniques.map((technique) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildTechniqueCard(technique),
        );
      }).toList(),
    );
  }

  Widget _buildAmbientSoundscapesSection() {
    return InteractiveSoundscapeWidget(
      userMotive: _userMotive,
      primaryColor: _getMotivePrimaryColor(),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.lato(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2D2D2D),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: GoogleFonts.lato(fontSize: 14, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildTechniqueCard(CalmTechnique technique) {
    final techniqueColor = _getTechniqueColor(technique.type);

    return GestureDetector(
      onTap: () => _handleTechniqueNavigation(technique),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: techniqueColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(technique.icon, style: const TextStyle(fontSize: 28)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    technique.title,
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2D2D2D),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getMotiveSpecificDescription(technique),
                    style: GoogleFonts.lato(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: techniqueColor),
                      const SizedBox(width: 4),
                      Text(
                        '${technique.durationMinutes} min',
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          color: techniqueColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      if (_isTechniquePrioritized(technique))
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getMotivePrimaryColor().withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Recommended',
                            style: GoogleFonts.lato(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _getMotivePrimaryColor(),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods for motive-based personalization
  Color _getMotiveBackgroundColor() {
    switch (_userMotive) {
      case 'Sleep':
        return const Color(0xFFF0F4FF);
      case 'Stress':
        return const Color(0xFFF0FFF4);
      case 'Anxiety':
        return const Color(0xFFFFF0F8);
      case 'Focus':
        return const Color(0xFFFFF8F0);
      case 'Habit Building':
        return const Color(0xFFFFF0F0);
      default:
        return const Color(0xFFF3F4F9);
    }
  }

  Color _getMotivePrimaryColor() {
    switch (_userMotive) {
      case 'Sleep':
        return const Color(0xFF6366F1);
      case 'Stress':
        return const Color(0xFF10B981);
      case 'Anxiety':
        return const Color(0xFF8B5CF6);
      case 'Focus':
        return const Color(0xFFF59E0B);
      case 'Habit Building':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF4DB6AC);
    }
  }

  LinearGradient _getMotiveGradient() {
    final primaryColor = _getMotivePrimaryColor();
    return LinearGradient(
      colors: [primaryColor, primaryColor.withValues(alpha: 0.8)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  String _getMotiveWelcomeMessage() {
    switch (_userMotive) {
      case 'Sleep':
        return 'Find peace and prepare for restful sleep';
      case 'Stress':
        return 'Release tension and build resilience';
      case 'Anxiety':
        return 'Ground yourself and find your center';
      case 'Focus':
        return 'Clear your mind and sharpen concentration';
      case 'Habit Building':
        return 'Stay motivated and build consistency';
      default:
        return 'Find your calm and inner peace';
    }
  }

  List<Map<String, dynamic>> _getMotiveQuickTechniques() {
    switch (_userMotive) {
      case 'Sleep':
        return [
          {'name': 'Body Scan', 'icon': '🧘', 'action': 'body_scan'},
          {'name': 'Deep Breathing', 'icon': '🫁', 'action': 'breathing'},
          {'name': 'Sleep Sounds', 'icon': '🌙', 'action': 'sounds'},
        ];
      case 'Stress':
        return [
          {'name': 'Breathing', 'icon': '🫁', 'action': 'breathing'},
          {'name': 'Grounding', 'icon': '🌱', 'action': 'grounding'},
          {'name': 'Meditation', 'icon': '🧘', 'action': 'meditation'},
        ];
      case 'Anxiety':
        return [
          {'name': 'Grounding', 'icon': '⚓', 'action': 'grounding'},
          {'name': '4-7-8 Breathing', 'icon': '🫁', 'action': 'breathing'},
          {'name': 'Safe Space', 'icon': '🏠', 'action': 'safe_space'},
        ];
      case 'Focus':
        return [
          {'name': 'Clarity', 'icon': '🎯', 'action': 'clarity'},
          {'name': 'Breathing', 'icon': '🫁', 'action': 'breathing'},
          {'name': 'Focus Sounds', 'icon': '🔊', 'action': 'sounds'},
        ];
      case 'Habit Building':
        return [
          {'name': 'Motivation', 'icon': '🔥', 'action': 'motivation'},
          {'name': 'Breathing', 'icon': '🫁', 'action': 'breathing'},
          {'name': 'Affirmations', 'icon': '💬', 'action': 'affirmations'},
        ];
      default:
        return [
          {'name': 'Breathing', 'icon': '🫁', 'action': 'breathing'},
          {'name': 'Grounding', 'icon': '🌱', 'action': 'grounding'},
          {'name': 'Meditation', 'icon': '🧘', 'action': 'meditation'},
        ];
    }
  }

  List<CalmTechnique> _getPrioritizedTechniques() {
    final allTechniques = CalmTechnique.defaults;

    // Sort techniques by priority
    final prioritized = <CalmTechnique>[];
    final others = <CalmTechnique>[];

    for (final technique in allTechniques) {
      if (_isTechniquePrioritized(technique)) {
        prioritized.add(technique);
      } else {
        others.add(technique);
      }
    }

    return [...prioritized, ...others];
  }

  bool _isTechniquePrioritized(CalmTechnique technique) {
    return MotiveConfig.isTechniquePrioritized(
      _userMotive,
      technique.type.name,
    );
  }

  String _getMotiveSpecificDescription(CalmTechnique technique) {
    // Return motive-specific benefits for techniques
    if (_userMotive == 'Sleep' && technique.type == TechniqueType.grounding) {
      return 'Perfect for calming racing thoughts before bed';
    } else if (_userMotive == 'Anxiety' &&
        technique.type == TechniqueType.grounding) {
      return 'Anchor yourself in the present moment';
    } else if (_userMotive == 'Focus' &&
        technique.type == TechniqueType.visualization) {
      return 'Clear mental fog and enhance concentration';
    }
    return technique.description;
  }

  Color _getTechniqueColor(TechniqueType type) {
    switch (type) {
      case TechniqueType.grounding:
        return const Color(0xFF81C784);
      case TechniqueType.affirmation:
        return const Color(0xFF9575CD);
      case TechniqueType.breathing:
        return const Color(0xFF64B5F6);
      case TechniqueType.visualization:
        return const Color(0xFF4DB6AC);
    }
  }

  void _handleQuickTechniqueNavigation(Map<String, dynamic> technique) {
    final action = technique['action'] as String;

    switch (action) {
      case 'breathing':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BreathingScreen()),
        );
        break;
      case 'grounding':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const GroundingExerciseScreen()),
        );
        break;
      case 'affirmations':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AffirmationsScreen()),
        );
        break;
      default:
        // Show coming soon message for other actions
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${technique['name']} coming soon!'),
            backgroundColor: _getMotivePrimaryColor(),
          ),
        );
    }
  }

  void _handleTechniqueNavigation(CalmTechnique technique) {
    if (technique.id == '5-4-3-2-1') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const GroundingExerciseScreen()),
      );
    } else if (technique.id == 'positive-affirmations') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AffirmationsScreen()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CalmTechniqueScreen(technique: technique),
        ),
      );
    }
  }
}
