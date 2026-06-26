import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopify_app/Helper/assets_helper.dart';
import 'package:shopify_app/features/home/presentation/screens/home_screen.dart';
import 'package:shopify_app/providers/config_providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

/// Total time the splash is visible before navigating away.
const Duration _splashDuration = Duration(milliseconds: 2200);

/// Duration of the logo entrance animation.
const Duration _entranceDuration = Duration(milliseconds: 700);

/// Logo width as a fraction of the screen width.
const double _logoWidthFactor = 0.4;

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _entranceDuration,
  )..forward();

  late final Animation<double> _animation = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutBack,
  );

  @override
  void initState() {
    super.initState();
    _scheduleNavigation();
  }

  Future<void> _scheduleNavigation() async {
    await Future<void>.delayed(_splashDuration);
    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(appConfigProvider);
    final colorScheme = Theme.of(context).colorScheme;
    // AssetsHelper prepends `assets/images/`; pass the bare file name.
    final logoName = config.logoAsset.split('/').last;
    return Scaffold(
      backgroundColor: colorScheme.primary,
      body: Center(
        child: FadeTransition(
          opacity: _animation,
          child: ScaleTransition(
            scale: _animation,
            child: Semantics(
              label: config.appName,
              image: true,
              child: FractionallySizedBox(
                widthFactor: _logoWidthFactor,
                child: AssetsHelper.getImageAsset(
                  logoName,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
