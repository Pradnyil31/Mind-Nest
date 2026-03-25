import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/app_providers.dart';
import '../../screens/journaling_screen.dart';
import '../../screens/breathing_screen.dart';
import '../../screens/meditation_library_screen.dart';

/// Widget showing calm system integration with the broader app ecosystem
/// Displays connections to routines, dashboard, journaling, and preferences
class EcosystemIntegrationWidget extends ConsumerStatefulWidget {
  final String userId;
  final VoidCallback? onJournalingTap;
  final VoidCallback? onBreathingTap;
  final VoidCallback? onMeditationTap;

  const EcosystemIntegrationWidget({
    super.key,
    required this.userId,
    this.onJournalingTap,
    this.onBreathingTap,
    this.onMeditationTap,
  });

  @override
  ConsumerState<EcosystemIntegrationWidget> createState() =>
      _EcosystemIntegrationWidgetState();
}

class _EcosystemIntegrationWidgetState
    extends ConsumerState<EcosystemIntegrationWidget> {
  Map<String, dynamic> _integrationStatus = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadIntegrationStatus();
  }

  Future<void> _loadIntegrationStatus() async {
    try {
      final status = await ref.read(ecosystemIntegrationServiceProvider).getEcosystemIntegrationStatus(
        widget.userId,
      );
      if (mounted) {
        setState(() {
          _integrationStatus = status;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingSkeleton();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
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
                  color: const Color(0xFF4DB6AC).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.hub_outlined,
                  color: Color(0xFF4DB6AC),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Connected Wellness',
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    Text(
                      'Your calm practice integrates with your entire wellness journey',
                      style: GoogleFonts.lato(
                        fontSize: 12,
                        color: const Color(0xFF6B7280),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildIntegrationGrid(),
        ],
      ),
    );
  }

  Widget _buildIntegrationGrid() {
    final todayUsage =
        _integrationStatus['todayUsage'] as Map<String, dynamic>? ?? {};

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildIntegrationCard(
                'Daily Routines',
                'Contributes to your daily goals',
                Icons.checklist_outlined,
                const Color(0xFF10B981),
                _integrationStatus['routineIntegration']?['contributesToDaily'] ==
                    true,
                onTap: () => _showRoutineIntegrationDetails(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildIntegrationCard(
                'Progress Dashboard',
                'Visible in unified insights',
                Icons.dashboard_outlined,
                const Color(0xFF3B82F6),
                _integrationStatus['dashboardIntegration']?['progressVisible'] ==
                    true,
                onTap: () => _showDashboardIntegrationDetails(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildIntegrationCard(
                'Journaling',
                todayUsage['journaling'] == true
                    ? 'Used today'
                    : 'Reflection prompts ready',
                Icons.edit_note_outlined,
                const Color(0xFF8B5CF6),
                _integrationStatus['journalingIntegration']?['reflectionPromptsEnabled'] ==
                    true,
                onTap: widget.onJournalingTap ?? () => _navigateToJournaling(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildIntegrationCard(
                'Breathing',
                todayUsage['breathing'] == true
                    ? 'Used today'
                    : 'Quick access available',
                Icons.air_outlined,
                const Color(0xFFF59E0B),
                true, // Always available
                onTap: widget.onBreathingTap ?? () => _navigateToBreathing(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildIntegrationCard(
                'Meditation',
                todayUsage['meditation'] == true
                    ? 'Used today'
                    : 'Library available',
                Icons.self_improvement_outlined,
                const Color(0xFF06B6D4),
                true, // Always available
                onTap: widget.onMeditationTap ?? () => _navigateToMeditation(),
              ),
            ),
            const SizedBox(width: 12),
            // Empty expanded to maintain layout balance
            const Expanded(child: SizedBox()),
          ],
        ),
      ],
    );
  }

  Widget _buildIntegrationCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    bool isActive, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? color.withValues(alpha: 0.3)
                : Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: isActive ? color : Colors.grey.shade400,
                  size: 20,
                ),
                const Spacer(),
                if (isActive)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.lato(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isActive
                    ? const Color(0xFF1F2937)
                    : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.lato(
                fontSize: 11,
                color: isActive
                    ? const Color(0xFF6B7280)
                    : Colors.grey.shade500,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 16,
                      width: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 12,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showRoutineIntegrationDetails() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily Routine Integration',
              style: GoogleFonts.lato(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 16),
            _buildIntegrationDetail(
              Icons.check_circle_outline,
              'Contributes to Daily Goals',
              'Calm techniques count toward your daily routine completion',
              const Color(0xFF10B981),
            ),
            _buildIntegrationDetail(
              Icons.local_fire_department_outlined,
              'Streak Integration',
              'Your calm practice contributes to your overall wellness streak',
              const Color(0xFFF59E0B),
            ),
            _buildIntegrationDetail(
              Icons.emoji_events_outlined,
              'Badge System',
              'Earn badges and achievements for consistent calm practice',
              const Color(0xFF8B5CF6),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showDashboardIntegrationDetails() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dashboard Integration',
              style: GoogleFonts.lato(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 16),
            _buildIntegrationDetail(
              Icons.insights_outlined,
              'Unified Progress',
              'Your calm progress appears in the main dashboard insights',
              const Color(0xFF3B82F6),
            ),
            _buildIntegrationDetail(
              Icons.psychology_outlined,
              'Motive Personalization',
              'Dashboard adapts to your wellness motive for personalized insights',
              const Color(0xFF4DB6AC),
            ),
            _buildIntegrationDetail(
              Icons.trending_up_outlined,
              'Mood Tracking',
              'Mood improvements from calm sessions enhance your progress analytics',
              const Color(0xFF10B981),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildIntegrationDetail(
    IconData icon,
    String title,
    String description,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                Text(
                  description,
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    color: const Color(0xFF6B7280),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToJournaling() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const JournalingScreen(),
        settings: const RouteSettings(
          name: '/journaling',
          arguments: {'source': 'calm_ecosystem'},
        ),
      ),
    );
  }

  void _navigateToBreathing() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const BreathingScreen(),
        settings: const RouteSettings(
          name: '/breathing',
          arguments: {'source': 'calm_ecosystem'},
        ),
      ),
    );
  }

  void _navigateToMeditation() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const MeditationLibraryScreen(),
        settings: const RouteSettings(
          name: '/meditation',
          arguments: {'source': 'calm_ecosystem'},
        ),
      ),
    );
  }
}
