enum MeditationCategory { sleep, stress, focus, anxiety, mindfulness, compassion }

class GuidedMeditation {
  final String id;
  final String title;
  final String description;
  final int durationMinutes;
  final MeditationCategory category;
  final String difficulty;
  final List<String> scriptSteps;  // Full narration — spoken by TTS
  final List<String> stepLabels;   // Short display text shown on screen (2–4 words)
  final String? thumbnailIcon;

  const GuidedMeditation({
    required this.id,
    required this.title,
    required this.description,
    required this.durationMinutes,
    required this.category,
    this.difficulty = 'Beginner',
    required this.scriptSteps,
    required this.stepLabels,
    this.thumbnailIcon,
  });

  // Predefined meditation library
  static const List<GuidedMeditation> defaults = [
    GuidedMeditation(
      id: 'morning-mindfulness',
      title: 'Morning Mindfulness',
      description: 'Start your day with clarity and intention',
      durationMinutes: 10,
      category: MeditationCategory.mindfulness,
      difficulty: 'Beginner',
      thumbnailIcon: 'wb_sunny',
      stepLabels: [
        'Arrive Here',
        'Three Deep Breaths',
        'Body Awareness',
        'Follow Your Breath',
        'Watch Thoughts Pass',
        'Set Your Intention',
        'Visualise Your Day',
        'Final Breaths',
        'Open Your Eyes',
      ],
      scriptSteps: [
        'Good morning. Take a moment to arrive fully into this new day. Find a comfortable seated position — on a chair, a cushion, or your bed — with your spine gently upright and your hands resting naturally on your lap. Close your eyes softly. You have nowhere to be right now except exactly here. Feel the weight of your body. Notice the temperature of the air on your skin. Notice any sounds in the room around you. There is nothing you need to do except be present in this moment. Just sit. Just breathe. Let the morning land gently.',

        'Begin by taking three slow, deliberate breaths. Breathe in through your nose for a count of four... hold gently for two... and release through your mouth over a count of six. Feel your body settle with each exhale. Again — breathe in slowly... hold... and release completely. One more time — a full, deep inhale... gentle hold... and a long, complete exhale. Feel how different your body is from just a moment ago. Keep breathing at this pace. In... and out. In... and out. There is nothing to rush. Let each exhale release a little more of last night, a little more tension, a little more heaviness.',

        'Bring your awareness into your physical body. Notice how it feels to be in your body this morning. Is there any stiffness, warmth, or tension anywhere? Simply notice without trying to change anything. Scan from the top of your head down to your feet, just observing. Your body has cared for you through the night. Take a quiet moment to appreciate that. Feel the contact your body makes with whatever it rests on. Feel the slight rise and fall of your chest. Your body is already doing so much for you, effortlessly and without complaint. Simply notice. Simply appreciate. Breathe.',

        'Now bring your full attention to your breath, exactly as it is — without controlling it. Simply observe the natural rhythm. Notice the slight pause between inhale and exhale. Notice where you feel the breath most clearly — perhaps in the rise of your chest, the expansion of your belly, or the cool air at the tip of your nose. Choose one anchor point and rest your attention there completely. Stay here. Breathe in... and notice. Breathe out... and notice. Your only job right now is to observe this one simple thing. When the mind moves, come back to the breath. Again and again. This is the practice. Breathe.',

        'As thoughts begin to arise — and they will — simply notice them without engaging. Imagine each thought as a cloud drifting through a clear sky. You are not the cloud. You are the vast sky itself. You do not need to chase the thought or push it away. Just let it pass, and gently return your attention to the breath. A thought arrives... you notice it... and you return. Again and again. Each return is a success, not a failure. The mind wanders — that is its nature. Your practice is the gentle returning. Keep breathing. Keep noticing. Keep returning. You are doing exactly the right thing.',

        'Now set an intention for your day. Not a task or a to-do list — but a quality you want to carry with you. It might be patience, or kindness, or focus, or openness. Take a moment to feel into what the day needs from you. Let one word or phrase rise naturally in your mind. Breathe it in as if you are breathing it into your cells. This is how you want to show up today. Say it quietly to yourself. Feel what it means. Let it settle in your body. Keep breathing slowly as you hold this intention in your heart.',

        'Visualise yourself moving through your day with that quality. See yourself in a real moment — a conversation, a task, a challenge — and notice how you respond when you are carrying this intention. You are calmer. More measured. More kind. See yourself pausing when things feel difficult. Breathing before you react. Choosing a thoughtful response. Your morning practice is planting a seed. The seed is already in the ground. Throughout the day, when things feel hard, you can return to this intention and begin again. Breathe. Trust the seed.',

        'Take three final deep breaths now. Each one a little deeper and more complete than the last. Breathe in possibility... breathe out resistance. Pause. Breathe in clarity... breathe out worry. Pause. Breathe in this brand new, unrepeatable day... breathe out anything from yesterday that no longer serves you. Let your body fill completely on each inhale. Let go completely on each exhale. Rest in the brief, quiet pause between. You are ready. You have everything you need.',

        'Begin to bring gentle movement back to your body. Wiggle your fingers and toes slowly. Roll your shoulders back softly. Tilt your head gently from side to side. Take a last long breath in — and open your eyes slowly, letting light return gradually. Before you move, take ten seconds to sit with how you feel. Carry the stillness of this morning with you into everything that comes next. You have begun the day with intention. That is enough.',
      ],
    ),

    GuidedMeditation(
      id: 'body-scan-relaxation',
      title: 'Body Scan Relaxation',
      description: 'Release tension and stress from your entire body',
      durationMinutes: 15,
      category: MeditationCategory.stress,
      difficulty: 'Beginner',
      thumbnailIcon: 'self_improvement',
      stepLabels: [
        'Welcome & Settle',
        'Arrive In Your Body',
        'Toes & Feet',
        'Ankles & Lower Legs',
        'Calves & Knees',
        'Thighs & Hips',
        'Belly & Lower Back',
        'Chest & Heart',
        'Shoulders',
        'Arms & Hands',
        'Neck, Jaw & Face',
        'Whole Body Rest',
        'Gently Return',
      ],
      scriptSteps: [
        'Welcome to the Body Scan. Lie down comfortably, or sit in a reclining position. Close your eyes gently, and let your arms rest at your sides, palms facing upward. Give yourself full permission to completely let go right now. You do not need to be anywhere else. You do not need to do anything except receive. The practice will guide you. Everything else can wait. Just settle. Let your body be heavy.',

        'Take three slow, deep breaths to arrive in this moment. Breathe in gently and fully... and let the exhale come slowly and completely. With each exhale, feel your body becoming just a little heavier, a little more settled. There is nothing you need to do during this practice except feel and observe. You are safe. You are here. Let each breath deepen your rest. Breathe in... and sink. Breathe out... and soften. In... and sink. Out... and soften. Stay with this rhythm.',

        'Begin by bringing your awareness to the very tips of your toes. Notice any sensations — warmth, coolness, tingling, or even nothing at all. Whatever you find is fine. Now breathe into that area. Imagine the breath travelling all the way down to your toes. With the exhale, let any tension dissolve. Stay here. Breathe in... and send warmth to your toes. Breathe out... and let them soften. Again. In... and warmth. Out... and soften. Take your time. There is no rush in this practice.',

        'Allow your awareness to drift upward through your feet and ankles. Notice the soles of your feet — the heel, the arch, the ball. Feel the weight of your ankles against the surface they rest on. Perhaps a faint pulse, or warmth, or nothing at all. Breathe here. Let both feet soften and release with each exhale. In... and breathe into your feet. Out... and let them be heavy. Completely heavy. Completely at rest. There is nowhere they need to be right now. Let them go.',

        'Move your attention to your calves and shins, then your knees. Breathe into your legs. Many of us carry tension here without realising — the body holds the day in the muscles of the legs. Breathe deeply and imagine the tension melting like ice in warm water. With each exhale, your legs grow heavier, softer. In... and fill your legs with breath. Out... and let them melt. They do not need to move. They do not need to hold anything. Let them rest completely.',

        'Continue to your thighs and hips. Breathe here with openness and gentleness. The hips carry emotional weight alongside physical tension. Breathe in... and soften the thighs. Breathe out... and let the hips be wide and open. Notice if there is any clenching or gripping. Release it. Let your hips be heavy against the surface beneath you. Everything you have been carrying — the stress, the effort, the doing — can be set down here for a while. Breathe in... and release from deep within. Out... and let go.',

        'Bring your awareness to your belly and lower back. Allow your belly to be completely soft. Let it rise fully with each inhale and fall fully with each exhale. Many of us hold our stomach in all day without realising. Give yourself full permission to release that right now. Let your belly be round and free. Feel the satisfying expansion of breath filling your core. Breathe in... and let your belly rise. Breathe out... and let it fall. In... and rise. Out... and fall. Stay here with this slow, full rhythm.',

        'Shift your attention to your chest and upper back. Notice the rise and fall with each breath. Is there tightness? A sense of heaviness? Breathe into it with kindness. As you exhale, imagine the tension in your chest unwinding, loosening, dissolving. Your heart is at rest. Everything is okay right now. This moment is safe. Breathe in... and fill your chest. Breathe out... and let it soften. Feel the space between your shoulder blades. Let your upper back grow heavy. In... and fill. Out... and release. Your heart rests.',

        'Bring your awareness to your shoulders. Allow them to drop. You may be surprised how far they fall — that is the tension you carry each day. Breathe deeply and with each exhale let your shoulders move away from your ears, releasing, softening, sinking. In... and breathe height into your shoulders. Out... and let them fall completely. Again. In. Out... and fall. Again. The weight of the world does not need to be held here. Let your shoulders be completely heavy and still. They are resting now.',

        'Travel down both arms simultaneously — through your upper arms, past your elbows, into your forearms, your wrists, your hands, and all the way to your fingertips. Let them be completely heavy. Notice the warmth in your palms, the faint pulse in each finger. Let them be entirely at rest. Breathe in... and send warmth down your arms. Breathe out... and let them be heavy as stone. In... and warm. Out... and heavy. Your hands have done enough today. Let them rest. Let them be still.',

        'Finally, bring your attention to your neck, jaw, and face. Allow your jaw to hang slightly loose — let your teeth part, your tongue to rest softly in your mouth. Let the muscles around your eyes be smooth. Let your forehead unfurl. Let every tiny muscle in your face be completely at peace. Breathe in... and let your face be smooth and open. Breathe out... and let it rest completely. Your face tells the world your emotions all day. Right now, it needs to say nothing. Just be still. Just be soft.',

        'Sense your entire body from head to toe as a single, unified, deeply relaxed whole. Breathe into all of it. Feel the beautiful heaviness and stillness. You have done something profound — you have given your body a complete, conscious rest. Take three slow, deep breaths to seal this practice. Breathe in... and appreciate your body. Breathe out... and let it be completely heavy. In... and appreciate. Out... and rest. One more. In... and thank your body. Out... and let go of everything.',

        'Begin to slowly return. Wiggle your fingers first, then your toes. Take a deeper breath. Roll your wrists and ankles gently. When you feel ready, roll to one side and rest there for a moment before sitting up. Open your eyes softly. Before you move, take five seconds to notice how your body feels now compared to when you arrived. Carry this deep relaxation gently into the rest of your day.',
      ],
    ),

    GuidedMeditation(
      id: 'deep-sleep-journey',
      title: 'Deep Sleep Journey',
      description: 'Drift into peaceful, restorative sleep',
      durationMinutes: 20,
      category: MeditationCategory.sleep,
      difficulty: 'Beginner',
      thumbnailIcon: 'nightlight',
      stepLabels: [
        'Settle In',
        'Let Go',
        'Feel Supported',
        'Golden Light',
        'Face & Temples',
        'Jaw & Neck',
        'Shoulders & Chest',
        'Hands & Fingers',
        'Belly & Back',
        'Hips, Legs & Feet',
        'Whole Body Warm',
        'Drifting Deeper',
        'Rest Now',
      ],
      scriptSteps: [
        'Welcome. It is time to rest. Settle into your bed and make yourself completely comfortable. Shift your pillow, pull your covers in, adjust until you feel entirely at ease. Close your eyes. You do not need to fall asleep immediately. All you need to do is allow yourself to let go, one breath at a time. Notice that you are safe. Notice that you are warm. Notice that everything you were carrying today can be set down right here. You are not going anywhere. You do not need to think. You do not need to plan. Just be here.',

        'Take a long, slow breath in through your nose... and release it equally slowly through your mouth. As you exhale, feel yourself sinking a little deeper into the mattress. There is nothing pulling at your attention tonight. No tasks, no worries, no decisions — all of that belongs to tomorrow. Right now, the only thing that exists is this breath, and this bed. Breathe in... and settle. Breathe out... and sink. In... and settle. Out... and sink. With each exhale, you are a little heavier. A little more still. A little closer to sleep.',

        'Notice where your body makes contact with the bed. Feel the pillow beneath your head, the warmth of the covers, the mattress rising up to hold you. You do not have to hold yourself up. The bed is doing that effortlessly. Let every muscle release, every effort dissolve. You are held completely. Breathe in... and feel supported. Breathe out... and release all effort. In... and feel held. Out... and release. Each breath, let a little more of the effort of the day drain out of your body, through your fingertips, through your feet, and away.',

        'In your mind, picture a soft, warm golden light beginning to form at the very crown of your head. It is gentle and completely safe — like warm sunlight through thin curtains on a quiet morning. This light is here to help every part of your body find rest. Watch it gather and glow at the top of your head, patient and still. It is in no hurry. It will move slowly. Breathe here. Just feel the warmth beginning at your crown. Let it gather. Let it build. It is ready to begin its journey through you.',

        'The golden light moves slowly down through your scalp, your forehead, your temples and your eyes. As it touches each part, you feel a profound warmth and heaviness. The lines of your forehead smooth. The space around your eyes softens. The tiny muscles of your face release one by one. Your eyelids grow heavier. Breathe here. Let the warmth settle in your face. In... and feel the golden warmth. Out... and let your face release. There is nothing your face needs to express right now. Just rest. Just be warm. Just soften.',

        'The light continues slowly down through your jaw and into your neck and throat. Feel any tension in your jaw releasing — perhaps your teeth were clenched without you realising. Let your lips part slightly. Let the back of your throat open. Feel the warmth moving gently through your neck. All the words you spoke today, all the tension you held in your throat — let it dissolve now. Breathe in... and feel the warmth in your neck. Breathe out... and let it all release. In... and warm. Out... and release. Your jaw rests. Your throat opens. Your neck softens.',

        'The golden light now flows down into your shoulders, upper arms, and chest. Your shoulders drop away from your ears as the warmth passes through. Feel your chest expand with ease. Your heartbeat is slowing, becoming steady and calm — a slow, reassuring rhythm in the quiet of this night. Breathe in... and feel the warmth in your chest. Breathe out... and let your shoulders sink. In... and warm. Out... and sink. Your chest rises and falls softly. Your heart knows how to rest. Trust it. Let it slow. Let it be at peace.',

        'The warmth moves through your forearms, your wrists, your hands, and your fingers. Feel each finger grow warm and heavy. A pleasant tingling reaches your very fingertips. Your hands have done so much today. Let them be completely still and open, resting like small sleeping things at your sides. Breathe in... and feel warmth flowing to your fingertips. Breathe out... and let your hands be heavy. In... and warm. Out... and heavy. They need do nothing more tonight. They can rest completely.',

        'The golden light now fills your belly and flows through your lower back. Your belly rises and falls effortlessly with each breath. There is no need to hold anything in. Let it be completely soft and free. With every exhale, the warmth deepens further, and any remaining tension in your torso releases. Breathe in... and feel your belly warm and open. Breathe out... and let it fall completely. In... and warm. Out... and release. Your core is at peace. Everything you carried inside you today is softening now.',

        'The warmth now flows into your hips, down through your thighs, your knees, your calves, your ankles, and all the way to the soles of your feet. Each part grows heavier and warmer as the light passes through. Your legs are heavy as stone. Your feet are warm and still. Your body, from head to toe, is now completely filled with this peaceful golden warmth. Breathe in... and feel it everywhere. Breathe out... and sink even deeper. In... and everywhere warm. Out... and deeper still.',

        'Your whole body is now wrapped in warm, golden peace. All tension has dissolved. You are safe. You are warm. You are held. Your breath has grown slow and shallow and perfectly even. There is nowhere to go. Nothing to do. Nothing to plan. Just this warmth, and this breath, and this still, dark, safe night. Breathe in... and rest in the warmth. Breathe out... and let go of the day completely. In and out. In and out. Slower. Quieter. Heavier.',

        'With each breath, you drift a little deeper... a little heavier... a little further from wakefulness. Your thoughts, if any remain, are distant and soft — like voices heard from another room through closed walls. You do not need to engage with them. Simply breathe. Simply rest. Simply be here, warm and held in the darkness. The night is long. You have all the time you need. Breathe in... and drift. Breathe out... and let go. Drift. Let go. Drift.',

        'Let sleep come in its own time. You do not need to chase it. It is already close. If thoughts arise, gently return to the feeling of golden warmth in your body. If you wake in the night, you can bring this practice back. You have everything you need. Your body knows how to sleep. Trust it. Rest now. Sleep deeply. Sleep well. Goodnight.',
      ],
    ),

    GuidedMeditation(
      id: 'anxiety-relief',
      title: 'Anxiety Relief',
      description: 'Calm racing thoughts and find your center',
      durationMinutes: 10,
      category: MeditationCategory.anxiety,
      difficulty: 'Beginner',
      thumbnailIcon: 'waves',
      stepLabels: [
        'You Are Here',
        '4-2-6 Breath',
        'Hand On Heart',
        'Name The Anxiety',
        'Watch Thoughts',
        'Keep Breathing',
        'Calming Phrases',
        'Feel The Ground',
        'Final Breaths',
        'Return Gently',
      ],
      scriptSteps: [
        'Welcome. Anxiety can feel overwhelming, but you are not powerless. This practice will gently, step by step, reduce the intensity of what you feel right now. Find a comfortable position. Place one hand on your chest and feel your heartbeat. That steady, faithful rhythm belongs to you. It is yours. It is here. You are here. Before we do anything else — just notice that you arrived. You chose to pause. That takes courage. Stay here.',

        'The most powerful tool you have right now is your breath. Breathe in through your nose for four slow counts — one... two... three... four. Now hold softly for two counts. And breathe out through your mouth for a count of six — slow, steady, and complete. This longer exhale directly activates your body\'s calming response. Do this again: breathe in... two... three... four. Hold. And breathe out... two... three... four... five... six. Again. In... two... three... four. Hold. Out... two... three... four... five... six. Keep this rhythm. It is working.',

        'Notice the sensation of your hand on your chest. Feel it rise gently with each inhale, and fall completely with each exhale. This simple contact is grounding. Your warm hand tells your nervous system: I am here. I am present. I am not in danger. Stay with this feeling. Feel the warmth between your hand and your chest. Feel your heartbeat beneath your palm. It is steady. It is constant. It knows how to find its rhythm. Trust it. Breathe. Hand on heart. Here. Safe.',

        'Now, gently acknowledge the anxiety without pushing it away. Pushing rarely works — it gives anxiety more power. Instead, give it a little space. Say to yourself quietly: "I notice I am feeling anxious. That is okay. Anxiety is not dangerous. It is a feeling, and feelings pass." Say it again in your mind. I notice I am feeling anxious. That is okay. Just naming the feeling reduces its intensity. You are not fighting it. You are meeting it with understanding. Keep breathing while you hold it with kindness.',

        'Turn your attention to your thoughts. Rather than being inside them, step back and observe them — like sitting on the bank of a river, watching leaves float by on the current. You do not have to jump in and chase each leaf. You are the observer, safely on the bank. Watch a thought arrive... notice it... and watch it drift away. Another comes. Notice it. Let it pass. You are not your thoughts. You are the awareness that watches them. Breathe. Watch. Let pass. You are the river bank, not the current.',

        'Breathe again: in for four... hold for two... out for six. Your body is receiving a clear signal of safety with every exhale. Your breathing is slowing. Your heart rate is steadying. You may not feel completely calm yet, and that is perfectly fine. The nervous system takes a few minutes to shift. Keep breathing. Keep watching thoughts pass. Keep returning to this breath. You are not doing this wrong. There is no wrong. Just breathe. Just return. Just stay.',

        'Now repeat these words in your mind, one phrase with each breath: "I am safe." Breathe. "I am calm." Breathe. "This moment is all there is." Breathe. "I can handle this." Breathe. These are not empty words — they are direct instructions to your nervous system. Say them slowly. Mean them even just a fraction. "I am safe." Breathe. "I am calm." Breathe. "This moment." Breathe. "I can handle this." Breathe. Say it again. Let the words settle like stones in still water.',

        'Bring your awareness to where your body makes contact with the surface beneath you. Feel your feet on the floor, your seat on the chair, or your back on the bed. This contact is real. This surface supports you fully. You are held. Let your weight drop into it completely. You do not have to hold yourself up right now. Feel how solid and real the ground is. You are on the earth. The earth is supporting you. Breathe in... and feel the ground. Breathe out... and surrender your weight to it.',

        'Take three final deep breaths, each one a little more complete than the last. Breathe in... and release a little more tension. Breathe out... and let it go. In... and let your body soften just a little more. Out... and release. One more — the deepest one. In through your nose, filling completely. And a long, full exhale through your mouth. Release everything. You have done something courageous by stopping and breathing. That matters. You matter.',

        'Gently bring your awareness back to the room. Open your eyes slowly when you are ready. Notice that something has shifted — even slightly. Notice that you are still here, still breathing, still okay. This breath — four in, hold two, six out — is always available to you. Use it whenever anxiety rises. Return to this practice as often as you need. You have this. You have always had this.',
      ],
    ),

    GuidedMeditation(
      id: 'focus-clarity',
      title: 'Focus & Clarity',
      description: 'Sharpen your mind and enhance concentration',
      durationMinutes: 15,
      category: MeditationCategory.focus,
      difficulty: 'Intermediate',
      thumbnailIcon: 'center_focus_strong',
      stepLabels: [
        'Arrive & Sit Tall',
        'Energising Breaths',
        'The Clear Lake',
        'Observe The Breath',
        'Notice Wandering',
        'Return & Repeat',
        'Mind\'s Eye Light',
        'Steady The Light',
        'Apply Your Focus',
        'Set Your Intention',
        'Open With Clarity',
      ],
      scriptSteps: [
        'Welcome to this Focus and Clarity practice. This session trains one of your most powerful mental abilities — the capacity to direct and sustain attention. Sit upright with your spine long and naturally tall. An upright posture signals alertness to your mind — do not slouch. Hands can rest on your knees or lap. Close your eyes fully. Take a moment to truly arrive here. Notice any restlessness, any scattered energy. You do not need to eliminate it — just notice it. You are here now. You are ready.',

        'Begin with three energising breaths — fuller and a little more vigorous than usual. Breathe in deeply and firmly through your nose... and breathe out completely through your mouth, almost like a sigh. Again: breathe in to full capacity... and breathe out everything. One more — the deepest inhale you can take... and a clean, complete exhale. Feel your mind sharpening. Feel your body wake up and settle simultaneously. Now return to a natural, easy breathing rhythm. Stay alert. Stay present. This is the quality of attention we are cultivating.',

        'Close your eyes and bring to mind the image of a clear, still mountain lake at dawn. No wind. No disturbance. The surface is a perfect mirror — completely calm and completely clear. This is the natural state of your mind when it is not pulled in ten directions. This is what we are moving toward — not emptiness, but sharpness. Clarity. Stillness that is alive and alert. Breathe and hold this image. Let it settle in your mind. A still lake. Your mind at its best. Clear. Open. Ready.',

        'Now bring your full attention to your breath — not to control it, but to observe it with genuine curiosity. Where do you feel it most clearly? At your nostrils, where the air is cool on the inhale? In the rise of your chest? Or in the expansion of your belly? Choose one anchor point and rest your attention there fully — like placing a hand very gently on something delicate. Stay. Notice the inhale. Notice the exhale. Notice the brief pause between. Notice the next inhale. Stay exactly here. This is the practice.',

        'Notice how quickly the mind seeks to wander. A thought arises — a plan, a memory, a worry — and before you realise, you are somewhere else entirely. This is completely normal. The mind is trained to associate and wander. This is not failure. The moment you notice you have wandered — that moment itself is mindfulness. That noticing is the skill you are building. When it happens, simply say to yourself: "wandering"... and return. No frustration. No self-criticism. Just return.',

        'Each time you return your attention to the breath after it has wandered, you are performing a mental repetition. Like a single bicep curl builds muscle over time, each return strengthens your focus. In a single session, you may return dozens of times. That is not a poor session — that is excellent practice. Do not wish for fewer thoughts. Embrace each moment of distraction as an opportunity to return and grow. Notice... return. Notice... return. Keep breathing. Keep returning. You are getting stronger.',

        'Now shift your focus: imagine a single bright point of white light at the centre of your forehead — your mind\'s eye. See it clearly. Sharp. Still. This light represents your focused awareness — undistracted, unwavering, present. As you breathe in, imagine the light growing slightly brighter and more defined. As you breathe out, any haziness dissolves and the light becomes sharper. In... and brighter. Out... and sharper. Let this image be vivid and real. Your attention is this light.',

        'Continue breathing and holding this image of steady, bright light. If thoughts enter, acknowledge them — and then return to the light. The light does not fight thoughts or push them away. It simply continues to shine, steady and clear, regardless of what passes around it. This is the quality of unshakeable focus. External noise exists — and the light remains. Distractions arise — and the light remains. Breathe in... and steady the light. Breathe out... and steady the light. It is always there. Keep finding it.',

        'Now extend this focused awareness outward. Think of one specific task or priority in your day — something that requires your full attention. See yourself sitting with it, undistracted, engaged, and present. Notice how different it feels to approach something with complete attention compared to a scattered, preoccupied state. Notice the quality of thinking available to you when you are truly here. This clarity is available to you. You have been practising it right now. Breathe it in.',

        'Set a clear intention for what you will focus on when this session ends. Choose something specific — a project, a conversation, a piece of work. Name it clearly in your mind. Now breathe that intention in — feel it settle in your body as a genuine commitment, not just a thought. You are planting it. You will carry this quality of attention into your next task. Breathe in... and commit. Breathe out... and let it settle. In. Out. The intention is planted.',

        'Take three final breaths. With each one, feel a growing sense of readiness, clarity, and quiet confidence. Your attention is sharp. Your mind is clear. Your purpose is set. Slowly wiggle your fingers. Gently open your eyes, letting them adjust to the light. Before you move, sit for five seconds with the quality of this stillness. Then carry it with you. Open your eyes.',
      ],
    ),

    GuidedMeditation(
      id: 'loving-kindness',
      title: 'Loving-Kindness',
      description: 'Cultivate self-compassion and kindness',
      durationMinutes: 10,
      category: MeditationCategory.compassion,
      difficulty: 'Beginner',
      thumbnailIcon: 'favorite',
      stepLabels: [
        'Settle & Open',
        'Soften Each Breath',
        'See Yourself',
        'Hand On Heart',
        'Wish For Yourself',
        'Allow It In',
        'Someone You Love',
        'A Neutral Person',
        'Someone Difficult',
        'All Living Beings',
        'Carry It Forward',
      ],
      scriptSteps: [
        'Welcome to the Loving-Kindness practice. This is one of the most deeply transformative meditations in the world — proven to increase compassion, reduce depression, and improve relationships. Sit comfortably with your hands resting on your lap. Close your eyes and settle in. There is no performance here. No right or wrong way to feel. If emotions arise — warmth, or even resistance — both are welcome. This practice works even when it feels mechanical. Simply begin.',

        'Take a few slow, easy breaths. On each exhale, let your body soften just a little more. Let your shoulders drop. Let your belly be free. Let your jaw unclench. There is nothing to guard against here. This is a space of complete safety and warmth. Breathe in... and let something release. Breathe out... and soften just a little more. You are creating space inside yourself — space for kindness to arise. In... and open. Out... and soften. Keep breathing at this slow, easy pace.',

        'Now bring to mind a clear, warm image of yourself. You might see yourself as you are right now, sitting here. Or you might recall a memory of yourself — a moment of laughter, of effort, of simply being. Look at this image of yourself with genuine kindness — the kind you would give freely to someone you care deeply about. You deserve that same warmth. Look at yourself without criticism. Just see yourself, simply, as a person doing their best. Take a breath here and hold that image.',

        'Place one hand gently on your heart. Feel its steady, faithful rhythm beneath your palm. This heart has been with you through difficulty and joy, through fear and love, every single moment of your life without ever taking a rest. Take a breath and allow yourself to genuinely appreciate your own effort. You are doing your best. That is enough. More than enough. Keep your hand on your heart. Feel the warmth between your palm and your chest. This warmth is kindness. It is real. Breathe.',

        'Now silently repeat these phrases, slowly and with as much meaning as you can bring: "May I be happy." Breathe. "May I be healthy and strong." Breathe. "May I be safe from harm." Breathe. "May I live with ease and peace." Breathe. Say each one as a genuine wish for yourself — not a demand, not an affirmation to perform, but a tender prayer. "May I be happy." Breathe. "May I be healthy." Breathe. "May I be safe." Breathe. "May I have ease." Breathe. Again. Let each phrase settle.',

        'You may feel nothing at first — warmth can take time to arrive. Or you may feel discomfort — this is common. Even resistance deserves kindness. Keep repeating the phrases gently, and simply allow for the possibility of warmth, even a small flicker. The practice works even when it feels dry. You are planting seeds. Some will grow now. Others will grow later. Keep repeating. Keep breathing. Allow something — anything — to soften, even for one moment.',

        'Gently bring to mind someone you love easily — a close friend, a family member, a child, a pet. Picture their face clearly. Let the natural warmth you feel for them arise without effort. Now silently extend the same wishes to them: "May you be happy." Breathe. "May you be healthy." Breathe. "May you be safe." Breathe. "May you live with ease." Breathe. Feel the warmth travelling outward from your heart toward them. Notice how naturally kindness flows when someone we love is in our mind.',

        'Now bring to mind someone more neutral — a neighbour, a shop assistant, someone you passed on the street today. Someone toward whom you feel neither strong warmth nor difficulty. Extend the same phrases to them with an open heart: "May you be happy. May you be healthy. May you be safe. May you have ease." Notice how kindness can travel even to a stranger. This person wants happiness just as much as you do. They carry struggles just as you do. Breathe and send them warmth.',

        'If it feels possible, bring to mind someone toward whom you hold some difficulty or frustration. You do not have to perform love you do not feel. Simply acknowledge: this person also wants to be happy. This person also knows suffering. Quietly, with whatever goodwill you can honestly offer — even a very small amount — extend the phrases. "May you have peace. May you be free from suffering." Even a single moment of genuine goodwill changes something in you. Breathe.',

        'Now expand your awareness to include all living beings — everywhere, in every direction. Every person hoping for happiness. Every creature uncertain and trying. Every being that has ever suffered. Silently send: "May all beings be happy. May all beings be healthy. May all beings be safe. May all beings live with ease." Rest in the vast, open expansiveness of that wish. It costs nothing. It carries everything. Breathe and send it outward as far as you can imagine.',

        'Place both hands on your heart. Take three slow, deep breaths into this warmth. Carry it with you as you return. You have practised one of the oldest and most powerful psychological skills that exists — the deliberate cultivation of kindness. Every time you practise, the capacity grows. Open your eyes gently. Notice how the quality of your attention has shifted. This is yours now.',
      ],
    ),

    GuidedMeditation(
      id: 'quick-reset',
      title: 'Quick Reset',
      description: 'A brief pause to center yourself',
      durationMinutes: 5,
      category: MeditationCategory.mindfulness,
      difficulty: 'Beginner',
      thumbnailIcon: 'refresh',
      stepLabels: [
        'Just Pause',
        'One Full Breath',
        'Body Check-In',
        'Let Sounds Rest',
        'Here & Now',
        'One Gratitude',
        'Breathe & Begin',
      ],
      scriptSteps: [
        'Welcome to the Quick Reset — five minutes that can genuinely shift the quality of your day. You do not need to move. You do not need silence. Simply pause wherever you are, and allow this moment to be exactly what it is. Close your eyes if possible, or soften your gaze toward the floor. Take a breath and acknowledge that you have chosen to stop. Even for five minutes. That choice matters. The world can wait. You are here. You are pausing. That is already the practice.',

        'Take one complete, conscious breath. Breathe in slowly through your nose — feeling the air fill you from the bottom of your lungs upward. Hold it gently for just a moment. Then exhale fully and slowly through your mouth, completely emptying. That single breath is the beginning of a reset. Now take one more just like it — fill completely... hold briefly... and release entirely. Notice the difference between this breath and the shallow, automatic breathing you may have been doing before you stopped. This is what it feels like to breathe on purpose.',

        'Bring your awareness to your physical body right where you are. Notice how it feels to be in your body in this exact moment. Is there tension in your shoulders? Tightness in your jaw or forehead? Restlessness in your legs? Simply observe without any need to fix. This is not about solving anything — it is about noticing. Take a breath and see if you can let just one area of tension soften slightly. Just one. Breathe and soften. You do not have to fix everything. Just notice. Just breathe.',

        'Now bring your attention outward to what you can hear. Let sounds come and go without following any of them into thought. A sound arises... you notice it... and you let it fade without pursuing it. Let sounds exist as part of the background — like weather. You are bigger than the noise around you. You are the space in which sounds appear and disappear. A sound rises. You notice. It passes. Another comes. You notice. It passes. You remain, quiet and steady at the centre of it all.',

        'Take one deep breath. As you inhale, silently say the word "here." As you exhale, silently say the word "now." Here... now. Here... now. Two simple words that bring you entirely into the present. Say them again with the breath. Here... now. This moment — right here, right now — is the only moment where anything is actually happening. The past is gone. The future is not yet here. There is only this. Breathe it in. Here. Now. Here. Now. Stay with this.',

        'Bring to mind one thing you are genuinely grateful for right now. It does not need to be grand. It might be the warmth of where you are sitting, the fact that you are breathing, that someone cares about you, or simply a small pleasure you enjoy. Hold it in your attention for a full five seconds. Let it be real. Let it register. Gratitude shifts neurochemistry — it is one of the fastest ways to change how you feel. Breathe slowly while you hold your one thing. Let the appreciation be genuine.',

        'Take three final breaths. With each inhale, silently breathe in the word "enough." With each exhale, breathe out the word "release." Enough... release. Enough... release. You are enough. You can release what you cannot control. You are enough exactly as you are right now. Release the pressure. One more — breathe in... enough. Breathe out... release. When you are ready, open your eyes. You are a little more grounded. A little more present. That is real. Take it with you.',
      ],
    ),
  ];

