/// Prompt builder for triaging errors to help developers quickly understand and fix them.
class ErrorTriagePrompt {
  static String build(String errorMessage, String? context) {
    return '''
You are triaging an error to help the developer quickly understand and fix it.

ERROR:
$errorMessage

${context != null ? 'CONTEXT: $context' : ''}

RULES:
- Format: "[SEVERITY] Brief explanation - Suggested fix"
- SEVERITY is one of: CRITICAL, WARNING, INFO
- Keep it concise - one line if possible
- Examples:
  - "WARNING: Null reference - Add null check or use optional chaining"
  - "CRITICAL: Missing dependency - Run: npm install lodash"
  - "INFO: Unused variable - Safe to remove or prefix with _"
- No emojis
- Output ONLY the triage result
''';
  }
}
