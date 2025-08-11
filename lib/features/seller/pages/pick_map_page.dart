import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class PickMapPage extends StatefulWidget {
  const PickMapPage({super.key});

  @override
  State<PickMapPage> createState() => _PickMapPageState();
}

class _PickMapPageState extends State<PickMapPage> {
  final MapController _mapController = MapController();
  final TextEditingController _searchCtrl = TextEditingController();

  // lokasi awal (misal Jakarta). Nanti boleh kamu ganti ke lokasi user (GPS)
  static const LatLng _defaultCenter = LatLng(-6.200000, 106.816666);
  LatLng? selectedLocation;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar tetap ada (back button & judul)
      appBar: AppBar(title: const Text('Pilih Lokasi Warung')),
      body: Stack(
        children: [
          // PETA
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _defaultCenter,
              initialZoom: 13,
              onTap: (tapPosition, latLng) {
                setState(() => selectedLocation = latLng);
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                subdomains: const ['a', 'b', 'c'],
              ),
              MarkerLayer(
                markers: selectedLocation != null
                    ? [
                        Marker(
                          point: selectedLocation!,
                          width: 80,
                          height: 80,
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                      ]
                    : const [],
              ),
            ],
          ),

          // SEARCH BAR overlay di atas peta
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
                child: TextField(
                  controller: _searchCtrl,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Cari alamat atau tempat…',
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_searchCtrl.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() {}); // refresh suffix
                            },
                          ),
                        IconButton(
                          icon: const Icon(
                            Icons.send,
                            color: Color(0xFFD53D3D),
                          ),
                          onPressed: () {
                            // BELUM AKTIF: nanti sambungkan ke API geocoding
                            // contoh: panggil API -> dapat LatLng -> _mapController.move(...)
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Fitur pencarian akan aktif setelah API geocoding dihubungkan.\nQuery: "${_searchCtrl.text}"',
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  onChanged: (_) =>
                      setState(() {}), // agar tombol clear muncul/hilang
                  onSubmitted: (_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Fitur pencarian akan aktif setelah API geocoding dihubungkan.\nQuery: "${_searchCtrl.text}"',
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // Info koordinat terpilih di bawah
          if (selectedLocation != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 90),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    'Lat: ${selectedLocation!.latitude.toStringAsFixed(6)}, '
                    'Lng: ${selectedLocation!.longitude.toStringAsFixed(6)}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
            ),
        ],
      ),

      // Tombol konfirmasi
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.check),
        onPressed: () {
          if (selectedLocation != null) {
            Navigator.pop(context, selectedLocation);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Tap untuk memilih lokasi.')),
            );
          }
        },
      ),
    );
  }
}
