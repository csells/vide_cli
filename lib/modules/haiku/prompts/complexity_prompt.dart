/// Prompt builder for estimating task complexity
class ComplexityPrompt {
  static String build(String taskDescription) {
    return '''
You are estimating the complexity of a development task.

TASK: $taskDescription

RULES:
- Format: "[SIZE] - Brief explanation"
- SIZE is one of: SMALL, MEDIUM, LARGE
- SMALL: Single file, quick change
- MEDIUM: Multiple files, moderate changes
- LARGE: Architectural changes, many files
- Keep explanation to 5-10 words
- Examples:
  - "SMALL - Quick config update"
  - "MEDIUM - New component with tests"
  - "LARGE - Database schema migration needed"
- No emojis
- Output ONLY the estimation
''';
  }
}
