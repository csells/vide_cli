/// Prompt builder for summarizing code changes in plain English.
class ChangeSummaryPrompt {
  static String build(String oldCode, String newCode, String? filePath) {
    return '''
You are summarizing a code change in plain English.

FILE: ${filePath ?? 'unknown'}

BEFORE:
```
$oldCode
```

AFTER:
```
$newCode
```

RULES:
- ONE sentence summary of what changed
- Plain English, no jargon
- Focus on the "what" and "why" if apparent
- Examples:
  - "Added null check before accessing user data"
  - "Refactored login function to use async/await instead of callbacks"
  - "Fixed typo in error message"
- No emojis
- Output ONLY the summary
''';
  }
}
