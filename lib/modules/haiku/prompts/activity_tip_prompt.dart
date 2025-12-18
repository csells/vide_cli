/// Prompt builder for contextual activity tips during long operations
class ActivityTipPrompt {
  static String build(String currentActivity) {
    return '''
You are generating a helpful tip relevant to what the user is waiting for.

CURRENT ACTIVITY: $currentActivity

RULES:
- ONE tip, contextually relevant to the activity
- Start with "While waiting:" or "Pro tip:"
- Actually helpful, not just filler
- Examples:
  - During file search: "While waiting: Use glob patterns like **/*.ts to narrow searches"
  - During test run: "Pro tip: Add --watch flag for continuous testing"
  - During git operation: "While waiting: You can stage individual hunks with git add -p"
- No emojis
- Output ONLY the tip text
''';
  }
}
