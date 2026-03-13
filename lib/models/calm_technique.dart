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

  const CalmTechnique({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.type,
    this.durationMinutes = 5,
    this.steps,
    this.content,
  });

  // Predefined calm techniques
  static const List<CalmTechnique> defaults = [
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
  ];

  // Get techniques by type
  static List<CalmTechnique> getByType(TechniqueType type) {
    return defaults.where((t) => t.type == type).toList();
  }
}
