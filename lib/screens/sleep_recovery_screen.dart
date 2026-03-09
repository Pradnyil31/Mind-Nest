import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SleepRecoveryScreen extends StatefulWidget {
  final Map<String, dynamic> sleepData;
  final String displayName;

  const SleepRecoveryScreen({
    super.key,
    required this.sleepData,
    required this.displayName,
  });

  @override
  State<SleepRecoveryScreen> createState() => _SleepRecoveryScreenState();
}

class _SleepRecoveryScreenState extends State<SleepRecoveryScreen> {
  // Mock data/State for interactive elements
  double _energyLevel = 3.0;
  String _selectedMood = 'Okay';
  final Map<String, bool> _routineCompletion = {
    'sunlight': false,
    'hydration': false,
    'lunch': false,
    'stress_relief': false,
    'wind_down': false,
  };

  @override
  Widget build(BuildContext context) {
    // Extract sleep stats
    final durationMinutes = widget.sleepData['durationMinutes'] as int? ?? 0;
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;
    final quality = widget.sleepData['qualityScore'] as int? ?? 50;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE0EAFC), // Light morning blue
              Color(0xFFCFDEF3), // Soft purple/blue transition
              Color(0xFFF5F7FA), // White/cloudy
            ],
            stops: [0.0, 0.4, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildSleepSummaryCard(hours, minutes, quality),
                const SizedBox(height: 24),
                _buildImpactPrediction(),
                const SizedBox(height: 32),
                Text(
                  'Full-Day Recovery Routine',
                  style: GoogleFonts.lato(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2D3436),
                  ),
                ),
                const SizedBox(height: 16),
                _buildRecoveryTimeline(),
                const SizedBox(height: 32),
                _buildSmartReminders(),
                const SizedBox(height: 32),
                _buildQuickCheckIn(),
                const SizedBox(height: 40),
                _buildProgressSection(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Good Morning, ${widget.displayName}',
          style: GoogleFonts.lato(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF2D3436),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Let\'s help you recover today.',
          style: GoogleFonts.lato(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF636E72),
          ),
        ),
      ],
    );
  }

  Widget _buildSleepSummaryCard(int hours, int minutes, int quality) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF6C5CE7).withOpacity(0.9), // Soft Indigo
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C5CE7).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Last Night',
                    style: GoogleFonts.lato(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${hours}h ${minutes}m',
                        style: GoogleFonts.lato(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Mock sleep debt calculation
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '-2h 35m', // Static mock for now
                          style: GoogleFonts.lato(
                            color: const Color(0xFFFF7675), // Soft Red
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Quality Ring
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: CircularProgressIndicator(
                      value: quality / 100,
                      backgroundColor: Colors.white24,
                      color: quality > 70
                          ? const Color(0xFF55EFC4)
                          : const Color(0xFFFFEAA7),
                      strokeWidth: 6,
                    ),
                  ),
                  Text(
                    '$quality',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lato(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Status Tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFDAB9), // Peach
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 16,
                  color: Color(0xFFD35400),
                ),
                const SizedBox(width: 6),
                Text(
                  'Recovering',
                  style: GoogleFonts.lato(
                    color: const Color(0xFFD35400),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 12),
          Text(
            'One short night doesn\'t define you. Focus on gentle movement and hydration today.',
            style: GoogleFonts.lato(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImpactPrediction() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'How today may feel',
              style: GoogleFonts.lato(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2D3436),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.info_outline, size: 16, color: Colors.grey),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildImpactItem(
              Icons.bolt,
              'Energy',
              'Low',
              const Color(0xFFFF9F43),
            ),
            _buildImpactItem(
              Icons.psychology,
              'Focus',
              'Reduced',
              const Color(0xFFFF7675),
            ),
            _buildImpactItem(
              Icons.sentiment_dissatisfied,
              'Mood',
              'Unstable',
              const Color(0xFFA29BFE),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImpactItem(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.lato(color: Colors.grey, fontSize: 12),
          ),
          Text(
            value,
            style: GoogleFonts.lato(
              color: const Color(0xFF2D3436),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecoveryTimeline() {
    return Column(
      children: [
        _buildTimelineItem(
          'Morning',
          'Wake -> 12 PM',
          Icons.wb_sunny_rounded,
          const Color(0xFFFDBB2D),
          [
            _buildActionItem(
              'sunlight',
              '15 min Sunlight',
              'Boosts cortisol naturally',
            ),
            _buildActionItem(
              'hydration',
              'Drink 500ml Water',
              'Rehydrate brain',
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildTimelineItem(
          'Midday',
          '12 PM -> 4 PM',
          Icons.restaurant,
          const Color(0xFF22C1C3),
          [
            _buildActionItem('lunch', 'Balanced Lunch', 'Avoid heavy carbs'),
            // Power nap is optional, simpler to just list it or have a special button
            _buildActionItem('nap', 'Power Nap (20m)', 'Set an alarm!'),
          ],
        ),
        const SizedBox(height: 16),
        _buildTimelineItem(
          'Evening',
          '4 PM -> Bedtime',
          Icons.nights_stay,
          const Color(0xFF6C5CE7),
          [
            _buildActionItem(
              'stress_relief',
              'Light Stretch',
              'Release tension',
            ),
            _buildActionItem('wind_down', 'No Screens', '90 min before bed'),
          ],
        ),
      ],
    );
  }

  Widget _buildTimelineItem(
    String timeOfDay,
    String timeRange,
    IconData icon,
    Color color,
    List<Widget> children,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: color, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                timeOfDay,
                style: GoogleFonts.lato(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D3436),
                ),
              ),
              const Spacer(),
              Text(
                timeRange,
                style: GoogleFonts.lato(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildActionItem(String id, String title, String subtitle) {
    final isDone = _routineCompletion[id] ?? false;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _routineCompletion[id] = !isDone;
          });
        },
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isDone ? const Color(0xFF55EFC4) : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDone ? Colors.transparent : Colors.grey.shade300,
                ),
              ),
              child: isDone
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                    color: isDone ? Colors.grey : const Color(0xFF2D3436),
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.lato(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmartReminders() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Smart Reminders',
          style: GoogleFonts.lato(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2D3436),
          ),
        ),
        const SizedBox(height: 12),
        _buildReminderCard(
          'Last caffeine window ends at 2:00 PM',
          Icons.coffee_rounded,
        ),
        const SizedBox(height: 8),
        _buildReminderCard('Start wind-down at 9:15 PM', Icons.bedtime_rounded),
      ],
    );
  }

  Widget _buildReminderCard(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFDFE6E9).withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF636E72)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.lato(
                color: const Color(0xFF2D3436),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Icon(Icons.alarm_on, size: 20, color: Color(0xFF6C5CE7)),
        ],
      ),
    );
  }

  Widget _buildQuickCheckIn() {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Check-in',
            style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            'How is your energy?',
            style: GoogleFonts.lato(color: Colors.grey),
          ),
          Slider(
            value: _energyLevel,
            min: 1,
            max: 5,
            divisions: 4,
            activeColor: const Color(0xFF6C5CE7),
            label: _energyLevel.round().toString(),
            onChanged: (val) {
              setState(() {
                _energyLevel = val;
              });
            },
          ),
          const SizedBox(height: 8),
          Text('Mood right now?', style: GoogleFonts.lato(color: Colors.grey)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _moodOption('😞', 'Low'),
              _moodOption('😐', 'Okay'),
              _moodOption('🙂', 'Good'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Check-in logged!')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D3436),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Log Check-in',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _moodOption(String emoji, String label) {
    final isSelected = _selectedMood == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMood = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF6C5CE7).withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF6C5CE7) : Colors.grey.shade300,
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            Text(
              label,
              style: GoogleFonts.lato(
                fontSize: 12,
                color: isSelected ? const Color(0xFF6C5CE7) : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSection() {
    return Column(
      children: [
        Text(
          'Recovery Progress',
          style: GoogleFonts.lato(
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: 0.4,
          backgroundColor: Colors.grey.shade200,
          color: const Color(0xFF00B894),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 8),
        Text(
          'Consistency matters more than duration.',
          style: GoogleFonts.lato(
            color: const Color(0xFF2D3436),
            fontStyle: FontStyle.italic,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
