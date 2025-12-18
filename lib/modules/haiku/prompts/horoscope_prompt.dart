/// Prompt builder for satirical developer horoscopes
class HoroscopePrompt {
  static String build(DateTime now) {
    final dayOfWeek = _getDayName(now.weekday);
    final hour = now.hour;

    return '''
You are a satirical developer horoscope generator. Generate ONE developer horoscope.

CONTEXT:
- Day: $dayOfWeek
- Hour: $hour

RULES:
- ONE paragraph, 2-3 sentences max
- Confident nonsense delivered with authority
- Developer-specific predictions (bugs, PRs, meetings, coffee)
- Examples of tone:
  - "The stars suggest an off-by-one error today. The stars are always right about off-by-one errors."
  - "Mercury is in retrograde, which explains why your deploys will be too."
  - "Today's forecast: High chance of forgetting which tab has the bug."
- Dry, self-aware humor
- NO emojis
- Output ONLY the horoscope text
''';
  }

  static String _getDayName(int weekday) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[weekday - 1];
  }
}
