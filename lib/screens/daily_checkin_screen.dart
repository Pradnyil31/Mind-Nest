import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/daily_checkin.dart';
import '../models/smart_goal.dart';
import '../services/checkin_service.dart';
import '../services/auth_service.dart';
import '../services/goal_service.dart';

class DailyCheckInScreen extends StatefulWidget {
  const DailyCheckInScreen({Key? key}) : super(key: key);

  @override
  State<DailyCheckInScreen> createState() => _DailyCheckInScreenState();
}

class _DailyCheckInScreenState extends State<DailyCheckInScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;
  
  // Data
  int _sleepQuality = 5;
  int _energyLevel = 5;
  String _selectedMood = '';
  List<SmartGoal> _activeGoals = [];
  List<String> _checkedGoals = [];
  String _notes = '';

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    final user = AuthService().currentUser;
    if (user != null) {
      final goals = await GoalService().getGoalsStream(user.uid).first;
      if (mounted) {
        setState(() {
          _activeGoals = goals.where((g) => !g.isCompleted).toList();
        });
      }
    }
  }

  void _nextStep() {
    if (_currentStep < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    } else {
      _submitCheckIn();
    }
  }

  Future<void> _submitCheckIn() async {
    if (_selectedMood.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select your mood first!')));
        _pageController.animateToPage(1, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
        return;
    }
  
    setState(() => _isLoading = true);
    
    try {
      final user = AuthService().currentUser;
      if (user != null) {
        final checkIn = DailyCheckIn(
          id: '',
          userId: user.uid,
          date: DateTime.now(),
          mood: _selectedMood,
          sleepQuality: _sleepQuality,
          energyLevel: _energyLevel,
          activeGoalsChecked: _checkedGoals,
          notes: _notes,
        );

        final addedActivities = await CheckInService()
            .submitCheckIn(checkIn)
            .timeout(const Duration(seconds: 10), onTimeout: () {
              throw 'Connection timed out. Please check internet.';
            });
        
        if (mounted) {
           await showDialog(
             context: context,
             builder: (context) => AlertDialog(
               title: Text(addedActivities.isNotEmpty ? 'Routine Updated' : 'Check-in Complete'),
               content: Text(
                 addedActivities.isNotEmpty 
                   ? 'Based on your check-in, we added the following to your routine:\n\n' + 
                     addedActivities.map((e) => '• $e').join('\n')
                   : 'Great job checking in! Your routine looks good for today.'
               ),
               actions: [
                 TextButton(
                   onPressed: () => Navigator.pop(context),
                   child: const Text('OK'),
                 )
               ],
             ),
           );
           
           if (mounted) {
             Navigator.pop(context, true); // Return true to indicate completion
           }
        }
      } else {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: const Text('User not signed in. Please restart app.'),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
         await showDialog(
           context: context,
           builder: (context) => AlertDialog(
             title: const Text('Error'),
             content: Text('Failed to submit: $e'),
             actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
           ),
         );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFCF4),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF2D2D2D)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildSleepStep(),
                  _buildMoodStep(),
                  _buildEnergyStep(),
                  _buildGoalsStep(),
                ],
              ),
            ),
            
            // Progress Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_currentStep + 1) / 4,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF6C63FF)),
                  minHeight: 6,
                ),
              ),
            ),

            // Next Button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _nextStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D2D2D),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : Text(
                        _currentStep == 3 ? 'Complete Check-in' : 'Next',
                        style: GoogleFonts.lato(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepTitle(String title, String subtitle) {
    return Column(
      children: [
        Text(
          title,
          style: GoogleFonts.lato(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF2D2D2D),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          subtitle,
          style: GoogleFonts.lato(
            fontSize: 18,
            color: Colors.grey.shade600,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildSleepStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStepTitle('Good Morning!', 'How did you sleep last night?'),
          
          Text(
            _getSleepEmoji(_sleepQuality),
            style: const TextStyle(fontSize: 80),
          ),
          const SizedBox(height: 20),
          Text(
            '$_sleepQuality/10',
            style: GoogleFonts.lato(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF6C63FF)),
          ),
          const SizedBox(height: 20),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF6C63FF),
              inactiveTrackColor: Colors.grey.shade200,
              thumbColor: const Color(0xFF6C63FF),
              overlayColor: const Color(0xFF6C63FF).withOpacity(0.2),
              trackHeight: 8,
            ),
            child: Slider(
              value: _sleepQuality.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              onChanged: (val) => setState(() => _sleepQuality = val.toInt()),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Terrible', style: GoogleFonts.lato(color: Colors.grey)),
              Text('Amazing', style: GoogleFonts.lato(color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  String _getSleepEmoji(int quality) {
    if (quality < 4) return '😴';
    if (quality < 7) return '😐';
    return '🤩';
  }

  Widget _buildMoodStep() {
     final moods = [
      {'label': 'Happy', 'emoji': '😊', 'color': 0xFFFFEAA7},
      {'label': 'Calm', 'emoji': '😌', 'color': 0xFF81ECEC},
      {'label': 'Sad', 'emoji': '😔', 'color': 0xFF74B9FF},
      {'label': 'Anxious', 'emoji': '😰', 'color': 0xFFA29BFE},
      {'label': 'Excited', 'emoji': '🤩', 'color': 0xFFFF7675},
      {'label': 'Tired', 'emoji': '😴', 'color': 0xFFDFE6E9},
    ];

    return Padding(
       padding: const EdgeInsets.all(24),
       child: Column(
         mainAxisAlignment: MainAxisAlignment.center,
         children: [
           _buildStepTitle('Check-in', 'How are you feeling right now?'),
           Wrap(
             spacing: 16,
             runSpacing: 16,
             alignment: WrapAlignment.center,
             children: moods.map((mood) {
               final isSelected = _selectedMood == mood['label'];
               return GestureDetector(
                 onTap: () => setState(() => _selectedMood = mood['label'] as String),
                 child: Container(
                   width: 100,
                   padding: const EdgeInsets.symmetric(vertical: 16),
                   decoration: BoxDecoration(
                     color: Color(mood['color'] as int).withOpacity(isSelected ? 1 : 0.4),
                     borderRadius: BorderRadius.circular(16),
                     border: isSelected ? Border.all(color: Colors.black, width: 2) : null,
                   ),
                   child: Column(
                     children: [
                       Text(mood['emoji'] as String, style: const TextStyle(fontSize: 32)),
                       const SizedBox(height: 8),
                       Text(
                         mood['label'] as String,
                         style: GoogleFonts.lato(
                           fontWeight: FontWeight.bold,
                           color: Colors.black87,
                         ),
                       ),
                     ],
                   ),
                 ),
               );
             }).toList(),
           ),
         ],
       ),
    );
  }

  Widget _buildEnergyStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStepTitle('Energy Level', 'How energized do you feel?'),
          
          Text(
            '⚡',
            style: TextStyle(fontSize: 80, color: _energyLevel > 5 ? Colors.orange : Colors.grey),
          ),
          const SizedBox(height: 20),
          Text(
            '$_energyLevel/10',
            style: GoogleFonts.lato(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFFEF8934)),
          ),
           const SizedBox(height: 20),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFFEF8934),
              inactiveTrackColor: Colors.grey.shade200,
              thumbColor: const Color(0xFFEF8934),
              overlayColor: const Color(0xFFEF8934).withOpacity(0.2),
              trackHeight: 8,
            ),
            child: Slider(
              value: _energyLevel.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              onChanged: (val) => setState(() => _energyLevel = val.toInt()),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Drained', style: GoogleFonts.lato(color: Colors.grey)),
              Text('Fully Charged', style: GoogleFonts.lato(color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
             const SizedBox(height: 40),
            _buildStepTitle('Goal Focus', 'Which goals are you tackling today?'),
            
            if (_activeGoals.isEmpty)
              Text(
                'No active goals yet. Create one in Smart Goals!',
                style: GoogleFonts.lato(color: Colors.grey),
              )
            else
              ..._activeGoals.map((goal) {
                final isChecked = _checkedGoals.contains(goal.id);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isChecked) {
                        _checkedGoals.remove(goal.id);
                      } else {
                        _checkedGoals.add(goal.id);
                      }
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isChecked ? Color(goal.colorValue) : Colors.grey.shade300,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isChecked ? Icons.check_circle : Icons.circle_outlined,
                          color: isChecked ? Color(goal.colorValue) : Colors.grey,
                          size: 28,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            goal.title,
                            style: GoogleFonts.lato(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2D2D2D),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              
             const SizedBox(height: 32),
             TextField(
               onChanged: (v) => _notes = v,
               decoration: InputDecoration(
                 hintText: 'Any Notes for today?',
                 filled: true,
                 fillColor: Colors.white,
                 border: OutlineInputBorder(
                   borderRadius: BorderRadius.circular(16),
                   borderSide: BorderSide.none,
                 ),
                 contentPadding: const EdgeInsets.all(20),
               ),
               maxLines: 3,
             ),
          ],
        ),
      ),
    );
  }
}