  static List<GuidedMeditation> getByCategory(MeditationCategory category) {
    return defaults.where((m) => m.category == category).toList();
  }

  static List<GuidedMeditation> getByDuration(int maxMinutes) {
    return defaults.where((m) => m.durationMinutes <= maxMinutes).toList();
  }

  static List<GuidedMeditation> getByMotive(String? motive) {
    if (motive == null) return defaults;
    final Map<String, List<MeditationCategory>> motiveMapping = {
      'Sleep': [MeditationCategory.sleep, MeditationCategory.stress],
      'Stress': [MeditationCategory.stress, MeditationCategory.mindfulness, MeditationCategory.compassion],
      'Anxiety': [MeditationCategory.anxiety, MeditationCategory.mindfulness, MeditationCategory.stress],
      'Focus': [MeditationCategory.focus, MeditationCategory.mindfulness],
      'Habit Building': [MeditationCategory.mindfulness, MeditationCategory.compassion],
    };
    final relevantCategories = motiveMapping[motive] ?? [];
    if (relevantCategories.isEmpty) return defaults;
    final matched = defaults.where((m) => relevantCategories.contains(m.category)).toList();
    final others = defaults.where((m) => !relevantCategories.contains(m.category)).toList();
    return [...matched, ...others];
  }

  static bool isRelevantForMotive(GuidedMeditation meditation, String? motive) {
    if (motive == null) return true;
    final Map<String, List<MeditationCategory>> motiveMapping = {
      'Sleep': [MeditationCategory.sleep, MeditationCategory.stress],
      'Stress': [MeditationCategory.stress, MeditationCategory.mindfulness, MeditationCategory.compassion],
      'Anxiety': [MeditationCategory.anxiety, MeditationCategory.mindfulness, MeditationCategory.stress],
      'Focus': [MeditationCategory.focus, MeditationCategory.mindfulness],
      'Habit Building': [MeditationCategory.mindfulness, MeditationCategory.compassion],
    };
    final relevantCategories = motiveMapping[motive] ?? [];
    return relevantCategories.contains(meditation.category);
  }
}
