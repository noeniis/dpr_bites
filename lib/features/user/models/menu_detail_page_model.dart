import 'package:flutter/foundation.dart';

@immutable
class MenuDetailFetchResult {
  final Map<String, dynamic>? menu; // normalized keys for UI
  final String? error;
  const MenuDetailFetchResult({this.menu, this.error});
  bool get success => error == null && menu != null;
}

@immutable
class FavoriteStatusResult {
  final bool favorited;
  final String? error;
  const FavoriteStatusResult({required this.favorited, this.error});
  bool get success => error == null;
}
