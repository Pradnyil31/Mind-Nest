import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../models/focus_session.dart';
import '../services/auth_service.dart';
import '../services/focus_service.dart';

class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> with TickerProviderStateMixin {
  // Config
  int _durationMinutes = 25;
  String _taskName = '';
  FocusMode _selectedMode = FocusMode.timer;
  String? _selectedResource; // Video URL or Sound name
  
  // State
  bool _isActive = false;
  late final ValueNotifier<int> _remainingSeconds;
  Timer? _timer;
  YoutubePlayerController? _videoController;

  // Animation
  late AnimationController _breathingController;

  // Resources
  final List<Map<String, String>> _videos = [
    {'title': 'Lofi Study Session', 'id': 'TURbeWK2wwg'}, 
    {'title': 'Forest Rain', 'id': 'qHTbTBxXQ7I'},
    {'title': 'Deep Focus 40Hz', 'id': '1t8CmZ7u6qQ'},
    {'title': 'Classical Flow', 'id': 'RDfjXNqJohg'},
    {'title': 'Pomodoro with Timer', 'id': '555oiY9RPt4'}, 
  ];

  final List<Map<String, dynamic>> _sounds = [
    {'title': 'Rain', 'icon': Icons.water_drop, 'color': 0xFF64B5F6},
    {'title': 'Forest', 'icon': Icons.forest, 'color': 0xFF81C784},
    {'title': 'Cafe', 'icon': Icons.coffee, 'color': 0xFFA1887F},
    {'title': 'Zen', 'icon': Icons.self_improvement, 'color': 0xFF9575CD},
  ];

