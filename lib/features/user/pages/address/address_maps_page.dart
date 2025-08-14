import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter/rendering.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../../../app/gradient_background.dart';
import '../../../../common/widgets/custom_widgets.dart';

class AddressMapsPage extends StatefulWidget {
  final double? initialLat;
  final double? initialLon;
  final String? initialAddress;

  const AddressMapsPage({
    super.key,
    this.initialLat,
    this.initialLon,
    this.initialAddress,
  });

  @override
  State<AddressMapsPage> createState() => _AddressMapsPageState();
}

class _AddressMapsPageState extends State<AddressMapsPage> {
  final MapController _mapController = MapController();
  final TextEditingController _searchC = TextEditingController();

  LatLng? _picked;
  String _pickedAddress = '';
  bool _locPermDenied = false;
  bool _loading = false;
  Timer? _debounce;
  List<_Suggestion> _suggestions = [];
  LatLng? _pendingCenter;
  double _pendingZoom = 16;
  bool _mapReady = false;
  double _bottomSheetHeight = 0;

  // Allowed center: Kompleks DPR/MPR RI (approx)
  static const LatLng _allowedCenter = LatLng(
    -6.209064130877545,
    106.79965206041742,
  );
  static const double _allowedRadiusMeters = 400; // 400 m
  static final Distance _geo = const Distance();

  // Polygon boundary (Kompleks DPR/MPR) provided by user
  static const List<LatLng> _allowedPolygon = [
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
  static const List<LatLng> _worldMask = [
    LatLng(-89, -180),
    LatLng(-89, 180),
    LatLng(89, 180),
    LatLng(89, -180),
  ];

  @override
  void initState() {
    super.initState();
    // If there is an initial location (from previous selection), center to it
    if (widget.initialLat != null && widget.initialLon != null) {
      final p = LatLng(widget.initialLat!, widget.initialLon!);
      if (_isAllowed(p)) {
        _centerTo(p, setPicked: true);
        if ((widget.initialAddress ?? '').isNotEmpty) {
          _pickedAddress = widget.initialAddress!;
        } else {
          _reverseGeocode(p);
        }
      } else {
        final c = _defaultCenter;
        // don't move map yet; we'll fit to polygon on ready
        _picked = c;
        _reverseGeocode(c);
      }
    } else {
      // Default open: pick polygon centroid if available; map will fit to polygon on ready
      final c = _defaultCenter;
      _picked = c;
      _reverseGeocode(c);
    }
    _searchC.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchC.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _ensureLocationAndCenter() async {
    setState(() => _loading = true);
    try {
      final perm = await Geolocator.checkPermission();
      LocationPermission granted = perm;
      if (perm == LocationPermission.denied) {
        granted = await Geolocator.requestPermission();
      }
      if (granted == LocationPermission.deniedForever ||
          granted == LocationPermission.denied) {
        setState(() => _locPermDenied = true);
        _centerTo(_allowedCenter, setPicked: false);
      } else {
        final pos = await Geolocator.getCurrentPosition();
        final me = LatLng(pos.latitude, pos.longitude);
        if (_isAllowed(me)) {
          _centerTo(me, setPicked: true);
          await _reverseGeocode(me);
        } else {
          _showInfo('Lokasi Anda di luar jangkauan Kompleks DPR/MPR.');
          _centerTo(_allowedCenter, setPicked: false);
        }
      }
    } catch (_) {
      _centerTo(_allowedCenter, setPicked: false);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _centerTo(LatLng target, {bool setPicked = true}) {
    if (_mapReady) {
      _mapController.move(target, 16);
    } else {
      _pendingCenter = target;
      _pendingZoom = 16;
    }
    if (setPicked) {
      setState(() {
        _picked = target;
      });
    }
  }

  bool _isAllowed(LatLng p) {
    // Prefer polygon check when available; fallback to circle radius
    if (_allowedPolygon.isNotEmpty) {
      return _isInPolygon(p, _allowedPolygon);
    }
    final d = _geo.distance(_allowedCenter, p); // meters
    return d <= _allowedRadiusMeters;
  }

  // Ray-casting algorithm for point in polygon
  bool _isInPolygon(LatLng point, List<LatLng> polygon) {
    final x = point.longitude;
    final y = point.latitude;
    bool inside = false;
    for (int i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      final xi = polygon[i].longitude;
      final yi = polygon[i].latitude;
      final xj = polygon[j].longitude;
      final yj = polygon[j].latitude;

      final intersect =
          ((yi > y) != (yj > y)) &&
          (x <
              (xj - xi) * (y - yi) / ((yj - yi) == 0 ? 1e-12 : (yj - yi)) + xi);
      if (intersect) inside = !inside;
    }
    return inside;
  }

  void _onSearchChanged() {
    final text = _searchC.text;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _fetchSuggestions(text);
    });
  }

  Future<void> _reverseGeocode(LatLng latLng) async {
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
        setState(() => _pickedAddress = disp);
      }
    } catch (_) {
      // ignore
    }
  }

