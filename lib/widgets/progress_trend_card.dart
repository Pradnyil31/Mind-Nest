import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProgressTrendCard extends StatelessWidget {
  final String encouragingMessage;
  final String trendDirection;
  final List<String> highlights;
  final VoidCallback? onTap;

  const ProgressTrendCard({
    super.key,
    required this.encouragingMessage,
    required this.trendDirection,
    required this.highlights,
    this.onTap,
  });

  Color _getTrendColor() {
    switch (trendDirection) {
      case 'improving':
        return const Color(0xFF4CAF50);
      case 'stable':
        return const Color(0xFFFFB74D);
      case 'needs_attention':
        return const Color(0xFFFF7675);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  IconData _getTrendIcon() {
    switch (trendDirection) {
      case 'improving':
        return Icons.trending_up_rounded;
      case 'stable':
        return Icons.trending_flat_rounded;
      case 'needs_attention':
        return Icons.trending_down_rounded;
      default:
        return Icons.trending_flat_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _getTrendColor().withOpacity(0.1),
              _getTrendColor().withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _getTrendColor().withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with trend icon
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getTrendColor(),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getTrendIcon(),
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      encouragingMessage,
                      style: GoogleFonts.lato(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2D2D2D),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Highlights
            if (highlights.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(),
                    const SizedBox(height: 12),
                    Text(
                      'This Week\'s Highlights',
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...highlights.take(3).map((highlight) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  highlight,
                                  style: GoogleFonts.lato(
                                    fontSize: 14,
                                    color: const Color(0xFF2D2D2D),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),

            // Tap to see more hint
            if (onTap != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Tap to see more',
                      style: GoogleFonts.lato(
                        fontSize: 12,
                        color: _getTrendColor(),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: _getTrendColor(),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
