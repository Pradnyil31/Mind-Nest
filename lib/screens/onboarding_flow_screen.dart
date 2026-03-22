import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../config/motive_config.dart';
// The instruction asked to remove 'routine_screen.dart', but it was not present.
// The instruction's example output also removed 'home_screen.dart' and duplicated 'motive_config.dart'.
// Following the explicit instruction to remove 'routine_screen.dart' means no change to the imports as it's not there.
// However, if the intent was to match the provided 'Code Edit' snippet's import list,
// then 'home_screen.dart' would be removed and 'motive_config.dart' would be duplicated.
// Sticking strictly to "Remove the import of routine_screen.dart" and "without making any unrelated edits".
// Since 'routine_screen.dart' is not in the original content, no change is made to the imports.
import 'home_screen.dart';

class OnboardingFlowScreen extends StatefulWidget {
  const OnboardingFlowScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingFlowScreen> createState() => _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends State<OnboardingFlowScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  bool _isSaving = false;

  // selections
  String? _selectedMotive; // Primary motive selection
  final List<String> _selectedSupportAreas = [];
  String _selectedExperienceLevel = '';
  String _selectedCommitment = '';

  // Sleep/Wake Times (Newly added for personalization)
  TimeOfDay _wakeUpTime = const TimeOfDay(hour: 7, minute: 30);
  TimeOfDay _bedTime = const TimeOfDay(hour: 21, minute: 0);

  /// Dynamic support areas based on selected motive
  List<String> get _dynamicSupportOptions {
    return MotiveConfig.getSupportAreaOptions(_selectedMotive);
  }

  String get _supportQuestion {
    return MotiveConfig.getSupportQuestion(_selectedMotive);
  }

  final List<String> _experienceLevelOptions = [
    'New Beginner',
    'Tried a little',
    'Long ago',
    'Never tried',
  ];

  final List<String> _commitmentOptions = [
    '5 minutes — Just a quick reset',
    '10 minutes — A solid pause',
    '15 minutes — Real me-time',
    '30+ minutes — Full deep dive',
  ];

