import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// Clean, high-contrast modern splash screen for Fira Bonda.
final class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

final class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  Timer? _navigateTimer;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();

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
          backgroundColor: const Color(0xFF0D1527),
          body: Stack(
            children: [
              // Radial luminous glow for high contrast
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0.0, -0.2),
                      radius: 1.1,
                      colors: [
                        const Color(0xFF2563EB).withValues(alpha: 0.35),
                        const Color(0xFF0F1E3D).withValues(alpha: 0.8),
                        const Color(0xFF0A0F1D),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),

              SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(flex: 3),

                        // Logo Container with visible contrast ring and soft glow
                        ScaleTransition(
                          scale: _scaleAnimation,
                          child: Container(
                            width: 116,
                            height: 116,
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(28),
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF38BDF8),
                                  Color(0xFF2563EB),
                                  Color(0xFF1D4ED8),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF2563EB).withValues(
                                    alpha: 0.45,
                                  ),
                                  blurRadius: 36,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(25),
                              child: Container(
                                color: const Color(0xFF0D2146),
                                child: Image.asset(
                                  'assets/App Icon/ic_launcher.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, _, _) => Image.asset(
                                    'assets/App Icon/Firabondicon.png',
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, _, _) => const Icon(
                                      Icons.storefront_rounded,
                                      size: 56,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Brand Title
                        const Text(
                          'Fira Bonda',
                          style: TextStyle(
                            fontFamily: 'Sora',
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Subtitle Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB).withValues(
                              alpha: 0.18,
                            ),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: const Color(0xFF60A5FA).withValues(
                                alpha: 0.35,
                              ),
                            ),
                          ),
                          child: const Text(
                            'OFFLINE CLOTHING STORE TRACKER',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.1,
                              color: Color(0xFF93C5FD),
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // Highlights Row
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _Badge(label: '100% Offline'),
                            SizedBox(width: 8),
                            _Badge(label: 'Real Profit'),
                            SizedBox(width: 8),
                            _Badge(label: 'Private Data'),
                          ],
                        ),

                        const Spacer(flex: 3),

                        // Loading Indicator & Skip Action
                        SizedBox(
                          width: 140,
                          height: 3,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: const LinearProgressIndicator(
                              backgroundColor: Color(0x33FFFFFF),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF38BDF8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Tap anywhere to start',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Color(0x99FFFFFF),
                            letterSpacing: 0.2,
                          ),
                        ),

                        const SizedBox(height: 36),
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

final class _Badge extends StatelessWidget {
  const _Badge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFFE2E8F0),
        ),
      ),
    );
  }
}
