import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
// Polygon batas kawasan DPR (copy dari user)
const List<LatLng> dprPolygon = [
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

class SellerPickLocationPage extends StatefulWidget {
  final LatLng? initialPosition;
  final LatLng dprSouthWest;
  final LatLng dprNorthEast;

  const SellerPickLocationPage({
    super.key,
    this.initialPosition,
    required this.dprSouthWest,
    required this.dprNorthEast,
  });

  @override
  State<SellerPickLocationPage> createState() => _SellerPickLocationPageState();
}

class _SellerPickLocationPageState extends State<SellerPickLocationPage> {
  late LatLng markerPosition;
  late MapController mapController;
  String? errorText;
  String? pickedAddress;

  LatLng get dprCentroid {
    double lat = 0, lng = 0;
    for (final p in dprPolygon) {
      lat += p.latitude;
      lng += p.longitude;
    }
    return LatLng(lat / dprPolygon.length, lng / dprPolygon.length);
  }

  @override
  void initState() {
    super.initState();
    markerPosition = widget.initialPosition ?? dprCentroid;
    mapController = MapController();
    // Set default address
    reverseGeocode(markerPosition);
  }

  // Point in polygon (ray-casting)
  bool isInDprArea(LatLng point) {
    final x = point.longitude;
    final y = point.latitude;
    bool inside = false;
    for (int i = 0, j = dprPolygon.length - 1; i < dprPolygon.length; j = i++) {
      final xi = dprPolygon[i].longitude;
      final yi = dprPolygon[i].latitude;
      final xj = dprPolygon[j].longitude;
      final yj = dprPolygon[j].latitude;
      final intersect = ((yi > y) != (yj > y)) &&
          (x < (xj - xi) * (y - yi) / ((yj - yi) == 0 ? 1e-12 : (yj - yi)) + xi);
      if (intersect) inside = !inside;
    }
    return inside;
  }

  Future<void> reverseGeocode(LatLng latLng) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=${latLng.latitude}&lon=${latLng.longitude}',
      );
      final res = await http.get(
        url,
        headers: {'User-Agent': 'dpr-bites/1.0 (contact: example@example.com)'},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final disp = (data['display_name'] ?? '') as String;
        setState(() => pickedAddress = disp);
      }
    } catch (_) {
      // ignore
    }
  }

  Future<void> _goToMyLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      final latLng = LatLng(position.latitude, position.longitude);
      mapController.move(latLng, 17);
      setState(() {
        markerPosition = latLng;
      });
    } catch (e) {
      setState(() {
        errorText = 'Gagal mendapatkan lokasi: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Lokasi Gerai'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _goToMyLocation,
            tooltip: 'Ke Lokasi Saya',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              mapController: mapController,
              options: MapOptions(
                center: markerPosition,
                zoom: 16,
                onTap: (tapPos, latlng) {
                  if (isInDprArea(latlng)) {
                    setState(() {
                      markerPosition = latlng;
                      errorText = null;
                    });
                    reverseGeocode(latlng);
                  } else {
                    setState(() {
                      errorText = 'Titik harus di dalam kawasan DPR.';
                    });
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.dpr_bites',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      width: 60,
                      height: 60,
                      point: markerPosition,
                      child: GestureDetector(
                        onPanUpdate: (details) async {
                          // Drag marker (optional: implement drag logic)
                        },
                        child: const Icon(Icons.location_on, size: 40, color: Colors.red),
                      ),
                    ),
                  ],
                ),
                PolygonLayer(
                  polygons: [
                    Polygon(
                      points: dprPolygon,
                      color: Colors.green.withOpacity(0.18),
                      borderStrokeWidth: 2.5,
                      borderColor: Colors.green,
                      isFilled: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (pickedAddress != null && pickedAddress!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(pickedAddress!, style: const TextStyle(fontSize: 14)),
            ),
          if (errorText != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(errorText!, style: const TextStyle(color: Colors.red)),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (!isInDprArea(markerPosition)) {
                    setState(() {
                      errorText = 'Lokasi harus di dalam kawasan DPR.';
                    });
                    return;
                  }
                  Navigator.pop(context, {
                    'lat': markerPosition.latitude,
                    'lng': markerPosition.longitude,
                    'address': pickedAddress ?? '',
                  });
                },
                child: const Text('Pilih Lokasi Ini'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
