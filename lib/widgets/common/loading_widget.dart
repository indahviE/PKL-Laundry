import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/themes/app_theme.dart';

/// Loading Widget dengan berbagai varian
class LoadingWidget extends StatelessWidget {
  final LoadingType type;
  final String? message;
  final Color? color;
  final double size;
  final bool fullScreen;

  const LoadingWidget({
    Key? key,
    this.type = LoadingType.circular,
    this.message,
    this.color,
    this.size = 50,
    this.fullScreen = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget loadingWidget = _buildLoadingByType();

    if (fullScreen) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              loadingWidget,
              if (message != null) ...[
                const SizedBox(height: AppTheme.lg),
                Text(
                  message!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          loadingWidget,
          if (message != null) ...[
            const SizedBox(height: AppTheme.lg),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingByType() {
    switch (type) {
      case LoadingType.circular:
        return SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: 4,
            valueColor: AlwaysStoppedAnimation<Color>(
              color ?? AppTheme.primaryColor,
            ),
          ),
        );

      case LoadingType.linear:
        return SizedBox(
          width: size,
          child: LinearProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              color ?? AppTheme.primaryColor,
            ),
            backgroundColor: AppTheme.gray200,
          ),
        );

      case LoadingType.dots:
        return _buildDotsLoading();

      case LoadingType.shimmer:
        return _buildShimmerLoading();
    }
  }

  /// Dots loading animation
  Widget _buildDotsLoading() {
    return SizedBox(
      width: size,
      height: size,
      child: _DotsLoader(
        color: color ?? AppTheme.primaryColor,
      ),
    );
  }

  /// Shimmer loading animation
  Widget _buildShimmerLoading() {
    return SizedBox(
      width: size,
      height: size,
      child: _ShimmerLoader(
        color: color ?? AppTheme.primaryColor,
      ),
    );
  }
}

// ============================================
// LOADING TYPES ENUM
// ============================================

enum LoadingType {
  circular,
  linear,
  dots,
  shimmer,
}

// ============================================
// CUSTOM LOADING ANIMATIONS
// ============================================

/// Dots loading animation
class _DotsLoader extends StatefulWidget {
  final Color color;

  const _DotsLoader({
    Key? key,
    required this.color,
  }) : super(key: key);

  @override
  State<_DotsLoader> createState() => _DotsLoaderState();
}

class _DotsLoaderState extends State<_DotsLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          3,
          (index) => AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final scale = 1.0 +
                  0.3 *
                      sin((_controller.value * 2 * 3.14159) - (index * 0.2));
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Shimmer loading animation
class _ShimmerLoader extends StatefulWidget {
  final Color color;

  const _ShimmerLoader({
    Key? key,
    required this.color,
  }) : super(key: key);

  @override
  State<_ShimmerLoader> createState() => _ShimmerLoaderState();
}

class _ShimmerLoaderState extends State<_ShimmerLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withOpacity(0.3),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(
                  0.7 + (0.3 * sin(_controller.value * 2 * 3.14159)),
                ),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================
// CONVENIENCE LOADING WIDGETS
// ============================================

/// Simple circular loading
class CircularLoading extends StatelessWidget {
  final String? message;
  final Color? color;
  final double size;

  const CircularLoading({
    Key? key,
    this.message,
    this.color,
    this.size = 50,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LoadingWidget(
      type: LoadingType.circular,
      message: message,
      color: color,
      size: size,
    );
  }
}

/// Linear loading bar
class LinearLoading extends StatelessWidget {
  final String? message;
  final Color? color;

  const LinearLoading({
    Key? key,
    this.message,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LoadingWidget(
      type: LoadingType.linear,
      message: message,
      color: color,
    );
  }
}

/// Dots loading animation
class DotsLoading extends StatelessWidget {
  final String? message;
  final Color? color;

  const DotsLoading({
    Key? key,
    this.message,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LoadingWidget(
      type: LoadingType.dots,
      message: message,
      color: color,
    );
  }
}

/// Shimmer loading animation
class ShimmerLoading extends StatelessWidget {
  final String? message;
  final Color? color;

  const ShimmerLoading({
    Key? key,
    this.message,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LoadingWidget(
      type: LoadingType.shimmer,
      message: message,
      color: color,
    );
  }
}

// ============================================
// FULL SCREEN LOADING OVERLAY
// ============================================

/// Loading dialog (pop-up)
Future<void> showLoadingDialog(
  BuildContext context, {
  String? message,
  bool dismissible = false,
}) {
  return showDialog(
    context: context,
    barrierDismissible: dismissible,
    builder: (context) => PopScope(
      canPop: dismissible,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: LoadingWidget(
          message: message,
        ),
      ),
    ),
  );
}

/// Loading overlay (covers entire screen)
class LoadingOverlay extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  final String? message;
  final Color? color;

  const LoadingOverlay({
    Key? key,
    required this.child,
    required this.isLoading,
    this.message,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: LoadingWidget(
              message: message,
              color: color,
            ),
          ),
      ],
    );
  }
}

// ============================================
// SKELETON LOADING CARD (Placeholder)
// ============================================

/// Skeleton loading card untuk list items
class SkeletonCard extends StatelessWidget {
  final double height;
  final double borderRadius;

  const SkeletonCard({
    Key? key,
    this.height = 100,
    this.borderRadius = AppTheme.radiusLg,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.gray200,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: _ShimmerSkeleton(),
    );
  }
}

/// Shimmer effect untuk skeleton
class _ShimmerSkeleton extends StatefulWidget {
  @override
  State<_ShimmerSkeleton> createState() => _ShimmerSkeletonState();
}

class _ShimmerSkeletonState extends State<_ShimmerSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                AppTheme.gray200,
                AppTheme.gray300.withOpacity(0.7),
                AppTheme.gray200,
              ],
              stops: [
                0.0,
                _controller.value,
                1.0,
              ],
            ),
          ),
        );
      },
    );
  }
}

// ============================================
// SKELETON LIST LOADING
// ============================================

/// Skeleton list untuk loading state
class SkeletonList extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  final EdgeInsetsGeometry padding;

  const SkeletonList({
    Key? key,
    this.itemCount = 5,
    this.itemHeight = 100,
    this.padding = const EdgeInsets.all(AppTheme.lg),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: padding,
      itemCount: itemCount,
      separatorBuilder: (context, index) => const SizedBox(
        height: AppTheme.lg,
      ),
      itemBuilder: (context, index) => SkeletonCard(
        height: itemHeight,
      ),
    );
  }
}