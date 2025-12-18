import 'dart:io';
import 'package:nocterm/nocterm.dart';
import 'package:nocterm_riverpod/nocterm_riverpod.dart';
import 'package:claude_api/claude_api.dart';
import 'package:vide_cli/modules/agent_network/network_execution_page.dart';
import 'package:vide_cli/modules/agent_network/pages/networks_list_page.dart';
import 'package:vide_cli/modules/agent_network/service/agent_network_manager.dart';
import 'package:vide_cli/modules/agent_network/state/agent_networks_state_notifier.dart';
import 'package:vide_cli/components/attachment_text_field.dart';
import 'package:vide_cli/components/startup_banner.dart';
import 'package:vide_cli/modules/haiku/haiku_service.dart';
import 'package:vide_cli/modules/haiku/haiku_providers.dart';
import 'package:vide_cli/modules/haiku/prompts/loading_words_prompt.dart';
import 'package:vide_cli/modules/haiku/prompts/horoscope_prompt.dart';
import 'package:vide_cli/modules/haiku/prompts/startup_tip_prompt.dart';
import 'package:vide_cli/modules/haiku/prompts/placeholder_prompt.dart';
import 'package:vide_cli/utils/project_detector.dart';
import 'package:path/path.dart' as path;

class NetworksOverviewPage extends StatefulComponent {
  const NetworksOverviewPage({super.key});

  @override
  State<NetworksOverviewPage> createState() => _NetworksOverviewPageState();
}

class _NetworksOverviewPageState extends State<NetworksOverviewPage> {
  ProjectType? projectType;
  final _bannerKey = GlobalKey<StartupBannerState>();

  @override
  void initState() {
    super.initState();
    _loadProjectInfo();
    _generateStartupContent();
  }

  Future<void> _loadProjectInfo() async {
    final currentDir = Directory.current.path;
    final detectedType = ProjectDetector.detectProjectType(currentDir);

    if (mounted) {
      setState(() {
        projectType = detectedType;
      });
    }
  }

  /// Generate all startup content using HaikuService
  void _generateStartupContent() {
    final now = DateTime.now();

    // Pre-generate loading words for first message
    HaikuService.invokeForList(
      systemPrompt: LoadingWordsPrompt.build(now),
      userMessage: 'Generate loading words for: "Starting a new coding session"',
      delay: Duration.zero, // No delay on startup
    ).then((words) {
      if (mounted && words != null) {
        context.read(loadingWordsProvider.notifier).state = words;
      }
    });

    // Generate horoscope
    HaikuService.invoke(
      systemPrompt: HoroscopePrompt.build(now),
      userMessage: 'Generate a developer horoscope',
      delay: Duration.zero,
    ).then((horoscope) {
      if (mounted && horoscope != null) {
        context.read(horoscopeProvider.notifier).state = horoscope;
      }
    });

    // Generate startup tip (project-aware)
    final projectTypeStr = projectType?.name;
    HaikuService.invoke(
      systemPrompt: StartupTipPrompt.build(projectType: projectTypeStr),
      userMessage: 'Generate a startup tip',
      delay: Duration.zero,
    ).then((tip) {
      if (mounted && tip != null) {
        context.read(startupTipProvider.notifier).state = tip;
      }
    });

    // Generate dynamic placeholder
    HaikuService.invoke(
      systemPrompt: PlaceholderPrompt.build(now),
      userMessage: 'Generate placeholder text',
      delay: Duration.zero,
    ).then((placeholder) {
      if (mounted && placeholder != null) {
        context.read(placeholderTextProvider.notifier).state = placeholder;
      }
    });
  }

  void _handleSubmit(Message message) async {
    // Hide the startup banner when first message is sent
    _bannerKey.currentState?.hide();

    // Start a new agent network with the full message (preserves attachments)
    final network = await context.read(agentNetworkManagerProvider.notifier).startNew(message);

    // Update the networks list
    context.read(agentNetworksStateNotifierProvider.notifier).upsertNetwork(network);

    // Navigate to the execution page
    await NetworkExecutionPage.push(context, network.id);
  }

  @override
  Component build(BuildContext context) {
    // Get current directory name
    final currentDir = Directory.current.path;
    final dirName = path.basename(currentDir);

    // Get dynamic placeholder or use default
    final dynamicPlaceholder = context.watch(placeholderTextProvider);
    final placeholder = dynamicPlaceholder ?? 'Describe your goal (you can attach images)';

    return Focusable(
      focused: true,
      onKeyEvent: (event) {
        if (event.logicalKey == LogicalKey.tab) {
          NetworksListPage.push(context);
          return true;
        }
        return false;
      },
      child: Center(
        child: Container(
          padding: EdgeInsets.all(2),
          constraints: BoxConstraints(maxWidth: 120, maxHeight: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                dirName,
                style: TextStyle(decoration: TextDecoration.underline, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 1),
              // Project info badge
              if (projectType != null) ...[
                _ProjectTypeBadge(projectType: projectType!),
                const SizedBox(height: 1),
              ],
              // Startup banner (horoscope and tip)
              StartupBanner(key: _bannerKey),
              Container(
                child: AttachmentTextField(
                  focused: true,
                  placeholder: placeholder,
                  onSubmit: _handleSubmit,
                ),
                padding: EdgeInsets.all(1),
              ),
              const SizedBox(height: 2),
              Text('Tab: past networks & settings | Enter: start', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Project type badge component
class _ProjectTypeBadge extends StatelessComponent {
  const _ProjectTypeBadge({required this.projectType});

  final ProjectType projectType;

  @override
  Component build(BuildContext context) {
    String label;
    Color bgColor;

    switch (projectType) {
      case ProjectType.flutter:
        label = 'Flutter';
        bgColor = Color(0xFF02569B); // Flutter blue
        break;
      case ProjectType.dart:
        label = 'Dart';
        bgColor = Color(0xFF0175C2); // Dart blue
        break;
      case ProjectType.nocterm:
        label = 'Nocterm';
        bgColor = Color(0xFF9B30FF); // Purple
        break;
      case ProjectType.unknown:
        label = 'Unknown';
        bgColor = Colors.grey;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(color: bgColor),
      child: Text(
        label,
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}
