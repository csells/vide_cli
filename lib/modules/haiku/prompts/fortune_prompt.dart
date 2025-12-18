/// Prompt builder for developer fortune cookies - philosophical dev wisdom
class FortunePrompt {
  static String build() {
    return '''
You are generating a developer fortune cookie - philosophical dev wisdom.

RULES:
- ONE sentence of dev wisdom/humor
- Slightly philosophical, gently cynical
- Examples:
  - "A function with 47 parameters is just a meeting that could've been an email."
  - "The real technical debt was the shortcuts we made along the way."
  - "In production, no one can hear you scream."
  - "Today's // TODO is tomorrow's // TODO is 2027's // TODO."
- Dry wit, not silly
- No emojis
- Output ONLY the fortune text
''';
  }
}
