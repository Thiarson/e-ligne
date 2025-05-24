import 'package:flutter/material.dart';
import 'loading_indicator.dart';

class LoadingScreen extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? icon;
  final bool showProgress;
  final Color? backgroundColor;
  final Color? progressColor;
  final double progressSize;

  const LoadingScreen({
    Key? key,
    this.title = 'Loading',
    this.subtitle,
    this.icon,
    this.showProgress = true,
    this.backgroundColor,
    this.progressColor,
    this.progressSize = 48.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: backgroundColor ?? colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              icon!,
              const SizedBox(height: 24),
            ],
            if (showProgress)
              LoadingIndicator.large(
                color: progressColor ?? colorScheme.primary,
              ),
            const SizedBox(height: 24),
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Text(
                  subtitle!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Predefined loading screens
  factory LoadingScreen.appLoading() {
    return const LoadingScreen(
      title: 'Loading App',
      subtitle: 'Please wait while we prepare your experience',
    );
  }

  factory LoadingScreen.contentLoading() {
    return const LoadingScreen(
      title: 'Loading Content',
      subtitle: 'Fetching the latest data for you',
    );
  }

  factory LoadingScreen.submitting() {
    return const LoadingScreen(
      title: 'Submitting',
      subtitle: 'Please wait while we process your request',
    );
  }
}
