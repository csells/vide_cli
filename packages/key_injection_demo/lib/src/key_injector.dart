import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// A service for programmatically injecting text and key events into Flutter widgets.
///
/// This works with:
/// - TextField/TextFormField (via TextInputClient)
/// - RawKeyboardListener (via raw KeyEvent dispatch)
/// - Focus-based widgets (via FocusNode.onKeyEvent)
/// - Any widget implementing TextInputClient
class KeyInjector {
  /// Pattern to match special key sequences like {enter}, {ctrl+c}, {alt+shift+tab}
  static final _specialKeyPattern = RegExp(r'\{([^}]+)\}');

  /// Injects text into the currently focused widget.
  ///
  /// Supports special keys via curly braces:
  /// - `{enter}` - Enter/Return key
  /// - `{backspace}` - Backspace key
  /// - `{tab}` - Tab key
  /// - `{ctrl+c}` - Ctrl+C
  /// - `{cmd+v}` - Cmd+V (macOS)
  /// - `{shift+tab}` - Shift+Tab
  /// - `{f1}` through `{f12}` - Function keys
  /// - `{left}`, `{right}`, `{up}`, `{down}` - Arrow keys
  ///
  /// Example: `injectText("Hello{enter}World")` types "Hello", presses Enter, types "World"
  static Future<KeyInjectionResult> injectText(String text) async {
    final focusNode = FocusManager.instance.primaryFocus;
    if (focusNode == null) {
      return KeyInjectionResult(
        success: false,
        error: 'No widget has focus',
        method: InjectionMethod.none,
      );
    }

    final tokens = _parseText(text);
    final textInputClient = _findTextInputClient();
    final method = textInputClient != null
        ? InjectionMethod.textInputClient
        : InjectionMethod.rawKeyEvent;

    for (final token in tokens) {
      if (token.isSpecialKey) {
        await _handleSpecialKey(token.value);
      } else if (textInputClient != null) {
        await _insertViaTextInputClient(textInputClient, token.value);
      } else {
        // Fallback: raw key events for Focus-based widgets without TextInputClient
        for (final char in token.value.split('')) {
          await _simulateCharacterKeyPress(char);
          await Future.delayed(const Duration(milliseconds: 30));
        }
      }
    }

    return KeyInjectionResult(
      success: true,
      method: method,
      textInputClientFound: textInputClient != null,
    );
  }

  /// Sends a single key event (for testing raw key listeners).
  static Future<bool> sendKeyEvent({
    required LogicalKeyboardKey logicalKey,
    PhysicalKeyboardKey? physicalKey,
    String? character,
    bool isDown = true,
  }) async {
    final physical = physicalKey ?? _getPhysicalKeyForLogical(logicalKey);
    if (physical == null) return false;

    if (isDown) {
      return _sendKeyDown(
        physicalKey: physical,
        logicalKey: logicalKey,
        character: character,
      );
    } else {
      return _sendKeyUp(
        physicalKey: physical,
        logicalKey: logicalKey,
      );
    }
  }

  /// Gets diagnostic info about the currently focused widget.
  static FocusedWidgetInfo? getFocusedWidgetInfo() {
    final focusNode = FocusManager.instance.primaryFocus;
    if (focusNode == null) return null;

    final context = focusNode.context;
    final textInputClient = _findTextInputClient();

    return FocusedWidgetInfo(
      debugLabel: focusNode.debugLabel,
      hasTextInputClient: textInputClient != null,
      currentText: textInputClient?.currentTextEditingValue?.text,
      widgetType: context?.widget.runtimeType.toString(),
      hasOnKeyEvent: focusNode.onKeyEvent != null,
    );
  }

  // ============ Private Implementation ============

  /// Find a TextInputClient in the widget tree from the focused element.
  ///
  /// TextField's EditableTextState implements TextInputClient, but it's a
  /// DESCENDANT of the Focus widget, not an ancestor. We need to search
  /// both directions.
  static TextInputClient? _findTextInputClient() {
    final focusNode = FocusManager.instance.primaryFocus;
    if (focusNode == null) return null;

    final context = focusNode.context;
    if (context == null) return null;

    // First, check if the focused element itself is a TextInputClient
    if (context is StatefulElement && context.state is TextInputClient) {
      return context.state as TextInputClient;
    }

    // Search DESCENDANTS (children) - this is where EditableTextState lives
    TextInputClient? client;
    void visitChildren(Element element) {
      if (client != null) return; // Already found

      if (element is StatefulElement && element.state is TextInputClient) {
        client = element.state as TextInputClient;
        return;
      }
      element.visitChildren(visitChildren);
    }

    (context as Element).visitChildren(visitChildren);
    if (client != null) return client;

    // Also search ANCESTORS in case the TextInputClient wraps the Focus
    context.visitAncestorElements((element) {
      if (element is StatefulElement && element.state is TextInputClient) {
        client = element.state as TextInputClient;
        return false; // Stop visiting
      }
      return true; // Continue visiting
    });

    return client;
  }

