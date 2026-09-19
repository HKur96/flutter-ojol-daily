import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_theme.dart';

/// Reusable Shimmer loading placeholders for list screens and cards.
class ShimmerWidget extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerWidget.rectangular({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
  });

  const ShimmerWidget.circular({
    super.key,
    required double size,
  })  : width = size,
        height = size,
        borderRadius = size / 2;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppTheme.surfaceContainerHighest,
      highlightColor: AppTheme.surfaceContainerLowest,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// Shimmer placeholder for dynamic button loading state.
class ShimmerButton extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerButton({
    super.key,
    this.width = double.infinity,
    this.height = 44,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerWidget.rectangular(
      width: width,
      height: height,
      borderRadius: borderRadius,
    );
  }
}