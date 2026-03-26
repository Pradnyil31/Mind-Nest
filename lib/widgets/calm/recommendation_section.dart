import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/calm/application/calm_recommendation_service.dart';
import '../../models/calm_technique.dart';
import '../../providers/app_providers.dart';

/// Widget that displays personalized technique recommendations
/// This would be integrated into the EnhancedCalmScreen
class RecommendationSection extends ConsumerStatefulWidget {
  final String? userMotive;
  final Color primaryColor;

  const RecommendationSection({
    super.key,
    this.userMotive,
    this.primaryColor = const Color(0xFF4DB6AC),
  });

  @override
  ConsumerState<RecommendationSection> createState() =>
      _RecommendationSectionState();
}

class _RecommendationSectionState extends ConsumerState<RecommendationSection> {
  CalmRecommendationService get _recommendationService =>
      ref.read(calmRecommendationServiceProvider);
  List<CalmTechnique> _recommendations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  @override
  void didUpdateWidget(RecommendationSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userMotive != widget.userMotive) {
      _loadRecommendations();
    }
  }

  Future<void> _loadRecommendations() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = ref.read(authServiceProvider).currentUser;
      if (user != null) {
        final recommendations = await _recommendationService
            .getPersonalizedRecommendations(user.uid, widget.userMotive);

        if (mounted) {
          setState(() {
            _recommendations = recommendations;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      // Fallback to default techniques if recommendation service fails
      if (mounted) {
        setState(() {
          _recommendations = CalmTechnique.defaults.take(3).toList();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            'Recommended for You',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: widget.primaryColor,
            ),
          ),
        ),
        const SizedBox(height: 16),

        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(),
            ),
          )
        else
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              itemCount: _recommendations.length,
              itemBuilder: (context, index) {
                final technique = _recommendations[index];
                return _RecommendationCard(
                  technique: technique,
                  primaryColor: widget.primaryColor,
                  onTap: () => _navigateToTechnique(technique),
                );
              },
            ),
          ),
      ],
    );
  }

  void _navigateToTechnique(CalmTechnique technique) {
    // This would navigate to the appropriate technique screen
    // Implementation would depend on the existing navigation structure
    Navigator.of(context).pushNamed('/calm-technique', arguments: technique);
  }
}

class _RecommendationCard extends StatelessWidget {
  final CalmTechnique technique;
  final Color primaryColor;
  final VoidCallback onTap;

  const _RecommendationCard({
    required this.technique,
    required this.primaryColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Technique icon and duration
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(technique.icon, style: const TextStyle(fontSize: 24)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${technique.durationMinutes}m',
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Technique title
                Text(
                  technique.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 8),

                // Technique description
                Expanded(
                  child: Text(
                    technique.description,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                const SizedBox(height: 8),

                // Technique type badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getTypeColor(technique.type).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getTypeName(technique.type),
                    style: TextStyle(
                      color: _getTypeColor(technique.type),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getTypeColor(TechniqueType type) {
    switch (type) {
      case TechniqueType.grounding:
        return Colors.green;
      case TechniqueType.affirmation:
        return Colors.blue;
      case TechniqueType.breathing:
        return Colors.orange;
      case TechniqueType.visualization:
        return Colors.purple;
    }
  }

  String _getTypeName(TechniqueType type) {
    switch (type) {
      case TechniqueType.grounding:
        return 'GROUNDING';
      case TechniqueType.affirmation:
        return 'AFFIRMATION';
      case TechniqueType.breathing:
        return 'BREATHING';
      case TechniqueType.visualization:
        return 'VISUALIZATION';
    }
  }
}