  /// Insert text via TextInputClient (simulates platform text input)
  static Future<void> _insertViaTextInputClient(
      TextInputClient client, String text) async {
    final current = client.currentTextEditingValue ?? TextEditingValue.empty;
    final selection = current.selection;

    // Insert at cursor position if valid, otherwise append
    final newText = selection.isValid
        ? current.text.replaceRange(selection.start, selection.end, text)
        : current.text + text;

    final newCursorPosition =
        selection.isValid ? selection.start + text.length : newText.length;

    final newValue = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursorPosition),
    );

    client.updateEditingValue(newValue);
    await Future.delayed(const Duration(milliseconds: 30));
  }

  /// Parse text into tokens (regular text and special keys)
  static List<_TypeToken> _parseText(String text) {
    final tokens = <_TypeToken>[];
    var lastEnd = 0;

    for (final match in _specialKeyPattern.allMatches(text)) {
      if (match.start > lastEnd) {
        tokens.add(
            _TypeToken(text.substring(lastEnd, match.start), isSpecialKey: false));
      }
      tokens.add(_TypeToken(match.group(1)!, isSpecialKey: true));
      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      tokens.add(_TypeToken(text.substring(lastEnd), isSpecialKey: false));
    }

    return tokens;
  }

  /// Simulate a key press for a single character
  static Future<void> _simulateCharacterKeyPress(String char) async {
    final keyInfo = _getKeyInfoForCharacter(char);
    if (keyInfo == null) return;

    if (keyInfo.needsShift) {
      await _sendKeyDown(
        physicalKey: PhysicalKeyboardKey.shiftLeft,
        logicalKey: LogicalKeyboardKey.shiftLeft,
      );
      await Future.delayed(const Duration(milliseconds: 5));
    }

    await _sendKeyDown(
      physicalKey: keyInfo.physicalKey,
      logicalKey: keyInfo.logicalKey,
      character: char,
    );
    await Future.delayed(const Duration(milliseconds: 10));
    await _sendKeyUp(
      physicalKey: keyInfo.physicalKey,
      logicalKey: keyInfo.logicalKey,
    );

    if (keyInfo.needsShift) {
      await Future.delayed(const Duration(milliseconds: 5));
      await _sendKeyUp(
        physicalKey: PhysicalKeyboardKey.shiftLeft,
        logicalKey: LogicalKeyboardKey.shiftLeft,
      );
    }
  }

  /// Handle special key actions via raw key events
  static Future<void> _handleSpecialKey(String keySpec) async {
    final parts = keySpec.toLowerCase().split('+');

    var ctrl = false;
    var alt = false;
    var shift = false;
    var meta = false;
    String? mainKey;

    for (final part in parts) {
      switch (part) {
        case 'ctrl':
        case 'control':
          ctrl = true;
        case 'alt':
        case 'option':
          alt = true;
        case 'shift':
          shift = true;
        case 'meta':
        case 'cmd':
        case 'command':
        case 'win':
        case 'super':
          meta = true;
        default:
          mainKey = part;
      }
    }

    if (mainKey == null) return;

    final keyInfo = _getSpecialKeyInfo(mainKey);
    if (keyInfo == null) return;

    // Press modifiers
    if (ctrl) {
      await _sendKeyDown(
        physicalKey: PhysicalKeyboardKey.controlLeft,
        logicalKey: LogicalKeyboardKey.controlLeft,
      );
    }
    if (alt) {
      await _sendKeyDown(
        physicalKey: PhysicalKeyboardKey.altLeft,
        logicalKey: LogicalKeyboardKey.altLeft,
      );
    }
    if (shift) {
      await _sendKeyDown(
        physicalKey: PhysicalKeyboardKey.shiftLeft,
        logicalKey: LogicalKeyboardKey.shiftLeft,
      );
    }
    if (meta) {
      await _sendKeyDown(
        physicalKey: PhysicalKeyboardKey.metaLeft,
        logicalKey: LogicalKeyboardKey.metaLeft,
      );
    }

    if (ctrl || alt || shift || meta) {
      await Future.delayed(const Duration(milliseconds: 5));
    }

    // Press main key
    await _sendKeyDown(
      physicalKey: keyInfo.physicalKey,
      logicalKey: keyInfo.logicalKey,
      character: keyInfo.character,
    );
    await Future.delayed(const Duration(milliseconds: 10));
    await _sendKeyUp(
      physicalKey: keyInfo.physicalKey,
      logicalKey: keyInfo.logicalKey,
    );

    // Release modifiers (reverse order)
    if (meta) {
      await Future.delayed(const Duration(milliseconds: 5));
      await _sendKeyUp(
        physicalKey: PhysicalKeyboardKey.metaLeft,
        logicalKey: LogicalKeyboardKey.metaLeft,
      );
    }
    if (shift) {
      await Future.delayed(const Duration(milliseconds: 5));
      await _sendKeyUp(
        physicalKey: PhysicalKeyboardKey.shiftLeft,
        logicalKey: LogicalKeyboardKey.shiftLeft,
      );
    }
    if (alt) {
      await Future.delayed(const Duration(milliseconds: 5));
      await _sendKeyUp(
        physicalKey: PhysicalKeyboardKey.altLeft,
        logicalKey: LogicalKeyboardKey.altLeft,
      );
    }
    if (ctrl) {
      await Future.delayed(const Duration(milliseconds: 5));
      await _sendKeyUp(
        physicalKey: PhysicalKeyboardKey.controlLeft,
        logicalKey: LogicalKeyboardKey.controlLeft,
      );
    }

    await Future.delayed(const Duration(milliseconds: 30));
  }

  /// Send a key down event
  static Future<bool> _sendKeyDown({
    required PhysicalKeyboardKey physicalKey,
    required LogicalKeyboardKey logicalKey,
    String? character,
  }) async {
    final primaryFocus = FocusManager.instance.primaryFocus;
    if (primaryFocus == null) return false;

    final keyEvent = KeyDownEvent(
      physicalKey: physicalKey,
      logicalKey: logicalKey,
      character: character,
      timeStamp: Duration.zero,
    );

    final onKeyEvent = primaryFocus.onKeyEvent;
    if (onKeyEvent != null) {
      final result = onKeyEvent(primaryFocus, keyEvent);
      if (keyEvent.character != null && keyEvent.character!.isNotEmpty) {
        return true;
      }
      return result == KeyEventResult.handled;
    }

    // Fallback: send through HardwareKeyboard API
    // ignore: deprecated_member_use - This is intentional; the new addHandler API
    // is for listeners, not for injecting events. handleKeyData is the only way
    // to programmatically inject key events at the system level.
    return ServicesBinding.instance.keyEventManager.handleKeyData(
      ui.KeyData(
        type: ui.KeyEventType.down,
        physical: physicalKey.usbHidUsage,
        logical: logicalKey.keyId,
        timeStamp: Duration.zero,
        character: character,
        synthesized: true,
      ),
    );
  }

  /// Send a key up event
  static Future<bool> _sendKeyUp({
    required PhysicalKeyboardKey physicalKey,
    required LogicalKeyboardKey logicalKey,
  }) async {
    final primaryFocus = FocusManager.instance.primaryFocus;
    if (primaryFocus == null) return false;

    final keyEvent = KeyUpEvent(
      physicalKey: physicalKey,
      logicalKey: logicalKey,
      timeStamp: Duration.zero,
    );

    final onKeyEvent = primaryFocus.onKeyEvent;
    if (onKeyEvent != null) {
      final result = onKeyEvent(primaryFocus, keyEvent);
      return result == KeyEventResult.handled;
    }

    // ignore: deprecated_member_use - Intentional; see comment above.
    return ServicesBinding.instance.keyEventManager.handleKeyData(
      ui.KeyData(
        type: ui.KeyEventType.up,
        physical: physicalKey.usbHidUsage,
        logical: logicalKey.keyId,
        timeStamp: Duration.zero,
        character: null,
        synthesized: true,
      ),
    );
  }

  // ============ Key Mappings ============

  static _SpecialKeyInfo? _getSpecialKeyInfo(String key) {
    switch (key) {
      case 'enter':
      case 'return':
        return _SpecialKeyInfo(
            PhysicalKeyboardKey.enter, LogicalKeyboardKey.enter, '\n');
      case 'tab':
        return _SpecialKeyInfo(
            PhysicalKeyboardKey.tab, LogicalKeyboardKey.tab, '\t');
      case 'backspace':
        return _SpecialKeyInfo(
            PhysicalKeyboardKey.backspace, LogicalKeyboardKey.backspace);
      case 'delete':
      case 'del':
        return _SpecialKeyInfo(
            PhysicalKeyboardKey.delete, LogicalKeyboardKey.delete);
      case 'escape':
      case 'esc':
        return _SpecialKeyInfo(
            PhysicalKeyboardKey.escape, LogicalKeyboardKey.escape);
      case 'space':
        return _SpecialKeyInfo(
            PhysicalKeyboardKey.space, LogicalKeyboardKey.space, ' ');
      case 'left':
      case 'arrowleft':
        return _SpecialKeyInfo(
            PhysicalKeyboardKey.arrowLeft, LogicalKeyboardKey.arrowLeft);
      case 'right':
      case 'arrowright':
        return _SpecialKeyInfo(
            PhysicalKeyboardKey.arrowRight, LogicalKeyboardKey.arrowRight);
      case 'up':
      case 'arrowup':
        return _SpecialKeyInfo(
            PhysicalKeyboardKey.arrowUp, LogicalKeyboardKey.arrowUp);
      case 'down':
      case 'arrowdown':
        return _SpecialKeyInfo(
            PhysicalKeyboardKey.arrowDown, LogicalKeyboardKey.arrowDown);
      case 'home':
        return _SpecialKeyInfo(
            PhysicalKeyboardKey.home, LogicalKeyboardKey.home);
      case 'end':
        return _SpecialKeyInfo(PhysicalKeyboardKey.end, LogicalKeyboardKey.end);
      case 'pageup':
      case 'pgup':
        return _SpecialKeyInfo(
            PhysicalKeyboardKey.pageUp, LogicalKeyboardKey.pageUp);
      case 'pagedown':
      case 'pgdn':
        return _SpecialKeyInfo(
            PhysicalKeyboardKey.pageDown, LogicalKeyboardKey.pageDown);
      case 'f1':
        return _SpecialKeyInfo(PhysicalKeyboardKey.f1, LogicalKeyboardKey.f1);
      case 'f2':
        return _SpecialKeyInfo(PhysicalKeyboardKey.f2, LogicalKeyboardKey.f2);
      case 'f3':
        return _SpecialKeyInfo(PhysicalKeyboardKey.f3, LogicalKeyboardKey.f3);
      case 'f4':
        return _SpecialKeyInfo(PhysicalKeyboardKey.f4, LogicalKeyboardKey.f4);
      case 'f5':
        return _SpecialKeyInfo(PhysicalKeyboardKey.f5, LogicalKeyboardKey.f5);
      case 'f6':
        return _SpecialKeyInfo(PhysicalKeyboardKey.f6, LogicalKeyboardKey.f6);
      case 'f7':
        return _SpecialKeyInfo(PhysicalKeyboardKey.f7, LogicalKeyboardKey.f7);
      case 'f8':
        return _SpecialKeyInfo(PhysicalKeyboardKey.f8, LogicalKeyboardKey.f8);
      case 'f9':
        return _SpecialKeyInfo(PhysicalKeyboardKey.f9, LogicalKeyboardKey.f9);
      case 'f10':
        return _SpecialKeyInfo(PhysicalKeyboardKey.f10, LogicalKeyboardKey.f10);
      case 'f11':
        return _SpecialKeyInfo(PhysicalKeyboardKey.f11, LogicalKeyboardKey.f11);
      case 'f12':
        return _SpecialKeyInfo(PhysicalKeyboardKey.f12, LogicalKeyboardKey.f12);
    }

    // Single letter/digit keys (for combos like ctrl+c)
    if (key.length == 1) {
      final char = key;
      final code = char.codeUnitAt(0);

      if (code >= 'a'.codeUnitAt(0) && code <= 'z'.codeUnitAt(0)) {
        final keyInfo = _getLowercaseLetterKey(char);
        if (keyInfo != null) {
          return _SpecialKeyInfo(
              keyInfo.physicalKey, keyInfo.logicalKey, char);
        }
      }

      if (code >= '0'.codeUnitAt(0) && code <= '9'.codeUnitAt(0)) {
        final keyInfo = _getDigitKey(char);
        if (keyInfo != null) {
          return _SpecialKeyInfo(
              keyInfo.physicalKey, keyInfo.logicalKey, char);
        }
      }
    }

    return null;
  }

  static _KeyInfo? _getKeyInfoForCharacter(String char) {
    final code = char.codeUnitAt(0);

    // Lowercase letters
    if (code >= 'a'.codeUnitAt(0) && code <= 'z'.codeUnitAt(0)) {
      return _getLowercaseLetterKey(char);
    }

    // Uppercase letters
    if (code >= 'A'.codeUnitAt(0) && code <= 'Z'.codeUnitAt(0)) {
      return _getUppercaseLetterKey(char);
    }

    // Digits
    if (code >= '0'.codeUnitAt(0) && code <= '9'.codeUnitAt(0)) {
      return _getDigitKey(char);
    }

    if (char == ' ') {
      return const _KeyInfo(
        physicalKey: PhysicalKeyboardKey.space,
        logicalKey: LogicalKeyboardKey.space,
      );
    }

    return _getSymbolKey(char);
  }

  static _KeyInfo? _getLowercaseLetterKey(String char) {
    final offset = char.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final physical = _letterPhysicalKeys[offset];
    final logical = _letterLogicalKeys[offset];
    if (physical == null || logical == null) return null;
    return _KeyInfo(physicalKey: physical, logicalKey: logical);
  }

  static _KeyInfo? _getUppercaseLetterKey(String char) {
    final lower = char.toLowerCase();
    final offset = lower.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final physical = _letterPhysicalKeys[offset];
    final logical = _letterLogicalKeys[offset];
    if (physical == null || logical == null) return null;
    return _KeyInfo(
      physicalKey: physical,
      logicalKey: logical,
      needsShift: true,
    );
  }

  static _KeyInfo? _getDigitKey(String char) {
    final offset = char.codeUnitAt(0) - '0'.codeUnitAt(0);
    final physical = _digitPhysicalKeys[offset];
    final logical = _digitLogicalKeys[offset];
    if (physical == null || logical == null) return null;
    return _KeyInfo(physicalKey: physical, logicalKey: logical);
  }

  static _KeyInfo? _getSymbolKey(String char) {
    switch (char) {
      case '-':
        return const _KeyInfo(
            physicalKey: PhysicalKeyboardKey.minus,
            logicalKey: LogicalKeyboardKey.minus);
      case '=':
        return const _KeyInfo(
            physicalKey: PhysicalKeyboardKey.equal,
            logicalKey: LogicalKeyboardKey.equal);
      case '[':
        return const _KeyInfo(
            physicalKey: PhysicalKeyboardKey.bracketLeft,
            logicalKey: LogicalKeyboardKey.bracketLeft);
      case ']':
        return const _KeyInfo(
            physicalKey: PhysicalKeyboardKey.bracketRight,
            logicalKey: LogicalKeyboardKey.bracketRight);
      case '\\':
        return const _KeyInfo(
            physicalKey: PhysicalKeyboardKey.backslash,
            logicalKey: LogicalKeyboardKey.backslash);
      case ';':
        return const _KeyInfo(
            physicalKey: PhysicalKeyboardKey.semicolon,
            logicalKey: LogicalKeyboardKey.semicolon);
      case "'":
        return const _KeyInfo(
            physicalKey: PhysicalKeyboardKey.quote,
            logicalKey: LogicalKeyboardKey.quoteSingle);
      case '`':
        return const _KeyInfo(
            physicalKey: PhysicalKeyboardKey.backquote,
            logicalKey: LogicalKeyboardKey.backquote);
      case ',':
        return const _KeyInfo(
            physicalKey: PhysicalKeyboardKey.comma,
            logicalKey: LogicalKeyboardKey.comma);
      case '.':
        return const _KeyInfo(
            physicalKey: PhysicalKeyboardKey.period,
            logicalKey: LogicalKeyboardKey.period);
      case '/':
        return const _KeyInfo(
            physicalKey: PhysicalKeyboardKey.slash,
            logicalKey: LogicalKeyboardKey.slash);
      // Shifted symbols
      case '!':
        return const _KeyInfo(
            physicalKey: PhysicalKeyboardKey.digit1,
            logicalKey: LogicalKeyboardKey.exclamation,
            needsShift: true);
      case '@':
        return const _KeyInfo(
            physicalKey: PhysicalKeyboardKey.digit2,
            logicalKey: LogicalKeyboardKey.at,
            needsShift: true);
      case '#':
        return const _KeyInfo(
            physicalKey: PhysicalKeyboardKey.digit3,
            logicalKey: LogicalKeyboardKey.numberSign,
            needsShift: true);
      case '\$':
        return const _KeyInfo(
            physicalKey: PhysicalKeyboardKey.digit4,
            logicalKey: LogicalKeyboardKey.dollar,
            needsShift: true);
      case '%':
        return const _KeyInfo(
            physicalKey: PhysicalKeyboardKey.digit5,
            logicalKey: LogicalKeyboardKey.percent,
            needsShift: true);
      case '^':
        return const _KeyInfo(
            physicalKey: PhysicalKeyboardKey.digit6,
            logicalKey: LogicalKeyboardKey.caret,
            needsShift: true);
      case '&':
        return const _KeyInfo(
            physicalKey: PhysicalKeyboardKey.digit7,
            logicalKey: LogicalKeyboardKey.ampersand,
            needsShift: true);
      case '*':
        return const _KeyInfo(
            physicalKey: PhysicalKeyboardKey.digit8,
            logicalKey: LogicalKeyboardKey.asterisk,
            needsShift: true);
      case '(':
        return const _KeyInfo(
            physicalKey: PhysicalKeyboardKey.digit9,
            logicalKey: LogicalKeyboardKey.parenthesisLeft,
            needsShift: true);
      case ')':
        return const _KeyInfo(
            physicalKey: PhysicalKeyboardKey.digit0,
            logicalKey: LogicalKeyboardKey.parenthesisRight,
            needsShift: true);
      case '_':
        return const _KeyInfo(
            physicalKey: PhysicalKeyboardKey.minus,
            logicalKey: LogicalKeyboardKey.underscore,
            needsShift: true);
      case '+':
        return const _KeyInfo(
            physicalKey: PhysicalKeyboardKey.equal,
            logicalKey: LogicalKeyboardKey.add,
            needsShift: true);
      case '{':
        return const _KeyInfo(
            physicalKey: PhysicalKeyboardKey.bracketLeft,
            logicalKey: LogicalKeyboardKey.braceLeft,
            needsShift: true);
      case '}':
        return const _KeyInfo(
            physicalKey: PhysicalKeyboardKey.bracketRight,
            logicalKey: LogicalKeyboardKey.braceRight,
            needsShift: true);
      case '|':
        return const _KeyInfo(
            physicalKey: PhysicalKeyboardKey.backslash,
            logicalKey: LogicalKeyboardKey.bar,
            needsShift: true);
      case ':':
        return const _KeyInfo(
            physicalKey: PhysicalKeyboardKey.semicolon,
            logicalKey: LogicalKeyboardKey.colon,
            needsShift: true);
      case '"':
        return const _KeyInfo(
            physicalKey: PhysicalKeyboardKey.quote,
            logicalKey: LogicalKeyboardKey.quote,
            needsShift: true);
      case '~':
        return const _KeyInfo(
            physicalKey: PhysicalKeyboardKey.backquote,
            logicalKey: LogicalKeyboardKey.tilde,
            needsShift: true);
      case '<':
        return const _KeyInfo(
            physicalKey: PhysicalKeyboardKey.comma,
            logicalKey: LogicalKeyboardKey.less,
            needsShift: true);
      case '>':
        return const _KeyInfo(
            physicalKey: PhysicalKeyboardKey.period,
            logicalKey: LogicalKeyboardKey.greater,
            needsShift: true);
      case '?':
        return const _KeyInfo(
            physicalKey: PhysicalKeyboardKey.slash,
            logicalKey: LogicalKeyboardKey.question,
            needsShift: true);
      default:
        return null;
    }
  }

  static PhysicalKeyboardKey? _getPhysicalKeyForLogical(LogicalKeyboardKey key) {
    // Letters
    if (key == LogicalKeyboardKey.keyA) return PhysicalKeyboardKey.keyA;
    if (key == LogicalKeyboardKey.keyB) return PhysicalKeyboardKey.keyB;
    if (key == LogicalKeyboardKey.keyC) return PhysicalKeyboardKey.keyC;
    if (key == LogicalKeyboardKey.keyD) return PhysicalKeyboardKey.keyD;
    if (key == LogicalKeyboardKey.keyE) return PhysicalKeyboardKey.keyE;
    if (key == LogicalKeyboardKey.keyF) return PhysicalKeyboardKey.keyF;
    if (key == LogicalKeyboardKey.keyG) return PhysicalKeyboardKey.keyG;
    if (key == LogicalKeyboardKey.keyH) return PhysicalKeyboardKey.keyH;
    if (key == LogicalKeyboardKey.keyI) return PhysicalKeyboardKey.keyI;
    if (key == LogicalKeyboardKey.keyJ) return PhysicalKeyboardKey.keyJ;
    if (key == LogicalKeyboardKey.keyK) return PhysicalKeyboardKey.keyK;
    if (key == LogicalKeyboardKey.keyL) return PhysicalKeyboardKey.keyL;
    if (key == LogicalKeyboardKey.keyM) return PhysicalKeyboardKey.keyM;
    if (key == LogicalKeyboardKey.keyN) return PhysicalKeyboardKey.keyN;
    if (key == LogicalKeyboardKey.keyO) return PhysicalKeyboardKey.keyO;
    if (key == LogicalKeyboardKey.keyP) return PhysicalKeyboardKey.keyP;
    if (key == LogicalKeyboardKey.keyQ) return PhysicalKeyboardKey.keyQ;
    if (key == LogicalKeyboardKey.keyR) return PhysicalKeyboardKey.keyR;
    if (key == LogicalKeyboardKey.keyS) return PhysicalKeyboardKey.keyS;
    if (key == LogicalKeyboardKey.keyT) return PhysicalKeyboardKey.keyT;
    if (key == LogicalKeyboardKey.keyU) return PhysicalKeyboardKey.keyU;
    if (key == LogicalKeyboardKey.keyV) return PhysicalKeyboardKey.keyV;
    if (key == LogicalKeyboardKey.keyW) return PhysicalKeyboardKey.keyW;
    if (key == LogicalKeyboardKey.keyX) return PhysicalKeyboardKey.keyX;
    if (key == LogicalKeyboardKey.keyY) return PhysicalKeyboardKey.keyY;
    if (key == LogicalKeyboardKey.keyZ) return PhysicalKeyboardKey.keyZ;

    // Common keys
    if (key == LogicalKeyboardKey.enter) return PhysicalKeyboardKey.enter;
    if (key == LogicalKeyboardKey.space) return PhysicalKeyboardKey.space;
    if (key == LogicalKeyboardKey.backspace) return PhysicalKeyboardKey.backspace;
    if (key == LogicalKeyboardKey.tab) return PhysicalKeyboardKey.tab;
    if (key == LogicalKeyboardKey.escape) return PhysicalKeyboardKey.escape;

    return null;
  }

  static const _letterPhysicalKeys = <int, PhysicalKeyboardKey>{
    0: PhysicalKeyboardKey.keyA,
    1: PhysicalKeyboardKey.keyB,
    2: PhysicalKeyboardKey.keyC,
    3: PhysicalKeyboardKey.keyD,
    4: PhysicalKeyboardKey.keyE,
    5: PhysicalKeyboardKey.keyF,
    6: PhysicalKeyboardKey.keyG,
    7: PhysicalKeyboardKey.keyH,
    8: PhysicalKeyboardKey.keyI,
    9: PhysicalKeyboardKey.keyJ,
    10: PhysicalKeyboardKey.keyK,
    11: PhysicalKeyboardKey.keyL,
    12: PhysicalKeyboardKey.keyM,
    13: PhysicalKeyboardKey.keyN,
    14: PhysicalKeyboardKey.keyO,
    15: PhysicalKeyboardKey.keyP,
    16: PhysicalKeyboardKey.keyQ,
    17: PhysicalKeyboardKey.keyR,
    18: PhysicalKeyboardKey.keyS,
    19: PhysicalKeyboardKey.keyT,
    20: PhysicalKeyboardKey.keyU,
    21: PhysicalKeyboardKey.keyV,
    22: PhysicalKeyboardKey.keyW,
    23: PhysicalKeyboardKey.keyX,
    24: PhysicalKeyboardKey.keyY,
    25: PhysicalKeyboardKey.keyZ,
  };

  static const _letterLogicalKeys = <int, LogicalKeyboardKey>{
    0: LogicalKeyboardKey.keyA,
    1: LogicalKeyboardKey.keyB,
    2: LogicalKeyboardKey.keyC,
    3: LogicalKeyboardKey.keyD,
    4: LogicalKeyboardKey.keyE,
    5: LogicalKeyboardKey.keyF,
    6: LogicalKeyboardKey.keyG,
    7: LogicalKeyboardKey.keyH,
    8: LogicalKeyboardKey.keyI,
    9: LogicalKeyboardKey.keyJ,
    10: LogicalKeyboardKey.keyK,
    11: LogicalKeyboardKey.keyL,
    12: LogicalKeyboardKey.keyM,
    13: LogicalKeyboardKey.keyN,
    14: LogicalKeyboardKey.keyO,
    15: LogicalKeyboardKey.keyP,
    16: LogicalKeyboardKey.keyQ,
    17: LogicalKeyboardKey.keyR,
    18: LogicalKeyboardKey.keyS,
    19: LogicalKeyboardKey.keyT,
    20: LogicalKeyboardKey.keyU,
    21: LogicalKeyboardKey.keyV,
    22: LogicalKeyboardKey.keyW,
    23: LogicalKeyboardKey.keyX,
    24: LogicalKeyboardKey.keyY,
    25: LogicalKeyboardKey.keyZ,
  };

  static const _digitPhysicalKeys = <int, PhysicalKeyboardKey>{
    0: PhysicalKeyboardKey.digit0,
    1: PhysicalKeyboardKey.digit1,
    2: PhysicalKeyboardKey.digit2,
    3: PhysicalKeyboardKey.digit3,
    4: PhysicalKeyboardKey.digit4,
    5: PhysicalKeyboardKey.digit5,
    6: PhysicalKeyboardKey.digit6,
    7: PhysicalKeyboardKey.digit7,
    8: PhysicalKeyboardKey.digit8,
    9: PhysicalKeyboardKey.digit9,
  };

  static const _digitLogicalKeys = <int, LogicalKeyboardKey>{
    0: LogicalKeyboardKey.digit0,
    1: LogicalKeyboardKey.digit1,
    2: LogicalKeyboardKey.digit2,
    3: LogicalKeyboardKey.digit3,
    4: LogicalKeyboardKey.digit4,
    5: LogicalKeyboardKey.digit5,
    6: LogicalKeyboardKey.digit6,
    7: LogicalKeyboardKey.digit7,
    8: LogicalKeyboardKey.digit8,
    9: LogicalKeyboardKey.digit9,
  };
}

