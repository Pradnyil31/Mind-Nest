import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeCheckInCard extends StatelessWidget {
  final bool isCompleted;
  final VoidCallback onTap;

  const HomeCheckInCard({
    Key? key,
    required this.isCompleted,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isCompleted ? null : onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: isCompleted 
            ? LinearGradient(colors: [Colors.green.shade50, Colors.green.shade100])
            : const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF8B9DFF)]),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
             BoxShadow(
               color: const Color(0xFF6C63FF).withOpacity(0.3),
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
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCompleted ? Icons.check : Icons.wb_sunny,
                color: isCompleted ? Colors.green : Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isCompleted ? '${_getTimePeriod()} Check-in Complete' : 'Review your ${_getTimePeriod()}',
                    style: GoogleFonts.lato(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isCompleted ? Colors.green.shade800 : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isCompleted ? 'Have a great day!' : 'Log sleep & mood to adapt routine.',
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      color: isCompleted ? Colors.green.shade600 : Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            if (!isCompleted)
              const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }
  String _getTimePeriod() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }
}
