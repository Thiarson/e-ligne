import 'package:flutter/material.dart';

enum LoadingIndicatorSize { small, medium, large }

class LoadingIndicator extends StatelessWidget {
  final LoadingIndicatorSize size;
  final Color? color;
  final double? value;
  final String? message;
  final bool showBackground;

  const LoadingIndicator({
    Key? key,
    this.size = LoadingIndicatorSize.medium,
    this.color,
    this.value,
    this.message,
    this.showBackground = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = this.color ?? theme.colorScheme.primary;
    
    Widget indicator = SizedBox(
      width: _getSize(),
      height: _getSize(),
      child: CircularProgressIndicator.adaptive(
        value: value,
        strokeWidth: _getStrokeWidth(),
        valueColor: AlwaysStoppedAnimation<Color>(color),
        backgroundColor: color.withOpacity(0.2),
      ),
    );

    if (message != null) {
      indicator = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          indicator,
          const SizedBox(height: 16),
          Text(
            message!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    if (showBackground) {
      return Container(
        color: theme.scaffoldBackgroundColor.withOpacity(0.8),
        child: Center(
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(16),
            color: theme.cardColor,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: indicator,
            ),
          ),
        ),
      );
    }

    return Center(child: indicator);
  }

  double _getSize() {
    switch (size) {
      case LoadingIndicatorSize.small:
        return 20.0;
      case LoadingIndicatorSize.medium:
        return 32.0;
      case LoadingIndicatorSize.large:
        return 48.0;
    }
  }

  double _getStrokeWidth() {
    switch (size) {
      case LoadingIndicatorSize.small:
        return 2.0;
      case LoadingIndicatorSize.medium:
        return 3.0;
      case LoadingIndicatorSize.large:
        return 4.0;
    }
  }

  // Convenience constructors
  factory LoadingIndicator.small({
    Color? color,
    double? value,
    String? message,
    bool showBackground = false,
  }) {
    return LoadingIndicator(
      size: LoadingIndicatorSize.small,
      color: color,
      value: value,
      message: message,
      showBackground: showBackground,
    );
  }

  factory LoadingIndicator.large({
    Color? color,
    double? value,
    String? message,
    bool showBackground = false,
  }) {
    return LoadingIndicator(
      size: LoadingIndicatorSize.large,
      color: color,
      value: value,
      message: message,
      showBackground: showBackground,
    );
  }
}

class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;
  final bool dismissible;
  final Color? color;
  final Color? backgroundColor;
  final double opacity;

  const LoadingOverlay({
    Key? key,
    required this.isLoading,
    required this.child,
    this.message,
    this.dismissible = true,
    this.color,
    this.backgroundColor,
    this.opacity = 0.6,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          GestureDetector(
            onTap: dismissible ? () {} : null,
            behavior: HitTestBehavior.opaque,
            child: Container(
              color: (backgroundColor ?? Colors.black).withOpacity(opacity),
              child: Center(
                child: LoadingIndicator.large(
                  color: color,
                  message: message,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// Extension to easily show loading overlay on any widget
extension LoadingOverlayExtension on Widget {
  Widget withLoadingOverlay({
    required bool isLoading,
    String? message,
    bool dismissible = true,
    Color? color,
    Color? backgroundColor,
    double opacity = 0.6,
  }) {
    return LoadingOverlay(
      isLoading: isLoading,
      message: message,
      dismissible: dismissible,
      color: color,
      backgroundColor: backgroundColor,
      opacity: opacity,
      child: this,
    );
  }
}
