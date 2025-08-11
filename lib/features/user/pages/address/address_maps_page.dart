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
        _centerTo(_allowedCenter, setPicked: true);
        _reverseGeocode(_allowedCenter);
      }
    } else {
      // Default open at DPR/MPR center and set initial pick there
      _centerTo(_allowedCenter, setPicked: true);
      _reverseGeocode(_allowedCenter);
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
    final d = _geo.distance(_allowedCenter, p); // meters
    return d <= _allowedRadiusMeters;
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
          if (_pendingCenter != null) {
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
        // Visualize allowed radius
        CircleLayer(
          circles: [
            CircleMarker(
              point: _allowedCenter,
              color: const Color(0x1AD53D3D),
              borderStrokeWidth: 1.5,
              borderColor: const Color(0xFFD53D3D),
              useRadiusInMeter: true,
              radius: _allowedRadiusMeters,
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
