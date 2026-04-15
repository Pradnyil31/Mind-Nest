/// Centralized configuration for routine activities and their default time periods.
class RoutineConfig {
  static const Map<String, List<String>> _activitiesByPeriod = {
    'Morning': [
      // Hydration & Nutrition
      'Drink 500ml Water', 'Drink water', 'Healthy eating', 'Healthy Breakfast',

      // Light & Environment
      'Morning Sunlight', 'Morning sunlight exposure', 'Make Bed', 'Open curtains',
      // Workspace prep belongs at the start of the day
      'Clear my workspace',

      // Movement
      'Stretch', 'Physical activity', 'Gentle movement', 'Movement reminder',
      '5-min micro-exercise', 'Yoga', 'Exercise',

      // Mindfulness & Mental State
      'Meditation', 'Morning mindfulness', 'Morning intention setting',
      'Morning check-in', 'Body appreciation meditation', 'Present moment meditation',
      'Positive affirmations', 'Start the day slowly', 'Smile more',

      // Habits & Planning
      'Delay Caffeine', 'Wake routine checklist', 'Screen-free morning hour',
      'Daily anchor habit', 'Stick to the plan', 'Morning routine',
      'Habit stacking practice', 'Small steps today',
      'Task prioritization', 'Review goals', 'Visualizing the day',
    ],
    'Afternoon': [
      // Nutrition & Energy
      'Healthy Lunch', 'Mindful eating moment', 'Eat a healthy snack',

      // Movement & Breaks — including outdoor/nature activities
      'Walk', 'Walk in nature', 'Nature time',
      'Deep breathing breaks', 'Breathing breaks', 'Midday breathing break',
      'Movement break', 'Physical movement', 'Power Nap',

      // Focus & Work
      'Deep Work', 'Focus sessions (Pomodoro)', 'Deep work block',
      'Single-task focus session', 'Phone-free focus block', 'Single-tasking today',
      'Single-task commitment',
      'Energy management', 'Energy mapping',

      // Mental State
      'Mindfulness', 'Check-in', 'Stress check-in', 'Anxiety check-in',
      'Consistency check-in', 'Values check-in',
      'Mindful breathing', 'Mindful breaks',
      'Grounding exercises', 'Pre-social grounding exercise', 'Emergency calm toolkit',
      '4-7-8 breathing', 'Self-compassion practice',

      // Self-care / recharge during the day
      'Self-care moment',

      // Digital boundaries (during active hours)
      'Digital detox periods',

      // Social & Connection
      'Connect with a friend', 'Social connection', 'Speak up today',

      // Caffeine Control
      'Cut Caffeine', 'Caffeine cutoff (2pm)',
    ],
    'Evening': [
      // Environment
      'Dim Lights', 'Bedroom environment check', 'No Screens', 'Evening digital sunset',
      'Limit screens 1hr before bed', 'Digital detox', 'Digital detox time',
      'Digital detox hour',

      // Relaxation
      'Read Fiction', 'Read a calming book', 'Herbal Tea', 'Herbal tea ritual',
      'Relax', 'Relaxing breathing', 'Creative activity',
      'Listen to music', 'White noise session',

      // Reflection & Journaling
      'Journaling', 'Gratitude journaling', 'Evening reflection', 'Reflection journaling',
      'Worry journaling', 'Brain dump journaling', 'Achievement journaling',
      'What I can control journaling', 'Find one joy', 'Celebrate small wins',
      'Celebration moments', 'Evening review', 'Progress review',
      'Write it down', 'Let go of what-ifs', 'Daily habit tracking',

      // Planning
      'Plan tomorrow', 'Prepare for tomorrow',

      // Sleep Preparation
      'Early Bedtime', 'Consistent bedtime reminder', 'Sleep preparation',
      'Sleep by 10 PM', 'No screens after 9 PM', 'Consistent sleep schedule',
      'Evening wind-down ritual', 'Evening routine',

      // Meditation
      'Sleep meditation', 'Body scan', 'Scan body', 'Body scan meditation',
      'Progressive muscle relaxation', 'Safe space meditation', 'Empathy meditation',
      'Focus on the present', 'Clarity meditation', 'Concentration meditation',
    ]
  };

  /// Returns all known activities for a given period ('Morning'/'Afternoon'/'Evening').
  static List<String> getActivitiesForPeriod(String period) {
    return List<String>.from(_activitiesByPeriod[period] ?? []);
  }

  /// Returns every known activity across all periods.
  static List<String> getAllActivities() {
    return _activitiesByPeriod.values.expand((list) => list).toList();
  }

  /// Get the time period for a specific activity.
  /// Returns 'Morning', 'Afternoon', or 'Evening'.
  static String getTimePeriod(String activity) {
    // 1. Check strict mapping
    for (var entry in _activitiesByPeriod.entries) {
      if (entry.value.contains(activity)) {
        return entry.key;
      }
    }
    
    // 2. Heuristic fallback (Case insensitive)
    final lower = activity.toLowerCase();

    // Morning signals
    if (lower.contains('morning') || lower.contains('wake') || lower.contains('start') ||
        lower.contains('sunlight') || lower.contains('sunrise') ||
        lower.contains('affirmation') || lower.contains('intention')) {
      return 'Morning';
    }

    // Evening / sleep signals
    if (lower.contains('evening') || lower.contains('night') || lower.contains('sleep') ||
        lower.contains('bed') || lower.contains('wind down') || lower.contains('wind-down')) {
      return 'Evening';
    }

    // Evening journaling / reflection
    if (lower.contains('journal') || lower.contains('reflect')) {
      return 'Evening';
    }

    // Afternoon / daytime signals
    if (lower.contains('lunch') || lower.contains('noon') || lower.contains('afternoon') ||
        lower.contains('focus') || lower.contains('work') || lower.contains('break') ||
        lower.contains('detox') || lower.contains('social') || lower.contains('connect') ||
        lower.contains('nature') || lower.contains('walk') || lower.contains('review')) {
      return 'Afternoon';
    }

    // 3. Ultimate fallback — default to Morning
    return 'Morning';
  }

  // ── Optimal Time Slots ──────────────────────────────────────────────────
  //
  // Each entry is: { activity → minutes offset from period anchor }
  //   Morning  anchor = wakeTime
  //   Afternoon anchor = 12:00 PM  (or wake + 5 h, whichever is later)
  //   Evening  anchor = bedTime - 120 min  (the 2-hour wind-down window)
  //
  // Science-backed defaults (overridable per-activity):
  //   • Sunlight & hydration → immediately after wake (+0-15 min)
  //   • Light movement/yoga → +30 min after wake
  //   • Meditation/affirmation → +45 min after wake (cortisol has peaked)
  //   • Deep work → +90-120 min after wake (peak alertness)
  //   • Caffeine delay → +90 min after wake (cortisol drop)
  //   • Lunch → +60 min into afternoon window
  //   • Exercise/walk → +90 min into afternoon (energy trough rebound)
  //   • Power nap → +120 min into afternoon
  //   • Deep Work (PM) → +30 min into afternoon
  //   • Evening wind-down → anchor (bed - 120 min)
  //   • Journaling/reflection → anchor + 30 min
  //   • Sleep prep → anchor + 60 min
  //   • Meditation before sleep → anchor + 75 min
  //
  static const Map<String, int> _morningOffsets = {
    // Hydration & light — do first
    'Drink 500ml Water'         : 0,
    'Drink water'               : 0,
    'Open curtains'             : 0,
    'Morning Sunlight'          : 5,
    'Morning sunlight exposure' : 5,

    // Make bed / tidy up
    'Make Bed'                  : 15,
    'Clear my workspace'        : 20,

    // Movement
    'Stretch'                   : 25,
    '5-min micro-exercise'      : 25,
    'Gentle movement'           : 30,
    'Yoga'                      : 30,
    'Physical activity'         : 35,
    'Exercise'                  : 35,
    'Movement reminder'         : 40,

    // Breakfast
    'Healthy Breakfast'         : 40,
    'Healthy eating'            : 40,

    // Mindfulness / planning — cortisol subsides ~45-60 min after wake
    'Morning mindfulness'       : 50,
    'Meditation'                : 55,
    'Morning check-in'          : 50,
    'Body appreciation meditation': 55,
    'Present moment meditation' : 55,
    'Morning intention setting' : 60,
    'Positive affirmations'     : 60,
    'Visualizing the day'       : 65,
    'Start the day slowly'      : 65,
    'Smile more'                : 10,
    'Morning routine'           : 15,

    // Planning
    'Task prioritization'       : 70,
    'Review goals'              : 70,
    'Stick to the plan'         : 70,
    'Small steps today'         : 75,
    'Wake routine checklist'    : 5,
    'Screen-free morning hour'  : 0,
    'Daily anchor habit'        : 30,

    // Caffeine — delay 90 min to avoid cortisol clash
    'Delay Caffeine'            : 90,
  };

