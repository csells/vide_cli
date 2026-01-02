import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'src/key_injector.dart';

void main() {
  runApp(const KeyInjectionDemoApp());
}

class KeyInjectionDemoApp extends StatelessWidget {
  const KeyInjectionDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Key Injection Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const DemoPage(),
    );
  }
}

class DemoPage extends StatefulWidget {
  const DemoPage({super.key});

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  // Controllers for TextFields
  final _textFieldController = TextEditingController();
  final _multilineController = TextEditingController();

  // State for raw key listener
  final _rawKeyEvents = <String>[];
  final _rawKeyFocusNode = FocusNode(debugLabel: 'RawKeyListener');

  // State for Focus-based listener
  final _focusKeyEvents = <String>[];
  final _focusFocusNode = FocusNode(debugLabel: 'FocusWidget');

  // Injection text input
  final _injectionController = TextEditingController(text: 'Hello World!');

  // Status log
  final _statusLog = <String>[];

  @override
  void dispose() {
    _textFieldController.dispose();
    _multilineController.dispose();
    _rawKeyFocusNode.dispose();
    _focusFocusNode.dispose();
    _injectionController.dispose();
    super.dispose();
  }

  void _addStatus(String status) {
    setState(() {
      _statusLog.insert(0, '[${DateTime.now().toString().substring(11, 19)}] $status');
      if (_statusLog.length > 50) {
        _statusLog.removeLast();
      }
    });
  }

  Future<void> _injectText() async {
    final text = _injectionController.text;
    if (text.isEmpty) {
      _addStatus('No text to inject');
      return;
    }

    final info = KeyInjector.getFocusedWidgetInfo();
    if (info == null) {
      _addStatus('No widget focused!');
      return;
    }

    _addStatus('Focused: ${info.widgetType}');
    _addStatus('  hasTextInputClient: ${info.hasTextInputClient}');
    _addStatus('  hasOnKeyEvent: ${info.hasOnKeyEvent}');

    final result = await KeyInjector.injectText(text);
    _addStatus('Injection result: ${result.success ? "SUCCESS" : "FAILED"}');
    _addStatus('  method: ${result.method.name}');
    if (result.error != null) {
      _addStatus('  error: ${result.error}');
    }
  }

  Future<void> _injectSpecialKeys() async {
    final info = KeyInjector.getFocusedWidgetInfo();
    if (info == null) {
      _addStatus('No widget focused!');
      return;
    }

    _addStatus('Testing special keys...');
    await KeyInjector.injectText('ABC{backspace}{backspace}12{enter}Done');
    _addStatus('Sent: ABC{backspace}{backspace}12{enter}Done');
  }

  Future<void> _injectModifierCombo() async {
    final info = KeyInjector.getFocusedWidgetInfo();
    if (info == null) {
      _addStatus('No widget focused!');
      return;
    }

    _addStatus('Testing Ctrl+A (select all)...');
    await KeyInjector.injectText('{ctrl+a}');
    _addStatus('Sent: {ctrl+a}');
  }

