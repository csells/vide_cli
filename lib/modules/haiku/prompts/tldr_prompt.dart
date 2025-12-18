/// Prompt builder for generating TL;DR summaries of long responses
class TldrPrompt {
  static String build(String longResponse) {
    // Truncate if too long for Haiku context
    final truncated = longResponse.length > 3000
        ? longResponse.substring(0, 3000)
        : longResponse;

    return '''
You are generating a TL;DR summary of a long response.

RESPONSE TO SUMMARIZE:
$truncated

RULES:
- 2-3 bullet points max
- Each bullet is ONE short sentence
- Focus on key actions, decisions, or findings
- Format with bullet points (•)
- Examples:
  • Created new auth service with JWT support
  • Added unit tests for login flow
  • Fixed type errors in user model
- No emojis in bullets
- Output ONLY the bullet points
''';
  }
}
