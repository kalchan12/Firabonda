import 'package:flutter/material.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/skeleton_loader.dart';

/// A rich, structured skeleton loading view for the dashboard
/// that closely mirrors the real dashboard hierarchy and cards.
final class DashboardSkeletonView extends StatelessWidget {
  const DashboardSkeletonView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Shift banner skeleton
        _SkeletonCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _SkeletonBox(width: 36, height: 36, radius: 10),
                  SizedBox(width: AppSpacing.s),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SkeletonBox(width: 120, height: 16),
                        SizedBox(height: 6),
                        _SkeletonBox(width: 180, height: 12),
                      ],
                    ),
                  ),
                  _SkeletonBox(width: 32, height: 32, radius: 16),
                ],
              ),
              SizedBox(height: AppSpacing.m),
              _SkeletonBox(width: double.infinity, height: 36, radius: 12),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.m),

        // 2. Net profit hero tile skeleton
        _SkeletonCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _SkeletonBox(width: 130, height: 14),
                  _SkeletonBox(width: 80, height: 22, radius: 11),
                ],
              ),
              SizedBox(height: AppSpacing.m),
              _SkeletonBox(width: 200, height: 36, radius: 8),
              SizedBox(height: AppSpacing.s),
              Row(
                children: [
                  _SkeletonBox(width: 16, height: 16, radius: 8),
                  SizedBox(width: 6),
                  _SkeletonBox(width: 140, height: 12),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.m),

        // 3. 2x2 Grid skeletons
        Row(
          children: [
            Expanded(
              child: _SkeletonCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _SkeletonBox(width: 90, height: 12),
                    SizedBox(height: 8),
                    _SkeletonBox(width: 110, height: 20),
                  ],
                ),
              ),
            ),
            SizedBox(width: AppSpacing.m),
            Expanded(
              child: _SkeletonCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _SkeletonBox(width: 90, height: 12),
                    SizedBox(height: 8),
                    _SkeletonBox(width: 110, height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.m),
        Row(
          children: [
            Expanded(
              child: _SkeletonCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _SkeletonBox(width: 90, height: 12),
                    SizedBox(height: 8),
                    _SkeletonBox(width: 110, height: 20),
                  ],
                ),
              ),
            ),
            SizedBox(width: AppSpacing.m),
            Expanded(
              child: _SkeletonCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _SkeletonBox(width: 90, height: 12),
                    SizedBox(height: 8),
                    _SkeletonBox(width: 110, height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.m),

        // 4. Target Card Skeleton
        _SkeletonCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _SkeletonBox(width: 18, height: 18, radius: 9),
                      SizedBox(width: 8),
                      _SkeletonBox(width: 120, height: 14),
                    ],
                  ),
                  _SkeletonBox(width: 70, height: 18, radius: 9),
                ],
              ),
              SizedBox(height: AppSpacing.m),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _SkeletonBox(width: 60, height: 22),
                  _SkeletonBox(width: 140, height: 14),
                ],
              ),
              SizedBox(height: AppSpacing.s),
              _SkeletonBox(width: double.infinity, height: 6, radius: 3),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.m),

        // 5. Paid with Credit Skeleton
        _SkeletonCard(
          child: Row(
            children: [
              _SkeletonBox(width: 36, height: 36, radius: 10),
              SizedBox(width: AppSpacing.s),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _SkeletonBox(width: 130, height: 14),
                    SizedBox(height: 6),
                    _SkeletonBox(width: 90, height: 12),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _SkeletonBox(width: 80, height: 18),
                  SizedBox(height: 4),
                  _SkeletonBox(width: 60, height: 12),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.m),

        // 6. Recent Sales Skeleton
        _SkeletonCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _SkeletonBox(width: 100, height: 16),
                  _SkeletonBox(width: 50, height: 18, radius: 9),
                ],
              ),
              SizedBox(height: AppSpacing.m),
              Row(
                children: [
                  _SkeletonBox(width: 44, height: 22, radius: 6),
                  SizedBox(width: AppSpacing.s),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SkeletonBox(width: 100, height: 14),
                        SizedBox(height: 4),
                        _SkeletonBox(width: 70, height: 11),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _SkeletonBox(width: 70, height: 14),
                      SizedBox(height: 4),
                      _SkeletonBox(width: 45, height: 11),
                    ],
                  ),
                ],
              ),
              Divider(height: 14),
              Row(
                children: [
                  _SkeletonBox(width: 44, height: 22, radius: 6),
                  SizedBox(width: AppSpacing.s),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SkeletonBox(width: 100, height: 14),
                        SizedBox(height: 4),
                        _SkeletonBox(width: 70, height: 11),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _SkeletonBox(width: 70, height: 14),
                      SizedBox(height: 4),
                      _SkeletonBox(width: 45, height: 11),
                    ],
                  ),
                ],
              ),
              Divider(height: 14),
              Row(
                children: [
                  _SkeletonBox(width: 44, height: 22, radius: 6),
                  SizedBox(width: AppSpacing.s),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SkeletonBox(width: 100, height: 14),
                        SizedBox(height: 4),
                        _SkeletonBox(width: 70, height: 11),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _SkeletonBox(width: 70, height: 14),
                      SizedBox(height: 4),
                      _SkeletonBox(width: 45, height: 11),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

final class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colors.border.withValues(alpha: 0.5)),
      ),
      child: child,
    );
  }
}

final class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({
    required this.width,
    required this.height,
    this.radius = 4,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}
