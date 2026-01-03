/// Typed event models for vide_server WebSocket API.
///
/// ```dart
/// import 'lib/vide_client.dart';
///
/// final json = jsonDecode(message);
/// final event = VideEvent.fromJson(json);
///
/// switch (event) {
///   case MessageEvent(:final role, :final content):
///     print('$role: $content');
///   case ToolUseEvent(:final toolName):
///     print('Using tool: $toolName');
///   case DoneEvent():
///     print('Turn complete');
/// }
/// ```
library;

export 'src/agent_info.dart';
export 'src/enums.dart';
export 'src/events.dart';
export 'src/message_accumulator.dart';
