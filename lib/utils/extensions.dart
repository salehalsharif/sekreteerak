import 'package:flutter/material.dart';

/// Extension methods for common patterns
extension ContextExtensions on BuildContext {
  /// Quick access to theme
  ThemeData get theme => Theme.of(this);

  /// Quick access to text theme
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// Quick access to color scheme
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// Quick access to media query
  MediaQueryData get mediaQuery => MediaQuery.of(this);

  /// Screen width
  double get screenWidth => MediaQuery.of(this).size.width;

  /// Screen height
  double get screenHeight => MediaQuery.of(this).size.height;

  /// Bottom padding (safe area)
  double get bottomPadding => MediaQuery.of(this).padding.bottom;

  /// Show a snackbar
  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'Tajawal'),
        ),
        backgroundColor: isError
            ? Theme.of(this).colorScheme.error
            : const Color(0xFF1A1F38),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

extension StringExtensions on String {
  /// Truncate string with ellipsis
  String truncate(int maxLength) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}...';
  }
}
