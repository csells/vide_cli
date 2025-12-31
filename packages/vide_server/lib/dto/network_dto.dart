import 'dart:convert';

/// Request to create a new agent network
class CreateNetworkRequest {
  final String initialMessage;
  final String workingDirectory;

  CreateNetworkRequest({
    required this.initialMessage,
    required this.workingDirectory,
  });

  factory CreateNetworkRequest.fromJson(Map<String, dynamic> json) {
    return CreateNetworkRequest(
      initialMessage: json['initialMessage'] as String,
      workingDirectory: json['workingDirectory'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'initialMessage': initialMessage,
    'workingDirectory': workingDirectory,
  };
}

/// Response from creating a new agent network
class CreateNetworkResponse {
  final String networkId;
  final String mainAgentId;
  final DateTime createdAt;

  CreateNetworkResponse({
    required this.networkId,
    required this.mainAgentId,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'networkId': networkId,
    'mainAgentId': mainAgentId,
    'createdAt': createdAt.toIso8601String(),
  };

  String toJsonString() => jsonEncode(toJson());
}

/// Request to send a message to an agent network
class SendMessageRequest {
  final String content;

  SendMessageRequest({required this.content});

  factory SendMessageRequest.fromJson(Map<String, dynamic> json) {
    return SendMessageRequest(content: json['content'] as String);
  }

  Map<String, dynamic> toJson() => {'content': content};
}

/// WebSocket event for agent streaming
class WebSocketEvent {
  final String agentId;
  final String agentType;
  final String? agentName;
  final String? taskName;
  final String type;
  final dynamic data;
  final DateTime timestamp;

  WebSocketEvent({
    required this.agentId,
    required this.agentType,
    this.agentName,
    this.taskName,
    required this.type,
    this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'agentId': agentId,
    'agentType': agentType,
    if (agentName != null) 'agentName': agentName,
    if (taskName != null) 'taskName': taskName,
    'type': type,
    if (data != null) 'data': data,
    'timestamp': timestamp.toIso8601String(),
  };

  /// Format as JSON string for WebSocket transmission
  String toJsonString() {
    return jsonEncode(toJson());
  }

  /// Create a message event
  factory WebSocketEvent.message({
    required String agentId,
    required String agentType,
    String? agentName,
    String? taskName,
    required String content,
    required String role,
  }) {
    return WebSocketEvent(
      agentId: agentId,
      agentType: agentType,
      agentName: agentName,
      taskName: taskName,
      type: 'message',
      data: {'role': role, 'content': content},
    );
  }

  /// Create a message delta event (streaming chunk)
  factory WebSocketEvent.messageDelta({
    required String agentId,
    required String agentType,
    String? agentName,
    String? taskName,
    required String delta,
    required String role,
  }) {
    return WebSocketEvent(
      agentId: agentId,
      agentType: agentType,
      agentName: agentName,
      taskName: taskName,
      type: 'message_delta',
      data: {'role': role, 'delta': delta},
    );
  }

  /// Create a tool use event
  factory WebSocketEvent.toolUse({
    required String agentId,
    required String agentType,
    String? agentName,
    String? taskName,
    required String toolName,
    required Map<String, dynamic> toolInput,
  }) {
    return WebSocketEvent(
      agentId: agentId,
      agentType: agentType,
      agentName: agentName,
      taskName: taskName,
      type: 'tool_use',
      data: {'toolName': toolName, 'toolInput': toolInput},
    );
  }

  /// Create a tool result event
  factory WebSocketEvent.toolResult({
    required String agentId,
    required String agentType,
    String? agentName,
    String? taskName,
    required String toolName,
    required dynamic result,
    bool? isError,
  }) {
    return WebSocketEvent(
      agentId: agentId,
      agentType: agentType,
      agentName: agentName,
      taskName: taskName,
      type: 'tool_result',
      data: {
        'toolName': toolName,
        'result': result,
        if (isError != null) 'isError': isError,
      },
    );
  }

  /// Create a done event (conversation turn complete)
  factory WebSocketEvent.done({
    required String agentId,
    required String agentType,
    String? agentName,
    String? taskName,
  }) {
    return WebSocketEvent(
      agentId: agentId,
      agentType: agentType,
      agentName: agentName,
      taskName: taskName,
      type: 'done',
    );
  }

  /// Create an error event
  factory WebSocketEvent.error({
    required String agentId,
    required String agentType,
    String? agentName,
    String? taskName,
    required String message,
    String? stack,
  }) {
    return WebSocketEvent(
      agentId: agentId,
      agentType: agentType,
      agentName: agentName,
      taskName: taskName,
      type: 'error',
      data: {'message': message, if (stack != null) 'stack': stack},
    );
  }

  /// Create a status event (agent status change)
  factory WebSocketEvent.status({
    required String agentId,
    required String agentType,
    String? agentName,
    String? taskName,
    required String status,
  }) {
    return WebSocketEvent(
      agentId: agentId,
      agentType: agentType,
      agentName: agentName,
      taskName: taskName,
      type: 'status',
      data: {'status': status},
    );
  }
}
