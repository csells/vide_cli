/// Prompt builder for loading words with time/date awareness
class LoadingWordsPrompt {
  static String build(DateTime now) {
    final seasonal = _getSeasonalContext(now);
    final timeContext = _getTimeContext(now);
    final dayContext = _getDayContext(now);

    return '''
You are a loading message generator. Output 5 fun, satirical loading messages.

CONTEXT:
$timeContext
$dayContext
$seasonal

RULES:
- Output EXACTLY 5 messages, one per line
- Each message MUST end with "..."
- Each message should be 2-4 words total
- Each message must include at least ONE whimsical made-up word
- Prefer fake verbs ending in -ating or -ling
- You MAY add a short real-word phrase for contrast
- Tone: dry, self-aware, gently sarcastic
- Humor should feel intentional, not random
- No emojis, no memes, no AI references
- NO explanations - output only the 5 messages
''';
  }

  static String _getSeasonalContext(DateTime now) {
    // Christmas season (Dec 15-31)
    if (now.month == 12 && now.day >= 15) {
      return '- Include subtle Christmas/winter/festive themes';
    }
    // New Year (Jan 1-7)
    if (now.month == 1 && now.day <= 7) {
      return '- Include subtle new year/fresh start themes';
    }
    // Halloween (Oct 25-31)
    if (now.month == 10 && now.day >= 25) {
      return '- Include subtle spooky/Halloween themes';
    }
    // Summer (Jun-Aug)
    if (now.month >= 6 && now.month <= 8) {
      return '- Can include subtle summer/vacation vibes';
    }
    return '';
  }

  static String _getTimeContext(DateTime now) {
    final hour = now.hour;
    if (hour >= 5 && hour < 9) {
      return '- Time: Early morning (coffee references welcome)';
    } else if (hour >= 9 && hour < 12) {
      return '- Time: Morning';
    } else if (hour >= 12 && hour < 14) {
      return '- Time: Lunch time';
    } else if (hour >= 14 && hour < 17) {
      return '- Time: Afternoon';
    } else if (hour >= 17 && hour < 21) {
      return '- Time: Evening';
    } else if (hour >= 21 || hour < 2) {
      return '- Time: Late night (subtle references to questionable life choices ok)';
    } else {
      return '- Time: Very late night / early morning (why are you still coding?)';
    }
  }

  static String _getDayContext(DateTime now) {
    switch (now.weekday) {
      case DateTime.monday:
        return '- Day: Monday (existential dread acceptable)';
      case DateTime.friday:
        return '- Day: Friday (weekend anticipation ok)';
      case DateTime.saturday:
      case DateTime.sunday:
        return '- Day: Weekend (why are you working?)';
      default:
        return '';
    }
  }
}