  void _nextPage() {
    if (_currentPage < 5) { // 6 pages total (0-5)
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _finishOnboarding() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final user = _authService.currentUser;
      if (user != null) {
        await _firestoreService.updateUser(user.uid, {
          'primaryMotive': _selectedMotive,
          'primaryGoals': [_selectedMotive ?? 'General Wellness'], // Save for compatibility
          'supportAreas': _selectedSupportAreas,
          'experienceLevel': _selectedExperienceLevel,
          'dailyCommitment': _selectedCommitment,
          'routine': {
            'wakeUpTime': _formatTime(_wakeUpTime),
            'bedTime': _formatTime(_bedTime),
          },
          'onboardingCompleted': true,
          'onboardingCompleted': true,
          // Set initial routine: scaled by commitment level
          'baseRoutine': MotiveConfig.generateRoutine(
             motive: _selectedMotive, 
             commitment: _selectedCommitment,
             supportAreas: _selectedSupportAreas,
          ),
          'routineActivities': MotiveConfig.generateRoutine(
             motive: _selectedMotive, 
             commitment: _selectedCommitment,
             supportAreas: _selectedSupportAreas,
          ),
          'lastGeneratedDate': DateTime.now().toIso8601String(),
        });

        if (mounted) {
          // Navigate to Home Screen directly now
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
          ); 
          
          ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('✨ Profile set! Welcome to your personalized routine.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }



  Future<void> _selectTime(bool isWakeUp) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isWakeUp ? _wakeUpTime : _bedTime,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFA78BFA), // Matched onboarding purple
              onPrimary: Colors.white,
              onSurface: Color(0xFF4A4A4A),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFA78BFA),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isWakeUp) {
          _wakeUpTime = picked;
        } else {
          _bedTime = picked;
        }
      });
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7FD),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Bar
            LinearProgressIndicator(
              value: (_currentPage + 1) / 6, // 6 pages
              backgroundColor: const Color(0xFFE0D4F5),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFA78BFA)),
              minHeight: 6,
            ),
            
            // App Bar / Nav
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: Row(
                children: [
                   if (_currentPage > 0)
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Color(0xFF4A4A4A)),
                      onPressed: _previousPage,
                    )
                  else
                    const SizedBox(width: 48),
                  
                  const Spacer(),
                  Text(
                    'Step ${_currentPage + 1}/6',
                    style: const TextStyle(
                      color: Color(0xFF757575),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  // Step 1: Motive Selection
                  _buildMotiveSelectionPage(),

                  // Step 2: Support Areas (Personalized by motive)
                  _buildSelectionPage(
                    title: _supportQuestion,
                    subtitle: 'This helps us personalize your experience',
                    options: _dynamicSupportOptions,
                    selectedValues: _selectedSupportAreas,
                    allowMultiple: true,
                  ),

                  // Step 3: Experience Level
                  _buildSelectionPage(
                    title: 'Have you tried meditation or mindfulness before?',
                    subtitle: 'Help us guide you',
                    options: _experienceLevelOptions,
                    selectedValues: [_selectedExperienceLevel].where((e) => e.isNotEmpty).toList(),
                    allowMultiple: false,
                    onSingleSelect: (val) {
                      setState(() {
                        _selectedExperienceLevel = val;
                      });
                    },
                  ),

                  // Step 4: Daily Commitment
                  _buildSelectionPage(
                    title: 'How much time can you commit daily?',
                    subtitle: 'Start small — you can always adjust later',
                    options: _commitmentOptions,
                    selectedValues: [_selectedCommitment].where((e) => e.isNotEmpty).toList(),
                    allowMultiple: false,
                    onSingleSelect: (val) {
                      setState(() {
                        _selectedCommitment = val;
                      });
                    },
                  ),

                  // Step 6: Wake Up Time
                  _buildRoutineTimePage(
                    title: 'When do you usually wake up?',
                    subtitle: 'This helps us set your morning window',
                    time: _wakeUpTime,
                    isWakeUp: true,
                  ),

                  // Step 7: Bed Time
                  _buildRoutineTimePage(
                    title: 'When do you usually go to bed?',
                    subtitle: 'This helps us personalize your wind-down time',
                    time: _bedTime,
                    isWakeUp: false,
                  ),
                ],
              ),
            ),

            // Bottom Navigation
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFA78BFA),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          _currentPage == 5 ? 'Let\'s Go! 🚀' : 'Next',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
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

  Widget _buildSelectionPage({
    required String title,
    required String subtitle,
    required List<String> options,
    required List<String> selectedValues,
    bool allowMultiple = true,
    Function(String)? onSingleSelect,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D2D2D),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF757575),
            ),
          ),
          const SizedBox(height: 32),
          ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: options.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final option = options[index];
              final isSelected = selectedValues.contains(option);
              
              return InkWell(
                onTap: () {
                  setState(() {
                    if (allowMultiple) {
                      if (isSelected) {
                        selectedValues.remove(option);
                      } else {
                        selectedValues.add(option);
                      }
                    } else {
                       if (onSingleSelect != null) {
                         onSingleSelect(option);
                       }
                    }
                  });
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFA78BFA).withOpacity(0.1) : Colors.white,
                    border: Border.all(
                      color: isSelected ? const Color(0xFFA78BFA) : const Color(0xFFEEEEEE),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          option,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: isSelected ? const Color(0xFFA78BFA) : const Color(0xFF4A4A4A),
                          ),
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle,
                          color: Color(0xFFA78BFA),
                          size: 24,
                        )
                      else
                        const Icon(
                          Icons.circle_outlined,
                          color: Color(0xFFBDBDBD),
                          size: 24,
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMotiveSelectionPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What brings you here?',
            style: GoogleFonts.lato(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D2D2D),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose your primary focus area',
            style: GoogleFonts.lato(
              fontSize: 16,
              color: const Color(0xFF757575),
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: ListView(
              children: MotiveConfig.allMotives.map((motive) {
                final profile = MotiveConfig.getProfile(motive);
                final isSelected = _selectedMotive == motive;
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (_selectedMotive != motive) {
                        _selectedSupportAreas.clear(); // Reset when motive changes
                      }
                      _selectedMotive = motive;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF667EEA).withOpacity(0.1) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF667EEA) : Colors.grey.shade200,
                        width: isSelected ? 2.5 : 1,
                      ),
                      boxShadow: [
                        if (!isSelected)
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Emoji
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? const Color(0xFF667EEA).withOpacity(0.2)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              profile?.emoji ?? '🎯',
                              style: const TextStyle(fontSize: 30),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile?.displayName ?? motive,
                                style: GoogleFonts.lato(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF2D2D2D),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                profile?.description ?? '',
                                style: GoogleFonts.lato(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Checkmark
                        if (isSelected)
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Color(0xFF667EEA),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoutineTimePage({
    required String title,
    required String subtitle,
    required TimeOfDay time,
    required bool isWakeUp,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D2D2D),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF757575),
            ),
          ),
          const SizedBox(height: 60),
          Center(
            child: Column(
              children: [
                Icon(
                  isWakeUp ? Icons.wb_sunny_rounded : Icons.nights_stay_rounded,
                  size: 80,
                  color: const Color(0xFFA78BFA),
                ),
                const SizedBox(height: 32),
                GestureDetector(
                  onTap: () => _selectTime(isWakeUp),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFA78BFA), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFA78BFA).withOpacity(0.1),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Text(
                      _formatTime(time),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D2D2D),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Tap to change time',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
