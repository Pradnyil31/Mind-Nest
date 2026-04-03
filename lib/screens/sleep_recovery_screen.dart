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
  // Recovery checklist state
  final Map<String, bool> _checklist = {
    'Drink 500ml water': false,
    'Get 15 min of sunlight': false,
    'Eat a balanced lunch': false,
    '20-min power nap': false,
    'Light evening stretch': false,
    'No screens 90 min before bed': false,
  };

  // Quick check-in state
  double _energyLevel = 3;
  String _selectedMood = '';

  @override
  Widget build(BuildContext context) {
    // Extract sleep stats
    final durationMinutes = widget.sleepData['durationMinutes'] as int? ?? 0;
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;
    final quality = widget.sleepData['qualityScore'] as int? ?? 50;

    // Dynamic sleep debt: target 8 hours (480 minutes)
    const targetMinutes = 480;
    final debtMinutes = (targetMinutes - durationMinutes).clamp(0, targetMinutes);
    final debtHours = debtMinutes ~/ 60;
    final debtMins = debtMinutes % 60;
    final debtLabel = debtMinutes == 0
        ? 'On Target 🎯'
        : '-${debtHours}h ${debtMins}m';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE0EAFC), // Light morning blue
              Color(0xFFFDFCF4), // Warm white
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.bedtime_rounded,
                          color: Color(0xFF6C63FF), size: 28),
                      const SizedBox(width: 12),
                      Text(
                        'Sleep Recovery',
                        style: GoogleFonts.lato(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2D2D2D),
                        ),
                      ),
                    ],
                  ),
                ),

                // Sleep summary card
                _buildSleepSummaryCard(
                  hours: hours,
                  minutes: minutes,
                  quality: quality,
                  debtLabel: debtLabel,
                  debtMinutes: debtMinutes,
                ),

                const SizedBox(height: 24),

                // How today may feel
                _buildSectionHeader('How Today May Feel'),
                const SizedBox(height: 12),
                _buildImpactRow(),

                const SizedBox(height: 24),

                // Recovery plan
                _buildSectionHeader('Your Recovery Plan'),
                const SizedBox(height: 12),
                _buildRecoveryTimeline(),

                const SizedBox(height: 24),

                // Smart reminders
                _buildSectionHeader('Smart Reminders'),
                const SizedBox(height: 12),
                _buildSmartReminders(),

                const SizedBox(height: 24),

                // Quick check-in
                _buildSectionHeader('Quick Energy Check-in'),
                const SizedBox(height: 12),
                _buildQuickCheckIn(),

                const SizedBox(height: 24),

                // Recovery progress
                _buildSectionHeader('Recovery Progress'),
                const SizedBox(height: 12),
                _buildRecoveryProgress(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSleepSummaryCard({
    required int hours,
    required int minutes,
    required int quality,
    required String debtLabel,
    required int debtMinutes,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7986CB), Color(0xFF5C6BC0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7986CB).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  debtMinutes == 0 ? 'Well Rested ✨' : 'Recovering 🌙',
                  style: GoogleFonts.lato(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Sleep debt chip
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: debtMinutes == 0
                      ? Colors.green.withValues(alpha: 0.3)
                      : const Color(0xFFFF7675).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  debtLabel,
                  style: GoogleFonts.lato(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              // Hours slept
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${hours}h ${minutes}m',
                      style: GoogleFonts.lato(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'slept last night',
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),

              // Quality ring
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 72,
                    height: 72,
                    child: CircularProgressIndicator(
                      value: quality / 100,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 6,
                    ),
                  ),
                  Text(
                    '$quality',
                    style: GoogleFonts.lato(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          Text(
            debtMinutes == 0
                ? 'Great sleep! Keep this routine going. 🌟'
                : 'Your body is in recovery mode. Follow today\'s plan to feel your best.',
            style: GoogleFonts.lato(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.85),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImpactRow() {
    return Row(
      children: [
        _buildImpactItem(Icons.battery_2_bar_rounded, 'Energy', 'Low',
            const Color(0xFFFF7675)),
        const SizedBox(width: 12),
        _buildImpactItem(Icons.center_focus_weak_rounded, 'Focus', 'Reduced',
            const Color(0xFFFDAC5A)),
        const SizedBox(width: 12),
        _buildImpactItem(Icons.sentiment_dissatisfied, 'Mood', 'Unstable',
            const Color(0xFFA29BFE)),
      ],
    );
  }

  Widget _buildImpactItem(
      IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.lato(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: GoogleFonts.lato(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecoveryTimeline() {
    return Column(
      children: [
        _buildTimeBlock(
          emoji: '🌅',
          label: 'Morning',
          items: ['Drink 500ml water', 'Get 15 min of sunlight'],
        ),
        const SizedBox(height: 12),
        _buildTimeBlock(
          emoji: '🍽️',
          label: 'Midday',
          items: ['Eat a balanced lunch', '20-min power nap'],
        ),
        const SizedBox(height: 12),
        _buildTimeBlock(
          emoji: '🌙',
          label: 'Evening',
          items: ['Light evening stretch', 'No screens 90 min before bed'],
        ),
      ],
    );
  }

  Widget _buildTimeBlock({
    required String emoji,
    required String label,
    required List<String> items,
  }) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.lato(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D2D2D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((item) => _buildChecklistItem(item)),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(String item) {
    final isChecked = _checklist[item] ?? false;
    return GestureDetector(
      onTap: () => setState(() => _checklist[item] = !isChecked),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Icon(
              isChecked
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked,
              color: isChecked ? const Color(0xFF6C63FF) : Colors.grey.shade400,
              size: 22,
            ),
            const SizedBox(width: 12),
            Text(
              item,
              style: GoogleFonts.lato(
                fontSize: 14,
                color: isChecked
                    ? Colors.grey.shade400
                    : const Color(0xFF2D2D2D),
                decoration:
                    isChecked ? TextDecoration.lineThrough : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmartReminders() {
    return Container(
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
      child: Column(
        children: [
          _buildReminderRow(
              icon: Icons.coffee_rounded,
              color: const Color(0xFFF39C12),
              label: 'Caffeine cutoff',
              time: '2:00 PM'),
          const Divider(height: 20),
          _buildReminderRow(
              icon: Icons.nights_stay_rounded,
              color: const Color(0xFF6C63FF),
              label: 'Wind-down starts',
              time: '9:15 PM'),
        ],
      ),
    );
  }

  Widget _buildReminderRow({
    required IconData icon,
    required Color color,
    required String label,
    required String time,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.lato(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2D2D2D),
            ),
          ),
        ),
        Text(
          time,
          style: GoogleFonts.lato(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickCheckIn() {
    final moods = ['Low', 'Okay', 'Good'];
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Energy',
            style: GoogleFonts.lato(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2D2D2D),
            ),
          ),
          Row(
            children: [
              const Text('😴', style: TextStyle(fontSize: 18)),
              Expanded(
                child: Slider(
                  value: _energyLevel,
                  min: 1,
                  max: 5,
                  divisions: 4,
                  activeColor: const Color(0xFF6C63FF),
                  inactiveColor: Colors.grey.shade200,
                  onChanged: (val) => setState(() => _energyLevel = val),
                ),
              ),
              const Text('⚡', style: TextStyle(fontSize: 18)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Current Mood',
            style: GoogleFonts.lato(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2D2D2D),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: moods.map((mood) {
              final isSelected = _selectedMood == mood;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedMood = mood),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF6C63FF)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      mood,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lato(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color:
                            isSelected ? Colors.white : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Check-in logged! Keep going 💪'),
                    backgroundColor: Color(0xFF6C63FF),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text(
                'Log Check-in',
                style: GoogleFonts.lato(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecoveryProgress() {
    final completed = _checklist.values.where((v) => v).length;
    final total = _checklist.length;
    final progress = total > 0 ? completed / total : 0.0;

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$completed / $total tasks done',
                style: GoogleFonts.lato(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D2D2D),
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: GoogleFonts.lato(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF6C63FF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade200,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            progress == 0
                ? 'Start checking off your recovery tasks above 💪'
                : progress < 0.5
                    ? 'Good start! Keep going to feel better faster.'
                    : progress < 1.0
                        ? 'Almost there! Great recovery effort today.'
                        : 'Perfect recovery day! Sleep well tonight. 🌙',
            style: GoogleFonts.lato(
              fontSize: 13,
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.lato(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF2D2D2D),
      ),
    );
  }
}
