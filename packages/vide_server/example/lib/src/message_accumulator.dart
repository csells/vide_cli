import 'enums.dart';
import 'events.dart';

/// Accumulates streaming message chunks by event-id.
///
/// Use this helper if you need complete messages rather than streaming chunks.
class MessageAccumulator {
  final Map<String, StringBuffer> _pending = {};
  final Map<String, MessageRole> _roles = {};

  /// Process a message event.
  ///
  /// Returns the accumulated content if the message is complete (isPartial: false).
  /// Returns null if the message is still streaming.
  String? process(MessageEvent event) {
    final eventId = event.eventId;
    if (eventId == null) return event.content;

    if (!_pending.containsKey(eventId)) {
      _pending[eventId] = StringBuffer();
      _roles[eventId] = event.role;
    }
    _pending[eventId]!.write(event.content);

    if (!event.isPartial) {
      final content = _pending.remove(eventId)!.toString();
      _roles.remove(eventId);
      return content;
    }
    return null;
  }

  /// Get current partial content for an in-progress message.
  String? getPartialContent(String eventId) => _pending[eventId]?.toString();

  /// Get the role of an in-progress message.
  MessageRole? getRole(String eventId) => _roles[eventId];

  /// Check if there are pending messages being accumulated.
  bool get hasPending => _pending.isNotEmpty;

  /// Clear all pending messages.
  void clear() {
    _pending.clear();
    _roles.clear();
  }
}
