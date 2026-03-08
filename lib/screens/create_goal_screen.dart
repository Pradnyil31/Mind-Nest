import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/smart_goal.dart';
import '../services/goal_service.dart';
import '../services/auth_service.dart';

class CreateGoalScreen extends StatefulWidget {
  const CreateGoalScreen({super.key});

  @override
  State<CreateGoalScreen> createState() => _CreateGoalScreenState();
}

class _CreateGoalScreenState extends State<CreateGoalScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;

  // Form Data
  final _titleController = TextEditingController(); // Specific
  final _targetController = TextEditingController(); // Measurable
  final _unitController = TextEditingController(); // Measurable (Unit)
  DateTime _deadline = DateTime.now().add(const Duration(days: 30)); // Time-bound
  int _selectedColor = 0xFF6C63FF;

  final List<int> _colors = [
    0xFF6C63FF, // Purple
    0xFFFF7675, // Red/Pink
    0xFF00B894, // Green
    0xFFFDCB6E, // Yellow/Orange
    0xFF0984E3, // Blue
    0xFFE84393, // Deep Pink
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _targetController.dispose();
    _unitController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    } else {
      _saveGoal();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _saveGoal() async {
    if (_isLoading) return;

    if (_titleController.text.isEmpty || _targetController.text.isEmpty || _unitController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in all fields')));
        return;
    }

    setState(() => _isLoading = true);

    try {
      final user = AuthService().currentUser;
      if (user == null) throw 'User not logged in';

      final goal = SmartGoal(
        id: '', // Service handles ID
        userId: user.uid,
        title: _titleController.text.trim(),
        description: 'Achieve ${_targetController.text} ${_unitController.text} by ${DateFormat('MMM d').format(_deadline)}', // Auto-generated description
        targetValue: double.parse(_targetController.text.trim()),
        currentValue: 0,
        unit: _unitController.text.trim(),
        deadline: _deadline,
        colorValue: _selectedColor,
      );

      await GoalService().addGoal(goal);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFCF4),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                children: [
                   IconButton(
                     icon: const Icon(Icons.arrow_back_ios, size: 20),
                     onPressed: _prevStep,
                   ),
                   Expanded(
                     child: ClipRRect(
                       borderRadius: BorderRadius.circular(4),
                       child: LinearProgressIndicator(
                         value: (_currentStep + 1) / 4,
                         backgroundColor: Colors.grey.shade200,
                         valueColor: AlwaysStoppedAnimation(Color(_selectedColor)),
                         minHeight: 8,
                       ),
                     ),
                   ),
                   const SizedBox(width: 16),
                   Text(
                     'Step ${_currentStep + 1}/4',
                     style: GoogleFonts.lato(
                       fontWeight: FontWeight.bold,
                       color: Colors.grey.shade600,
                     ),
                   ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // Disable swipe
                children: [
                   _buildStep1Specific(),
                   _buildStep2Measurable(),
                   _buildStep3TimeBound(),
                   _buildStep4Visuals(),
                ],
              ),
            ),

            // Footer Button
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _nextStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(_selectedColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : Text(
                        _currentStep == 3 ? 'Create Goal' : 'Next',
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

  Widget _buildStepTitle(String badge, String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
           decoration: BoxDecoration(
             color: Color(_selectedColor).withOpacity(0.1),
             borderRadius: BorderRadius.circular(8),
           ),
           child: Text(
             badge,
             style: GoogleFonts.lato(
               fontWeight: FontWeight.bold,
               color: Color(_selectedColor),
               fontSize: 14,
             ),
           ),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: GoogleFonts.lato(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF2D2D2D),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: GoogleFonts.lato(
            fontSize: 16,
            color: Colors.grey.shade600,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildStep1Specific() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStepTitle('S - Specific', 'What is your goal?', 'Be specific about what you want to achieve.'),
          TextField(
            controller: _titleController,
            style: GoogleFonts.lato(fontSize: 20, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: 'e.g., Read more books',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2Measurable() {
     return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStepTitle('M - Measurable', 'How much?', 'Set a number to track your progress.'),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _targetController,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.lato(fontSize: 20, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    hintText: 'e.g., 12',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(20),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _unitController,
                  style: GoogleFonts.lato(fontSize: 20, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    hintText: 'e.g., Books',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(20),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep3TimeBound() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStepTitle('T - Time-Bound', 'By when?', 'Deadlines help you stay focused.'),
          
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _deadline,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
              );
              if (picked != null) {
                setState(() => _deadline = picked);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Color(_selectedColor).withOpacity(0.3), width: 2),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: Color(_selectedColor)),
                  const SizedBox(width: 16),
                  Text(
                    DateFormat.yMMMMd().format(_deadline),
                    style: GoogleFonts.lato(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2D2D2D),
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.edit, size: 16, color: Colors.grey),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep4Visuals() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStepTitle('Visuals', 'Make it yours', 'Pick a color for your goal card.'),
          
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: _colors.map((color) {
              final isSelected = _selectedColor == color;
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = color),
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Color(color),
                    shape: BoxShape.circle,
                    border: isSelected ? Border.all(color: Colors.white, width: 4) : null,
                    boxShadow: [
                      BoxShadow(
                        color: Color(color).withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
