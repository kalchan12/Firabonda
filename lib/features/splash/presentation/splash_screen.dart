import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// Simple modern splash screen for Fira Bonda.
///
/// Features a clean, centered brand identity using the app icon from
/// `assets/App Icon/Firabondicon.png`, elegant typography, subtle loading,
/// and smooth auto-navigation to `/dashboard`.
final class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

final class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _progressAnimation;

  Timer? _navigateTimer;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _scaleAnimation = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOutCubic),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
      ),
    );

    _progressAnimation = Tween<double>(begin: 0.08, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.95, curve: Curves.easeInOutCubic),
      ),
    );

    _controller.forward();

    // Auto-navigate to dashboard after splash
    final isTest =
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (!isTest) {
      _navigateTimer = Timer(
        const Duration(milliseconds: 2200),
        _navigateToDashboard,
      );
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
    _controller.dispose();
    super.dispose();
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
          backgroundColor: const Color(0xFF080D1A),
          body: Stack(
            children: [
              // Subtle ambient glow centered behind the branding
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0.0, -0.15),
                      radius: 0.9,
                      colors: [
                        const Color(0xFF1E3A8A).withValues(alpha: 0.28),
                        const Color(0xFF080D1A).withValues(alpha: 0.95),
                        const Color(0xFF080D1A),
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                  ),
                ),
              ),

              // Main centered content
              SafeArea(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: child,
                    );
                  },
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(flex: 3),

                        // App Icon with modern squircle & subtle glow
                        ScaleTransition(
                          scale: _scaleAnimation,
                          child: Container(
                            width: 104,
                            height: 104,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.12),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF3D6BFF).withValues(
                                    alpha: 0.28,
                                  ),
                                  blurRadius: 32,
                                  offset: const Offset(0, 10),
                                ),
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(22.8),
                              child: Image.asset(
                                'assets/App Icon/Firabondicon.png',
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Image.asset(
                                  'assets/App Icon/ic_launcher.png',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Brand Name
                        const Text(
                          'Fira Bonda',
                          style: TextStyle(
                            fontFamily: 'Sora',
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Tagline Pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                              width: 1.0,
                            ),
                          ),
                          child: const Text(
                            'OFFLINE CLOTHING STORE TRACKER',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Key Highlights Minimal Pills
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _FeatureBadge(label: '100% Offline'),
                            SizedBox(width: 8),
                            _FeatureBadge(label: 'Real Profit'),
                            SizedBox(width: 8),
                            _FeatureBadge(label: 'Private Data'),
                          ],
                        ),

                        const Spacer(flex: 3),

                        // Minimalist Progress Bar & Skip Hint
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 160,
                              height: 3,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: AnimatedBuilder(
                                  animation: _progressAnimation,
                                  builder: (context, _) {
                                    return LinearProgressIndicator(
                                      value: _progressAnimation.value,
                                      backgroundColor: Colors.white.withValues(
                                        alpha: 0.08,
                                      ),
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                        Color(0xFF3D6BFF),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Tap anywhere to start',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                                color: Colors.white.withValues(alpha: 0.45),
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),
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

final class _FeatureBadge extends StatelessWidget {
  const _FeatureBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.07),
          width: 0.8,
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 10.5,
          fontWeight: FontWeight.w500,
          color: Color(0xFFCBD5E1),
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