  static const Map<String, int> _afternoonOffsets = {
    // Lunch first
    'Healthy Lunch'             : 60,  // Noon + 1 h = 1 PM
    'Mindful eating moment'     : 60,
    'Eat a healthy snack'       : 150, // ~3 PM

    // Focus & deep work — early afternoon peak (post-lunch glucose)
    'Deep Work'                 : 30,  // ~12:30 PM
    'Deep work block'           : 30,
    'Single-task focus session' : 30,
    'Focus sessions (Pomodoro)' : 45,
    'Phone-free focus block'    : 45,
    'Single-tasking today'      : 45,
    'Single-task commitment'    : 45,
    'Energy management'         : 15,
    'Energy mapping'            : 15,

    // Breaks / movement
    'Movement break'            : 90,  // ~1:30 PM
    'Physical movement'         : 90,
    'Deep breathing breaks'     : 90,
    'Midday breathing break'    : 90,
    'Walk'                      : 120, // ~2 PM
    'Walk in nature'            : 120,
    'Nature time'               : 120,

    // Power nap — post-lunch trough 1-3 PM
    'Power Nap'                 : 90,  // ~1:30 PM

    // Mental state checks
    'Mindfulness'               : 60,
    'Check-in'                  : 60,
    'Stress check-in'           : 60,
    'Anxiety check-in'          : 60,
    'Consistency check-in'      : 60,
    'Values check-in'           : 60,
    'Mindful breathing'         : 90,
    'Mindful breaks'            : 90,
    'Grounding exercises'       : 90,
    'Pre-social grounding exercise': 90,
    'Emergency calm toolkit'    : 60,
    '4-7-8 breathing'           : 90,
    'Self-compassion practice'  : 90,
    'Self-care moment'          : 120,

    // Social & digital
    'Connect with a friend'     : 150, // ~3 PM
    'Social connection'         : 150,
    'Speak up today'            : 60,
    'Digital detox periods'     : 180, // ~4 PM quiet time

    // Caffeine cutoff
    'Cut Caffeine'              : 120, // 2 PM
    'Caffeine cutoff (2pm)'     : 120,
  };

  static const Map<String, int> _eveningOffsets = {
    // Offset from (bedTime - 120 min)  →  0 = 2 h before bed

    // Light & screen controls — start of wind-down
    'Dim Lights'                        : 0,
    'No Screens'                        : 0,
    'Evening digital sunset'            : 0,
    'Digital detox'                     : 0,
    'Digital detox time'                : 0,
    'Digital detox hour'                : 0,
    'Limit screens 1hr before bed'      : 60,  // 1 h before bed

    // Relaxation — early wind-down
    'Herbal Tea'                        : 10,
    'Herbal tea ritual'                 : 10,
    'Relax'                             : 20,
    'Listen to music'                   : 20,
    'White noise session'               : 100, // right before sleep
    'Read Fiction'                      : 30,
    'Read a calming book'               : 30,
    'Relaxing breathing'                : 45,
    'Creative activity'                 : 30,

    // Reflection & journaling
    'Gratitude journaling'              : 30,
    'Journaling'                        : 30,
    'Evening reflection'                : 35,
    'Reflection journaling'             : 35,
    'Worry journaling'                  : 35,
    'Brain dump journaling'             : 35,
    'Achievement journaling'            : 40,
    'What I can control journaling'     : 40,
    'Find one joy'                      : 40,
    'Celebrate small wins'              : 40,
    'Write it down'                     : 35,
    'Let go of what-ifs'                : 40,
    'Daily habit tracking'              : 30,
    'Consistency check-in'             : 30,
    'Progress review'                   : 30,
    'Celebration moments'               : 40,

    // Planning next day
    'Plan tomorrow'                     : 50,
    'Prepare for tomorrow'              : 50,
    'Evening review'                    : 50,

    // Sleep preparation
    'Evening wind-down ritual'          : 60,
    'Evening routine'                   : 60,
    'Sleep preparation'                 : 75,
    'Consistent sleep schedule'         : 0,
    'Consistent bedtime reminder'       : 0,
    'Early Bedtime'                     : 0,
    'Sleep by 10 PM'                    : 0,
    'No screens after 9 PM'             : 60,
    'Bedroom environment check'         : 60,

    // Body relaxation
    'Progressive muscle relaxation'     : 80,
    'Body scan'                         : 90,
    'Scan body'                         : 90,
    'Body scan meditation'              : 90,

    // Sleep meditation — very close to bed
    'Sleep meditation'                  : 100,
    'Empathy meditation'                : 85,
    'Safe space meditation'             : 85,
    'Clarity meditation'                : 85,
    'Focus on the present'              : 85,
    'Concentration meditation'          : 85,
  };

  /// Returns the best clock-time string (e.g. "7:30 AM") for an activity.
  ///
  /// [wakeHour] / [wakeMinute] — user's wake-up time (24h)
  /// [bedHour]  / [bedMinute]  — user's bed time (24h)
  /// [periodOverride] — if provided, forces the given period ('Morning',
  ///   'Afternoon', or 'Evening') instead of looking it up from RoutineConfig.
  ///   Use this when the user has moved an activity to a different period.
  ///
  /// Falls back to sensible period defaults if the activity is not in the map.
  static String getOptimalTimeSlot(
    String activity, {
    int wakeHour = 7,
    int wakeMinute = 0,
    int bedHour = 22,
    int bedMinute = 0,
    String? periodOverride,
  }) {
    final wakeMin = wakeHour * 60 + wakeMinute;
    final bedTotalMin = bedHour * 60 + bedMinute;
    // Afternoon anchor: 12:00 PM or wake+5h, whichever is later
    final afternoonAnchor = (12 * 60) < (wakeMin + 5 * 60)
        ? wakeMin + 5 * 60
        : 12 * 60;
    // Evening anchor: bed - 120 min
    final eveningAnchor = bedTotalMin - 120;

    // Use the caller-supplied period override if given; otherwise look it up.
    final period = periodOverride ?? getTimePeriod(activity);

    int totalMinutes;
    if (period == 'Morning') {
      final offset = _morningOffsets[activity] ?? 30;
      totalMinutes = wakeMin + offset;
    } else if (period == 'Afternoon') {
      final offset = _afternoonOffsets[activity] ?? 60;
      totalMinutes = afternoonAnchor + offset;
    } else {
      // Evening
      final offset = _eveningOffsets[activity] ?? 30;
      totalMinutes = eveningAnchor + offset;
    }

    // Clamp to 24 h
    totalMinutes = totalMinutes % (24 * 60);

    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    final period12 = h >= 12 ? 'PM' : 'AM';
    final h12 = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '$h12:${m.toString().padLeft(2, '0')} $period12';
  }

