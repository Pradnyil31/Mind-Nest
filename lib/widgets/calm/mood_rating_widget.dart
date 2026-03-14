import 'package:flutter/material.dart';

/// Widget for collecting mood ratings on a 1-10 scale
/// Used for pre and post technique mood tracking
class MoodRatingWidget extends StatefulWidget {
  final String title;
  final String subtitle;
  final int? initialRating;
  final Function(int rating) onRatingChanged;
  final Color primaryColor;
  final bool enabled;

  const MoodRatingWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onRatingChanged,
    this.initialRating,
    this.primaryColor = const Color(0xFF4DB6AC),
    this.enabled = true,
  });

  @override
  State<MoodRatingWidget> createState() => _MoodRatingWidgetState();
}

class _MoodRatingWidgetState extends State<MoodRatingWidget> {
  int? _selectedRating;

  @override
  void initState() {
    super.initState();
    _selectedRating = widget.initialRating;
  }

  void _selectRating(int rating) {
    if (!widget.enabled) return;

    setState(() {
      _selectedRating = rating;
    });
    widget.onRatingChanged(rating);
  }

  String _getRatingLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Terrible';
      case 2:
        return 'Very Bad';
      case 3:
        return 'Bad';
      case 4:
        return 'Poor';
      case 5:
        return 'Okay';
      case 6:
        return 'Fair';
      case 7:
        return 'Good';
      case 8:
        return 'Very Good';
      case 9:
        return 'Great';
      case 10:
        return 'Excellent';
      default:
        return '';
    }
  }

  Color _getRatingColor(int rating) {
    if (rating <= 3) {
      return Colors.red.shade400;
    } else if (rating <= 5) {
      return Colors.orange.shade400;
    } else if (rating <= 7) {
      return Colors.yellow.shade600;
    } else {
      return Colors.green.shade400;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: widget.primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),

            // Rating scale
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '1\nTerrible',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
                ),
                Text(
                  '5\nOkay',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
                ),
                Text(
                  '10\nExcellent',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Rating buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(10, (index) {
                final rating = index + 1;
                final isSelected = _selectedRating == rating;
                final ratingColor = _getRatingColor(rating);

                return GestureDetector(
                  onTap: () => _selectRating(rating),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? ratingColor
                          : (widget.enabled
                                ? Colors.grey[200]
                                : Colors.grey[100]),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isSelected ? ratingColor : Colors.grey[300]!,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        rating.toString(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : (widget.enabled
                                    ? Colors.grey[700]
                                    : Colors.grey[400]),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),

            if (_selectedRating != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _getRatingColor(
                    _selectedRating!,
                  ).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getRatingLabel(_selectedRating!),
                  style: TextStyle(
                    color: _getRatingColor(_selectedRating!),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
