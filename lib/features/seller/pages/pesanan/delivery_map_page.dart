import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class DeliveryMapPage extends StatelessWidget {
  final double lat;
  final double lng;
  final String? address;

  const DeliveryMapPage({
    super.key,
    required this.lat,
    required this.lng,
    this.address,
  });

  @override
  Widget build(BuildContext context) {
    final LatLng point = LatLng(lat, lng);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lokasi Pengantaran'),
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: point,
          initialZoom: 17,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.dpr_bites',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: point,
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
      ),
      bottomNavigationBar: address != null && address!.isNotEmpty
          ? Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                address!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
            )
          : null,
    );
  }
}
