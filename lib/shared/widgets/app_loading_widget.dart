import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Reusable shimmer loading placeholder for generic loading states.
///
/// Use factory constructors for common sizes:
/// - [AppLoadingWidget.card] — 200 × full-width, radius 20
/// - [AppLoadingWidget.tile] — 64 × full-width, radius 8
/// - [AppLoadingWidget.chip] — 32 × 80, radius 16
/// - [AppLoadingWidget.avatar] — 48 × 48, radius 24
class AppLoadingWidget extends StatelessWidget {
  /// Height of the shimmer container.
  final double height;

  /// Width of the shimmer container. Defaults to [double.infinity].
  final double width;

  /// Border radius for the container corners.
  final double borderRadius;

  /// Default loading placeholder (100 × full-width, radius 12).
  const AppLoadingWidget({
    super.key,
    this.height = 100,
    this.width = double.infinity,
    this.borderRadius = 12,
  });

  /// Card-sized shimmer: 200 height, full width, radius 20.
  const AppLoadingWidget.card({Key? key})
      : this(key: key, height: 200, width: double.infinity, borderRadius: 20);

  /// Tile-sized shimmer: 64 height, full width, radius 8.
  const AppLoadingWidget.tile({Key? key})
      : this(key: key, height: 64, width: double.infinity, borderRadius: 8);

  /// Chip-sized shimmer: 32 height, 80 width, radius 16.
  const AppLoadingWidget.chip({Key? key})
      : this(key: key, height: 32, width: 80, borderRadius: 16);

  /// Avatar-sized shimmer: 48 × 48, radius 24.
  const AppLoadingWidget.avatar({Key? key})
      : this(key: key, height: 48, width: 48, borderRadius: 24);

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade100,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}