  @override
  void initState() {
    super.initState();
    _remainingSeconds = ValueNotifier(_durationMinutes * 60);
    _breathingController = AnimationController(
       vsync: this, 
       duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _remainingSeconds.dispose();
    _breathingController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  void _startFocus() {
    if (_taskName.isEmpty) _taskName = 'Focus';
    
    if (_selectedMode == FocusMode.video && _selectedResource != null) {
      // PROPER CLEANUP
      _videoController?.dispose(); 
      _videoController = YoutubePlayerController(
        initialVideoId: _selectedResource!,
        flags: const YoutubePlayerFlags(
          autoPlay: false, // Manual load only
          mute: false,
          isLive: false,
          forceHD: false, // Reduced for reliability
          enableCaption: false,
          hideControls: false, 
        ),
      );
    }
    
    setState(() {
      _isActive = true;
      _remainingSeconds.value = _durationMinutes * 60;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_remainingSeconds.value > 0) {
          _remainingSeconds.value--;
        } else {
          _completeFocus();
        }
    }); // No setState here to prevent rebuilding Video Player
  }

  Future<void> _completeFocus() async {
    _timer?.cancel();
    _videoController?.pause();
    
    final user = AuthService().currentUser;
    if (user != null) {
      final session = FocusSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: user.uid,
        startTime: DateTime.now(), // Technically started duration ago, but simplify
        durationMinutes: _durationMinutes,
        taskName: _taskName,
        mode: _selectedMode,
        resourceId: _selectedResource,
        completed: true,
      );
      await FocusService().saveSession(session);
    }
    
    setState(() => _isActive = false);
    
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Session Complete'),
          content: Text('Great job focusing on "$_taskName" for $_durationMinutes mins!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            )
          ],
        ),
      );
    }
  }

  void _stopFocus() {
    _timer?.cancel();
    _videoController?.pause();
    setState(() => _isActive = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isActive && _selectedMode == FocusMode.video && _videoController != null) {
       return _buildVideoFocusView();
    }
    
    if (_isActive) {
      return _buildActiveTimerView();
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E), // Dark theme
      appBar: AppBar(
        title: Text('MindFlow Focus', style: GoogleFonts.lato(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Task Input
            Text('I want to focus on...', style: GoogleFonts.lato(color: Colors.white70)),
            const SizedBox(height: 10),
            TextField(
              onChanged: (v) => _taskName = v,
              style: const TextStyle(color: Colors.white, fontSize: 24),
              decoration: const InputDecoration(
                hintText: 'e.g. Reading, Coding',
                hintStyle: TextStyle(color: Colors.white30),
                border: InputBorder.none,
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Duration Picker
            Text('Duration', style: GoogleFonts.lato(color: Colors.white70)),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [15, 25, 30, 45, 60].map((mins) {
                  final isSelected = _durationMinutes == mins;
                  return GestureDetector(
                    onTap: () => setState(() => _durationMinutes = mins),
                    child: Container(
                      margin: const EdgeInsets.only(right: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF6C63FF) : Colors.white10,
                        borderRadius: BorderRadius.circular(30),
                        border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
                      ),
                      child: Text(
                        '$mins min',
                        style: TextStyle(
                           color: isSelected ? Colors.white : Colors.white70, 
                           fontWeight: FontWeight.bold
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 40),

            // Mode Selector
            Text('Environment', style: GoogleFonts.lato(color: Colors.white70)),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildModeTab('Zen Timer', FocusMode.timer, Icons.timer),
                const SizedBox(width: 16),
                _buildModeTab('Sound', FocusMode.sound, Icons.music_note),
                const SizedBox(width: 16),
                _buildModeTab('Video', FocusMode.video, Icons.videocam),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Resources Grid
            if (_selectedMode == FocusMode.video) _buildVideoGrid(),
            if (_selectedMode == FocusMode.sound) _buildSoundGrid(),

            const SizedBox(height: 40),
            Center(
              child: SizedBox(
                width: 200,
                height: 56,
                child: ElevatedButton(
                  onPressed: _startFocus,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: Text('Start MindFlow', style: GoogleFonts.lato(fontSize: 18, color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeTab(String label, FocusMode mode, IconData icon) {
    final isSelected = _selectedMode == mode;
    return GestureDetector(
      onTap: () => setState(() {
         _selectedMode = mode;
         _selectedResource = null;
      }),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.white10,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: isSelected ? Colors.black : Colors.white),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.white30))
        ],
      ),
    );
  }

  Widget _buildVideoGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Curated Focus Videos', style: GoogleFonts.lato(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _videos.map((video) {
            final isSelected = _selectedResource == video['id'];
            return GestureDetector(
              onTap: () => setState(() => _selectedResource = video['id']),
              child: Container(
                width: 150,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF6C63FF).withOpacity(0.3) : Colors.white10,
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected ? Border.all(color: const Color(0xFF6C63FF)) : null,
                ),
                child: Column(
                  children: [
                    const Icon(Icons.play_circle_outline, color: Colors.white, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      video['title']!, 
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSoundGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         Text('Ambient Sounds (Simulated)', style: GoogleFonts.lato(color: Colors.white54, fontSize: 12)),
         const SizedBox(height: 12),
         Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _sounds.map((sound) {
            final isSelected = _selectedResource == sound['title'];
            return GestureDetector(
              onTap: () => setState(() => _selectedResource = sound['title'] as String),
              child: Container(
                width: 100,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(sound['color'] as int).withOpacity(isSelected ? 0.8 : 0.2),
                  borderRadius: BorderRadius.circular(12),
                   border: isSelected ? Border.all(color: Colors.white) : null,
                ),
                child: Column(
                  children: [
                    Icon(sound['icon'] as IconData, color: Colors.white, size: 32),
                    const SizedBox(height: 8),
                    Text(sound['title'] as String, style: const TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            );
          }).toList(),
         ),
      ],
    );
  }

  Widget _buildActiveTimerView() {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E), 
      body: SafeArea(
        child: Stack(
          children: [
            // Zen Circle Animation
            Center(
              child: AnimatedBuilder(
                animation: _breathingController,
                builder: (context, child) {
                  return Container(
                    width: 300 + (_breathingController.value * 20),
                    height: 300 + (_breathingController.value * 20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF6C63FF).withOpacity(0.2),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Timer Text
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   ValueListenableBuilder<int>(
                    valueListenable: _remainingSeconds,
                    builder: (context, val, _) => Text(
                      _formatTime(val),
                      style: GoogleFonts.lato(
                        fontSize: 64,
                        fontWeight: FontWeight.w100,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _taskName,
                    style: GoogleFonts.lato(fontSize: 24, color: Colors.white70),
                  ),
                  if (_selectedMode == FocusMode.sound && _selectedResource != null)
                     Padding(
                       padding: const EdgeInsets.only(top: 8.0),
                       child: Row(
                         mainAxisSize: MainAxisSize.min,
                         children: [
                           const Icon(Icons.music_note, color: Colors.white54, size: 16),
                           const SizedBox(width: 4),
                           Text('Playing: $_selectedResource', style: const TextStyle(color: Colors.white54)),
                         ],
                       ),
                     ),
                ],
              ),
            ),

            // Stop Button
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: Center(
                child: FloatingActionButton.large(
                  onPressed: _stopFocus,
                  backgroundColor: Colors.white10,
                  foregroundColor: Colors.white,
                  child: const Icon(Icons.stop),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildVideoFocusView() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: YoutubePlayer(
              controller: _videoController!,
              showVideoProgressIndicator: true,
              progressIndicatorColor: const Color(0xFF6C63FF),
              onReady: () {
                _videoController?.addListener(() {
                  if (mounted && _videoController?.value.errorCode != 0) {
                     ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar(content: Text('Error: ${_videoController?.value.errorCode}')),
                     );
                  }
                });
                _videoController?.load(_selectedResource!);
              },
            ),
          ),
          
          // Central Play Button (Fallback)
          Positioned.fill(
            child: ValueListenableBuilder<YoutubePlayerValue>(
              valueListenable: _videoController!,
              builder: (context, value, _) {
                 if (value.playerState == PlayerState.playing || value.playerState == PlayerState.buffering) {
                   return const SizedBox.shrink();
                 }
                 return Center(
                   child: Container(
                     decoration: BoxDecoration(
                       color: Colors.black45,
                       shape: BoxShape.circle,
                     ),
                     child: IconButton(
                       iconSize: 80,
                       icon: const Icon(Icons.play_arrow, color: Colors.white),
                       onPressed: () => _videoController?.load(_selectedResource!),
                     ),
                   ),
                 );
              },
            ),
          ),

          // Debug Info
          Positioned(
            bottom: 110,
            left: 24,
            child: ValueListenableBuilder<YoutubePlayerValue>(
              valueListenable: _videoController!,
              builder: (context, value, _) {
                 return Text(
                   'ID: $_selectedResource\nStatus: ${value.playerState}\nErr: ${value.errorCode}\nBuf: ${value.buffered}s',
                   style: const TextStyle(color: Colors.yellow, fontSize: 10, fontFamily: 'Courier'),
                 );
              },
            ),
          ),
          
          // Refresh Button
          Positioned(
            top: 40,
            left: 24,
            child: IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () => _videoController?.load(_selectedResource!),
              tooltip: 'Reload Video',
            ),
          ),
          
          // Overlay Timer
          Positioned(
            top: 40,
            right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: ValueListenableBuilder<int>(
                valueListenable: _remainingSeconds,
                builder: (context, val, _) => Text(
                  _formatTime(val),
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),

           // Stop Button
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: FloatingActionButton(
                  onPressed: _stopFocus,
                  backgroundColor: Colors.black54,
                  foregroundColor: Colors.white,
                  child: const Icon(Icons.stop),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
