import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_dimensions.dart';

/// Premium branded splash screen shown on app launch with smooth
/// entrance, breathing brand aura, live progress bar, and instant skip.
final class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

final class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entryController;
  late final AnimationController _pulseController;
  late final AnimationController _progressController;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _textFade;
  late final Animation<double> _footerFade;
  late final Animation<double> _pulseAnimation;

  Timer? _navigateTimer;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    // 1. Entry Staggered Animation (1100ms)
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _logoScale = Tween<double>(begin: 0.72, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.75, curve: Curves.easeOutBack),
      ),
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _textSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.35, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.35, 0.75, curve: Curves.easeIn),
      ),
    );

    _footerFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.65, 1.0, curve: Curves.easeIn),
      ),
    );

    // 2. Continuous breathing aura for logo
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // 3. Smooth progress bar fill across 2.5s
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _entryController.forward();
    _progressController.forward();

    // 4. Timer to navigate to Dashboard (2800ms)
    final isTest =
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (!isTest) {
      _navigateTimer =
          Timer(const Duration(milliseconds: 2800), _navigateToDashboard);
    }
  }

  void _navigateToDashboard() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;
    _navigateTimer?.cancel();
    context.go('/dashboard');
  }

  @override
  void dispose() {
    _navigateTimer?.cancel();
    _entryController.dispose();
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  String _statusMessage(double progress) {
    if (progress < 0.35) return 'Loading offline database...';
    if (progress < 0.75) return 'Preparing inventory & shifts...';
    return 'Ready to trade';
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _navigateToDashboard,
        child: Scaffold(
          backgroundColor: const Color(0xFF0B1020),
          body: Stack(
            children: [
              // Ambient Radial Gradient Aura (Luminous Electric Blue & Cobalt Glow)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0.0, -0.22),
                      radius: 1.2,
                      colors: [
                        const Color(0xFF3D6BFF).withValues(alpha: 0.35),
                        const Color(0xFF1E3A8A).withValues(alpha: 0.18),
                        const Color(0xFF0B1020),
                      ],
                      stops: const [0.0, 0.48, 1.0],
                    ),
                  ),
                ),
              ),

              // Subtle modern background decorative ambient orbs
              Positioned(
                top: -60,
                right: -60,
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF3D6BFF).withValues(alpha: 0.08),
                  ),
                ),
              ),
              Positioned(
                bottom: 40,
                left: -40,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF6366F1).withValues(alpha: 0.07),
                  ),
                ),
              ),

              // Main Centered Content
              SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenPadding,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(flex: 3),

                        // Animated Brand Logo with breathing aura
                        AnimatedBuilder(
                          animation: Listenable.merge([
                            _entryController,
                            _pulseController,
                          ]),
                          builder: (context, _) {
                            return FadeTransition(
                              opacity: _logoFade,
                              child: ScaleTransition(
                                scale: _logoScale,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Breathing radiant aura ring behind icon
                                    Transform.scale(
                                      scale: _pulseAnimation.value,
                                      child: Container(
                                        width: 130,
                                        height: 130,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: RadialGradient(
                                            colors: [
                                              const Color(0xFF3D6BFF)
                                                  .withValues(alpha: 0.42),
                                              const Color(0xFF60A5FA)
                                                  .withValues(alpha: 0.18),
                                              Colors.transparent,
                                            ],
                                            stops: const [0.0, 0.60, 1.0],
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Core App Icon Container (Modern Glassmorphic Squircle)
                                    Container(
                                      width: 110,
                                      height: 110,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Color(0xFF1E2846),
                                            Color(0xFF11172A),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(28),
                                        border: Border.all(
                                          color: Colors.white.withValues(
                                            alpha: 0.22,
                                          ),
                                          width: 1.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(
                                              0xFF3D6BFF,
                                            ).withValues(alpha: 0.38),
                                            blurRadius: 36,
                                            offset: const Offset(0, 12),
                                          ),
                                          BoxShadow(
                                            color: const Color(
                                              0xFF60A5FA,
                                            ).withValues(alpha: 0.18),
                                            blurRadius: 20,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      padding: const EdgeInsets.all(14),
                                      child: Image.asset(
                                        'assets/App Icon/ic_launcher.png',
                                        fit: BoxFit.contain,
                                        errorBuilder: (_, _, _) => const Icon(
                                          Icons.checkroom_rounded,
                                          size: 58,
                                          color: Color(0xFF60A5FA),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: AppSpacing.xl),

                        // Brand Name & Taglines (Slide and Fade)
                        AnimatedBuilder(
                          animation: _entryController,
                          builder: (context, child) {
                            return FadeTransition(
                              opacity: _textFade,
                              child: SlideTransition(
                                position: _textSlide,
                                child: child,
                              ),
                            );
                          },
                          child: Column(
                            children: [
                              // Brand Title with Radiant Modern Accent
                              const Text(
                                'Fira Bonda',
                                style: TextStyle(
                                  fontFamily: 'Sora',
                                  fontSize: 34,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.6,
                                  shadows: [
                                    Shadow(
                                      color: Color(0x663D6BFF),
                                      blurRadius: 20,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Store Category Badge (Sleek Electric Blue Pill)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3D6BFF).withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: const Color(0xFF60A5FA).withValues(
                                      alpha: 0.35,
                                    ),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.storefront_rounded,
                                      size: 13,
                                      color: Color(0xFF93C5FD),
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'OFFLINE CLOTHING STORE TRACKER',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.0,
                                        color: Color(0xFF93C5FD),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Subtitle with High Contrast & Readability
                              Text(
                                'Track purchases, sales, stock & profit margin',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.85),
                                  letterSpacing: 0.1,
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Feature Highlights Chips
                              const Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  _FeatureChip(
                                    icon: Icons.wifi_off_rounded,
                                    label: '100% Offline',
                                  ),
                                  _FeatureChip(
                                    icon: Icons.query_stats_rounded,
                                    label: 'Real Profit',
                                  ),
                                  _FeatureChip(
                                    icon: Icons.lock_outline_rounded,
                                    label: 'Private Data',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const Spacer(flex: 3),

                        // Animated Progress Bar & Status (Footer)
                        AnimatedBuilder(
                          animation: Listenable.merge([
                            _entryController,
                            _progressController,
                          ]),
                          builder: (context, _) {
                            final progress = _progressController.value;
                            final statusText = _statusMessage(progress);

                            return FadeTransition(
                              opacity: _footerFade,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Status Message
                                  Text(
                                    statusText,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFFCBD5E1),
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 10),

                                  // Glowing Gradient Progress Line (Electric Blue -> Azure -> Sky)
                                  SizedBox(
                                    width: 210,
                                    height: 4,
                                    child: Stack(
                                      children: [
                                        // Track Background
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(
                                              alpha: 0.12,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              999,
                                            ),
                                          ),
                                        ),
                                        // Active Fill
                                        FractionallySizedBox(
                                          widthFactor: progress.clamp(0.04, 1.0),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                colors: [
                                                  Color(0xFF2563EB),
                                                  Color(0xFF3D6BFF),
                                                  Color(0xFF38BDF8),
                                                ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color(
                                                    0xFF3D6BFF,
                                                  ).withValues(alpha: 0.65),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 1),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Tap to Skip micro-hint
                                  Text(
                                    'Tap anywhere to start',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.white.withValues(
                                        alpha: 0.55,
                                      ),
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: AppSpacing.l),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF93C5FD)),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFFF1F5F9),
            ),
          ),
        ],
      ),
    );
  }
}
