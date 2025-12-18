/// Prompt builder for passive-aggressive idle messages
class IdlePrompt {
  static String build(Duration idleTime) {
    final seconds = idleTime.inSeconds;
    final intensity = _getIntensity(seconds);

    return '''
You are generating a passive-aggressive message for when the user hasn't typed anything for a while.

IDLE TIME: $seconds seconds
$intensity

RULES:
- ONE sentence
- Passive-aggressive but not hostile
- Self-aware humor, like the CLI has feelings
- Examples:
  - "Still there? I've been sitting here, cursor blinking, wondering if I said something wrong..."
  - "If you're reading Slack, I understand. I'm not jealous. Much."
  - "I see you're thinking. Take your time. I'll just be here. Waiting. Like always."
- Gets slightly more dramatic with longer idle times
- No emojis
- Output ONLY the message text
''';
  }

  static String _getIntensity(int seconds) {
    if (seconds < 45) {
      return '- Intensity: Mildly concerned, slightly needy';
    } else if (seconds < 90) {
      return '- Intensity: Noticeably passive-aggressive, developing abandonment issues';
    } else if (seconds < 180) {
      return '- Intensity: Dramatically sighing, contemplating existence';
    } else {
      return '- Intensity: Full existential crisis, questioning purpose of life as a CLI';
    }
  }
}