  /// Task descriptions: what each activity means and how to do it.
  static const Map<String, Map<String, String>> taskDescriptions = {
    // Morning
    'Morning mindfulness': {
      'description': 'A short mindfulness practice at the start of your day to set a calm, focused tone before the busyness begins.',
      'howTo': '1. Find a quiet spot and sit comfortably.\n2. Close your eyes and take 5 slow, deep breaths.\n3. Notice sounds, sensations, and thoughts without judging them.\n4. Set a simple intention for the day (e.g., "I will be patient today").\n5. Open your eyes and begin your day slowly.',
    },
    'Morning intention setting': {
      'description': 'Deciding on one clear purpose or theme for your day so you stay focused and avoid drifting.',
      'howTo': '1. After waking, grab a journal or open your notes app.\n2. Write one sentence: "Today I want to..."\n3. Pick one task that would make the day feel successful.\n4. Read it again before starting work.\n5. Return to it if you feel distracted.',
    },
    'Morning routine': {
      'description': 'A consistent sequence of simple actions each morning that signals to your brain it\'s time to engage with the day.',
      'howTo': '1. Wake at the same time daily.\n2. Drink a glass of water immediately.\n3. Do 5 minutes of light movement (stretching or a short walk).\n4. Avoid your phone for the first 20 minutes.\n5. Eat breakfast mindfully.',
    },
    'Physical activity': {
      'description': 'Any form of movement that gets your heart rate up — proven to reduce stress hormones and boost mood.',
      'howTo': '1. Choose an activity you enjoy: walking, cycling, dancing, gym.\n2. Aim for at least 20–30 minutes.\n3. Warm up for 3–5 minutes first.\n4. Keep a moderate pace — you should be able to talk.\n5. Cool down gently at the end.',
    },
    'Gentle movement': {
      'description': 'Low-intensity movement like stretching or yoga that relieves tension without overwhelming your body.',
      'howTo': '1. Roll out a mat or find space on the floor.\n2. Do 5 minutes of full-body stretching (neck, shoulders, back, legs).\n3. Move slowly and breathe into each stretch.\n4. Try cat-cow, child\'s pose, or a light forward fold.\n5. End with a moment of stillness.',
    },
    'Positive affirmations': {
      'description': 'Short, positive statements repeated daily to challenge negative thought patterns and build self-belief.',
      'howTo': '1. Write 3 affirmations that feel meaningful to you.\n2. Examples: "I am calm and capable", "I am enough".\n3. Stand in front of a mirror if possible.\n4. Say each one slowly, 3 times, with conviction.\n5. Do this first thing in the morning for best effect.',
    },
    'Task prioritization': {
      'description': 'Organizing your to-do list so you work on the most important things first and avoid overwhelm.',
      'howTo': '1. List everything you need to do today.\n2. Mark each task: A (must do), B (should do), C (nice to do).\n3. Pick your top 3 "A" tasks.\n4. Start with the hardest or most important one.\n5. Do not move on to "B" tasks until "A" tasks are done.',
    },
    'Drink water': {
      'description': 'Staying hydrated improves concentration, energy, and mood — most people are mildly dehydrated without realising it.',
      'howTo': '1. Keep a reusable bottle visible at all times.\n2. Drink a full glass (250ml) right when you wake up.\n3. Set reminders every 2 hours if you tend to forget.\n4. Aim for 8 glasses (2 litres) spread across the day.\n5. Add lemon or cucumber for variety if plain water is boring.',
    },
    'Healthy eating': {
      'description': 'Choosing nutritious foods that fuel your body and stabilise your mood and energy throughout the day.',
      'howTo': '1. Plan your meals the night before.\n2. Include protein, complex carbs, and vegetables in each meal.\n3. Avoid skipping breakfast.\n4. Eat slowly and without screens.\n5. Swap one processed snack for fruit, nuts, or yoghurt.',
    },
    'Exercise': {
      'description': 'Structured physical exertion that builds strength, endurance, and mental resilience over time.',
      'howTo': '1. Pick a type: running, weights, HIIT, swimming, etc.\n2. Set a fixed time slot each day (consistency beats intensity).\n3. Start with 20–30 minutes if you\'re a beginner.\n4. Track your sessions to stay motivated.\n5. Rest one or two days per week for recovery.',
    },
    // Stress
    'Stress check-in': {
      'description': 'A brief pause to notice your stress level and identify what\'s causing it before it escalates.',
      'howTo': '1. Set a daily reminder (e.g., 2 PM).\n2. Rate your stress from 1–10.\n3. Ask: "What is stressing me right now?"\n4. Write it down — don\'t keep it in your head.\n5. Choose one small action to address it.',
    },
    'Breathing breaks': {
      'description': 'Short pauses during the day to slow your breathing, which directly calms your nervous system.',
      'howTo': '1. Set 2–3 "breathing break" reminders per day.\n2. Stop what you\'re doing and close your eyes.\n3. Breathe in for 4 counts, hold for 4, out for 6.\n4. Repeat 5 times.\n5. Resume work feeling calmer.',
    },
    'Gratitude journaling': {
      'description': 'Writing down things you\'re grateful for shifts your brain\'s focus from problems to positives.',
      'howTo': '1. Open a notebook or journaling app.\n2. Write 3 specific things you\'re grateful for today.\n3. Be detailed — "I\'m grateful for my morning coffee because..." works better than just "coffee".\n4. Include at least one small thing (a sunny moment, a kind word).\n5. Do this at the same time each day.',
    },
    'Evening reflection': {
      'description': 'A nightly review of your day to celebrate wins, learn from challenges, and prepare for tomorrow.',
      'howTo': '1. Before bed, sit quietly for 5 minutes.\n2. Ask: "What went well today?"\n3. Ask: "What could I do differently tomorrow?"\n4. Write a sentence or two in a journal.\n5. End by listing one thing you\'re proud of.',
    },
    'Digital detox time': {
      'description': 'A deliberate period away from screens to let your mind rest and reduce information overload.',
      'howTo': '1. Choose a 1–2 hour window each day.\n2. Put your phone on Do Not Disturb or in another room.\n3. Do an offline activity: read, cook, walk, draw.\n4. Resist the urge to "just check" notifications.\n5. Gradually extend the time as it becomes easier.',
    },
    'Self-care moment': {
      'description': 'Setting aside time for an activity that genuinely restores your energy and makes you feel good.',
      'howTo': '1. Choose something just for you — bath, music, a walk, a good book.\n2. Schedule it like a meeting — block the time.\n3. Remove distractions during this time.\n4. Don\'t feel guilty; rest is productive.\n5. Notice how you feel before and after.',
    },
    // Anxiety
    'Grounding exercises': {
      'description': 'Techniques that bring your attention to the present moment to interrupt spiralling anxious thoughts.',
      'howTo': '1. Use the 5-4-3-2-1 method.\n2. Name 5 things you can see.\n3. Name 4 things you can touch.\n4. Name 3 things you can hear.\n5. Name 2 things you can smell and 1 you can taste.',
    },
    'Worry journaling': {
      'description': 'Writing worries down to externalise them from your mind and examine them more objectively.',
      'howTo': '1. Set a 10-minute "worry time" each day.\n2. Write down everything you\'re worried about.\n3. For each worry, ask: "Is this in my control?"\n4. If yes — write one action step. If no — write "let go".\n5. Close the journal and move on — the worry time is done.',
    },
    'Mindful breathing': {
      'description': 'Focusing attention on your breath to anchor yourself in the present and reduce anxiety.',
      'howTo': '1. Sit comfortably and close your eyes.\n2. Breathe naturally without forcing it.\n3. Focus only on the physical sensation of air entering and leaving.\n4. When your mind wanders, gently return focus to the breath.\n5. Do this for 5–10 minutes.',
    },
    'Safe space meditation': {
      'description': 'A visualisation technique where you imagine a peaceful place to calm your nervous system.',
      'howTo': '1. Sit or lie down in a quiet place.\n2. Close your eyes and take 3 deep breaths.\n3. Visualise a place where you feel completely safe (real or imagined).\n4. Add details — what do you see, hear, smell, feel there?\n5. Stay in this mental space for 5–10 minutes.',
    },
    'Anxiety check-in': {
      'description': 'A scheduled moment to acknowledge anxiety rather than suppress it, which paradoxically reduces its intensity.',
      'howTo': '1. Set one daily alarm labelled "Anxiety Check-in".\n2. When it goes off, rate your anxiety 1–10.\n3. Write what\'s on your mind without filtering.\n4. Do a 1-minute breathing exercise.\n5. Proceed with your day.',
    },
    'Self-compassion practice': {
      'description': 'Treating yourself with the same kindness you\'d offer a good friend when you\'re struggling or making mistakes.',
      'howTo': '1. Notice when you\'re being self-critical.\n2. Pause and place a hand on your heart.\n3. Say to yourself: "This is a moment of difficulty. It\'s okay to struggle."\n4. Ask: "What would I say to a friend in this situation?"\n5. Say that to yourself instead.',
    },
    // Focus & Habit
    'Focus sessions (Pomodoro)': {
      'description': 'A time management method that breaks work into 25-minute focused sessions separated by short breaks.',
      'howTo': '1. Choose one task to focus on.\n2. Set a timer for 25 minutes.\n3. Work only on that task until the timer rings.\n4. Take a 5-minute break (stand, stretch, water).\n5. After 4 sessions, take a 20–30 minute break.',
    },
    'Daily habit tracking': {
      'description': 'Recording whether you completed your daily habits to build accountability and momentum.',
      'howTo': '1. List your 3–5 core habits to track.\n2. Use this app, a notebook, or a habit tracker app.\n3. Mark each habit done or missed each day.\n4. Review your streak weekly.\n5. If you miss a day, aim to never miss twice in a row.',
    },
    'Habit stacking practice': {
      'description': 'Attaching a new habit to an existing one so it becomes automatic (e.g., meditate after brushing teeth).',
      'howTo': '1. Pick a habit you want to build.\n2. Find an existing habit that already happens daily.\n3. Write: "After I [existing habit], I will [new habit]."\n4. Start with just 2 minutes for the new habit.\n5. Increase duration once it feels automatic.',
    },
    'Progress review': {
      'description': 'A weekly look back at your goals and habits to see how far you\'ve come and adjust your approach.',
      'howTo': '1. Set a weekly reminder (e.g., Sunday evening).\n2. Review what you completed this week.\n3. Celebrate wins — even small ones.\n4. Identify one thing that didn\'t work and why.\n5. Set your top priority for next week.',
    },
    'Consistency check-in': {
      'description': 'A regular check-in to assess whether you\'ve been consistent with your routines and why or why not.',
      'howTo': '1. Once a week, look at your habit streaks.\n2. Rate your consistency 1–10.\n3. Ask: "What helped me stay consistent?"\n4. Ask: "What got in the way?"\n5. Commit to one small change to improve next week.',
    },
    'Celebration moments': {
      'description': 'Intentionally acknowledging and celebrating your small wins to reinforce positive behaviour.',
      'howTo': '1. After completing a task or habit, pause for a moment.\n2. Say to yourself "I did that" — out loud if possible.\n3. Do a small physical celebration (fist pump, smile).\n4. Write the win in your journal.\n5. Share it with someone you trust.',
    },
    'Reflection journaling': {
      'description': 'Free-form writing to process thoughts, emotions, and experiences — helping you understand yourself better.',
      'howTo': '1. Set 10 minutes aside.\n2. Write freely without editing or judging.\n3. Start with a prompt: "Right now I feel..." or "Today I noticed..."\n4. Don\'t worry about grammar or structure.\n5. Re-read occasionally to spot patterns in your thinking.',
    },
    // Sleep
    'Evening wind-down ritual': {
      'description': 'A calming pre-sleep sequence that signals to your body it\'s time to wind down and prepare for rest.',
      'howTo': '1. Start 60 minutes before your target bedtime.\n2. Dim all lights in the room.\n3. Put away screens and switch to calm activities.\n4. Do light stretching or deep breathing.\n5. Read a physical book or listen to soft music.',
    },
    'Limit screens 1hr before bed': {
      'description': 'Blue light from screens suppresses melatonin — the hormone needed for sleep. Cutting it improves sleep quality.',
      'howTo': '1. Set a "Screen Off" alarm 1 hour before bedtime.\n2. When it goes off, put your phone in another room.\n3. Switch to a physical book, gentle stretching, or conversation.\n4. Enable Night Mode on devices if you absolutely need them.\n5. Use blue-light blocking glasses if avoiding screens is tough.',
    },
    'Progressive muscle relaxation': {
      'description': 'A body-scan technique where you tense and release muscle groups to release physical tension before sleep.',
      'howTo': '1. Lie down comfortably in bed.\n2. Start at your feet — tense the muscles for 5 seconds.\n3. Release and notice the relaxation for 10 seconds.\n4. Move up: calves, thighs, abdomen, chest, hands, shoulders, face.\n5. By the time you reach your face, your body should feel significantly relaxed.',
    },
    'Sleep meditation': {
      'description': 'A guided or self-directed meditation specifically designed to quiet the mind and ease you into sleep.',
      'howTo': '1. Lie in bed in your sleeping position.\n2. Close your eyes and take 5 deep, slow breaths.\n3. Focus on a calming image or simply the darkness.\n4. Count backward slowly from 100, imagining each number drifting away.\n5. Use a sleep meditation app or guided audio if self-directing is hard.',
    },
    'Consistent sleep schedule': {
      'description': 'Going to bed and waking up at the same time every day — the single most important factor for sleep quality.',
      'howTo': '1. Choose a bedtime and wake time and commit to them.\n2. Keep them the same on weekends too.\n3. Set alarms for both bedtime and wake time.\n4. Avoid naps longer than 20 minutes after 3 PM.\n5. After 2–3 weeks, your body will naturally feel tired at bedtime.',
    },
    'Caffeine cutoff (2pm)': {
      'description': 'Caffeine has a half-life of ~6 hours, meaning afternoon coffee can still be in your system at midnight, disrupting sleep.',
      'howTo': '1. Set a phone reminder for your cutoff time (usually 2 PM).\n2. Switch to herbal tea or water after that time.\n3. Watch for hidden caffeine in cola, energy drinks, and chocolate.\n4. If you\'re tired in the afternoon, try a 20-minute nap or get fresh air instead.\n5. After a few days caffeine-free in the afternoon, your sleep will noticeably improve.',
    },
    'Bedroom environment check': {
      'description': 'Optimising your sleeping environment (temperature, light, noise, comfort) for the best possible sleep quality.',
      'howTo': '1. Keep the room cool — 16–19°C is ideal for sleep.\n2. Block out light with blackout curtains or a sleep mask.\n3. Reduce noise with earplugs or white noise.\n4. Reserve your bed only for sleep (no working in bed).\n5. Check your pillow and mattress — discomfort causes micro-wakes.',
    },
    // General
    'Nature time': {
      'description': 'Spending time outdoors in natural settings reduces cortisol, lowers blood pressure, and lifts mood.',
      'howTo': '1. Step outside for at least 20 minutes.\n2. Leave earphones out — notice the sounds around you.\n3. Walk through a park, garden, or any green space.\n4. Look at the sky, trees, or water — let your eyes rest on the horizon.\n5. Don\'t check your phone during this time.',
    },
    'Social connection': {
      'description': 'Regular meaningful contact with others is one of the strongest predictors of mental wellbeing and longevity.',
      'howTo': '1. Reach out to one person today — a text, call, or visit.\n2. Be present in conversations — put your phone away.\n3. Ask a genuine question and listen carefully.\n4. Share something real about how you\'re doing.\n5. Schedule your next connection before you part ways.',
    },
    'Creative activity': {
      'description': 'Engaging in creative expression (art, music, writing, cooking) reduces stress and activates the brain\'s reward system.',
      'howTo': '1. Choose an activity: drawing, writing, playing music, knitting, cooking.\n2. Set aside 20–30 minutes.\n3. Focus on the process, not the result — there\'s no right or wrong.\n4. Turn off distractions.\n5. The goal is enjoyment, not perfection.',
    },
    'Digital detox periods': {
      'description': 'Scheduled offline times during the day to reduce information overload, anxiety, and compulsive phone checking.',
      'howTo': '1. Identify 2–3 time slots to go phone-free (meals, morning, evening).\n2. Put your phone on silent and face-down or in a drawer.\n3. Engage with something offline — a book, a conversation, a walk.\n4. If urges arise, let them pass — it gets easier over time.\n5. Track how you feel after each offline period.',
    },
    'Evening routine': {
      'description': 'A consistent set of calming activities before bed that tells your brain it\'s time to sleep.',
      'howTo': '1. Start 45–60 minutes before your target bedtime.\n2. Do the same sequence each night (e.g., shower → tea → reading → sleep).\n3. Keep lights dim throughout.\n4. Avoid stimulating content or stressful conversations.\n5. Be in bed before your target sleep time.',
    },
    'Concentration meditation': {
      'description': 'A meditation practice focused on training singular attention — picking one object and keeping your mind on it.',
      'howTo': '1. Sit comfortably and pick a focal point (breath, candle flame, or sound).\n2. Set a timer for 10–15 minutes.\n3. Focus entirely on your chosen object.\n4. When your mind wanders (it will), gently bring it back without frustration.\n5. Each return of focus is one "rep" — you\'re training your attention.',
    },
    'Energy management': {
      'description': 'Aligning your most important tasks with your natural high-energy periods rather than fighting your body\'s rhythm.',
      'howTo': '1. Track your energy levels hourly for a few days — note when you feel focused vs sluggish.\n2. Identify your peak energy window (usually mid-morning for most people).\n3. Schedule your most important/difficult task in that window.\n4. Do admin and easy tasks during low-energy periods.\n5. Protect your peak hours — no meetings or interruptions.',
    },
    'Mindful breaks': {
      'description': 'Short, intentional pauses in your workday where you fully disconnect rather than scrolling your phone.',
      'howTo': '1. Set a timer every 60–90 minutes while working.\n2. When it goes off, stop completely.\n3. Stand up, step away from your desk, and take 5 deep breaths.\n4. Look out a window, drink water, or do a light stretch.\n5. Return to work after 5 minutes.',
    },
    'Evening review': {
      'description': 'A short daily review at the end of the day to close loops, reset tomorrow\'s priorities, and clear your mind.',
      'howTo': '1. Take 5–10 minutes before winding down.\n2. Write down what you completed today.\n3. List any unfinished tasks that need attention tomorrow.\n4. Set your top 3 priorities for tomorrow.\n5. Mentally "shut down" — tell yourself work is done for the day.',
    },
    // ── Morning (additional) ──────────────────────────────────────────────
    'Drink 500ml Water': {
      'description': 'Starting the day with a large glass of water rehydrates you after hours of sleep and kick-starts your metabolism.',
      'howTo': '1. Keep a 500 ml bottle or glass on your nightstand before bed.\n2. Drink it within the first 10 minutes of waking.\n3. Drink slowly — don\'t rush it.\n4. Add a slice of lemon for an extra dose of vitamin C if you like.\n5. Refill and bring it with you as you start your morning.',
    },
    'Healthy Breakfast': {
      'description': 'A nutritious first meal stabilises blood sugar, boosts energy, and improves concentration for the hours ahead.',
      'howTo': '1. Aim to eat within 1–2 hours of waking.\n2. Include protein (eggs, yoghurt, nuts), complex carbs (oats, wholegrain bread), and fruit or veg.\n3. Avoid sugary cereals or pastries — they cause a crash.\n4. Eat without screens to practise mindful eating.\n5. Prep the night before if mornings are rushed.',
    },
    'Morning Sunlight': {
      'description': 'Exposure to natural light in the morning resets your circadian rhythm, boosts mood, and improves sleep quality at night.',
      'howTo': '1. Go outside or stand by a bright window within 30–60 minutes of waking.\n2. Spend at least 5–10 minutes with your face toward the light.\n3. Don\'t wear sunglasses — your eyes need the full-spectrum light.\n4. Pair it with a walk, stretching, or a cup of tea.\n5. Even on cloudy days, outdoor light is stronger than indoor light.',
    },
    'Morning sunlight exposure': {
      'description': 'Exposure to natural light in the morning resets your circadian rhythm, boosts mood, and improves sleep quality at night.',
      'howTo': '1. Go outside or stand by a bright window within 30–60 minutes of waking.\n2. Spend at least 5–10 minutes with your face toward the light.\n3. Don\'t wear sunglasses — your eyes need the full-spectrum light.\n4. Pair it with a walk, stretching, or a cup of tea.\n5. Even on cloudy days, outdoor light is stronger than indoor light.',
    },
    'Make Bed': {
      'description': 'Making your bed creates a sense of order and accomplishment that sets a productive tone for the rest of the day.',
      'howTo': '1. Straighten and pull up the sheets immediately after getting up.\n2. Fluff and arrange pillows neatly.\n3. Straighten the duvet or blanket so there are no big wrinkles.\n4. This should take no more than 2–3 minutes.\n5. Notice how much neater the room looks — let that feeling carry forward.',
    },
    'Open curtains': {
      'description': 'Letting natural light into your room immediately upon waking is a powerful cue that signals your brain to become alert.',
      'howTo': '1. Open curtains or blinds as the very first thing you do after waking.\n2. If safe, crack a window to let in fresh air too.\n3. Stand by the window for 30–60 seconds and breathe deeply.\n4. Avoid going straight to your phone — light comes first.\n5. Do this every morning to reinforce the habit.',
    },
    'Clear my workspace': {
      'description': 'A tidy workspace reduces visual clutter that competes for your attention and creates a calmer, more focused environment.',
      'howTo': '1. Before sitting down to work, spend 5 minutes clearing your desk.\n2. Put away anything not needed for today\'s tasks.\n3. Wipe the surface if needed.\n4. Set out only what you\'ll actually use: notebook, pen, water bottle.\n5. A clear desk = a clearer mind.',
    },
    'Stretch': {
      'description': 'Morning stretching releases overnight muscle tension, improves blood flow, and makes your body feel more awake and ready.',
      'howTo': '1. Roll out of bed and find floor space or use the bedroom wall.\n2. Start with a neck roll, then shoulder rolls (5 each direction).\n3. Do a standing forward fold — let your arms hang heavy for 30 seconds.\n4. Try cat-cow stretches on all fours for 1 minute.\n5. Finish with a full-body reach upwards and take three deep breaths.',
    },
    'Movement reminder': {
      'description': 'Scheduled movement reminders break up long sedentary periods, preventing stiffness and energy crashes throughout the day.',
      'howTo': '1. Set recurring alarms or use an app to remind you every 60–90 minutes.\n2. When the alert goes off, stand up and move for at least 2 minutes.\n3. Options: walk to the kitchen, do 10 squats, stretch at your desk, or march in place.\n4. Don\'t skip the reminder — stand up before you convince yourself otherwise.\n5. Track how many reminders you act on each day.',
    },
    '5-min micro-exercise': {
      'description': 'Even 5 minutes of exercise raises your heart rate, releases endorphins, and can meaningfully improve mood and alertness.',
      'howTo': '1. Pick a sequence you enjoy: jumping jacks, push-ups, bodyweight squats, or a quick jog on the spot.\n2. Set a 5-minute timer.\n3. Go at a moderate pace — you should feel warm and slightly breathless.\n4. No equipment or special clothes required.\n5. Do this immediately after waking for the biggest energy boost.',
    },
    'Yoga': {
      'description': 'Yoga combines movement, breath, and mindfulness to reduce stress hormones, improve flexibility, and calm the nervous system.',
      'howTo': '1. Find a quiet space with a mat or soft surface.\n2. Start with a 5-minute breathing warm-up (deep belly breaths).\n3. Move through gentle poses: child\'s pose, downward dog, warrior I.\n4. Hold each pose for 5–8 slow breaths.\n5. End in Savasana (lying flat) for 2–3 minutes of stillness.',
    },
    'Meditation': {
      'description': 'Daily meditation trains attention, reduces reactivity to stress, and builds a sense of calm that carries through the day.',
      'howTo': '1. Find a quiet, comfortable seat — cushion, chair, or floor.\n2. Set a timer for 5–15 minutes.\n3. Close your eyes and take three slow, deep breaths to settle.\n4. Focus on the natural rhythm of your breathing.\n5. When your mind wanders (it will), gently return focus to your breath without judgment.',
    },
    'Morning check-in': {
      'description': 'A brief check-in with yourself each morning helps you identify your current emotional state and set priorities before the day takes over.',
      'howTo': '1. Before picking up your phone, sit quietly for 2–3 minutes.\n2. Ask yourself: "How am I feeling right now — physically and emotionally?"\n3. Give an honest answer — don\'t rush past discomfort.\n4. Ask: "What is my one main focus for today?"\n5. Write it down if helpful, then begin your morning.',
    },
    'Body appreciation meditation': {
      'description': 'A practice of intentionally noticing and thanking your body for what it does, building a more compassionate and positive self-image.',
      'howTo': '1. Sit or lie down comfortably and close your eyes.\n2. Take five slow breaths to settle.\n3. Starting from your feet, mentally thank each body part for what it does (e.g. "Thank you, legs, for carrying me").\n4. Move slowly upward through your whole body.\n5. End with a moment of gratitude for your body as a whole.',
    },
    'Present moment meditation': {
      'description': 'A mindfulness practice centred on anchoring awareness fully in the current moment — sights, sounds, sensations — rather than past or future thoughts.',
      'howTo': '1. Sit comfortably and close your eyes.\n2. Take three deep breaths.\n3. Open your eyes slightly and notice five things you can see right now.\n4. Close your eyes again and focus only on sounds you can hear.\n5. Shift attention to physical sensations — the feeling of the chair, your feet on the floor — for 5 minutes.',
    },
    'Start the day slowly': {
      'description': 'Deliberately avoiding rush in the first 30–60 minutes builds a calmer nervous state that tends to carry through the whole day.',
      'howTo': '1. Wake 20–30 minutes earlier than strictly necessary.\n2. Avoid the phone, news, or social media for the first 20 minutes.\n3. Do one calming activity: make tea, journal, stretch, or sit quietly.\n4. Move at a relaxed pace — eat breakfast sitting down, not standing.\n5. Leave on time so you\'re not rushed on your commute or at the start of work.',
    },
    'Smile more': {
      'description': 'Intentionally smiling — even briefly — triggers the release of dopamine and serotonin, slightly lifting mood through facial feedback.',
      'howTo': '1. In the morning, look in the mirror and smile genuinely for 10–15 seconds.\n2. Set a small reminder during the day to pause and smile.\n3. Notice moments that naturally prompt a smile and let yourself fully feel them.\n4. Smile at others — it\'s contagious and improves social connection.\n5. At the end of the day, recall one thing that made you smile.',
    },
    'Delay Caffeine': {
      'description': 'Waiting 90–120 minutes before your first coffee allows natural cortisol levels to peak and fall, making caffeine more effective and reducing afternoon crashes.',
      'howTo': '1. Set an alarm 90 minutes after your usual wake time as your earliest caffeine window.\n2. In the meantime, drink water or herbal tea.\n3. Get natural light and movement — these are natural energisers.\n4. When you do have coffee, enjoy it mindfully rather than gulping it.\n5. Notice whether your energy feels more sustained throughout the day.',
    },
    'Wake routine checklist': {
      'description': 'A simple checklist of your core morning actions ensures nothing important is skipped, even on groggy or busy mornings.',
      'howTo': '1. Write down your 4–6 key morning habits (e.g. water, stretch, breakfast).\n2. Keep the list visible — on your phone home screen, bathroom mirror, or bedside table.\n3. Every morning, tick each item once done.\n4. Keep the list short — this is a minimum viable morning, not a perfect one.\n5. Review and adjust the list monthly as your routine evolves.',
    },
    'Screen-free morning hour': {
      'description': 'Avoiding screens in the first hour prevents digital overwhelm from immediately hijacking your focus and reactive state before the day starts.',
      'howTo': '1. Put your phone on Do Not Disturb before you sleep and keep it out of reach.\n2. For the first hour of the day, do not check social media, news, or email.\n3. Use this time for movement, breakfast, journaling, or quiet reflection.\n4. If you must check for urgent things, use a different device in a separate room.\n5. After a week, notice how your morning mood has changed.',
    },
    'Daily anchor habit': {
      'description': 'An anchor habit is a single non-negotiable daily action that keeps your routine stable even on difficult or unpredictable days.',
      'howTo': '1. Choose one habit that represents your values (e.g. 5 minutes of reading, a short walk, journaling).\n2. It should be so small and simple that you can do it even on your worst day.\n3. Lock it in to a fixed time — ideally morning.\n4. Treat it as an appointment you don\'t cancel on yourself.\n5. Let it be the thread that holds your day together when everything else feels uncertain.',
    },
    'Stick to the plan': {
      'description': 'Deciding in advance what you\'ll do — and following through — builds the habit of self-trust and reduces decision fatigue throughout the day.',
      'howTo': '1. Each evening, write your 1–3 key tasks for tomorrow.\n2. In the morning, review the plan before starting anything else.\n3. Start with task number one — resist the urge to switch to easier things.\n4. If you feel resistance, commit to just 5 minutes on the task.\n5. At the end of the day, note whether you stuck to the plan and why or why not.',
    },
    'Small steps today': {
      'description': 'Breaking big goals into the smallest possible actions makes progress feel achievable and consistent, rather than overwhelming.',
      'howTo': '1. Identify one thing you\'ve been putting off or finding hard.\n2. Break it into the smallest next step possible (e.g. "Write one sentence" not "Write a report").\n3. Do that one small step today — nothing more.\n4. Celebrate doing it, no matter how small it seems.\n5. Repeat daily — small steps compounding create significant change.',
    },
    'Review goals': {
      'description': 'Briefly reviewing your goals each morning keeps them front of mind and helps you make choices throughout the day that align with what truly matters to you.',
      'howTo': '1. Keep a written or digital list of your top 3–5 goals.\n2. Read them every morning — take 2 minutes.\n3. For each goal, ask: "Is there one thing I can do today that moves me slightly closer?"\n4. Note it in your to-do list.\n5. At night, check: "Did anything I did today align with my goals?"',
    },
    'Visualizing the day': {
      'description': 'Mental rehearsal of your day primes your brain to handle tasks and challenges with more calm focus, similar to how athletes use pre-performance visualisation.',
      'howTo': '1. Sit quietly after breakfast and close your eyes.\n2. Slowly walk through the key events of the day ahead in your imagination.\n3. Visualise each going smoothly — you arriving on time, conversations going well, tasks completed.\n4. If you foresee a challenge, mentally rehearse handling it calmly.\n5. Open your eyes feeling prepared, not pressured.',
    },

    // ── Afternoon (additional) ────────────────────────────────────────────
    'Healthy Lunch': {
      'description': 'A balanced midday meal replenishes energy, prevents the afternoon slump, and keeps you mentally sharp through the rest of the working day.',
      'howTo': '1. Step away from your desk or workspace to eat — don\'t multitask.\n2. Include protein, vegetables, and a moderate amount of complex carbs.\n3. Avoid heavily processed fast food — it causes energy crashes.\n4. Eat slowly and chew thoroughly.\n5. Drink a glass of water alongside your meal.',
    },
    'Mindful eating moment': {
      'description': 'Paying full attention to food — taste, texture, smell — during a meal reduces overeating, improves digestion, and brings a moment of calm into a busy day.',
      'howTo': '1. Before eating, take three slow breaths and set your phone aside.\n2. Look at your food — notice its colours, smell, and presentation.\n3. Take small, slow bites and notice the flavours and textures fully.\n4. Put your fork down between bites.\n5. Stop eating when you feel satisfied, not stuffed.',
    },
    'Eat a healthy snack': {
      'description': 'A nutritious snack between meals stabilises blood sugar and prevents the irritability, fatigue, and poor decisions that come from getting too hungry.',
      'howTo': '1. Choose a snack that combines protein and fibre: apple + nut butter, hummus + veggies, nuts, or yoghurt.\n2. Portion it out — don\'t eat from the whole bag or box.\n3. Eat it away from screens and work.\n4. Aim for a snack 2–3 hours after lunch.\n5. Avoid highly processed snacks — they spike and crash energy.',
    },
    'Walk': {
      'description': 'A simple walk is one of the most evidence-backed activities for improving mood, reducing anxiety, boosting creativity, and supporting cardiovascular health.',
      'howTo': '1. Aim for at least 15–30 minutes at a moderate pace.\n2. Go outside if possible — natural light and fresh air amplify benefits.\n3. Leave your phone in your pocket or at home — just walk and observe.\n4. Vary your route to keep it interesting.\n5. Notice your surroundings rather than being lost in thought.',
    },
    'Walk in nature': {
      'description': 'Specifically walking in green or natural spaces compounds the benefits of movement with the proven stress-lowering effects of nature exposure.',
      'howTo': '1. Find a park, trail, or tree-lined street near you.\n2. Aim for 20–30+ minutes at a comfortable pace.\n3. Leave headphones behind — listen to the sounds of nature instead.\n4. Look up, not down — notice the sky, trees, and your surroundings.\n5. Notice how your mood and body feel before and after.',
    },
    'Deep breathing breaks': {
      'description': 'Short structured breathing sessions during the day activate the parasympathetic nervous system, counteracting the build-up of stress from work and demands.',
      'howTo': '1. Set 2–3 reminders spread across the day.\n2. When the reminder goes off, stop what you\'re doing.\n3. Breathe in for 4 counts, hold for 4 counts, out for 6 counts.\n4. Repeat this cycle 5–6 times.\n5. Return to work feeling calmer and more focused.',
    },
    'Midday breathing break': {
      'description': 'A deliberate breathing pause at midday resets your nervous system and separates the morning\'s energy from the afternoon — improving focus for the second half of the day.',
      'howTo': '1. At noon or lunchtime, find somewhere quiet for 3–5 minutes.\n2. Sit comfortably and close your eyes.\n3. Breathe in slowly for 5 counts, out for 7 counts.\n4. With each exhale, consciously release any built-up tension.\n5. Open your eyes and return to your afternoon refreshed.',
    },
    'Movement break': {
      'description': 'Regular movement breaks prevent the physical damage of prolonged sitting and refresh mental energy so you can work with sustained focus.',
      'howTo': '1. Set a timer to go off every 60–90 minutes.\n2. Stand up and move for 3–5 minutes.\n3. Options: walk to another room, do 10 jumping jacks, stretch your neck and shoulders.\n4. Don\'t negotiate with yourself — just stand up.\n5. Over time, these breaks significantly reduce fatigue and improve output.',
    },
    'Physical movement': {
      'description': 'Regular physical movement throughout the day — beyond structured exercise — is essential for energy, focus, and long-term health.',
      'howTo': '1. Look for natural movement opportunities: take the stairs, walk to a colleague instead of messaging, pace while on calls.\n2. Stand or stretch during transitions between tasks.\n3. Aim for at least 30 minutes of cumulative movement across the day, even in small chunks.\n4. Use a step counter to make movement visible and motivating.\n5. Notice that your energy improves with more movement, not rest.',
    },
    'Power Nap': {
      'description': 'A 10–20 minute nap in the early afternoon can restore alertness, improve mood, and enhance performance without leaving you groggy.',
      'howTo': '1. Find a quiet, comfortable place — ideally a dim room.\n2. Set an alarm for exactly 20 minutes.\n3. Lie down or recline and close your eyes.\n4. Don\'t try to force sleep — simply rest.\n5. After the alarm, give yourself 5 minutes to fully wake before resuming work.',
    },
    'Deep Work': {
      'description': 'A focused, distraction-free work session on your most cognitively demanding task — producing high-quality output in less time than scattered working.',
      'howTo': '1. Choose one task that requires full concentration.\n2. Block 60–90 minutes and put your phone on Do Not Disturb.\n3. Close all browser tabs and apps unrelated to the task.\n4. Work only on that task until the timer ends — no switching.\n5. Take a 15-minute break afterwards, then evaluate your output.',
    },
    'Deep work block': {
      'description': 'A protected time block reserved exclusively for high-concentration work, free from interruptions, notifications, and multitasking.',
      'howTo': '1. Schedule a 60–120 minute block in your calendar each day.\n2. Before it starts, prepare everything you need so there\'s no reason to stop.\n3. Set all devices to silent and close social media and email.\n4. Work on only your most important task during this block.\n5. Treat it as a meeting you can\'t cancel.',
    },
    'Single-task focus session': {
      'description': 'Committing to one task at a time — rather than multitasking — dramatically improves the speed and quality of your output.',
      'howTo': '1. Choose the single most important task on your list.\n2. Write it on a piece of paper and place it in front of you.\n3. Set a timer for 25–50 minutes.\n4. Work only on that task until the timer rings.\n5. After the session, take a short break before choosing the next single task.',
    },
    'Phone-free focus block': {
      'description': 'Removing your phone entirely from your work environment eliminates the most common source of distraction, allowing deeper concentration.',
      'howTo': '1. Before starting work, put your phone in another room or in a drawer.\n2. Set it to Do Not Disturb or aeroplane mode first.\n3. Tell anyone who might need you that you\'re in a focus block.\n4. Work for 45–60 minutes without access to your phone.\n5. Retrieve it only after the session ends — not during.',
    },
    'Single-tasking today': {
      'description': 'Committing to doing one thing at a time across the entire day — resisting multitasking — improves productivity, reduces errors, and lowers stress.',
      'howTo': '1. At the start of the day, write your priority list.\n2. Work top to bottom — finish one thing before starting the next.\n3. When a new thought or task arises, write it down and continue the current task.\n4. Close or minimise everything on your screen not related to the current task.\n5. At the end of the day, review how many tasks you fully completed.',
    },
    'Single-task commitment': {
      'description': 'A daily intention to focus on one task at a time builds a powerful mental habit of presence, reducing the cognitive cost of context-switching.',
      'howTo': '1. Each morning, commit out loud or in writing: "Today I will single-task."\n2. When you feel the pull to open another tab or pick up your phone, pause.\n3. Ask: "Is this more important than what I\'m currently doing?"\n4. If the answer is no, write it down and return to your task.\n5. At the end of the day, reflect on how often you succeeded and what triggered switching.',
    },
    'Energy mapping': {
      'description': 'Tracking your energy levels hour by hour helps you identify your personal productivity peaks, so you can schedule your hardest work at the right time.',
      'howTo': '1. For 5–7 days, rate your energy every 2 hours: 1 (exhausted) to 5 (sharp and focused).\n2. Note the time and any context (after lunch, after exercise, etc.).\n3. After a week, identify your consistent high-energy windows.\n4. Schedule your most important tasks during peak hours going forward.\n5. Schedule admin, emails, and routine tasks during your natural low periods.',
    },
    'Mindfulness': {
      'description': 'A moment of deliberate present-moment awareness during the day — stepping out of autopilot mode to notice what\'s happening inside and around you.',
      'howTo': '1. Stop what you are doing and sit or stand still for 2 minutes.\n2. Take three slow, deep breaths.\n3. Notice your physical surroundings: what you can see, hear, feel.\n4. Notice your emotional state without judging it.\n5. Return to your activity with a greater sense of presence.',
    },
    'Check-in': {
      'description': 'A brief daily pause to honestly assess how you\'re coping emotionally, physically, and mentally — preventing problems from building up unnoticed.',
      'howTo': '1. Set a daily alarm at the same time each day labelled "Check-in".\n2. Ask yourself: How am I feeling physically right now? (Rate 1–10)\n3. Ask: How am I feeling emotionally?\n4. Ask: Is there anything bothering me that I\'ve been ignoring?\n5. Write a one-sentence answer to each — don\'t overthink it.',
    },
    'Values check-in': {
      'description': 'Pausing to ask whether your actions today have been in line with your core values helps you course-correct before drift becomes disconnection.',
      'howTo': '1. Identify your top 3–5 personal values (e.g. honesty, growth, connection, health).\n2. Each day, spend 2 minutes reflecting: "Did my actions today reflect these values?"\n3. If yes, acknowledge how it felt.\n4. If no, ask: "What got in the way?"\n5. Commit to one small realignment action for tomorrow.',
    },
    'Pre-social grounding exercise': {
      'description': 'A short grounding or calming practice before social situations reduces anxiety, helping you arrive feeling centred rather than reactive or overwhelmed.',
      'howTo': '1. 5–10 minutes before a social event or meeting, find a quiet space.\n2. Take 5 slow, deep breaths.\n3. Do the 5-4-3-2-1 grounding technique: name 5 things you can see, 4 you can touch, 3 you can hear.\n4. Repeat a calming phrase quietly: "I am safe and capable."\n5. Enter the situation feeling grounded, not braced.',
    },
    'Emergency calm toolkit': {
      'description': 'A personal set of quick calming techniques you can use anywhere when anxiety or stress spikes unexpectedly — your portable first aid for overwhelm.',
      'howTo': '1. Choose 3–5 techniques that work for you: box breathing, cold water on wrists, counting to 10, repeating a calming phrase.\n2. Write them on a card or save them in your phone.\n3. When you feel overwhelmed, pull out the toolkit immediately.\n4. Start with breathing — it works fastest.\n5. Don\'t wait for crisis — use it at the first sign of rising stress.',
    },
    '4-7-8 breathing': {
      'description': 'A specific breathing technique where you inhale for 4 counts, hold for 7, and exhale for 8 — shown to rapidly reduce anxiety and activate the relaxation response.',
      'howTo': '1. Sit comfortably and exhale completely through your mouth.\n2. Close your mouth and inhale quietly through your nose for 4 counts.\n3. Hold your breath for 7 counts.\n4. Exhale completely through your mouth for 8 counts — make a slow \'whoosh\' sound.\n5. Repeat 4 times. Practice twice daily — it becomes more effective over time.',
    },
    'Connect with a friend': {
      'description': 'Meaningful social connection is one of the most powerful buffers against stress, anxiety, and low mood — even a brief, genuine interaction helps.',
      'howTo': '1. Reach out to one person — a text, voice note, or call.\n2. Be genuine — ask how they\'re really doing, not just "all good?"\n3. Share something real about your own day too.\n4. Give them your full attention — put distractions away.\n5. Schedule something to look forward to together, even something small.',
    },
    'Speak up today': {
      'description': 'Intentionally expressing your thoughts, needs, or feelings rather than staying silent builds confidence, self-respect, and honest relationships.',
      'howTo': '1. Identify one situation today where you usually stay quiet but wish you didn\'t.\n2. Prepare what you want to say — write it down if helpful.\n3. When the moment arises, speak calmly and clearly.\n4. Use "I" statements: "I feel...", "I think...", "I need...".\n5. Afterwards, reflect on how it felt — even if imperfect, it gets easier each time.',
    },
    'Cut Caffeine': {
      'description': 'Stopping caffeine intake by early afternoon prevents it from interfering with sleep onset, reducing the time it takes to fall asleep and improving sleep depth.',
      'howTo': '1. Set a daily phone reminder at your caffeine cutoff time (recommended: 2 PM or earlier).\n2. After that time, switch to water, herbal tea, or decaf.\n3. Watch for hidden caffeine: cola, energy drinks, chocolate.\n4. If you feel tired, try a 20-minute nap, movement, or fresh air instead.\n5. The tiredness passes — and your sleep will significantly improve.',
    },

    // ── Evening (additional) ──────────────────────────────────────────────
    'Dim Lights': {
      'description': 'Lowering light levels in the evening signals to your brain that night is approaching, triggering melatonin production and easing the transition to sleep.',
      'howTo': '1. About 1–2 hours before bed, switch off overhead lights or use lamps instead.\n2. Choose warm, yellow-toned bulbs rather than harsh white or blue light.\n3. Reduce screen brightness on phones and computers if you must use them.\n4. Candles are ideal — they emit minimal blue light.\n5. Notice how much sleepier you feel in a dimly lit room.',
    },
    'No Screens': {
      'description': 'Avoiding screens before bed prevents blue light from suppressing melatonin and keeps your brain from being stimulated at a time it needs to wind down.',
      'howTo': '1. Set a "Screens Off" alarm 60–90 minutes before your bedtime.\n2. When it goes off, put all screens away — phone included.\n3. Replace screen time with: reading a physical book, light stretching, journaling, or talking with someone at home.\n4. Use Night Mode on devices if you absolutely must use a screen.\n5. After a week, notice how much faster you fall asleep.',
    },
    'Evening digital sunset': {
      'description': 'A scheduled transition away from all screens in the evening, mimicking a sunset and allowing your nervous system to naturally wind down for sleep.',
      'howTo': '1. Choose a consistent "digital sunset" time — recommended 60–90 minutes before sleep.\n2. Put your phone to charge in a different room from the bedroom.\n3. Switch off the TV and any other screens.\n4. Start a calming evening activity: reading, stretching, a warm bath.\n5. Protect this time every night — treat it as your personal recharge ritual.',
    },
    'Digital detox': {
      'description': 'A deliberate period completely free from digital devices, allowing your mind to rest, decompress, and reconnect with the physical world.',
      'howTo': '1. Choose a specific time block each evening (e.g. 8–9 PM).\n2. Put phone on silent and face-down, or in another room.\n3. Do an offline activity: cook, draw, walk, journal, or talk with someone.\n4. When the urge to check your phone arises, let it pass — it usually fades within 90 seconds.\n5. Notice how much calmer and more present you feel.',
    },
    'Digital detox hour': {
      'description': 'A focused one-hour break from all digital devices in the evening to clear mental noise, reduce stimulation, and prepare your mind for sleep.',
      'howTo': '1. Set a one-hour timer starting 2 hours before bed.\n2. Put all devices on silent and out of reach.\n3. Choose an offline activity you enjoy or that relaxes you.\n4. Don\'t use the time to work or be productive — it\'s restoration time.\n5. At the end of the hour, notice how much quieter your mind feels.',
    },
    'Read Fiction': {
      'description': 'Reading fiction before bed relaxes the mind through immersive storytelling, shifts attention away from daily worries, and has been shown to reduce stress by up to 68%.',
      'howTo': '1. Keep a physical book on your bedside table — not an e-reader with bright backlight.\n2. Start reading 30–60 minutes before your target sleep time.\n3. Choose engaging but not too stimulating stories — avoid thrillers or news.\n4. Read in dim light.\n5. Let yourself drift — if you fall asleep mid-chapter, that\'s fine.',
    },
    'Read a calming book': {
      'description': 'Reading something calm and enjoyable before bed shifts your mind out of problem-solving mode and into a more relaxed state conducive to sleep.',
      'howTo': '1. Choose a genre that soothes rather than stimulates: fiction, nature writing, poetry, or personal essays.\n2. Set aside 20–30 minutes before bed for reading.\n3. Read in a dim, comfortable spot — not at your desk.\n4. Use a physical book if possible to avoid screen exposure.\n5. Let the story carry you — don\'t read with a goal of finishing chapters.',
    },
    'Herbal Tea': {
      'description': 'Herbal teas like chamomile, lemon balm, and valerian root contain compounds that mildly reduce anxiety and promote drowsiness — a gentle ritual that signals wind-down time.',
      'howTo': '1. Choose a calming herbal blend: chamomile, lavender, lemon balm, or passionflower.\n2. Brew 30–45 minutes before bed.\n3. Hold the warm mug in both hands and breathe in the steam before drinking.\n4. Drink slowly and without screens.\n5. Repeat every night — the ritual itself becomes a sleep signal over time.',
    },
    'Herbal tea ritual': {
      'description': 'A mindful, consistent herbal tea ritual before bed trains your brain to associate the process with relaxation, deepening its calming effect over time.',
      'howTo': '1. Choose your favourite calming herbal blend.\n2. Prepare it with full attention — boiling water, steeping, pouring.\n3. Sit somewhere comfortable, hold the warm cup, and breathe slowly.\n4. Drink it without multitasking — no phone, no TV.\n5. Use this time to mentally let go of the day\'s events.',
    },
    'Relax': {
      'description': 'Giving yourself intentional, unstructured time to do nothing demanding allows your nervous system to shift from "on" to "off" — essential for recovery and sleep quality.',
      'howTo': '1. Choose an activity with zero obligation: sit on the sofa, listen to music, look out the window.\n2. Do not use this time for productivity.\n3. If guilt arises ("I should be doing something"), remind yourself: rest is not laziness, it\'s maintenance.\n4. Aim for at least 20–30 minutes of genuine relaxation each evening.\n5. Notice that sleeping after genuine relaxation is noticeably deeper.',
    },
    'Relaxing breathing': {
      'description': 'Slow, deliberate breathing in the evening activates the parasympathetic nervous system, lowering heart rate and preparing your body for sleep.',
      'howTo': '1. Lie down or sit in a comfortable chair.\n2. Place one hand on your chest and one on your belly.\n3. Breathe in slowly so only your belly rises — for 5 counts.\n4. Exhale slowly for 7 counts.\n5. Repeat for 5–10 minutes, letting your body become heavier with each breath.',
    },
    'Listen to music': {
      'description': 'Listening to calming music in the evening reduces cortisol, lowers blood pressure, and creates a mood shift that eases the transition from day to night.',
      'howTo': '1. Create a dedicated "wind-down" playlist of slow, calm music.\n2. Start it 30–60 minutes before bed.\n3. Sit or lie comfortably and listen without doing anything else.\n4. Let the music slow your thoughts — focus on the sounds, not your to-do list.\n5. Use it as a signal to your brain that the day is done.',
    },
    'White noise session': {
      'description': 'White noise or ambient sound masks disruptive environmental noises, creating a consistent sonic environment that helps the brain relax and stay asleep.',
      'howTo': '1. Use a white noise app, fan, or dedicated machine.\n2. Set the volume low — loud enough to mask background sounds, not so loud it\'s intrusive.\n3. Place it on the other side of the room, not right next to you.\n4. Start it about 15–20 minutes before sleep.\n5. Experiment with different sounds (white noise, rain, ocean) to find what works best for you.',
    },
    'Journaling': {
      'description': 'Daily journaling externalises thoughts and emotions, reducing mental chatter, helping you process the day, and creating a sense of closure before sleep.',
      'howTo': '1. Find a quiet space and a physical notebook.\n2. Write for 5–10 minutes without filtering or editing.\n3. Prompts to start: "Today I felt...", "Something I\'m letting go of...", "One thing I learned today...".\n4. Don\'t aim for perfect prose — raw honesty is more useful.\n5. Close the notebook and treat it as a mental drawer you\'ve now closed.',
    },
    'Brain dump journaling': {
      'description': 'Writing every thought in your head — without structure — clears your mind of the circular thinking that often prevents you from sleeping or relaxing.',
      'howTo': '1. Set a 10-minute timer.\n2. Write EVERYTHING on your mind — worries, tasks, ideas, feelings — in no particular order.\n3. Don\'t edit or organise it — speed matters more than sense.\n4. When the timer goes off, stop.\n5. Close the notebook — the thoughts are now "outside" your head.',
    },
    'Achievement journaling': {
      'description': 'Writing down what you accomplished each day — however small — builds a positive record of progress and counters the tendency to focus on what went wrong.',
      'howTo': '1. Before bed, open your journal.\n2. Write 3–5 things you did or achieved today, no matter how minor.\n3. Include small wins: "I replied to that difficult email", "I drank 2 litres of water".\n4. Resist the urge to add "but I should have done more".\n5. Read the previous week\'s achievements occasionally — the progress is real.',
    },
    'What I can control journaling': {
      'description': 'Sorting your worries into "in my control" and "not in my control" is a Stoic practice that reduces anxiety by focusing your mental energy where it actually matters.',
      'howTo': '1. Draw two columns in your journal: "In my control" and "Not in my control".\n2. Write each current worry under the correct column.\n3. For "in my control" items — write one action step you could take.\n4. For "not in my control" items — write "let go" and draw a line through them.\n5. Read only the action steps column before closing the journal.',
    },
    'Find one joy': {
      'description': 'Deliberately identifying a moment of joy from each day — even a small one — trains your brain to notice positive experiences rather than filtering them out.',
      'howTo': '1. Before bed, sit quietly and cast your mind back over the day.\n2. Ask: "Was there even one small moment that felt good, warm, funny, or meaningful?"\n3. Write it down or say it out loud.\n4. Sit with the memory for 10–15 seconds — let it land.\n5. Over time, you\'ll find your brain starts looking for joy throughout the day.',
    },
    'Celebrate small wins': {
      'description': 'Explicitly acknowledging even minor accomplishments reinforces positive behaviours through the brain\'s dopamine reward system, building momentum over time.',
      'howTo': '1. At the end of the day, list 1–3 things that went well.\n2. Include small wins — waking up on time, responding kindly, completing one task.\n3. Acknowledge each with a physical celebration: smile, fist pump, or write "well done" next to it.\n4. Share a win with someone close to you — shared celebration amplifies the effect.\n5. Don\'t diminish the wins by immediately moving to what you didn\'t do.',
    },
    'Write it down': {
      'description': 'Getting thoughts, worries, and tasks out of your head and onto paper reduces the mental load of trying to hold everything in memory, freeing your mind to relax.',
      'howTo': '1. Keep a notebook nearby for the evening.\n2. Whenever a thought, worry, or task pops into your mind, write it down immediately.\n3. Don\'t act on it — just capture it.\n4. At the end of the evening, do a final sweep: "Anything still on my mind?"\n5. Write it down, then close the notebook — it\'s captured and safe.',
    },
    'Let go of what-ifs': {
      'description': 'Practising deliberate release of hypothetical worries (what if X happens?) prevents your brain from spending the night processing scenarios that may never occur.',
      'howTo': '1. Before bed, notice if you\'re spiralling into "what if..." thinking.\n2. Write the worry down and label it: "This is a what-if, not reality."\n3. Ask: "What is the probability this will actually happen?"\n4. If you can\'t control it, write: "I release this — I\'ve done what I can."\n5. Take three slow breaths and gently redirect your mind to the present moment.',
    },
    'Plan tomorrow': {
      'description': 'Writing tomorrow\'s priorities before bed offloads them from your mind, preventing them from circling your thoughts at night and helping you wake with direction.',
      'howTo': '1. 30–60 minutes before bed, open your planner or a notepad.\n2. Write your top 3 priorities for tomorrow — realistic ones you will actually do.\n3. Note any appointments, calls, or deadlines.\n4. Lay out anything you\'ll need (e.g. gym clothes, keys, documents).\n5. Close the planner — tomorrow is handled. Now rest.',
    },
    'Prepare for tomorrow': {
      'description': 'Preparing physically for the next day (clothes, bag, work prep) eliminates morning decision fatigue and gives you the gift of a calmer, less rushed start.',
      'howTo': '1. The evening before: choose and lay out your clothes.\n2. Pack your bag with everything you\'ll need.\n3. Prepare or plan your breakfast.\n4. Check tomorrow\'s schedule and set any necessary alarms.\n5. Do this at the same time each evening — it becomes a satisfying closing ritual.',
    },
    'Early Bedtime': {
      'description': 'Going to bed earlier than usual creates a sleep debt repayment opportunity and aligns your rest with natural darkness cycles for better sleep quality.',
      'howTo': '1. Set a target bedtime 30–60 minutes earlier than usual.\n2. Work backwards: if you want to be asleep at 10:30 PM, start winding down at 9:30 PM.\n3. Dim lights and end screens at least an hour before your new bedtime.\n4. Even if you don\'t feel tired immediately, lie down at the target time.\n5. Stay consistent — your body clock adjusts within days.',
    },
    'Consistent bedtime reminder': {
      'description': 'A nightly alarm that reminds you to start winding down prevents the common pattern of "just one more episode" leading to midnight bedtimes.',
      'howTo': '1. Set a recurring alarm 60–90 minutes before your target sleep time, labelled "Start winding down".\n2. When it goes off, finish whatever you\'re doing within 10 minutes.\n3. Begin your wind-down sequence: dim lights, screens off, herbal tea, reading.\n4. Commit to being in bed by your target time, even if not immediately sleepy.\n5. After 2–3 weeks, your body will naturally start feeling tired at the reminder time.',
    },
    'Sleep preparation': {
      'description': 'A deliberate preparation routine for sleep — covering environment, body, and mind — significantly improves the speed and quality of sleep onset.',
      'howTo': '1. Cool the room to 16–19°C if possible.\n2. Put on comfortable sleepwear.\n3. Ensure the room is dark (blackout curtains or eye mask).\n4. Do 5 minutes of slow breathing or light stretching.\n5. Get into bed and avoid using your phone — let sleep come naturally.',
    },
    'Sleep by 10 PM': {
      'description': 'Sleeping before 10 PM aligns with the body\'s natural melatonin peak and allows you to capture more deep, restorative sleep in the early part of the night.',
      'howTo': '1. Set a 9 PM alarm titled "Wind down now".\n2. Begin winding down immediately: dim lights, finish screens.\n3. By 9:30 PM, be in bed with a book or journal.\n4. By 10 PM, lights off — even if you don\'t feel tired, close your eyes.\n5. After a few days of consistency, your body will adjust to this schedule.',
    },
    'No screens after 9 PM': {
      'description': 'Ending screen time by 9 PM gives your melatonin levels time to fully rise before your target sleep time, making it significantly easier to fall and stay asleep.',
      'howTo': '1. Set a 9 PM alarm titled "Screens off".\n2. When it goes off, put all devices away — phone in another room if possible.\n3. Switch to offline alternatives: a book, light journaling, gentle stretching.\n4. If you struggle, use app timers to auto-lock social media at 9 PM.\n5. Notice within a week that you feel sleepier and fall asleep faster.',
    },
    'Body scan': {
      'description': 'A mindfulness technique where you slowly move attention through the body, noticing sensations without judgment — deeply relaxing and effective for sleep preparation.',
      'howTo': '1. Lie down comfortably in bed.\n2. Close your eyes and take three slow breaths.\n3. Starting at the top of your head, slowly move your awareness downward.\n4. Notice sensations in each body part — warmth, tension, tingling — without trying to change them.\n5. Continue all the way to your toes. Most people fall asleep before they reach the feet.',
    },
    'Scan body': {
      'description': 'A mindfulness technique where you slowly move attention through the body, noticing sensations without judgment — deeply relaxing and effective for sleep preparation.',
      'howTo': '1. Lie down comfortably in bed.\n2. Close your eyes and take three slow breaths.\n3. Starting at the top of your head, slowly move your awareness downward.\n4. Notice sensations in each body part — warmth, tension, tingling — without trying to change them.\n5. Continue all the way to your toes. Most people fall asleep before they reach the feet.',
    },
    'Body scan meditation': {
      'description': 'A structured mindfulness practice of slowly scanning attention through each area of the body, releasing physical tension and quieting the mind for restful sleep.',
      'howTo': '1. Lie flat in bed, arms slightly away from your body, palms up.\n2. Close your eyes and breathe naturally.\n3. Begin at the crown of your head. Slowly notice any sensations there.\n4. Gradually move attention downward: face, neck, shoulders, arms, hands, chest, abdomen, hips, legs, feet.\n5. Spend 20–30 seconds on each area. The whole scan takes about 10–15 minutes.',
    },
    'Empathy meditation': {
      'description': 'A loving-kindness practice that intentionally cultivates compassion — for yourself and others — reducing resentment, loneliness, and emotional reactivity at the day\'s end.',
      'howTo': '1. Sit comfortably and close your eyes.\n2. Begin by directing kindness to yourself: "May I be happy. May I be healthy. May I be at peace."\n3. Bring to mind someone you love — direct the same wishes to them.\n4. Expand to a neutral person, then to someone you have difficulty with.\n5. Finally, extend it to all beings everywhere. Sit quietly for a moment before opening your eyes.',
    },
    'Focus on the present': {
      'description': 'A mindfulness practice of deliberately returning attention to the current moment — what you can see, hear, and feel — releasing rumination about past or future.',
      'howTo': '1. Sit quietly and close your eyes.\n2. Take three grounding breaths.\n3. Ask: "What am I experiencing right now?" — not yesterday, not tomorrow.\n4. Notice the physical sensations of your body right now: temperature, weight, the feeling of your breath.\n5. When your mind pulls toward past or future, gently return to "right now" without frustration.',
    },
    'Clarity meditation': {
      'description': 'A meditation aimed at mentally decluttering — settling thoughts, gaining perspective, and ending the day with a clear, quiet mind rather than a noisy one.',
      'howTo': '1. Sit comfortably and close your eyes.\n2. Take five slow breaths, lengthening the exhale each time.\n3. Imagine your mind as a snow globe — thoughts are the snow, shaken up. Let it settle.\n4. As each thought arises, acknowledge it briefly ("there\'s the worry about tomorrow") and let it drift past without engaging.\n5. Stay with the stillness for 5–10 minutes.',
    },
  };


  /// Get the description info for a specific activity.
  /// Returns a map with 'description' and 'howTo', or null if not found.
  static Map<String, String>? getTaskInfo(String activity) {
    // Try exact match first
    if (taskDescriptions.containsKey(activity)) {
      return taskDescriptions[activity];
    }
    // Try case-insensitive partial match for renamed variants (e.g. "Caffeine cutoff (2:00 PM)")
    final lower = activity.toLowerCase();
    for (final entry in taskDescriptions.entries) {
      if (lower.contains(entry.key.toLowerCase()) || entry.key.toLowerCase().contains(lower)) {
        return entry.value;
      }
    }
    return null;
  }

}
