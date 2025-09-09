import 'dart:convert';
import 'package:dpr_bites/features/user/models/address_maps_page_model.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class AddressMapsPageService {
  static const _headers = {
    'User-Agent': 'dpr-bites/1.0 (contact: example@example.com)',
  };

  static Future<String?> reverseGeocode(LatLng p) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=${p.latitude}&lon=${p.longitude}',
      );
      final res = await http.get(url, headers: _headers);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final disp = (data['display_name'] as String?)?.trim();
        if (disp != null && disp.isNotEmpty) return disp;
      }
    } catch (_) {}
    return null;
  }

  static Future<List<SuggestionModel>> search(
    String query, {
    int limit = 5,
  }) async {
    final q = query.trim();
    if (q.isEmpty) return [];
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(q)}&format=json&limit=$limit',
      );
      final res = await http.get(url, headers: _headers);
      if (res.statusCode == 200) {
        final list = (jsonDecode(res.body) as List<dynamic>)
            .whereType<Map<String, dynamic>>()
            .map((m) {
              final lat = double.tryParse(m['lat'] as String? ?? '');
              final lon = double.tryParse(m['lon'] as String? ?? '');
              final name = (m['display_name'] as String?)?.trim() ?? '';
              if (lat != null && lon != null) {
                return SuggestionModel(LatLng(lat, lon), name);
              }
              return null;
            })
            .whereType<SuggestionModel>()
            .toList();
        return list;
      }
    } catch (_) {}
    return [];
  }
}
