import 'package:nocterm_riverpod/nocterm_riverpod.dart';

/// Dynamic loading words - shown during agent processing
final loadingWordsProvider = StateProvider<List<String>?>((ref) => null);

/// Startup horoscope - generated once on app start
final horoscopeProvider = StateProvider<String?>((ref) => null);

/// Startup tip - generated based on project context
final startupTipProvider = StateProvider<String?>((ref) => null);

/// Dynamic placeholder text for input field
final placeholderTextProvider = StateProvider<String?>((ref) => null);

/// Idle detector message - shown after inactivity
final idleMessageProvider = StateProvider<String?>((ref) => null);

/// Activity tip - shown during long operations
final activityTipProvider = StateProvider<String?>((ref) => null);

/// Fortune cookie - dev wisdom
final fortuneProvider = StateProvider<String?>((ref) => null);

/// Code sommelier commentary
final codeSommelierProvider = StateProvider<String?>((ref) => null);

/// Sub-agent progress summary
final agentProgressSummaryProvider = StateProvider<String?>((ref) => null);

/// Code change summary
final changeSummaryProvider = StateProvider<String?>((ref) => null);

/// Error triage result
final errorTriageProvider = StateProvider<String?>((ref) => null);

/// Task complexity estimate
final complexityEstimateProvider = StateProvider<String?>((ref) => null);

/// Long response TL;DR
final tldrProvider = StateProvider<String?>((ref) => null);
