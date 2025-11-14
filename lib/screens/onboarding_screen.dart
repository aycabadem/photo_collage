import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, this.onFinished});

  final Future<void> Function()? onFinished;

  static const String onboardingSeenKey = 'onboardingSeen';

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final VideoPlayerController _videoController;
  bool _isVideoReady = false;

  @override
  void initState() {
    super.initState();
    _videoController = VideoPlayerController.asset('assets/videos/video1.MOV')
      ..setLooping(true)
      ..setVolume(0);
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      await _videoController.initialize();
      if (!mounted) return;
      setState(() => _isVideoReady = true);
      unawaited(_videoController.play());
    } catch (_) {
      // A silent failure still allows the rest of the onboarding to render.
    }
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(OnboardingScreen.onboardingSeenKey, true);
    if (widget.onFinished != null) {
      await widget.onFinished!();
    }
  }

  List<PageViewModel> _buildPages(BuildContext context) {
    const headline = 'Craft stunning collages fast';
    const body =
        'Customize layouts, fine-tune colors, and share your story in minutes. '
        'These quick tips walk you through every step.';

    final pageDecoration = PageDecoration(
      bodyFlex: 0,
      imageFlex: 0,
      pageColor: Theme.of(context).scaffoldBackgroundColor,
      contentMargin: const EdgeInsets.symmetric(horizontal: 24),
    );

    return List<PageViewModel>.generate(
      6,
      (_) => PageViewModel(
        titleWidget: const SizedBox.shrink(),
        bodyWidget: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _VideoPreview(
              controller: _videoController,
              isReady: _isVideoReady,
            ),
            const SizedBox(height: 24),
            Text(
              headline,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              body,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    height: 1.5,
                    color: Theme.of(context)
                        .colorScheme
                        .onBackground
                        .withValues(alpha: 0.8),
                  ),
            ),
          ],
        ),
        decoration: pageDecoration,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IntroductionScreen(
          pages: _buildPages(context),
          showSkipButton: true,
          skip: const Text(
            'Skip',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          next: Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black,
            ),
            child: const Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white,
            ),
          ),
          done: const Text(
            'Done',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          dotsDecorator: const DotsDecorator(
            activeColor: Colors.black,
            spacing: EdgeInsets.symmetric(horizontal: 4),
          ),
          curve: Curves.easeInOut,
          onDone: _completeOnboarding,
          onSkip: _completeOnboarding,
          controlsMargin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          controlsPadding: const EdgeInsets.symmetric(vertical: 8),
          nextFlex: 0,
          skipOrBackFlex: 0,
        ),
      ),
    );
  }
}

class _VideoPreview extends StatelessWidget {
  final VideoPlayerController controller;
  final bool isReady;

  const _VideoPreview({
    required this.controller,
    required this.isReady,
  });

  @override
  Widget build(BuildContext context) {
    final double aspectRatio = isReady && controller.value.isInitialized
        ? controller.value.aspectRatio
        : 9 / 16;

    return LayoutBuilder(
      builder: (context, constraints) {
        final mediaSize = MediaQuery.of(context).size;
        final double availableWidth = constraints.hasBoundedWidth &&
                constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : mediaSize.width;
        final double fallbackHeight = mediaSize.height * 0.6;
        double availableHeight = constraints.hasBoundedHeight &&
                constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : fallbackHeight;
        if (!availableHeight.isFinite || availableHeight <= 0) {
          availableHeight = fallbackHeight;
        }

        final double maxHeight =
            availableHeight.clamp(220.0, 420.0); // keep video manageable

        double width = availableWidth;
        if (!width.isFinite || width <= 0) {
          width = mediaSize.width;
        }
        double height = width / aspectRatio;
        if (!height.isFinite || height <= 0) {
          height = maxHeight;
        }

        if (height > maxHeight) {
          height = maxHeight;
          width = height * aspectRatio;
        }

        width = math.min(width, availableWidth);

        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: width,
            height: height,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.grey.shade200,
                          Colors.grey.shade300,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  if (isReady)
                    VideoPlayer(controller)
                  else
                    const Center(
                      child: CircularProgressIndicator(strokeWidth: 3),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
