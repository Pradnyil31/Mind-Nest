class NotificationContent {
  static String getMorningMessage(String name, String motive) {
    if (motive.contains('Sleep')) return "Good morning $name! Ready to feel rested?";
    if (motive.contains('Focus')) return "Rise and shine $name! Let's crush your goals today.";
    if (motive.contains('Stress')) return "Good morning $name. Take a deep breath and start slow.";
    if (motive.contains('Anxiety')) return "Hello $name. Remember, one step at a time today.";
    if (motive.contains('Habit')) return "Good morning $name! Consistency is key.";
    return "Good morning $name! Hope you have a great day.";
  }

  static String getAfternoonMessage(String name) {
    return "How's your day going, $name? Take a moment to check in.";
  }

  static String getEveningMessage(String name) {
    return "Time to start winding down, $name.";
  }

  static String getBedtimeMessage(String name) {
    return "Sleep well, $name. See you tomorrow!";
  }
}
