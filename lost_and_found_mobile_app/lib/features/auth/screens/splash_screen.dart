import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../../router/app_router.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late VideoPlayerController _videoController;
  late AnimationController _buttonController;
  late Animation<double> _buttonFade;
  bool _videoReady = false;

  @override
  void initState() {
    super.initState();

    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _buttonFade = CurvedAnimation(
      parent: _buttonController,
      curve: Curves.easeIn,
    );

    _videoController = VideoPlayerController.asset(
      'assets/videos/logo.mp4',
    )..initialize().then((_) {
        if (!mounted) return;
        setState(() => _videoReady = true);
        _videoController.setLooping(true);
        _videoController.setVolume(0);
        _videoController.play();
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) _buttonController.forward();
        });
      });
  }

  @override
  void dispose() {
    _videoController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  void _getStarted() {
    final loggedIn =
        ref.read(authStateProvider).valueOrNull != null;
    if (loggedIn) {
      context.go(AppRoutes.home);
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: _videoReady
                    ? AspectRatio(
                        aspectRatio:
                            _videoController.value.aspectRatio,
                        child: VideoPlayer(_videoController),
                      )
                    : const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(
                            AppColors.cutSage),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 48),
              child: FadeTransition(
                opacity: _buttonFade,
                child: GestureDetector(
                  onTap: _getStarted,
                  child: Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.cutSageDark,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        'Get Started',
                        style: AppTextStyles.buttonLarge.copyWith(
                          color: Colors.white,
                          fontSize: 16,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}