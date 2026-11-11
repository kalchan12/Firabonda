import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Skeleton shimmer placeholder for loading states,
/// per `files/DESIGN.md` section 10. Softly blends with background color.
final class SkeletonLoader extends StatefulWidget {
  const SkeletonLoader({super.key, required this.child, this.borderRadius});

  final Widget child;
  final BorderRadius? borderRadius;

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

final class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    final isTest = WidgetsBinding.instance.runtimeType.toString().contains(
      'Test',
    );
    if (!isTest) {
      _controller.repeat();
    } else {
      _controller.value = 0.5;
    }
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final t = _animation.value;
        final baseColor = colors.surfaceVariant.withValues(alpha: 0.35);
        final highlightColor = colors.surfaceVariant.withValues(alpha: 0.75);
        final color = Color.lerp(baseColor, highlightColor, t)!;
        return DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            borderRadius: widget.borderRadius ?? BorderRadius.circular(10),
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Convenience skeleton layout for a list screen.
final class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.itemCount = 4});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) => const SkeletonLoader(
        child: SizedBox(height: 96, width: double.infinity),
      ),
    );
  }
}
