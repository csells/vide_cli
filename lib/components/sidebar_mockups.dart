import 'package:nocterm/nocterm.dart';

/// Sidebar design mockup viewer.
/// Run with: dart run bin/sidebar_mockup.dart
///
/// Use number keys 1-4 to switch between designs:
/// 1 = Clean & Minimal
/// 2 = Gutter Style
/// 3 = Modern/Material
/// 4 = Icon-rich

enum SidebarDesign {
  cleanMinimal,
  gutterStyle,
  modernMaterial,
  iconRich,
}

class SidebarMockupViewer extends StatefulComponent {
  const SidebarMockupViewer({super.key});

  @override
  State<SidebarMockupViewer> createState() => _SidebarMockupViewerState();
}

class _SidebarMockupViewerState extends State<SidebarMockupViewer> {
  SidebarDesign _currentDesign = SidebarDesign.cleanMinimal;

  @override
  Component build(BuildContext context) {
    return Focusable(
      focused: true,
      onKeyEvent: (event) {
        if (event.logicalKey == LogicalKey.digit1) {
          setState(() => _currentDesign = SidebarDesign.cleanMinimal);
        } else if (event.logicalKey == LogicalKey.digit2) {
          setState(() => _currentDesign = SidebarDesign.gutterStyle);
        } else if (event.logicalKey == LogicalKey.digit3) {
          setState(() => _currentDesign = SidebarDesign.modernMaterial);
        } else if (event.logicalKey == LogicalKey.digit4) {
          setState(() => _currentDesign = SidebarDesign.iconRich);
        } else if (event.logicalKey == LogicalKey.keyQ ||
            event.logicalKey == LogicalKey.escape) {
          // Exit
          return false;
        }
        return true;
      },
      child: Container(
        decoration: BoxDecoration(color: Color(0xFF1E1E1E)),
        child: Row(
          children: [
            // Sidebar mockup
            _buildCurrentDesign(),
            // Main content area (placeholder)
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Color(0xFF252526),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 2),
                    Center(
                      child: Text(
                        'Sidebar Design Mockups',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 2),
                    Center(
                      child: Text(
                        'Press 1-4 to switch designs, Q to quit',
                        style: TextStyle(color: Color(0xFF808080)),
                      ),
                    ),
                    SizedBox(height: 2),
                    _buildDesignSelector(),
                    SizedBox(height: 2),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: _buildDesignDescription(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Component _buildDesignSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildDesignTab('1: Clean', SidebarDesign.cleanMinimal),
        Text(' │ ', style: TextStyle(color: Color(0xFF404040))),
        _buildDesignTab('2: Gutter', SidebarDesign.gutterStyle),
        Text(' │ ', style: TextStyle(color: Color(0xFF404040))),
        _buildDesignTab('3: Modern', SidebarDesign.modernMaterial),
        Text(' │ ', style: TextStyle(color: Color(0xFF404040))),
        _buildDesignTab('4: Icons', SidebarDesign.iconRich),
      ],
    );
  }

  Component _buildDesignTab(String label, SidebarDesign design) {
    final isSelected = _currentDesign == design;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 1),
      decoration: isSelected
          ? BoxDecoration(color: Color(0xFF0D47A1))
          : null,
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Color(0xFF808080),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Component _buildDesignDescription() {
    final descriptions = {
      SidebarDesign.cleanMinimal: '''
Design A: Clean & Minimal

• Colored dots (●/○) for file status
• Tree-line connectors for visual grouping
• Subtle, refined appearance
• Badge inline with section header
• Minimal visual noise''',
      SidebarDesign.gutterStyle: '''
Design B: Gutter Style (VS Code inspired)

• Colored left gutter indicator
• Status letters with colored backgrounds
• Box-drawing section separators
• Familiar IDE-like appearance
• Clear visual hierarchy''',
      SidebarDesign.modernMaterial: '''
Design C: Modern/Material

• Rounded corners using Unicode
• Filled/hollow circles for status
• Bracketed count badges
• Card-like sections
• Contemporary feel''',
      SidebarDesign.iconRich: '''
Design D: Icon-rich

• File type icons (📄)
• Status as colored pills [S] [M] [?]
• Current branch indicator with dot
• More visual information density
• Colorful and expressive''',
    };

    return Text(
      descriptions[_currentDesign] ?? '',
      style: TextStyle(color: Color(0xFFB0B0B0)),
    );
  }

  Component _buildCurrentDesign() {
    switch (_currentDesign) {
      case SidebarDesign.cleanMinimal:
        return _CleanMinimalSidebar();
      case SidebarDesign.gutterStyle:
        return _GutterStyleSidebar();
      case SidebarDesign.modernMaterial:
        return _ModernMaterialSidebar();
      case SidebarDesign.iconRich:
        return _IconRichSidebar();
    }
  }
}

// =============================================================================
// Design A: Clean & Minimal
// =============================================================================

class _CleanMinimalSidebar extends StatelessComponent {
  // Colors
  static const _surface = Color(0xFF1E1E1E);
  static const _border = Color(0xFF3C3C3C);
  static const _text = Color(0xFFCCCCCC);
  static const _textMuted = Color(0xFF808080);
  static const _primary = Color(0xFF569CD6);
  static const _success = Color(0xFF4EC9B0);
  static const _warning = Color(0xFFDCDCAA);
  static const _accent = Color(0xFFC586C0);

  @override
  Component build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        border: BoxBorder(
          top: BorderSide(color: _border),
          right: BorderSide(color: _border),
          bottom: BorderSide(color: _border),
          left: BorderSide(color: _border),
        ),
      ),
      child: SizedBox(
        width: 32,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(color: _border.withOpacity(0.5)),
              child: Row(
                children: [
                  Text('', style: TextStyle(color: _accent)),
                  SizedBox(width: 1),
                  Text(
                    'main',
                    style: TextStyle(
                      color: _text,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 1),

            // Changes section
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 1),
              child: Row(
                children: [
                  Text('▾', style: TextStyle(color: _textMuted)),
                  SizedBox(width: 1),
                  Text(
                    'Changes',
                    style: TextStyle(
                      color: _text,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(child: SizedBox()),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(color: _warning.withOpacity(0.2)),
                    child: Text(
                      '3',
                      style: TextStyle(color: _warning),
                    ),
                  ),
                ],
              ),
            ),

            // Files with tree lines
            _buildFileRow('│', '●', 'auth_service.dart', _success),
            _buildFileRow('│', '●', 'user_model.dart', _warning),
            _buildFileRow('╰', '○', 'new_file.dart', _textMuted),

            SizedBox(height: 1),

            // Branches section
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 1),
              child: Row(
                children: [
                  Text('▸', style: TextStyle(color: _textMuted)),
                  SizedBox(width: 1),
                  Text(
                    'Branches',
                    style: TextStyle(
                      color: _text,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(child: SizedBox()),

            // Footer hint
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 1),
              child: Text(
                '→ to exit',
                style: TextStyle(color: _textMuted.withOpacity(0.6)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Component _buildFileRow(
    String connector,
    String dot,
    String filename,
    Color color,
  ) {
    return Padding(
      padding: EdgeInsets.only(left: 2),
      child: Row(
        children: [
          Text(connector, style: TextStyle(color: _border)),
          SizedBox(width: 1),
          Text(dot, style: TextStyle(color: color)),
          SizedBox(width: 1),
          Expanded(
            child: Text(
              filename,
              style: TextStyle(color: _text),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Design B: Gutter Style
// =============================================================================

class _GutterStyleSidebar extends StatelessComponent {
  static const _surface = Color(0xFF1E1E1E);
  static const _border = Color(0xFF3C3C3C);
  static const _text = Color(0xFFCCCCCC);
  static const _textMuted = Color(0xFF808080);
  static const _primary = Color(0xFF569CD6);
  static const _success = Color(0xFF4EC9B0);
  static const _warning = Color(0xFFDCDCAA);
  static const _accent = Color(0xFFC586C0);
  static const _gutterSuccess = Color(0xFF2D5A3D);
  static const _gutterWarning = Color(0xFF5A4A2D);
  static const _gutterUntracked = Color(0xFF3A3A3A);

  @override
  Component build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        border: BoxBorder(right: BorderSide(color: _border)),
      ),
      child: SizedBox(
        width: 32,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with gutter
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(color: _accent),
                  child: Text(' ', style: TextStyle(color: _accent)),
                ),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(color: _border.withOpacity(0.3)),
                    child: Row(
                      children: [
                        Text('', style: TextStyle(color: _accent)),
                        SizedBox(width: 1),
                        Text(
                          'main',
                          style: TextStyle(
                            color: _text,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Section separator
            _buildSeparator('┬'),

            // Changes header
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(color: _border.withOpacity(0.3)),
                  child: Text('│', style: TextStyle(color: _border)),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 1),
                    child: Row(
                      children: [
                        Text('▾', style: TextStyle(color: _primary)),
                        SizedBox(width: 1),
                        Text(
                          'Changes',
                          style: TextStyle(
                            color: _text,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Expanded(child: SizedBox()),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(color: _warning),
                          child: Text(
                            '3',
                            style: TextStyle(
                              color: _surface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Files with gutter
            _buildGutterFileRow(_gutterSuccess, 'S', 'auth_service.dart', _success),
            _buildGutterFileRow(_gutterWarning, 'M', 'user_model.dart', _warning),
            _buildGutterFileRow(_gutterUntracked, '?', 'new_file.dart', _textMuted),

            // Section separator
            _buildSeparator('├'),

            // Branches header
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(color: _border.withOpacity(0.3)),
                  child: Text('│', style: TextStyle(color: _border)),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 1),
                    child: Row(
                      children: [
                        Text('▸', style: TextStyle(color: _primary)),
                        SizedBox(width: 1),
                        Text(
                          'Branches',
                          style: TextStyle(
                            color: _text,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            Expanded(child: SizedBox()),
          ],
        ),
      ),
    );
  }

  Component _buildSeparator(String leftChar) {
    return Row(
      children: [
        Text(leftChar, style: TextStyle(color: _border)),
        Expanded(
          child: Text(
            '─' * 30,
            style: TextStyle(color: _border),
          ),
        ),
      ],
    );
  }

  Component _buildGutterFileRow(
    Color gutterColor,
    String status,
    String filename,
    Color statusColor,
  ) {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(color: gutterColor),
          child: Text('│', style: TextStyle(color: gutterColor)),
        ),
        SizedBox(width: 1),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 0),
          decoration: BoxDecoration(color: statusColor.withOpacity(0.2)),
          child: Text(
            status,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(width: 1),
        Expanded(
          child: Text(
            filename,
            style: TextStyle(color: _text),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Design C: Modern/Material
// =============================================================================

class _ModernMaterialSidebar extends StatelessComponent {
  static const _surface = Color(0xFF1E1E1E);
  static const _card = Color(0xFF252526);
  static const _border = Color(0xFF3C3C3C);
  static const _text = Color(0xFFCCCCCC);
  static const _textMuted = Color(0xFF808080);
  static const _primary = Color(0xFF569CD6);
  static const _success = Color(0xFF4EC9B0);
  static const _warning = Color(0xFFDCDCAA);
  static const _accent = Color(0xFFC586C0);

  @override
  Component build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: _surface),
      child: SizedBox(
        width: 32,
        child: Padding(
          padding: EdgeInsets.all(1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header card
              Container(
                decoration: BoxDecoration(
                  color: _card,
                  border: BoxBorder.all(color: _border),
                  title: BorderTitle(
                    text: '  main ',
                    alignment: TitleAlignment.left,
                    style: TextStyle(color: _accent, fontWeight: FontWeight.bold),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 1),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Changes section
                      Row(
                        children: [
                          Text('▼', style: TextStyle(color: _primary)),
                          SizedBox(width: 1),
                          Text(
                            'Changes',
                            style: TextStyle(
                              color: _text,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Expanded(child: SizedBox()),
                          Text('[', style: TextStyle(color: _textMuted)),
                          Text('3', style: TextStyle(color: _warning)),
                          Text(']', style: TextStyle(color: _textMuted)),
                        ],
                      ),
                      SizedBox(height: 0),
                      _buildModernFileRow('●', 'auth_service.dart', _success),
                      _buildModernFileRow('●', 'user_model.dart', _warning),
                      _buildModernFileRow('○', 'new_file.dart', _textMuted),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 1),

              // Branches card
              Container(
                decoration: BoxDecoration(
                  color: _card,
                  border: BoxBorder.all(color: _border),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 1),
                  child: Row(
                    children: [
                      Text('▶', style: TextStyle(color: _primary)),
                      SizedBox(width: 1),
                      Text(
                        'Branches',
                        style: TextStyle(
                          color: _text,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Expanded(child: SizedBox()),
            ],
          ),
        ),
      ),
    );
  }

  Component _buildModernFileRow(String indicator, String filename, Color color) {
    return Padding(
      padding: EdgeInsets.only(left: 2),
      child: Row(
        children: [
          Text(indicator, style: TextStyle(color: color)),
          SizedBox(width: 1),
          Expanded(
            child: Text(
              filename,
              style: TextStyle(color: _text),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Design D: Icon-rich
// =============================================================================

class _IconRichSidebar extends StatelessComponent {
  static const _surface = Color(0xFF1E1E1E);
  static const _border = Color(0xFF3C3C3C);
  static const _text = Color(0xFFCCCCCC);
  static const _textMuted = Color(0xFF808080);
  static const _primary = Color(0xFF569CD6);
  static const _success = Color(0xFF4EC9B0);
  static const _warning = Color(0xFFDCDCAA);
  static const _error = Color(0xFFF14C4C);
  static const _accent = Color(0xFFC586C0);

  @override
  Component build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        border: BoxBorder(right: BorderSide(color: _border)),
      ),
      child: SizedBox(
        width: 34,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon
            Container(
              padding: EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: _accent.withOpacity(0.15),
                border: BoxBorder(bottom: BorderSide(color: _border)),
              ),
              child: Row(
                children: [
                  Text('', style: TextStyle(color: _accent)),
                  SizedBox(width: 1),
                  Text(
                    'main',
                    style: TextStyle(
                      color: _text,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(child: SizedBox()),
                  Text('●', style: TextStyle(color: _success)),
                ],
              ),
            ),

            // Separator
            Text(
              '─' * 34,
              style: TextStyle(color: _border.withOpacity(0.5)),
            ),

            // Changes section
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 1),
              child: Row(
                children: [
                  Text('📁', style: TextStyle(color: _warning)),
                  SizedBox(width: 1),
                  Text(
                    'Changes',
                    style: TextStyle(
                      color: _text,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(child: SizedBox()),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(color: _warning),
                    child: Text(
                      ' 3 ',
                      style: TextStyle(
                        color: _surface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Files with icons and status pills
            _buildIconFileRow('📄', 'auth_service.dart', 'S', _success),
            _buildIconFileRow('📄', 'user_model.dart', 'M', _warning),
            _buildIconFileRow('📄', 'new_file.dart', '?', _textMuted),

            SizedBox(height: 1),

            // Branches section
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 1),
              child: Row(
                children: [
                  Text('🌿', style: TextStyle(color: _success)),
                  SizedBox(width: 1),
                  Text(
                    'Branches',
                    style: TextStyle(
                      color: _text,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Branch list
            _buildBranchRow('main', isCurrent: true),
            _buildBranchRow('feature/auth', isCurrent: false),
            _buildBranchRow('bugfix/login', isCurrent: false, hasWorktree: true),

            Expanded(child: SizedBox()),
          ],
        ),
      ),
    );
  }

  Component _buildIconFileRow(
    String icon,
    String filename,
    String status,
    Color statusColor,
  ) {
    return Padding(
      padding: EdgeInsets.only(left: 2),
      child: Row(
        children: [
          Text('│', style: TextStyle(color: _border)),
          SizedBox(width: 1),
          Text(icon),
          SizedBox(width: 1),
          Expanded(
            child: Text(
              filename,
              style: TextStyle(color: _text),
            ),
          ),
          Container(
            decoration: BoxDecoration(color: statusColor.withOpacity(0.3)),
            child: Text(
              status,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Component _buildBranchRow(
    String name, {
    required bool isCurrent,
    bool hasWorktree = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(left: 2),
      child: Row(
        children: [
          Text('│', style: TextStyle(color: _border)),
          SizedBox(width: 1),
          if (isCurrent)
            Text('●', style: TextStyle(color: _success))
          else
            Text(' ', style: TextStyle(color: _textMuted)),
          SizedBox(width: 1),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                color: isCurrent ? _primary : _text,
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          if (hasWorktree)
            Text('W', style: TextStyle(color: _accent)),
        ],
      ),
    );
  }
}
