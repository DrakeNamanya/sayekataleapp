import 'package:flutter/material.dart';

/// App Colors for SAYE Katale Agribusiness Market
/// Designed to represent agriculture, growth, and market vitality
class AppColors {
  AppColors._(); // Private constructor to prevent instantiation

  // ============================================
  // LIGHT MODE COLORS
  // ============================================

  /// Light background color - Clean, professional
  static const Color lightBackground = Color(0xFFF8F9FA); // Light gray

  /// Light card/surface color - Pure, clean
  static const Color lightCard = Color(0xFFFFFFFF); // White

  /// Primary text color - High contrast, readable
  static const Color lightText = Color(0xFF1A1A1A); // Dark gray

  /// Secondary text color - Subtle, supporting
  static const Color lightTextSecondary = Color(0xFF6C757D); // Medium gray

  /// Border color - Subtle separation
  static const Color lightBorder = Color(0xFFDEE2E6); // Light gray

  // ============================================
  // DARK MODE COLORS
  // ============================================

  /// Dark background color - Deep, comfortable
  static const Color darkBackground = Color(0xFF121212); // Dark gray

  /// Dark card/surface color - Elevated surface
  static const Color darkCard = Color(0xFF1E1E1E); // Slightly lighter dark gray

  /// Dark mode text color - High contrast
  static const Color darkText = Color(0xFFFFFFFF); // White

  /// Dark mode secondary text - Readable but subtle
  static const Color darkTextSecondary = Color(0xFFB0B0B0); // Light gray

  /// Dark mode border color - Subtle separation
  static const Color darkBorder = Color(0xFF333333); // Dark gray

  // ============================================
  // BRAND COLORS (Used in both themes)
  // ============================================

  /// Primary brand color - Agriculture, growth, life
  /// Use for: Primary buttons, active states, highlights
  static const Color primary = Color(0xFF28A745); // Green

  /// Secondary brand color - Harvest, sunshine, prosperity
  /// Use for: Secondary actions, accents, warnings
  static const Color secondary = Color(0xFFFFC107); // Amber/Yellow

  /// Accent color - Freshness, water, vitality
  /// Use for: Information, tertiary actions, highlights
  static const Color accent = Color(0xFF17A2B8); // Teal

  /// Highlight color - Urgency, attention, alerts
  /// Use for: Important notifications, featured items
  static const Color highlight = Color(0xFFDC3545); // Red

  // ============================================
  // SEMANTIC COLORS (Standardized feedback)
  // ============================================

  /// Success color - Positive actions, confirmations
  static const Color success = Color(0xFF28A745); // Green

  /// Warning color - Caution, review needed
  static const Color warning = Color(0xFFFFC107); // Amber/Yellow

  /// Danger/Error color - Critical actions, errors
  static const Color danger = Color(0xFFDC3545); // Red

  /// Info color - Neutral information, tips
  static const Color info = Color(0xFF17A2B8); // Teal

  // ============================================
  // ROLE-SPECIFIC COLORS (Optional)
  // ============================================

  /// Farmer/SHG role color
  static const Color farmerColor = Color(0xFF28A745); // Green - agriculture

  /// Buyer/SME role color
  static const Color buyerColor = Color(0xFF17A2B8); // Teal - business

  /// Supplier/PSA role color
  static const Color supplierColor = Color(0xFFFFC107); // Amber - supply chain

  // ============================================
  // CATEGORY COLORS (Product categories)
  // ============================================

  /// Poultry category color
  static const Color poultryColor = Color(0xFFFF9800); // Orange

  /// Crops category color
  static const Color cropsColor = Color(0xFF8BC34A); // Light green

  /// Livestock category color
  static const Color livestockColor = Color(0xFF795548); // Brown

  /// Inputs category color
  static const Color inputsColor = Color(0xFF9C27B0); // Purple

  // ============================================
  // GRADIENT COLORS
  // ============================================

  /// Primary gradient (green theme)
  static const List<Color> primaryGradient = [
    Color(0xFF28A745), // Green
    Color(0xFF20C997), // Lighter green
  ];

  /// Secondary gradient (amber theme)
  static const List<Color> secondaryGradient = [
    Color(0xFFFFC107), // Amber
    Color(0xFFFFD54F), // Light amber
  ];

  /// Accent gradient (teal theme)
  static const List<Color> accentGradient = [
    Color(0xFF17A2B8), // Teal
    Color(0xFF4DD0E1), // Light teal
  ];

  /// Success gradient
  static const List<Color> successGradient = [
    Color(0xFF28A745), // Green
    Color(0xFF34D058), // Light green
  ];

  /// Warning gradient
  static const List<Color> warningGradient = [
    Color(0xFFFFC107), // Amber
    Color(0xFFFFCA28), // Light amber
  ];

  /// Danger gradient
  static const List<Color> dangerGradient = [
    Color(0xFFDC3545), // Red
    Color(0xFFFF6B6B), // Light red
  ];

  // ============================================
  // HELPER METHODS
  // ============================================

  /// Get color based on current theme brightness
  static Color getTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkText
        : lightText;
  }

  /// Get secondary text color based on theme
  static Color getSecondaryTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkTextSecondary
        : lightTextSecondary;
  }

  /// Get background color based on theme
  static Color getBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkBackground
        : lightBackground;
  }

  /// Get card color based on theme
  static Color getCardColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkCard
        : lightCard;
  }

  /// Get border color based on theme
  static Color getBorderColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkBorder
        : lightBorder;
  }

  /// Create gradient from color list
  static LinearGradient createGradient(List<Color> colors) {
    return LinearGradient(
      colors: colors,
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  /// Get role color by role name
  static Color getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'shg':
      case 'farmer':
        return farmerColor;
      case 'sme':
      case 'buyer':
        return buyerColor;
      case 'psa':
      case 'supplier':
        return supplierColor;
      default:
        return primary;
    }
  }

  /// Get category color by category name
  static Color getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'poultry':
        return poultryColor;
      case 'crops':
        return cropsColor;
      case 'livestock':
        return livestockColor;
      case 'inputs':
        return inputsColor;
      default:
        return primary;
    }
  }
}
