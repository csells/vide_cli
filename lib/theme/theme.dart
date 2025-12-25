/// Theming system for Vide CLI.
///
/// This library provides Vide-specific theming on top of nocterm's theming
/// system, including colors for agent status, diff rendering, and syntax
/// highlighting.
///
/// ## Quick Start
///
/// Wrap your app in a [VideTheme] and access theme colors with [VideTheme.of]:
///
/// ```dart
/// // Wrap your app
/// VideTheme(
///   data: VideThemeData.dark(),
///   child: MyApp(),
/// )
///
/// // Access theme in components
/// final theme = VideTheme.of(context);
/// final workingColor = theme.status.working;
/// final addedColor = theme.diff.addedPrefix;
/// ```
///
/// ## Built-in Themes
///
/// - [VideThemeData.dark] - Dark theme (default)
/// - [VideThemeData.light] - Light theme
///
/// ## Color Categories
///
/// - [VideStatusColors] - Agent and task status colors
/// - [VideDiffColors] - Diff rendering colors
/// - [VideSyntaxColors] - Syntax highlighting colors
library;

export 'colors/diff_colors.dart';
export 'colors/status_colors.dart';
export 'colors/syntax_colors.dart';
export 'theme_provider.dart';
export 'vide_theme.dart';
export 'vide_theme_data.dart';