// ============ Data Classes ============

class _TypeToken {
  final String value;
  final bool isSpecialKey;
  _TypeToken(this.value, {required this.isSpecialKey});
}

class _SpecialKeyInfo {
  final PhysicalKeyboardKey physicalKey;
  final LogicalKeyboardKey logicalKey;
  final String? character;
  const _SpecialKeyInfo(this.physicalKey, this.logicalKey, [this.character]);
}

class _KeyInfo {
  final PhysicalKeyboardKey physicalKey;
  final LogicalKeyboardKey logicalKey;
  final bool needsShift;
  const _KeyInfo({
    required this.physicalKey,
    required this.logicalKey,
    this.needsShift = false,
  });
}

/// Result of a key injection operation.
class KeyInjectionResult {
  final bool success;
  final String? error;
  final InjectionMethod method;
  final bool textInputClientFound;

  const KeyInjectionResult({
    required this.success,
    this.error,
    required this.method,
    this.textInputClientFound = false,
  });

  @override
  String toString() =>
      'KeyInjectionResult(success: $success, method: $method, error: $error)';
}

/// Method used to inject text.
enum InjectionMethod {
  textInputClient,
  rawKeyEvent,
  none,
}

/// Information about the currently focused widget.
class FocusedWidgetInfo {
  final String? debugLabel;
  final bool hasTextInputClient;
  final String? currentText;
  final String? widgetType;
  final bool hasOnKeyEvent;

  const FocusedWidgetInfo({
    this.debugLabel,
    required this.hasTextInputClient,
    this.currentText,
    this.widgetType,
    required this.hasOnKeyEvent,
  });

  @override
  String toString() => '''FocusedWidgetInfo(
  widgetType: $widgetType,
  hasTextInputClient: $hasTextInputClient,
  hasOnKeyEvent: $hasOnKeyEvent,
  currentText: $currentText,
)''';
}
