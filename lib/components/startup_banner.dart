import 'package:nocterm/nocterm.dart';
import 'package:nocterm_riverpod/nocterm_riverpod.dart';
import 'package:vide_cli/constants/text_opacity.dart';
import 'package:vide_cli/modules/haiku/haiku_providers.dart';

/// A banner that displays startup horoscope and tip.
/// Fades out after first message is sent or after a timeout.
class StartupBanner extends StatefulComponent {
  const StartupBanner({super.key});

  @override
  State<StartupBanner> createState() => StartupBannerState();
}

/// Public state class so it can be accessed via GlobalKey
class StartupBannerState extends State<StartupBanner> {
  bool _visible = true;
  bool _fading = false;

  @override
  void initState() {
    super.initState();
    // Auto-fade after 30 seconds
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted && _visible) {
        _startFadeOut();
      }
    });
  }

  void _startFadeOut() {
    if (_fading) return;
    setState(() => _fading = true);
    // Give time for visual transition, then hide
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _visible = false);
      }
    });
  }

  /// Call this to hide the banner (e.g., when first message is sent)
  void hide() {
    _startFadeOut();
  }

  @override
  Component build(BuildContext context) {
    if (!_visible) return SizedBox();

    final horoscope = context.watch(horoscopeProvider);
    final tip = context.watch(startupTipProvider);

    // Don't show anything if we don't have content yet
    if (horoscope == null && tip == null) return SizedBox();

    final opacity = _fading ? TextOpacity.disabled : TextOpacity.secondary;

    return Container(
      padding: EdgeInsets.only(bottom: 1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (horoscope != null)
            Text(
              horoscope,
              style: TextStyle(
                color: Colors.white.withOpacity(opacity),
                fontStyle: FontStyle.italic,
              ),
            ),
          if (horoscope != null && tip != null) SizedBox(height: 1),
          if (tip != null)
            Text(
              tip,
              style: TextStyle(color: Colors.cyan.withOpacity(opacity)),
            ),
        ],
      ),
    );
  }
}
