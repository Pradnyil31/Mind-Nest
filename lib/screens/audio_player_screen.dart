import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../features/calm/application/enhanced_audio_controller.dart';
import '../models/ambient_sound.dart';

class AudioPlayerScreen extends ConsumerStatefulWidget {
  final AmbientSound sound;
  final Color primaryColor;

  const AudioPlayerScreen({
    super.key,
    required this.sound,
    this.primaryColor = const Color(0xFF4DB6AC),
  });

  @override
  ConsumerState<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends ConsumerState<AudioPlayerScreen> {
  late String _selectedSoundId;

  @override
  void initState() {
    super.initState();
    _selectedSoundId = widget.sound.id;
  }

  @override
  Widget build(BuildContext context) {
    final soundState = ref.watch(enhancedAudioControllerProvider);
    final soundController = ref.read(enhancedAudioControllerProvider.notifier);

    final selectedSound = AmbientSound.defaults.firstWhere(
      (sound) => sound.id == _selectedSoundId,
      orElse: () => widget.sound,
    );
    final isPlaying = soundState.activeSounds.contains(_selectedSoundId);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Sound Player',
          style: GoogleFonts.lato(
            color: const Color(0xFF1F2937),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCurrentSoundCard(selectedSound, isPlaying),
              const SizedBox(height: 16),
              _buildPlaybackSection(soundController, isPlaying, selectedSound),
              const SizedBox(height: 16),
              _buildVolumeSection(soundState, soundController),
              const SizedBox(height: 20),
              Text(
                'Available Sounds',
                style: GoogleFonts.lato(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _buildSoundList(
                  soundState: soundState,
                  soundController: soundController,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentSoundCard(AmbientSound sound, bool isPlaying) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.primaryColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Text(sound.emoji, style: const TextStyle(fontSize: 40)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sound.name,
                  style: GoogleFonts.lato(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sound.description,
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isPlaying
                  ? const Color(0xFFDCFCE7)
                  : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              isPlaying ? 'Playing' : 'Paused',
              style: GoogleFonts.lato(
                color: isPlaying
                    ? const Color(0xFF166534)
                    : const Color(0xFF4B5563),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaybackSection(
    EnhancedAudioController controller,
    bool isPlaying,
    AmbientSound selectedSound,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => controller.toggleSound(selectedSound, openPlayer: false),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
              label: Text(
                isPlaying ? 'Pause' : 'Play',
                style: GoogleFonts.lato(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: controller.stopAllSounds,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF374151),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              side: BorderSide(color: widget.primaryColor.withValues(alpha: 0.4)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('Stop', style: GoogleFonts.lato(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildVolumeSection(
    EnhancedAudioState soundState,
    EnhancedAudioController controller,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.volume_down, color: widget.primaryColor),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: widget.primaryColor,
                inactiveTrackColor: widget.primaryColor.withValues(alpha: 0.2),
                thumbColor: widget.primaryColor,
                overlayColor: widget.primaryColor.withValues(alpha: 0.2),
              ),
              child: Slider(
                value: soundState.masterVolume,
                onChanged: controller.setMasterVolume,
              ),
            ),
          ),
          Icon(Icons.volume_up, color: widget.primaryColor),
          const SizedBox(width: 8),
          Text(
            '${(soundState.masterVolume * 100).round()}%',
            style: GoogleFonts.lato(
              color: const Color(0xFF4B5563),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSoundList({
    required EnhancedAudioState soundState,
    required EnhancedAudioController soundController,
  }) {
    return ListView.separated(
      itemCount: AmbientSound.defaults.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final sound = AmbientSound.defaults[index];
        final isSelected = sound.id == _selectedSoundId;
        final isActive = soundState.activeSounds.contains(sound.id);

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () async {
              setState(() {
                _selectedSoundId = sound.id;
              });

              if (soundState.isPlaying && !isActive) {
                await soundController.toggleSound(sound, openPlayer: false);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? widget.primaryColor.withValues(alpha: 0.12)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? widget.primaryColor.withValues(alpha: 0.8)
                      : const Color(0xFFE5E7EB),
                ),
              ),
              child: Row(
                children: [
                  Text(sound.emoji, style: const TextStyle(fontSize: 26)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sound.name,
                          style: GoogleFonts.lato(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF111827),
                          ),
                        ),
                        Text(
                          sound.description,
                          style: GoogleFonts.lato(
                            color: const Color(0xFF6B7280),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isActive)
                    Icon(Icons.graphic_eq, color: widget.primaryColor),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
