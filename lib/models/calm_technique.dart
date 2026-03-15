import 'motive_technique_data.dart';

enum TechniqueType { grounding, affirmation, breathing, visualization }

class CalmTechnique {
  final String id;
  final String title;
  final String description;
  final String icon;
  final TechniqueType type;
  final int durationMinutes;
  final List<String>? steps; // For step-by-step techniques
  final List<String>? content; // For affirmations, quotes, etc.
  final Map<String, String>?
  motiveSpecificDescriptions; // Motive-specific descriptions
  final Map<String, List<String>>?
  motiveSpecificBenefits; // Motive-specific benefits
  final List<String>?
  primaryMotives; // Motives this technique is most effective for
  final List<String>? secondaryMotives; // Motives this technique can help with

  const CalmTechnique({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.type,
    this.durationMinutes = 5,
    this.steps,
    this.content,
    this.motiveSpecificDescriptions,
    this.motiveSpecificBenefits,
    this.primaryMotives,
    this.secondaryMotives,
  });

  // Predefined calm techniques - expanded library with 15+ techniques
  static const List<CalmTechnique> defaults = [
    // GROUNDING TECHNIQUES
    CalmTechnique(
      id: '5-4-3-2-1',
      title: '5-4-3-2-1 Grounding',
      description: 'Use your senses to calm anxiety',
      icon: '🧘',
      type: TechniqueType.grounding,
      durationMinutes: 5,
      steps: [
        'Welcome. We are going to gently bring your mind back to the present moment. Sit as comfortably as you can, place both feet flat on the floor, and rest your hands on your lap. Now take one slow, full breath in through your nose... and release it steadily through your mouth. Let your shoulders drop, and let any tension in your face soften. You are safe. You are here.',
        'Slowly open your eyes and look around the space you are in. We are going to find five things you can actually see right now. Take your time with each one — notice its shape, its colour, how the light touches it. It might be a window, a chair, a pattern on the wall, an object on a table. Quietly name each thing in your mind as you notice it. One... two... three... four... five. Well done.',
        'Now bring your attention to touch. We are looking for four things you can physically feel right now. Notice the weight of your body where you are sitting or standing. Feel the texture of your clothing against your skin. Press your feet into the floor and feel the ground beneath you. You might notice the temperature of the air on your hands or face. Name four sensations, taking a moment with each one.',
        'Now become very still and just listen. Notice three sounds you can actually hear right now. They might be near or far — the hum of an appliance, a sound from outside, even the sound of your own breath. You do not need to label them as good or bad. Simply hear them. The first sound... the second... the third. You are fully present in this moment.',
        'Turn your attention to your sense of smell. Notice two things you can smell, however faint. It might be the air in the room, your own skin, or fabric nearby. If nothing is detectable, that is fine — bring to mind two scents you enjoy. Perhaps fresh rain, warm coffee, or something familiar and comforting. Linger with each one for a few seconds.',
        'Finally, bring your attention to taste. Notice what is present in your mouth right now, even if very subtle. If there is nothing to taste, simply bring to mind one food or drink you truly enjoy — and imagine its taste, its texture, its warmth or coolness. This single moment of pleasure belongs entirely to you.',
        'You have completed the 5-4-3-2-1 grounding exercise. Now take three slow, deliberate breaths together. Breathe in through your nose... and out through your mouth. In... and out. One final breath in... and a long, complete exhale. Notice how much more settled you feel. You are grounded, present, and safe. This practice is always available to you, any time you need it.',
      ],
    ),
    CalmTechnique(
      id: 'worry-banking',
      title: 'Worry Banking',
      description: 'Set aside worries for later',
      icon: '📝',
      type: TechniqueType.grounding,
      durationMinutes: 5,
      steps: [
        'Welcome to Worry Banking — a technique that helps you take back control from your anxious mind. The idea is simple: instead of trying to push worries away, which rarely works, you will give them a dedicated time and place. Right now, your only job is to notice the worries, not solve them. Take a slow breath and get ready.',
        'Bring to mind the worry or worries that are on your mind right now. Do not try to fix them yet. Simply acknowledge them by name, the way you might greet someone at the door. You might say to yourself: "I see you, worry about work" or "I notice you, concern about money." Acknowledge each worry calmly and without judgment. You are not ignoring them — you are managing them deliberately.',
        'Now, mentally set each worry aside by placing it into your Worry Bank. Think of it like a safe deposit box — the worries go in, they are stored securely, and you can retrieve them later at a time you choose. You are not dismissing them. You are simply choosing not to process them right now, during this moment of rest. The bank is locked until you decide to open it.',
        'Choose a specific worry time for later today. It should be a real, defined window — for example, seven o\'clock this evening for ten minutes. Set this time clearly in your mind. Tell yourself: "I will think about these worries at seven pm. Until then, they are in the bank." Having a real time makes it much easier for your brain to let go in the meantime.',
        'Whenever a worry tries to creep back in before your worry time, gently redirect yourself. Say quietly: "Not now. Worry time is later." Then return your attention to whatever you were doing. This is a skill, and it gets easier with practice. You may need to do this many times. That is completely normal. Each redirection is a small victory.',
        'When worry time actually arrives, sit down with your list. Review each worry one by one. Ask: is there one action I can take on this? If yes, write it down. If no, practise letting it go. You will often find that worries feel much smaller when you face them in a calm, deliberate moment rather than when they ambush you.',
        'You have completed the Worry Banking exercise. Take a slow, deep breath in... and release it fully. Notice how much lighter you feel when worries have a definite place to go. You have taken back control of your mind. Carry this feeling of calm authority with you for the rest of your day.',
      ],
    ),
    CalmTechnique(
      id: 'body-scan',
      title: 'Progressive Body Scan',
      description: 'Release tension from head to toe',
      icon: '🫧',
      type: TechniqueType.grounding,
      durationMinutes: 8,
      steps: [
        'Welcome to the Progressive Body Scan. Find a comfortable position, either sitting or lying down. Close your eyes and take three deep breaths, allowing your body to settle with each exhale.',
        'Start at the top of your head. Notice any sensations - warmth, coolness, tension, or relaxation. Don\'t try to change anything, just observe. Now consciously relax your scalp and forehead.',
        'Move your attention to your face. Notice your eyebrows, eyes, cheeks, and jaw. If you\'re holding tension here, gently let it go. Allow your jaw to drop slightly and your face to soften.',
        'Bring awareness to your neck and shoulders. This is where many of us hold stress. Take a moment to really feel this area, then consciously release any tightness you find.',
        'Focus on your arms, from shoulders to fingertips. Notice each part - upper arms, elbows, forearms, wrists, hands, and fingers. Let them feel heavy and relaxed.',
        'Move to your chest and upper back. Feel your breathing naturally expanding and contracting this area. Let your chest be open and your upper back soft.',
        'Bring attention to your abdomen and lower back. Notice how this area moves with your breath. Release any holding or tension you find here.',
        'Focus on your hips and pelvis. Let this area feel stable and grounded, releasing any unnecessary tension.',
        'Move down to your thighs and knees. Feel the weight of your legs, letting them be completely supported.',
        'Finally, bring attention to your calves, ankles, and feet. Let them feel heavy and completely relaxed.',
        'Take a moment to feel your whole body as one connected, relaxed unit. Notice the difference from when you started. Take three deep breaths and slowly open your eyes when ready.',
      ],
    ),
    CalmTechnique(
      id: 'mindful-observation',
      title: 'Mindful Observation',
      description: 'Focus deeply on a single object',
      icon: '👁️',
      type: TechniqueType.grounding,
      durationMinutes: 3,
      steps: [
        'Choose a small object near you - it could be a pen, a leaf, a stone, or anything that fits in your hand. Hold it gently and get comfortable.',
        'Look at your object as if you\'ve never seen anything like it before. Notice its shape, size, and proportions. What makes it unique?',
        'Observe the colors and patterns. Are there variations in shade? Textures? How does light interact with its surface?',
        'Feel the object\'s weight in your hand. Notice its temperature, texture, and any other physical sensations it creates.',
        'If your mind wanders to other thoughts, gently bring your attention back to the object. This is normal and part of the practice.',
        'Spend the final moments appreciating this simple object and how it has anchored your attention in the present moment.',
      ],
    ),
    CalmTechnique(
      id: 'present-moment',
      title: 'Present Moment Awareness',
      description: 'Anchor yourself in now',
      icon: '🎯',
      type: TechniqueType.grounding,
      durationMinutes: 3,
      steps: [
        'Take a comfortable position and close your eyes. Begin by noticing that you are here, right now, in this moment.',
        'Say to yourself: "Right now, I am sitting. Right now, I am breathing. Right now, I am safe."',
        'Notice any thoughts about the past or future, and gently return to "right now."',
        'Feel your body in this present moment. Notice the weight, temperature, and sensations of being here now.',
        'Listen to the sounds that exist right now. Not thinking about them, just hearing them as they are.',
        'Rest in the simplicity of this moment. There is nowhere else you need to be right now.',
      ],
    ),

    // BREATHING TECHNIQUES
    CalmTechnique(
      id: 'deep-breathing',
      title: 'Deep Belly Breathing',
      description: 'Slow, deep breaths to activate calm',
      icon: '🫁',
      type: TechniqueType.breathing,
      durationMinutes: 4,
      steps: [
        'Place one hand on your chest and one on your belly. We\'re going to breathe in a way that moves the bottom hand more than the top.',
        'Breathe in slowly through your nose for 4 counts, letting your belly expand like a balloon. The hand on your chest should barely move.',
        'Hold this breath gently for 2 counts. Don\'t strain - just pause naturally.',
        'Exhale slowly through your mouth for 6 counts, letting your belly fall as the air leaves your body.',
        'Continue this pattern: In for 4, hold for 2, out for 6. Let each breath be smooth and natural.',
        'If you feel lightheaded, return to normal breathing. Otherwise, continue for several more cycles.',
        'Notice how your body feels more relaxed with each breath. This is your natural relaxation response activating.',
      ],
    ),
    CalmTechnique(
      id: 'alternate-nostril',
      title: 'Alternate Nostril Breathing',
      description: 'Balance your nervous system',
      icon: '🌬️',
      type: TechniqueType.breathing,
      durationMinutes: 5,
      steps: [
        'Sit comfortably with your spine straight. Use your right thumb to gently close your right nostril.',
        'Inhale slowly and deeply through your left nostril for 4 counts.',
        'Use your ring finger to close your left nostril, then release your thumb from the right nostril.',
        'Exhale slowly through your right nostril for 4 counts.',
        'Inhale through your right nostril for 4 counts.',
        'Close your right nostril with your thumb, release your left nostril, and exhale through the left for 4 counts.',
        'This completes one cycle. Continue for several more cycles, maintaining a steady, comfortable rhythm.',
        'End by breathing normally through both nostrils and notice the sense of balance and calm.',
      ],
    ),

    // AFFIRMATION TECHNIQUES
    CalmTechnique(
      id: 'positive-affirmations',
      title: 'Calming Affirmations',
      description: 'Positive self-talk for peace',
      icon: '💬',
      type: TechniqueType.affirmation,
      durationMinutes: 2,
      content: [
        'I am safe. I am calm. I am at peace.',
        'This feeling is temporary. It will pass.',
        'I trust myself to handle whatever comes.',
        'I release what I cannot control.',
        'I breathe in peace, I breathe out tension.',
        'I am doing the best I can, and that is enough.',
        'I deserve rest and relaxation.',
        'One step at a time, one breath at a time.',
        'I am stronger than my anxiety.',
        'I choose peace over worry.',
        'My mind is calm, my body is relaxed.',
        'I am grounded in the present moment.',
        'I let go of what no longer serves me.',
        'I am worthy of love and kindness.',
        'Everything I need is within me.',
      ],
    ),
    CalmTechnique(
      id: 'self-compassion',
      title: 'Self-Compassion Practice',
      description: 'Treat yourself with kindness',
      icon: '🤗',
      type: TechniqueType.affirmation,
      durationMinutes: 4,
      content: [
        'I acknowledge that I am struggling right now, and that\'s okay.',
        'Difficulty and pain are part of the human experience.',
        'I am not alone in feeling this way.',
        'May I be kind to myself in this moment.',
        'May I give myself the compassion I need.',
        'May I be strong and patient with myself.',
        'I forgive myself for any mistakes I\'ve made.',
        'I am learning and growing every day.',
        'I treat myself with the same kindness I would show a good friend.',
        'I am worthy of love and understanding, especially from myself.',
      ],
    ),
    CalmTechnique(
      id: 'gratitude-affirmations',
      title: 'Gratitude Practice',
      description: 'Focus on what you appreciate',
      icon: '🙏',
      type: TechniqueType.affirmation,
      durationMinutes: 3,
      content: [
        'I am grateful for this moment of peace.',
        'I appreciate my body for carrying me through each day.',
        'I am thankful for the breath that sustains me.',
        'I appreciate the people who care about me.',
        'I am grateful for the lessons I\'ve learned.',
        'I appreciate having a safe place to rest.',
        'I am thankful for my ability to feel and heal.',
        'I appreciate the small joys in my daily life.',
        'I am grateful for my resilience and strength.',
        'I appreciate this opportunity to care for myself.',
      ],
    ),
    CalmTechnique(
      id: 'loving-kindness',
      title: 'Loving-Kindness Practice',
      description: 'Send compassion to yourself and others',
      icon: '💝',
      type: TechniqueType.affirmation,
      durationMinutes: 6,
      steps: [
        'Begin by focusing on yourself. Place your hand on your heart and repeat: "May I be happy. May I be healthy. May I be at peace."',
        'Really feel the intention behind these words. You are offering yourself genuine kindness and care.',
        'Now bring to mind someone you love easily. Send them the same wishes: "May you be happy. May you be healthy. May you be at peace."',
        'Think of a neutral person - someone you neither particularly like nor dislike. Offer them the same loving wishes.',
        'If you feel ready, bring to mind someone you have difficulty with. Try to send them these same wishes, even if it feels challenging.',
        'Finally, expand your circle to include all beings everywhere: "May all beings be happy. May all beings be healthy. May all beings be at peace."',
        'Return to yourself and notice how this practice has affected your heart and mind.',
      ],
    ),

    // VISUALIZATION TECHNIQUES
    CalmTechnique(
      id: 'cold-water-visualization',
      title: 'Cold Water Reset',
      description: 'Visualize calming cold sensation',
      icon: '❄️',
      type: TechniqueType.visualization,
      durationMinutes: 2,
      steps: [
        'Welcome. This is a cold water visualization — a powerful technique that uses your imagination to activate your body\'s calming reflex. You do not need any water. Find a comfortable position, close your eyes, and take one slow breath in through your nose, and out through your mouth. Let your hands rest open on your lap. We are going to begin.',
        'In your mind, picture a wide, clear bowl filled with cold, pure water. You can see it shimmering in front of you. The surface is still except for a gentle ripple. You can feel the coolness radiating from it. Take a moment to really see it. Notice the clarity of the water, the way the light shines through it.',
        'Now, slowly and deliberately, you imagine lowering your hands into the water. Feel the cool temperature rush over your fingers and palms. The cold is immediate and clear — not painful, just intensely present. It pulls every bit of your attention to this single sensation. Notice how your mind has completely shifted, away from thoughts, into the feeling of cold.',
        'Let the coolness spread through your hands. Feel it moving up your wrists, into your forearms, releasing tension as it travels. Each part it touches softens and relaxes. With the cold comes a feeling of clarity, like waking up on a fresh morning. Your thoughts grow quieter as the sensation holds your full attention.',
        'Now notice how the cold sensation is washing something away. Picture any stress, anxiety, or tension leaving through your fingertips and dissolving into the water. The water accepts it all and neutralises it. As the tension flows out of you, the water does not hold it — it simply lets it disappear. You are becoming cleaner, lighter, and calmer.',
        'Begin to slowly lift your hands out of the water. As you do, feel the cool freshness remaining on your skin. The sensation is fading, but the calm it brought stays with you. Your hands are dry, your mind is clear. Take a slow breath in, feeling the fresh cool air fill your lungs.',
        'Take three slow, deliberate breaths now. Breathe in the calmness and breathe out anything that was weighing on you. In... and out. In... and out. One final breath in... and a complete, full exhale. When you are ready, gently open your eyes. You are reset. You are calm. You can return to this practice any time you feel overwhelmed.',
      ],
    ),
    CalmTechnique(
      id: 'safe-place-visualization',
      title: 'Safe Place Journey',
      description: 'Visit your inner sanctuary',
      icon: '🏞️',
      type: TechniqueType.visualization,
      durationMinutes: 6,
      steps: [
        'Close your eyes and take three deep breaths. With each exhale, let yourself settle more deeply into relaxation.',
        'Imagine yourself in a place where you feel completely safe and peaceful. This might be a real place you\'ve been, or somewhere entirely from your imagination.',
        'Look around this safe place. What do you see? Notice the colors, the light, the surroundings. Take time to really see this place clearly.',
        'What sounds do you hear in your safe place? Perhaps gentle water, wind in trees, or peaceful silence. Let these sounds surround you.',
        'Notice what you can feel in this place. The temperature, textures, perhaps a gentle breeze. Feel how supported and comfortable you are here.',
        'Are there any scents in your safe place? Fresh air, flowers, or something else that brings you peace? Breathe it in deeply.',
        'Spend a few moments simply being in this place. Feel the deep sense of safety and calm it provides. Know that you can return here anytime.',
        'When you\'re ready, take three deep breaths and slowly open your eyes, bringing the feeling of safety with you.',
      ],
    ),
    CalmTechnique(
      id: 'light-visualization',
      title: 'Healing Light Meditation',
      description: 'Visualize warm, healing energy',
      icon: '✨',
      type: TechniqueType.visualization,
      durationMinutes: 5,
      steps: [
        'Sit or lie comfortably and close your eyes. Take several deep breaths to center yourself.',
        'Imagine a warm, golden light above your head. This light represents healing, peace, and love.',
        'See this light slowly descending, entering through the top of your head. Feel its warmth and comfort.',
        'Let the light flow down through your head, relaxing your mind and releasing any mental tension.',
        'Feel the light moving into your neck and shoulders, melting away any stress or tightness.',
        'Allow the light to continue down through your arms, chest, and torso, bringing healing energy to every part.',
        'Let the light flow into your hips, legs, and feet, until your entire body is filled with this warm, healing glow.',
        'Rest in this feeling of being completely filled with peaceful, healing light. You are safe, loved, and whole.',
        'When ready, take three deep breaths and slowly open your eyes, carrying this light with you.',
      ],
    ),
    CalmTechnique(
      id: 'mountain-meditation',
      title: 'Mountain Strength Visualization',
      description: 'Find your inner stability',
      icon: '⛰️',
      type: TechniqueType.visualization,
      durationMinutes: 4,
      steps: [
        'Sit with your spine straight and imagine yourself as a majestic mountain. Feel your base rooted firmly in the earth.',
        'Your mountain body is strong and stable. Weather may come and go around you, but you remain unmoved.',
        'Feel the solid rock of your foundation. Nothing can shake your essential stability and strength.',
        'Clouds of thoughts and emotions may pass around your peak, but they don\'t disturb your mountain nature.',
        'Whether it\'s the storm of anxiety or the fog of confusion, you remain steady and grounded.',
        'Feel the timeless quality of your mountain self. You have weathered countless storms and remained standing.',
        'Rest in this sense of unshakeable stability and strength. This mountain nature is always within you.',
      ],
    ),
  ];

