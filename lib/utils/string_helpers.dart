/// String helper utilities for safe string operations
library;

import 'dart:math' as math;

/// Safely get a prefix of a string without throwing RangeError
/// Returns empty string if input is null or empty
String safePrefix(String? s, int n) {
  if (s == null || s.isEmpty) return '';
  return s.substring(0, math.min(n, s.length));
}

/// Safely get first N items from a list
/// Returns empty list if input is null or empty
List<T> safeHead<T>(List<T>? xs, int n) {
  if (xs == null || xs.isEmpty) return const [];
  return xs.sublist(0, math.min(n, xs.length));
}

/// Get safe order ID display (first 8 characters)
String getOrderIdDisplay(String? orderId) {
  return safePrefix(orderId, 8).toUpperCase();
}

/// Get safe order ID full display (first 12 characters)
String getOrderIdFullDisplay(String? orderId) {
  return safePrefix(orderId, 12).toUpperCase();
}

/// Safely get a non-null string (returns empty string if null)
String safe(String? s) => s ?? '';

/// Safely shorten a string to n characters
String short(String s, int n) => s.length <= n ? s : s.substring(0, n);

/// Safely get a value from a map with a default fallback
T safeGet<T>(Map<String, dynamic>? map, String key, T defaultValue) {
  if (map == null) return defaultValue;
  final value = map[key];
  return (value is T) ? value : defaultValue;
}