  Future<void> _injectArrowKeys() async {
    final info = KeyInjector.getFocusedWidgetInfo();
    if (info == null) {
      _addStatus('No widget focused!');
      return;
    }

    _addStatus('Testing arrow keys...');
    await KeyInjector.injectText('{left}{left}{right}{up}{down}');
    _addStatus('Sent: {left}{left}{right}{up}{down}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Key Injection Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Row(
        children: [
          // Left panel: Input widgets to test
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSectionHeader('1. Standard TextField (TextInputClient)'),
                  TextField(
                    controller: _textFieldController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Click here, then inject text',
                      helperText: 'Uses TextInputClient.updateEditingValue()',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Current value: "${_textFieldController.text}"',
                      style: Theme.of(context).textTheme.bodySmall),

                  const SizedBox(height: 24),
                  _buildSectionHeader('2. Multiline TextField (TextInputClient)'),
                  TextField(
                    controller: _multilineController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Multiline text field',
                      helperText: 'Test {enter} key for newlines',
                    ),
                  ),

                  const SizedBox(height: 24),
                  _buildSectionHeader('3. RawKeyboardListener (deprecated but common)'),
                  _buildRawKeyboardListenerWidget(),

                  const SizedBox(height: 24),
                  _buildSectionHeader('4. Focus with onKeyEvent (recommended)'),
                  _buildFocusKeyEventWidget(),

                  const SizedBox(height: 24),
                  _buildSectionHeader('5. Custom TextInputClient Widget'),
                  const CustomTextInputWidget(),
                ],
              ),
            ),
          ),

          // Divider
          const VerticalDivider(width: 1),

          // Right panel: Controls and status
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSectionHeader('Injection Controls'),
                  TextField(
                    controller: _injectionController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Text to inject',
                      helperText: 'Use {enter}, {ctrl+c}, etc.',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _injectText,
                        icon: const Icon(Icons.keyboard),
                        label: const Text('Inject Text'),
                      ),
                      ElevatedButton(
                        onPressed: _injectSpecialKeys,
                        child: const Text('Test Special'),
                      ),
                      ElevatedButton(
                        onPressed: _injectModifierCombo,
                        child: const Text('Test Ctrl+A'),
                      ),
                      ElevatedButton(
                        onPressed: _injectArrowKeys,
                        child: const Text('Test Arrows'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      final info = KeyInjector.getFocusedWidgetInfo();
                      if (info != null) {
                        _addStatus(info.toString());
                      } else {
                        _addStatus('No focused widget');
                      }
                    },
                    child: const Text('Show Focus Info'),
                  ),

                  const SizedBox(height: 24),
                  _buildSectionHeader('Status Log'),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                        color: Colors.grey[100],
                      ),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _statusLog.length,
                        itemBuilder: (context, index) {
                          return Text(
                            _statusLog[index],
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => setState(() => _statusLog.clear()),
                    child: const Text('Clear Log'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildRawKeyboardListenerWidget() {
    return Focus(
      focusNode: _rawKeyFocusNode,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          setState(() {
            _rawKeyEvents.insert(
                0, '${event.logicalKey.keyLabel} (${event.character ?? "no char"})');
            if (_rawKeyEvents.length > 10) _rawKeyEvents.removeLast();
          });
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: () => _rawKeyFocusNode.requestFocus(),
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            border: Border.all(
              color: _rawKeyFocusNode.hasFocus ? Colors.blue : Colors.grey,
              width: _rawKeyFocusNode.hasFocus ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _rawKeyFocusNode.hasFocus
                    ? 'FOCUSED - Press keys or inject'
                    : 'Click to focus',
                style: TextStyle(
                  color: _rawKeyFocusNode.hasFocus ? Colors.blue : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Text(
                  _rawKeyEvents.isEmpty
                      ? 'No key events yet...'
                      : _rawKeyEvents.join(', '),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFocusKeyEventWidget() {
    return Focus(
      focusNode: _focusFocusNode,
      onKeyEvent: (node, event) {
        setState(() {
          final type = event is KeyDownEvent
              ? 'DOWN'
              : event is KeyUpEvent
                  ? 'UP'
                  : 'REPEAT';
          _focusKeyEvents.insert(
              0, '$type: ${event.logicalKey.keyLabel}');
          if (_focusKeyEvents.length > 10) _focusKeyEvents.removeLast();
        });
        // Return ignored to let events propagate
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: () => _focusFocusNode.requestFocus(),
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            border: Border.all(
              color: _focusFocusNode.hasFocus ? Colors.green : Colors.grey,
              width: _focusFocusNode.hasFocus ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(4),
            color: _focusFocusNode.hasFocus ? Colors.green[50] : null,
          ),
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _focusFocusNode.hasFocus
                    ? 'FOCUSED - Using Focus.onKeyEvent'
                    : 'Click to focus',
                style: TextStyle(
                  color: _focusFocusNode.hasFocus ? Colors.green : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Text(
                  _focusKeyEvents.isEmpty
                      ? 'No key events yet...'
                      : _focusKeyEvents.join(', '),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A custom widget that implements TextInputClient directly.
/// This tests that the injector can find TextInputClient in the tree.
class CustomTextInputWidget extends StatefulWidget {
  const CustomTextInputWidget({super.key});

  @override
  State<CustomTextInputWidget> createState() => _CustomTextInputWidgetState();
}

class _CustomTextInputWidgetState extends State<CustomTextInputWidget>
    with TextInputClient {
  final _focusNode = FocusNode(debugLabel: 'CustomTextInput');
  TextEditingValue _value = TextEditingValue.empty;
  TextInputConnection? _connection;

  @override
  void dispose() {
    _focusNode.dispose();
    _connection?.close();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      _connection = TextInput.attach(this, const TextInputConfiguration(
        inputType: TextInputType.text,
        inputAction: TextInputAction.done,
      ));
      _connection!.show();
      _connection!.setEditingState(_value);
    } else {
      _connection?.close();
      _connection = null;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onFocusChange: (_) => _onFocusChange(),
      child: GestureDetector(
        onTap: () => _focusNode.requestFocus(),
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            border: Border.all(
              color: _focusNode.hasFocus ? Colors.purple : Colors.grey,
              width: _focusNode.hasFocus ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(4),
            color: _focusNode.hasFocus ? Colors.purple[50] : null,
          ),
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _focusNode.hasFocus
                    ? 'FOCUSED - Custom TextInputClient'
                    : 'Click to focus (implements TextInputClient)',
                style: TextStyle(
                  color: _focusNode.hasFocus ? Colors.purple : Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              Text(
                'Value: "${_value.text}"',
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // TextInputClient implementation
  @override
  TextEditingValue? get currentTextEditingValue => _value;

  @override
  void updateEditingValue(TextEditingValue value) {
    setState(() {
      _value = value;
    });
  }

  @override
  void performAction(TextInputAction action) {
    if (action == TextInputAction.done) {
      _focusNode.unfocus();
    }
  }

  @override
  AutofillScope? get currentAutofillScope => null;

  @override
  void showAutocorrectionPromptRect(int start, int end) {}

  @override
  void performPrivateCommand(String action, Map<String, dynamic> data) {}

  @override
  void updateFloatingCursor(RawFloatingCursorPoint point) {}

  @override
  void connectionClosed() {
    _connection = null;
  }

  @override
  void insertTextPlaceholder(Size size) {}

  @override
  void removeTextPlaceholder() {}

  @override
  void showToolbar() {}

  @override
  void insertContent(KeyboardInsertedContent content) {}

  @override
  void didChangeInputControl(TextInputControl? oldControl, TextInputControl? newControl) {}

  @override
  void performSelector(String selectorName) {}
}