  // Get techniques by type
  static List<CalmTechnique> getByType(TechniqueType type) {
    return defaults.where((t) => t.type == type).toList();
  }

  /// Get motive-specific description for this technique
  String getMotiveDescription(String? motive) {
    if (motiveSpecificDescriptions != null && motive != null) {
      return motiveSpecificDescriptions![motive] ?? description;
    }

    // Fallback to static data
    final descriptions = MotiveTechniqueData.descriptions[id];
    if (descriptions != null && motive != null) {
      return descriptions[motive] ?? description;
    }

    return description;
  }

  /// Get motive-specific benefits for this technique
  List<String> getMotiveBenefits(String? motive) {
    if (motiveSpecificBenefits != null && motive != null) {
      return motiveSpecificBenefits![motive] ?? [];
    }

    // Fallback to static data
    final benefits = MotiveTechniqueData.benefits[id];
    if (benefits != null && motive != null) {
      return benefits[motive] ?? [];
    }

    return [];
  }

  /// Check if this technique is primary for the given motive
  bool isPrimaryForMotive(String? motive) {
    if (primaryMotives != null) {
      return primaryMotives!.contains(motive);
    }

    // Fallback to static data
    final primaries = MotiveTechniqueData.primaryMotives[id];
    return primaries?.contains(motive) ?? false;
  }