  Future<void> _searchAddress(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    setState(() => _loading = true);
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(q)}&format=json&limit=1',
      );
      final res = await http.get(
        url,
        headers: {'User-Agent': 'dpr-bites/1.0 (contact: example@example.com)'},
      );
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List<dynamic>;
        if (list.isNotEmpty) {
          final m = list.first as Map<String, dynamic>;
          final lat = double.tryParse(m['lat'] as String? ?? '');
          final lon = double.tryParse(m['lon'] as String? ?? '');
          if (lat != null && lon != null) {
            final p = LatLng(lat, lon);
            if (_isAllowed(p)) {
              FocusScope.of(context).unfocus();
              setState(() {
                _picked = p;
                _pickedAddress = (m['display_name'] as String?) ?? '';
              });
              _centerTo(p, setPicked: false);
              // Clear search text after applying the result
              _searchC.clear();
              // refine address in background
              unawaited(_reverseGeocode(p));
            } else {
              _showInfo('Lokasi di luar jangkauan Kompleks DPR/MPR.');
            }
          }
        }
      }
    } catch (_) {
      // ignore
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _fetchSuggestions(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      if (mounted) setState(() => _suggestions = []);
      return;
    }
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(q)}&format=json&limit=5',
      );
      final res = await http.get(
        url,
        headers: {'User-Agent': 'dpr-bites/1.0 (contact: example@example.com)'},
      );
      if (res.statusCode == 200) {
        final list = (jsonDecode(res.body) as List<dynamic>)
            .whereType<Map<String, dynamic>>()
            .map((m) {
              final lat = double.tryParse(m['lat'] as String? ?? '');
              final lon = double.tryParse(m['lon'] as String? ?? '');
              final name = (m['display_name'] as String?) ?? '';
              return (lat != null && lon != null)
                  ? _Suggestion(LatLng(lat, lon), name)
                  : null;
            })
            .whereType<_Suggestion>()
            .toList();
        // Filter to allowed radius only
        final filtered = list.where((s) => _isAllowed(s.point)).toList();
        if (mounted) setState(() => _suggestions = filtered);
      }
    } catch (_) {
      // ignore errors
    }
  }

  void _applySuggestion(_Suggestion s) async {
    if (_isAllowed(s.point)) {
      FocusScope.of(context).unfocus();
      setState(() {
        _picked = s.point;
        _pickedAddress = s.name;
        _suggestions = [];
      });
      _centerTo(s.point, setPicked: false);
      // Clear search text after applying the suggestion
      _searchC.clear();
      // refine with reverse geocode quietly
      unawaited(_reverseGeocode(s.point));
    } else {
      _showInfo('Lokasi di luar jangkauan Kompleks DPR/MPR.');
    }
  }

  void _showInfo(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  Widget _buildMap() {
    final center = _picked ?? _allowedCenter;
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: 16,
        onMapReady: () {
          _mapReady = true;
          // First time: fit to polygon if no explicit initialLat/Lon
          if (widget.initialLat == null &&
              widget.initialLon == null &&
              _allowedPolygon.isNotEmpty) {
            _fitToPolygon();
          } else if (_pendingCenter != null) {
            _mapController.move(_pendingCenter!, _pendingZoom);
            _pendingCenter = null;
          }
        },
        onTap: (tapPos, latLng) async {
          if (_isAllowed(latLng)) {
            FocusScope.of(context).unfocus();
            setState(() {
              _picked = latLng;
              _pickedAddress = '';
              _suggestions = [];
            });
            await _reverseGeocode(latLng);
          } else {
            _showInfo('Lokasi di luar jangkauan Kompleks DPR/MPR.');
          }
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.dpr_bites',
        ),
        // Dim outside allowed area by drawing a world polygon with a hole
        if (_allowedPolygon.isNotEmpty)
          PolygonLayer(
            polygons: [
              Polygon(
                points: _worldMask,
                holePointsList: [_allowedPolygon],
                color: Colors.black.withOpacity(0.5),
                borderColor: Colors.transparent,
              ),
            ],
          ),
        // Visualize allowed polygon
        if (_allowedPolygon.isNotEmpty)
          PolygonLayer(
            polygons: [
              Polygon(
                points: _allowedPolygon,
                color: const Color(0x22D53D3D), // subtle fill to highlight area
                borderColor: const Color(0xFFD53D3D),
                borderStrokeWidth: 1.5,
              ),
            ],
          ),
        if (_picked != null)
          MarkerLayer(
            markers: [
              Marker(
                point: _picked!,
                width: 40,
                height: 40,
                alignment: Alignment.topCenter,
                child: const Icon(
                  Icons.location_on,
                  size: 40,
                  color: Color(0xFFD53D3D),
                ),
              ),
            ],
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(child: _buildMap()),

              // Back button top-left
              Positioned(
                top: 12,
                left: 12,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => Navigator.maybePop(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.black87),
                  ),
                ),
              ),

              // Bottom sheet area: search with suggestions, address, confirm button
              Align(
                alignment: Alignment.bottomCenter,
                child: _MeasureSize(
                  onChange: (size) {
                    if (!mounted) return;
                    final h = size.height;
                    if (h != _bottomSheetHeight) {
                      setState(() => _bottomSheetHeight = h);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x1A000000),
                          blurRadius: 10,
                          offset: Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Search field
                        CustomInputField(
                          hintText: 'Cari Alamat',
                          controller: _searchC,
                          prefixIcon: const Icon(Icons.search),
                          onSubmitted: _searchAddress,
                        ),
                        if (_suggestions.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Container(
                            constraints: const BoxConstraints(maxHeight: 160),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFE0E0E0),
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x14000000),
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              itemCount: _suggestions.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (ctx, i) {
                                final s = _suggestions[i];
                                return ListTile(
                                  dense: true,
                                  leading: const Icon(Icons.place_outlined),
                                  title: Text(
                                    s.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  onTap: () => _applySuggestion(s),
                                );
                              },
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        if (_pickedAddress.isNotEmpty)
                          Text(
                            _pickedAddress,
                            style: TextStyle(
                              color: Colors.black.withOpacity(0.75),
                            ),
                          ),
                        const SizedBox(height: 12),
                        CustomButtonKotak(
                          text: 'Pilih Titik Lokasi',
                          onPressed: (_picked != null && _isAllowed(_picked!))
                              ? () {
                                  Navigator.pop(context, {
                                    'lat': _picked!.latitude,
                                    'lon': _picked!.longitude,
                                    'address': _pickedAddress,
                                  });
                                }
                              : null,
                        ),
                        if (_locPermDenied)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(
                              'Aktifkan akses lokasi di perangkat Anda untuk menentukan titik lokasi secara otomatis.',
                              style: TextStyle(
                                color: Colors.black.withOpacity(0.7),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        if (_loading) const SizedBox(height: 8),
                        if (_loading)
                          const LinearProgressIndicator(minHeight: 2),
                      ],
                    ),
                  ),
                ),
              ),

              // My location button bottom-right (rendered after bottom sheet to stay on top)
              Positioned(
                right: 12,
                bottom: math.max(12.0, _bottomSheetHeight + 12.0),
                child: InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: _ensureLocationAndCenter,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.my_location, color: Colors.black87),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Suggestion {
  final LatLng point;
  final String name;
  _Suggestion(this.point, this.name);
}

// Helpers for polygon center and camera fitting
extension on _AddressMapsPageState {
  LatLng get _defaultCenter {
    if (_AddressMapsPageState._allowedPolygon.isNotEmpty) {
      return _polygonCentroid(_AddressMapsPageState._allowedPolygon);
    }
    return _AddressMapsPageState._allowedCenter;
  }

  LatLng _polygonCentroid(List<LatLng> pts) {
    // Simple average of vertices; adequate for small areas
    double lat = 0, lon = 0;
    for (final p in pts) {
      lat += p.latitude;
      lon += p.longitude;
    }
    return LatLng(lat / pts.length, lon / pts.length);
  }

  void _fitToPolygon() {
    if (_AddressMapsPageState._allowedPolygon.isEmpty) return;
    double minLat = _AddressMapsPageState._allowedPolygon.first.latitude;
    double maxLat = _AddressMapsPageState._allowedPolygon.first.latitude;
    double minLon = _AddressMapsPageState._allowedPolygon.first.longitude;
    double maxLon = _AddressMapsPageState._allowedPolygon.first.longitude;
    for (final p in _AddressMapsPageState._allowedPolygon) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLon) minLon = p.longitude;
      if (p.longitude > maxLon) maxLon = p.longitude;
    }
    final bounds = LatLngBounds(LatLng(minLat, minLon), LatLng(maxLat, maxLon));
    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(36)),
    );
  }
}

// Utility widget to measure child size changes
class _MeasureSize extends SingleChildRenderObjectWidget {
  final void Function(Size size) onChange;
  const _MeasureSize({required this.onChange, required Widget child, Key? key})
    : super(key: key, child: child);

  @override
  // ignore: library_private_types_in_public_api
  RenderObject createRenderObject(BuildContext context) {
    return _RenderMeasureSize(onChange);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderMeasureSize renderObject,
  ) {
    renderObject.onChange = onChange;
  }
}

class _RenderMeasureSize extends RenderProxyBox {
  _RenderMeasureSize(this.onChange);
  void Function(Size size) onChange;
  Size? _oldSize;

  @override
  void performLayout() {
    super.performLayout();
    final newSize = child?.size ?? Size.zero;
    if (_oldSize == newSize) return;
    _oldSize = newSize;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onChange(newSize);
    });
  }
}
