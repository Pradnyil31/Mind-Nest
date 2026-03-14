import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/calm/application/calm_recommendation_service.dart';
import '../../models/calm_technique.dart';
import '../../services/auth_service.dart';

/// Quick Access Emergency Panel for immediate anxiety relief
/// Displays 3-4 fastest-acting techniques based on user's motive and effectiveness
class QuickAccessPanel extends ConsumerStatefulWidget {
  final String? userMotive;
  final Color primaryColor;

  const QuickAccessPanel({
    super.key,
    this.userMotive,
    this.primaryColor = const Color(0xFF4DB6AC),
  });

  @override
  ConsumerState<QuickAccessPanel> createState() => _QuickAccessPanelState();
}

class _QuickAccessPanelState extends ConsumerState<QuickAccessPanel> {
  final CalmRecommendationService _recommendationService =
      CalmRecommendationService();
  List<CalmTechnique> _quickTechniques = [];
  CalmTechnique? _emergencyTechnique;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuickTechniques();
  }

  @override
  void didUpdateWidget(QuickAccessPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userMotive != widget.userMotive) {
      _loadQuickTechniques();
    }
  }

  Future<void> _loadQuickTechniques() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = AuthService().currentUser;
      if (user != null) {
        final quickTechniques = await _recommendationService
            .getQuickAccessTechniques(user.uid, widget.userMotive);

        final emergencyTechnique = await _recommendationService
            .getEmergencyTechnique(user.uid, widget.userMotive);

        if (mounted) {
          setState(() {
            _quickTechniques = quickTechniques;
            _emergencyTechnique = emergencyTechnique;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      // Fallback to default quick techniques
      if (mounted) {
        setState(() {
          _quickTechniques = CalmTechnique.defaults
              .where((t) => t.durationMinutes <= 5)
              .take(4)
              .toList();
          _emergencyTechnique = CalmTechnique.defaults.firstWhere(
            (t) => t.id == '5-4-3-2-1',
          );
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.primaryColor.withOpacity(0.1),
            widget.primaryColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.flash_on, color: widget.primaryColor, size: 24),
              const SizedBox(width: 8),
              Text(
                'Quick Relief',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: widget.primaryColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            'Immediate techniques for when you need relief right now',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),

          const SizedBox(height: 16),

          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(),
              ),
            )
          else ...[
            // Emergency technique (most prominent)
            if (_emergencyTechnique != null)
              _EmergencyTechniqueCard(
                technique: _emergencyTechnique!,
                primaryColor: widget.primaryColor,
                onTap: () => _startTechnique(_emergencyTechnique!),
              ),

            const SizedBox(height: 16),

            // Quick techniques grid
            if (_quickTechniques.isNotEmpty)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 2.5,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _quickTechniques.length.clamp(0, 4),
                itemBuilder: (context, index) {
                  final technique = _quickTechniques[index];
                  return _QuickTechniqueButton(
                    technique: technique,
                    primaryColor: widget.primaryColor,
                    onTap: () => _startTechnique(technique),
                  );
                },
              ),
          ],
        ],
      ),
    );
  }

  void _startTechnique(CalmTechnique technique) {
    // Navigate directly to technique without delays
    Navigator.of(context).pushNamed('/calm-technique', arguments: technique);
  }
}

class _EmergencyTechniqueCard extends StatelessWidget {
  final CalmTechnique technique;
  final Color primaryColor;
  final VoidCallback onTap;

  const _EmergencyTechniqueCard({
    required this.technique,
    required this.primaryColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    technique.icon,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),

                const SizedBox(width: 16),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'EMERGENCY',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white.withOpacity(0.8),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        technique.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        '${technique.durationMinutes} min • Tap to start immediately',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white.withOpacity(0.8),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickTechniqueButton extends StatelessWidget {
  final CalmTechnique technique;
  final Color primaryColor;
  final VoidCallback onTap;

  const _QuickTechniqueButton({
    required this.technique,
    required this.primaryColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryColor.withOpacity(0.2), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // Icon
                Text(technique.icon, style: const TextStyle(fontSize: 20)),

                const SizedBox(width: 8),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        technique.title,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      Text(
                        '${technique.durationMinutes}m',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
