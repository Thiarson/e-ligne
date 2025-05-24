import 'package:flutter/material.dart';
import 'package:ligne/ui/widgets/loading/loading.dart';

/// A customizable loading indicator with smooth animations and visual feedback
class CircularLoading extends StatefulWidget {
  /// Optional message to display below the loading indicator
  final String? message;
  
  /// Whether to show a background container
  final bool showBackground;
  
  /// Background color of the container
  final Color? backgroundColor;
  
  /// Color of the loading indicator
  final Color? color;
  
  /// Size of the loading indicator
  final double size;
  
  /// Width of the loading indicator line
  final double strokeWidth;
  
  /// Whether to show the app logo above the loading indicator
  final bool showLogo;
  
  /// Whether to enable the pulsing animation
  final bool showPulse;

  /// Creates a circular loading indicator with optional animations and styling
  const CircularLoading({
    super.key,
    this.message,
    this.showBackground = true,
    this.backgroundColor,
    this.color,
    this.size = 40.0,
    this.strokeWidth = 3.0,
    this.showLogo = false,
    this.showPulse = true,
  });

  @override
  State<CircularLoading> createState() => _CircularLoadingState();
}

class _CircularLoadingState extends State<CircularLoading> 
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _pulseAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colors = theme.colorScheme;
    
    final loadingContent = FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: widget.showPulse ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.showLogo) ...[
              _buildLogo(colors),
            ],
            _buildLoadingIndicator(colors),
            if (widget.message != null) ...[
              _buildMessage(theme, isDark),
            ],
          ],
        ),
      ),
    );

    if (!widget.showBackground) {
      return Center(child: loadingContent);
    }

    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: widget.backgroundColor ?? (isDark ? Colors.grey[900] : Colors.white),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: loadingContent,
      ),
    );
  }

  /// Builds the logo widget that appears above the loading indicator
  Widget _buildLogo(ColorScheme colors) {
    return Container(
      width: widget.size * 1.5,
      height: widget.size * 1.5,
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: colors.primary.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.account_balance_wallet_rounded,
        size: widget.size * 1.2,
        color: colors.primary,
      ),
    );
  }

  /// Builds the actual circular progress indicator
  Widget _buildLoadingIndicator(ColorScheme colors) {
    return LoadingIndicator(
      size: _getLoadingIndicatorSize(widget.size),
      color: widget.color ?? colors.primary,
    );
  }

  /// Converts the size to a LoadingIndicatorSize enum value
  LoadingIndicatorSize _getLoadingIndicatorSize(double size) {
    if (size <= 24) return LoadingIndicatorSize.small;
    if (size <= 48) return LoadingIndicatorSize.medium;
    return LoadingIndicatorSize.large;
  }

  /// Builds the optional message text that appears below the loading indicator
  Widget _buildMessage(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Text(
        widget.message!,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: isDark ? Colors.white70 : Colors.black87,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