  /// Check if this technique is secondary for the given motive
  bool isSecondaryForMotive(String? motive) {
    if (secondaryMotives != null) {
      return secondaryMotives!.contains(motive);
    }

    // Fallback to static data
    final secondaries = MotiveTechniqueData.secondaryMotives[id];
    return secondaries?.contains(motive) ?? false;
  }

  /// Check if this technique is relevant for the given motive
  bool isRelevantForMotive(String? motive) {
    return isPrimaryForMotive(motive) || isSecondaryForMotive(motive);
  }

  /// Get priority score for motive (higher = more relevant)
  int getMotivePriorityScore(String? motive) {
    if (isPrimaryForMotive(motive)) return 3;
    if (isSecondaryForMotive(motive)) return 2;
    return 1; // All techniques are accessible
  }

  /// Get techniques prioritized by motive
  static List<CalmTechnique> getMotivePrioritized(String? motive) {
    final techniques = List<CalmTechnique>.from(defaults);

    // Sort by priority score (descending) then by type
    techniques.sort((a, b) {
      final scoreA = a.getMotivePriorityScore(motive);
      final scoreB = b.getMotivePriorityScore(motive);

      if (scoreA != scoreB) {
        return scoreB.compareTo(scoreA); // Higher score first
      }

      // Secondary sort by type order
      final typeOrder = [
        TechniqueType.grounding,
        TechniqueType.breathing,
        TechniqueType.visualization,
        TechniqueType.affirmation,
      ];

      return typeOrder.indexOf(a.type).compareTo(typeOrder.indexOf(b.type));
    });

    return techniques;
  }

