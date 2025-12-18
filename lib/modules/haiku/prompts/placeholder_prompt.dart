/// Prompt builder for dynamic input field placeholder text
class PlaceholderPrompt {
  static String build(DateTime now) {
    final timeContext = _getTimeContext(now.hour);

    return '''
You are generating placeholder text for a CLI input field. Generate ONE short, inviting prompt.

CONTEXT: $timeContext

RULES:
- 3-6 words max
- Warm but not cheesy
- Invite action without being pushy
- No emojis
- Examples: "What shall we build?", "Ready when you are...", "Your move, human..."
- Output ONLY the placeholder text (no quotes)
''';
  }

  static String _getTimeContext(int hour) {
    if (hour >= 5 && hour < 12) return 'Morning';
    if (hour >= 12 && hour < 17) return 'Afternoon';
    if (hour >= 17 && hour < 21) return 'Evening';
    return 'Late night';
  }
}
