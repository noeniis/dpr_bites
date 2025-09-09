import 'package:flutter/foundation.dart';

@immutable
class RatingPageFetchResult {
  final double rating;
  final int ratingCount;
  final String? geraiName;
  final List<Map<String, dynamic>> breakdown; // [{star, count}]
  final List<Map<String, dynamic>> reviews; // normalized entries
  final String? error;

  const RatingPageFetchResult({
    required this.rating,
    required this.ratingCount,
    required this.breakdown,
    required this.reviews,
    this.geraiName,
    this.error,
  });

  bool get success => error == null;
}
