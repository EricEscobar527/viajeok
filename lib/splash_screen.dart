import 'package:flutter/material.dart';

import 'app_info.dart';
import 'theme/app_theme.dart';

/// Must match the Android native launch color to avoid a flash.
const splashBackground = AppColors.background;

/// Dark splash that reveals the app name with a gradient sweep and fade,
/// then fades into [next].
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.next});

  final Widget next;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3000),
  );

  // Reveal runs during the first 60% of the timeline; the rest is a hold.
  late final Animation<double> _reveal = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
  );
  late final Animation<double> _scale = Tween(begin: 0.92, end: 1.0).animate(
    CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
    ),
  );

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 600),
            pageBuilder: (_, _, _) => widget.next,
            transitionsBuilder: (_, animation, _, child) =>
                FadeTransition(opacity: animation, child: child),
          ),
        );
      }
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: splashBackground,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            // A soft-edged band slides left to right: everything before it is
            // visible, everything after is still hidden.
            final t = _reveal.value;
            return Opacity(
              opacity: t,
              child: Transform.scale(
                scale: _scale.value,
                child: ShaderMask(
                  blendMode: BlendMode.dstIn,
                  shaderCallback: (bounds) => LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: const [Colors.white, Colors.transparent],
                    stops: [
                      (t * 1.4 - 0.4).clamp(0.0, 1.0),
                      (t * 1.4).clamp(0.0, 1.0),
                    ],
                  ).createShader(bounds),
                  child: child,
                ),
              ),
            );
          },
          child: const Text(
            AppInfo.name,
            style: TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }
}
