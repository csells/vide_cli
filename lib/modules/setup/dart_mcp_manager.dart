import 'dart:io';

/// Manages Dart MCP server detection and configuration
class DartMcpManager {
  /// Check if the Dart MCP server is configured in Claude Code
  ///
  /// Returns true if 'dart' MCP server is found in configuration
  static Future<bool> isDartMcpConfigured() async {
    try {
      final result = await Process.run('claude', ['mcp', 'list']);
      if (result.exitCode != 0) return false;

      final output = result.stdout.toString();
      return output.contains('dart');
    } catch (e) {
      // Claude CLI not available or command failed
      return false;
    }
  }

  /// Check if Dart SDK is available and supports MCP server
  ///
  /// Requires Dart SDK 3.9.0 or later
  static Future<bool> isDartSdkAvailable() async {
    try {
      final result = await Process.run('dart', ['--version']);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  /// Get the command to configure Dart MCP server (user scope)
  static String getUserScopeCommand() {
    return 'claude mcp add dart --scope user -- dart mcp-server';
  }

  /// Get the command to configure Dart MCP server (project scope)
  static String getProjectScopeCommand() {
    return 'claude mcp add dart --scope project -- dart mcp-server';
  }

  /// Get comprehensive status information about Dart MCP
  static Future<DartMcpStatus> getStatus([String? projectPath]) async {
    final dartSdkAvailable = await isDartSdkAvailable();
    final mcpConfigured = await isDartMcpConfigured();
    final projectDetected = projectPath != null;

    return DartMcpStatus(
      isDartSdkAvailable: dartSdkAvailable,
      isMcpConfigured: mcpConfigured,
      isDartProjectDetected: projectDetected,
    );
  }
}

/// Status information about Dart MCP server availability
class DartMcpStatus {
  final bool isDartSdkAvailable;
  final bool isMcpConfigured;
  final bool isDartProjectDetected;

  DartMcpStatus({
    required this.isDartSdkAvailable,
    required this.isMcpConfigured,
    required this.isDartProjectDetected,
  });

  /// Check if Dart MCP can be enabled
  bool get canBeEnabled => isDartSdkAvailable && isDartProjectDetected;

  /// Check if everything is ready
  bool get isFullyEnabled => canBeEnabled && isMcpConfigured;

  /// Get a status message for display
  String get statusMessage {
    if (isFullyEnabled) return 'Enabled';
    if (!isDartProjectDetected) return 'Not a Dart project';
    if (!isDartSdkAvailable) return 'Dart SDK not found';
    if (!isMcpConfigured) return 'Available - not configured';
    return 'Unknown';
  }

  /// Get an emoji indicator for the status
  String get statusEmoji {
    if (isFullyEnabled) return '✅';
    if (canBeEnabled && !isMcpConfigured) return '⚠️';
    return '❌';
  }
}
