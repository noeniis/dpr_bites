import 'package:latlong2/latlong.dart';

class SuggestionModel {
  final LatLng point;
  final String name;
  const SuggestionModel(this.point, this.name);
}

class MapsGeometry {
  static const LatLng allowedCenter = LatLng(
    -6.209064130877545,
    106.79965206041742,
  );

  static const double allowedRadiusMeters = 400; // fallback radius
  static final Distance _geo = const Distance();

  // Polygon boundary (Kompleks DPR/MPR)
  static const List<LatLng> allowedPolygon = [
    LatLng(-6.212730101218966, 106.79752892595128),
    LatLng(-6.212360574458213, 106.798097869374),
    LatLng(-6.212254995336067, 106.79870474235824),
    LatLng(-6.212119250719337, 106.79900817885036),
    LatLng(-6.212126792087837, 106.7994405758516),
    LatLng(-6.212481236286165, 106.79948609132542),
    LatLng(-6.211832678635703, 106.80204254377149),
    LatLng(-6.211712016659093, 106.80219426201755),
    LatLng(-6.211568730525919, 106.80223219157904),
    LatLng(-6.211206744302917, 106.80260390132642),
    LatLng(-6.210248987963318, 106.80380247547028),
    LatLng(-6.209796504047311, 106.80352179671507),
    LatLng(-6.209585344753447, 106.803870748681),
    LatLng(-6.210000121857643, 106.80415142743621),
    LatLng(-6.210060453045579, 106.80436383298067),
    LatLng(-6.210075535841469, 106.80461416808669),
    LatLng(-6.210000121857643, 106.8049251904911),
    LatLng(-6.208853827930598, 106.80402246692121),
    LatLng(-6.20837871854989, 106.80359006991996),
    LatLng(-6.2079941058801715, 106.80331697707706),
    LatLng(-6.2074435813740605, 106.80282389277737),
    LatLng(-6.20719471394273, 106.80258114358368),
    LatLng(-6.206470735292228, 106.80193634103793),
    LatLng(-6.208484298449314, 106.79953919275025),
    LatLng(-6.208318387169288, 106.79947850545183),
    LatLng(-6.2076547415266115, 106.79893231976602),
    LatLng(-6.20759441006717, 106.79873508602888),
    LatLng(-6.207624575799798, 106.79854543822132),
    LatLng(-6.207858360169064, 106.79826475946612),
    LatLng(-6.207865901598605, 106.79815855669386),
    LatLng(-6.208016730166707, 106.79787029202636),
    LatLng(-6.208137392990108, 106.79761237100809),
    LatLng(-6.208318387173359, 106.79755168370966),
    LatLng(-6.208378718553962, 106.79767305830649),
    LatLng(-6.209954873423296, 106.79688412342699),
    LatLng(-6.210241446569706, 106.79683860794492),
    LatLng(-6.21070147149229, 106.79692963889256),
    LatLng(-6.210927713110037, 106.79693722480486),
    LatLng(-6.2110936235679395, 106.79707377122632),
    LatLng(-6.211432985705341, 106.7973241063323),
    LatLng(-6.211704475257758, 106.7970206698402),
    LatLng(-6.212737642551843, 106.79749858231528),
  ];

  // World polygon to create a mask (outer) with allowed polygon as a hole
  static const List<LatLng> worldMask = [
    LatLng(-89, -180),
    LatLng(-89, 180),
    LatLng(89, 180),
    LatLng(89, -180),
  ];

  static bool isAllowed(LatLng p) {
    if (allowedPolygon.isNotEmpty) {
      return isInPolygon(p, allowedPolygon);
    }
    final d = _geo.distance(allowedCenter, p); // meters
    return d <= allowedRadiusMeters;
  }

  // Ray-casting algorithm for point in polygon
  static bool isInPolygon(LatLng point, List<LatLng> polygon) {
    final x = point.longitude;
    final y = point.latitude;
    bool inside = false;
    for (int i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      final xi = polygon[i].longitude;
      final yi = polygon[i].latitude;
      final xj = polygon[j].longitude;
      final yj = polygon[j].latitude;

      final denom = (yj - yi);
      final ratio = denom == 0 ? 1e-12 : denom;
      final intersect =
          ((yi > y) != (yj > y)) && (x < (xj - xi) * (y - yi) / ratio + xi);
      if (intersect) inside = !inside;
    }
    return inside;
  }

  static LatLng get defaultCenter {
    if (allowedPolygon.isNotEmpty) {
      return polygonCentroid(allowedPolygon);
    }
    return allowedCenter;
  }

  static LatLng polygonCentroid(List<LatLng> pts) {
    double lat = 0, lon = 0;
    for (final p in pts) {
      lat += p.latitude;
      lon += p.longitude;
    }
    return LatLng(lat / pts.length, lon / pts.length);
  }
}