  /// Get techniques filtered by motive relevance
  static List<CalmTechnique> getMotiveFiltered(
    String? motive, {
    bool primaryOnly = false,
  }) {
    if (motive == null) return defaults;

    return defaults.where((technique) {
      if (primaryOnly) {
        return technique.isPrimaryForMotive(motive);
      }
      return technique.isRelevantForMotive(motive);
    }).toList();
  }

  /// Get techniques by category for motive
  static Map<TechniqueType, List<CalmTechnique>> getMotiveCategorized(
    String? motive,
  ) {
    final prioritized = getMotivePrioritized(motive);
    final categorized = <TechniqueType, List<CalmTechnique>>{};

    for (final type in TechniqueType.values) {
      categorized[type] = prioritized.where((t) => t.type == type).toList();
    }

    return categorized;
  }

  /// Get emergency techniques for quick access (fastest, most effective)
  static List<CalmTechnique> getEmergencyTechniques(String? motive) {
    final emergency = defaults.where((technique) {
      // Quick techniques (5 minutes or less) that are primary for the motive
      return technique.durationMinutes <= 5 &&
          (technique.isPrimaryForMotive(motive) ||
              technique.id == '5-4-3-2-1' || // Always include grounding
              technique.id == 'deep-breathing' || // Always include breathing
              technique.id ==
                  'cold-water-visualization'); // Always include reset
    }).toList();

    // Sort by motive priority
    emergency.sort(
      (a, b) => b
          .getMotivePriorityScore(motive)
          .compareTo(a.getMotivePriorityScore(motive)),
    );

    return emergency.take(4).toList(); // Limit to 4 for quick access
  }
}
