import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for theme brightness mode
final themeBrightnessProvider = StateProvider<Brightness>((ref) {
  return Brightness.light; // Default to light mode
});

/// Provider for primary app color
final primaryColorProvider = Provider<Color>((ref) {
  return const Color(0xFFA78BFA); // Purple from existing design
});

/// Provider for time-based background color
/// 
/// Returns different colors based on time of day:
/// - Morning (5 AM - 12 PM): Sky blue
/// - Afternoon (12 PM - 5 PM): Warm beige
/// - Evening (5 PM - 9 PM): Pink
/// - Night (9 PM - 5 AM): Dark blue
final timeBasedBackgroundProvider = Provider<Color>((ref) {
  final hour = DateTime.now().hour;
  
  if (hour >= 5 && hour < 12) {
    // Morning
    return const Color(0xFF87CEEB);
  } else if (hour >= 12 && hour < 17) {
    // Afternoon
    return const Color(0xFFFFE4B5);
  } else if (hour >= 17 && hour < 21) {
    // Evening
    return const Color(0xFFFFB6C1);
  } else {
    // Night
    return const Color(0xFF2C3E50);
  }
});

/// Provider for greeting message based on time
final greetingMessageProvider = Provider<String>((ref) {
  final hour = DateTime.now().hour;
  
  if (hour >= 5 && hour < 12) {
    return 'Good Morning';
  } else if (hour >= 12 && hour < 17) {
    return 'Good Afternoon';
  } else if (hour >= 17 && hour < 21) {
    return 'Good Evening';
  } else {
    return 'Good Night';
  }
});
