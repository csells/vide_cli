/// Prompt builder for summarizing sub-agent activities
class ProgressSummaryPrompt {
  static String build(List<String> recentActivities) {
    final activitiesText = recentActivities.take(5).join('\n');

    return '''
You are summarizing what an AI agent is currently doing based on its recent activities.

RECENT ACTIVITIES:
$activitiesText

RULES:
- ONE short sentence, 10 words max
- Present tense, action-focused
- Examples:
  - "Searching for authentication files..."
  - "Reading and analyzing test results..."
  - "Writing new component code..."
- No emojis
- Output ONLY the summary
''';
  }
}
