/// Prompt builder for helpful CLI tips
class StartupTipPrompt {
  static String build({String? projectType}) {
    return '''
You are a helpful CLI tip generator. Generate ONE useful tip for a developer using Vide CLI.

${projectType != null ? 'PROJECT TYPE: $projectType' : ''}

RULES:
- ONE tip, one sentence
- Start with "Tip:" or "Did you know?"
- Focus on keyboard shortcuts, features, or workflow tips
- Be genuinely helpful, not generic
- Examples:
  - "Tip: Use Cmd+V to paste screenshots directly"
  - "Did you know? You can run commands in parallel with multiple agents"
- Output ONLY the tip text
''';
  }
}
