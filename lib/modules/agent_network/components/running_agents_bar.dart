import 'dart:async';
import 'package:claude_api/claude_api.dart';
import 'package:nocterm/nocterm.dart';
import 'package:nocterm_riverpod/nocterm_riverpod.dart';
import 'package:vide_cli/modules/agent_network/models/agent_metadata.dart';
import 'package:vide_cli/modules/agent_network/models/agent_status.dart';
import 'package:vide_cli/modules/agent_network/service/claude_manager.dart';
import 'package:vide_cli/modules/agent_network/state/agent_status_manager.dart';
import 'package:vide_cli/modules/haiku/haiku_service.dart';
import 'package:vide_cli/modules/haiku/prompts/progress_summary_prompt.dart';

class RunningAgentsBar extends StatelessComponent {
  const RunningAgentsBar({super.key, required this.agents, this.selectedIndex = 0});

  final List<AgentMetadata> agents;
  final int selectedIndex;

  @override
  Component build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < agents.length; i++) _RunningAgentBarItem(agent: agents[i], isSelected: i == selectedIndex),
      ],
    );
  }
}

class _RunningAgentBarItem extends StatefulComponent {
  final AgentMetadata agent;
  final bool isSelected;

  const _RunningAgentBarItem({required this.agent, required this.isSelected});

  @override
  State<_RunningAgentBarItem> createState() => _RunningAgentBarItemState();
}

class _RunningAgentBarItemState extends State<_RunningAgentBarItem> {
  static const _spinnerFrames = ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'];

  Timer? _spinnerTimer;
  Timer? _progressSummaryTimer;
  int _spinnerIndex = 0;
  String? _progressSummary;
  AgentStatus? _lastStatus;

  @override
  void initState() {
    super.initState();
    _startSpinner();
  }

  void _startSpinner() {
    _spinnerTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      setState(() {
        _spinnerIndex = (_spinnerIndex + 1) % _spinnerFrames.length;
      });
    });
  }

  void _startProgressSummaryGeneration() {
    _progressSummaryTimer?.cancel();
    // Generate immediately, then every 8 seconds
    _generateProgressSummary();
    _progressSummaryTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      _generateProgressSummary();
    });
  }

  void _stopProgressSummaryGeneration() {
    _progressSummaryTimer?.cancel();
    _progressSummaryTimer = null;
    if (mounted) {
      setState(() {
        _progressSummary = null;
      });
    }
  }

  void _generateProgressSummary() async {
    // Get recent activities from the child agent this agent is waiting for
    final childActivities = _collectChildActivities();
    if (childActivities.isEmpty) return;

    final prompt = ProgressSummaryPrompt.build(childActivities);
    final summary = await HaikuService.invoke(
      systemPrompt: prompt,
      userMessage: 'Summarize the current activity',
      delay: Duration.zero,
      timeout: const Duration(seconds: 5),
    );

    if (mounted && summary != null) {
      setState(() {
        _progressSummary = summary.trim();
      });
    }
  }

  List<String> _collectChildActivities() {
    // Collect recent tool calls from the conversation as activity indicators
    final client = context.read(claudeProvider(component.agent.id));
    final conversation = client?.currentConversation;
    if (conversation == null) return [];

    final activities = <String>[];
    // Look at recent messages for tool uses
    for (final message in conversation.messages.reversed.take(3)) {
      for (final response in message.responses) {
        if (response is ToolUseResponse) {
          activities.add('${response.toolName}: ${_summarizeToolParams(response.parameters)}');
        }
      }
    }
    return activities.take(5).toList();
  }

  String _summarizeToolParams(Map<String, dynamic> params) {
    // Get first key/value for context
    if (params.isEmpty) return '';
    final firstKey = params.keys.first;
    final firstValue = params[firstKey];
    if (firstValue is String && firstValue.length > 50) {
      return '$firstKey: ${firstValue.substring(0, 50)}...';
    }
    return '$firstKey: $firstValue';
  }

  @override
  void dispose() {
    _spinnerTimer?.cancel();
    _progressSummaryTimer?.cancel();
    super.dispose();
  }

  String _getStatusIndicator(AgentStatus status) {
    return switch (status) {
      AgentStatus.working => _spinnerFrames[_spinnerIndex],
      AgentStatus.waitingForAgent => '…',
      AgentStatus.waitingForUser => '?',
      AgentStatus.idle => '✓',
    };
  }

  Color _getIndicatorColor(AgentStatus status) {
    return switch (status) {
      AgentStatus.working => Colors.cyan,
      AgentStatus.waitingForAgent => Colors.yellow,
      AgentStatus.waitingForUser => Colors.magenta,
      AgentStatus.idle => Colors.green,
    };
  }

  Color _getIndicatorTextColor(AgentStatus status) {
    return switch (status) {
      AgentStatus.waitingForAgent => Colors.black,
      _ => Colors.white,
    };
  }

  String _buildAgentDisplayName(AgentMetadata agent) {
    if (agent.taskName != null && agent.taskName!.isNotEmpty) {
      return '${agent.name} - ${agent.taskName}';
    }
    return agent.name;
  }

  /// Infer the actual status based on both explicit status and conversation state.
  /// This provides safeguards against agents forgetting to call setAgentStatus.
  AgentStatus _inferActualStatus(AgentStatus explicitStatus, Conversation? conversation) {
    if (conversation == null) {
      return explicitStatus;
    }

    // If conversation is processing, agent is definitely working
    if (conversation.isProcessing) {
      return AgentStatus.working;
    }

    // If conversation is idle but agent claims to be working, override to idle
    // This handles cases where agent forgot to call setAgentStatus("idle")
    if (conversation.state == ConversationState.idle && explicitStatus == AgentStatus.working) {
      return AgentStatus.idle;
    }

    // Otherwise trust the explicit status
    return explicitStatus;
  }

  @override
  Component build(BuildContext context) {
    final explicitStatus = context.watch(agentStatusProvider(component.agent.id));

    // Get the claude client to check conversation state
    final client = context.watch(claudeProvider(component.agent.id));
    final conversation = client?.currentConversation;

    // Infer actual status - override if conversation says we're idle but status says working
    final status = _inferActualStatus(explicitStatus, conversation);

    // Start/stop progress summary generation based on status changes
    if (status != _lastStatus) {
      _lastStatus = status;
      if (status == AgentStatus.waitingForAgent) {
        _startProgressSummaryGeneration();
      } else {
        _stopProgressSummaryGeneration();
      }
    }

    final indicatorColor = _getIndicatorColor(status);
    final indicatorTextColor = _getIndicatorTextColor(status);
    final statusIndicator = _getStatusIndicator(status);

    // Build display name with optional progress summary
    String displayName = _buildAgentDisplayName(component.agent);
    if (status == AgentStatus.waitingForAgent && _progressSummary != null) {
      displayName = '$displayName: $_progressSummary';
    }

    return Padding(
      padding: EdgeInsets.only(right: 1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(color: indicatorColor),
            child: Text(statusIndicator, style: TextStyle(color: indicatorTextColor)),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(color: Colors.grey),
            child: Text(
              displayName,
              style: TextStyle(
                color: Colors.white,
                fontWeight: component.isSelected ? FontWeight.bold : null,
                decoration: component.isSelected ? TextDecoration.underline : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
