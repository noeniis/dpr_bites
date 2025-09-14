import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' show LatLng;
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:location/location.dart' as loc;
import '../../../../app/gradient_background.dart';
import '../../../../common/widgets/custom_widgets.dart';
import '../../../../common/data/dummy_address.dart';
import '../../../../common/data/address_store.dart';
import 'package:dpr_bites/features/user/services/home_page_service.dart';
import 'filter_category_sheet.dart';
import 'package:dpr_bites/features/user/pages/cart/cart.dart';
import 'filter_price_sheet.dart';
import 'package:dpr_bites/features/user/pages/search/search_page.dart';
import 'package:dpr_bites/features/user/pages/restaurant_detail/restaurant_detail_page.dart';
import 'package:dpr_bites/features/user/pages/profile/profile_page.dart';
import 'package:dpr_bites/features/user/pages/history/history_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with RouteAware, WidgetsBindingObserver {
  String? searchQuery;
  String? selectedRating;
  String? selectedPrice;
  String? selectedCategory;
  final searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  // Data restoran dari API
  List<Map<String, dynamic>> _restaurants = [];
  bool _loadingRestaurants = true;
  bool _errorRestaurants = false;

  String _buildingName = '';
  String _detailPengantaran = '';

  bool _locationHandled = false; // ensure only once per mount
  bool _outOfRangeDialogOpen = false;
  bool _serviceDialogOpen = false;
  bool _usedCurrentLocation =
      false; // set true after we successfully use GPS-based address
  StreamSubscription<ServiceStatus>? _serviceSub;

  // Polygon Komplek DPR/MPR RI (allowed area)
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchUserAddress();
    _fetchRestaurants();
    _searchFocus.addListener(() => setState(() {}));
    searchController.addListener(() => setState(() {}));

    // Coba minta izin lokasi dan isi alamat otomatis (tanpa mengubah flow lain)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeRequestLocationAndFill();
    });

    // Dengarkan perubahan status layanan lokasi (GPS diaktifkan/dimatikan)
    _serviceSub = Geolocator.getServiceStatusStream().listen((status) async {
      if (!mounted) return;
      if (status == ServiceStatus.disabled) {
        _usedCurrentLocation = false; // akan coba lagi nanti ketika aktif
        if (!_serviceDialogOpen) {
          await _promptEnableLocationServices();
        }
      } else if (status == ServiceStatus.enabled) {
        // Saat layanan aktif lagi, coba ambil lokasi dan perbarui alamat
        await _fetchAndSetCurrentAddress();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Daftarkan route observer jika tersedia
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      _routeObserverSubscribe(route);
    }
  }

  void _routeObserverSubscribe(PageRoute<dynamic> route) {
    // Cari RouteObserver di Navigator (global observer bisa dibuat di main)
    // Jika belum ada global, kita skip tanpa error.
    final navigator = route.navigator;
    if (navigator != null) {
      // Tidak ada referensi langsung ke observer global sekarang, jadi manual call not possible.
      // Alternatif: gunakan addPostFrameCallback untuk clear ketika muncul kembali (fallback simple).
    }
  }

  // Request lokasi, cek dalam polygon, reverse geocode dan isi header.
  Future<void> _maybeRequestLocationAndFill() async {
    if (_locationHandled) return;
    _locationHandled = true;

    try {
      // 1) Minta izin dulu agar prompt tetap muncul walau layanan lokasi mati
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return; // pakai alamat_utama
        }
      }
      if (permission == LocationPermission.deniedForever) {
        // Pengguna menolak permanen, biarkan fallback alamat_utama
        return;
      }

      // 2) Pastikan layanan lokasi aktif; jika tidak, minta user menyalakan
      var serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled && mounted) {
        await _promptEnableLocationServices();
        // Coba cek ulang setelah user menutup dialog / kembali dari pengaturan
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          // Masih mati, biarkan fallback alamat_utama
          return;
        }
      }
      // 3) Ambil posisi akurat dan perbarui alamat
      await _fetchAndSetCurrentAddress();
    } catch (_) {
      // Abaikan error; tetap pakai alamat_utama
    }
  }

  // Ray casting algorithm: treat longitude as X, latitude as Y
  bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
    int intersections = 0;
    final px = point.longitude; // X
    final py = point.latitude; // Y
    for (int i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      final xi = polygon[i].longitude;
      final yi = polygon[i].latitude;
      final xj = polygon[j].longitude;
      final yj = polygon[j].latitude;

      final bool intersect =
          ((yi > py) != (yj > py)) &&
          (px <
              (xj - xi) * (py - yi) / ((yj - yi) == 0 ? 1e-12 : (yj - yi)) +
                  xi);
      if (intersect) intersections++;
    }
    return (intersections % 2) == 1;
  }

  String _joinNonEmpty(List<String?> parts) {
    return parts
        .whereType<String>()
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .join(', ');
  }

  // Prompt untuk menyalakan layanan lokasi (GPS)
  Future<void> _promptEnableLocationServices() async {
    if (_serviceDialogOpen) return;
    _serviceDialogOpen = true;
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: false,
        backgroundColor: Colors.transparent,
        builder: (ctx) => _EnableLocationBottomSheet(
          onOpenSettings: () async {
            await Geolocator.openLocationSettings();
            if (ctx.mounted) Navigator.of(ctx).pop();
          },
          onLater: () async {
            // User memilih nanti saja: kembalikan ke alamat_utama
            await _fetchUserAddress();
            if (ctx.mounted) Navigator.of(ctx).pop();
          },
        ),
      );
    } finally {
      _serviceDialogOpen = false;
    }
  }

  // Reverse geocoding lewat native Geocoding (Android/iOS), berbahasa Indonesia.
  // Mengembalikan (street, details, countryCode) dengan format:
  // street  => hanya nama jalan, mis: "JL. Kebagusan 1"
  // details => (kelurahan,kecamatan,kota/kabupaten,provinsi)
  Future<({String street, String details, String countryCode})>
  _reverseGeocodeNative(double lat, double lon) async {
    try {
      final placemarks = await geocoding.placemarkFromCoordinates(
        lat,
        lon,
        localeIdentifier: 'id_ID',
      );
      if (placemarks.isEmpty) return (street: '', details: '', countryCode: '');

      // Pilih placemark yang paling kaya informasi
      geocoding.Placemark pick = placemarks.first;
      for (final p in placemarks) {
        final richness = [
          p.thoroughfare,
          p.street,
          p.subLocality,
          p.locality,
          p.subAdministrativeArea,
          p.administrativeArea,
        ].where((e) => (e ?? '').trim().isNotEmpty).length;
        final currRichness = [
          pick.thoroughfare,
          pick.street,
          pick.subLocality,
          pick.locality,
          pick.subAdministrativeArea,
          pick.administrativeArea,
        ].where((e) => (e ?? '').trim().isNotEmpty).length;
        if (richness > currRichness) pick = p;
      }

      // Street: gunakan thoroughfare atau street; jika kosong, jatuhkan ke name/subLocality/locality/subAdministrativeArea
      String rawStreet = (pick.thoroughfare ?? pick.street ?? '').trim();
      final lower = rawStreet.toLowerCase();
      if (lower.contains('unnamed') ||
          lower.contains('google') ||
          lower.contains('building')) {
        rawStreet = '';
      }
      if (rawStreet.isEmpty) {
        rawStreet = (pick.name ?? '').trim();
      }
      if (rawStreet.isEmpty) {
        rawStreet = (pick.subLocality ?? '').trim();
      }
      if (rawStreet.isEmpty) {
        rawStreet = (pick.locality ?? '').trim();
      }
      if (rawStreet.isEmpty) {
        rawStreet = (pick.subAdministrativeArea ?? '').trim();
      }

      String streetName = rawStreet;
      if (streetName.toLowerCase().startsWith('jalan ')) {
        streetName = streetName.replaceFirst(
          RegExp(r'^jalan\s+', caseSensitive: false),
          '',
        );
      }
      if (streetName.isNotEmpty &&
          !(streetName.toLowerCase().startsWith('jl') ||
              streetName.toLowerCase().startsWith('jln') ||
              streetName.toLowerCase().startsWith('jalan'))) {
        streetName = 'JL. $streetName';
      } else if (streetName.toLowerCase().startsWith('jl')) {
        // Normalisasi ke "JL." kapital
        streetName = streetName.replaceFirst(
          RegExp(r'^jl\.?\s*', caseSensitive: false),
          'JL. ',
        );
      }

      // Komponen wilayah: kelurahan, kecamatan, kota/kabupaten, provinsi
      final kelurahan = pick.subLocality?.trim();
      final kecamatan = pick.locality?.trim();
      final kotaKab = pick.subAdministrativeArea?.trim();
      final provinsi = pick.administrativeArea?.trim();

      final detailsParts = <String?>[kelurahan, kecamatan, kotaKab, provinsi];
      final details = _joinNonEmpty(detailsParts);
      final cc = (pick.isoCountryCode ?? pick.country ?? '').toUpperCase();

      return (street: streetName, details: details, countryCode: cc);
    } catch (_) {
      return (street: '', details: '', countryCode: '');
    }
  }

  // Deteksi koordinat default emulator (sekitar Googleplex, Mountain View)
  bool _looksLikeDefaultUS(double lat, double lon) {
    final bool nearGoogleplex =
        lat > 37.3 && lat < 37.5 && lon > -122.2 && lon < -121.9;
    final bool nearNullIsland = lat.abs() < 0.0001 && lon.abs() < 0.0001;
    return nearGoogleplex || nearNullIsland;
  }

  Future<void> _showInfo(String message) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
  }

  // Ambil posisi yang lebih akurat (coba stream jika awalnya kurang akurat)
  Future<Position> _getAccuratePosition() async {
    // Coba gunakan plugin 'location' untuk koordinat akurat saat ini
    try {
      final location = loc.Location();
      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          // Jatuh ke Geolocator
          throw Exception('service disabled');
        }
      }
      var permission = await location.hasPermission();
      if (permission == loc.PermissionStatus.denied) {
        permission = await location.requestPermission();
        if (permission == loc.PermissionStatus.denied) {
          throw Exception('perm denied');
        }
      }
      if (permission == loc.PermissionStatus.deniedForever) {
        throw Exception('perm denied forever');
      }
      await location.changeSettings(
        accuracy: loc.LocationAccuracy.navigation,
        interval: 0,
        distanceFilter: 0,
      );
      final data = await location.getLocation();
      if (data.latitude != null && data.longitude != null) {
        // Bungkus ke Position agar kompatibel dengan downstream
        return Position(
          latitude: data.latitude!,
          longitude: data.longitude!,
          timestamp: DateTime.now(),
          accuracy: (data.accuracy ?? 50).toDouble(),
          altitude: (data.altitude ?? 0).toDouble(),
          heading: (data.heading ?? 0).toDouble(),
          speed: (data.speed ?? 0).toDouble(),
          speedAccuracy: (data.speedAccuracy ?? 0).toDouble(),
          altitudeAccuracy: 0.0,
          headingAccuracy: 0.0,
        );
      }
      // Jika null, fallback ke Geolocator
    } catch (_) {}

    Position pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.bestForNavigation,
      timeLimit: const Duration(seconds: 10),
    );
    try {
      // Jika akurasi > 80m, coba tunggu update yang lebih baik sebentar
      if (pos.accuracy > 80) {
        final settings = const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 0,
        );
        final improved =
            await Geolocator.getPositionStream(locationSettings: settings)
                .firstWhere((p) => p.accuracy <= 50)
                .timeout(const Duration(seconds: 8));
        return improved;
      }
    } catch (_) {
      // Abaikan dan gunakan posisi awal
    }
    return pos;
  }

  // Cek izin & layanan, ambil lokasi akurat, cek polygon, reverse geocode OSM, lalu isi header
  Future<void> _fetchAndSetCurrentAddress() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      var pos = await _getAccuratePosition();

      // Check polygon; show popup jika di luar jangkauan
      final inside = _isPointInPolygon(
        LatLng(pos.latitude, pos.longitude),
        _allowedPolygon,
      );
      if (!inside && mounted && !_outOfRangeDialogOpen) {
        _outOfRangeDialogOpen = true;
        try {
          await showDialog(
            context: context,
            barrierDismissible: true,
            builder: (ctx) => const _OutOfRangeModernDialog(),
            useRootNavigator: true,
          );
        } finally {
          if (mounted) _outOfRangeDialogOpen = false;
        }
      }

      var result = await _reverseGeocodeNative(pos.latitude, pos.longitude);

      // Jika hasil geocoding tidak di Indonesia atau terlihat default emulator,
      // coba sekali lagi dengan menunggu update posisi baru.
      if ((result.countryCode != 'ID' ||
              _looksLikeDefaultUS(pos.latitude, pos.longitude)) &&
          mounted) {
        try {
          final settings = const LocationSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            distanceFilter: 0,
          );
          // Ambil satu update baru dalam 10 detik
          pos = await Geolocator.getPositionStream(
            locationSettings: settings,
          ).first.timeout(const Duration(seconds: 10));
          result = await _reverseGeocodeNative(pos.latitude, pos.longitude);
        } catch (_) {
          // biarkan result lama
        }
      }
      if (!mounted) return;
      // Jika gagal menyusun nama jalan, jangan tampilkan kosong—kembalikan ke alamat_utama
      // Jika masih kosong atau bukan Indonesia, fallback ke alamat_utama
      if (result.street.trim().isEmpty || result.countryCode != 'ID') {
        if (result.countryCode != 'ID') {
          await _showInfo(
            'Lokasi perangkat belum akurat. Menggunakan alamat tersimpan.',
          );
        }
        await _fetchUserAddress();
        return;
      }
      setState(() {
        _buildingName = result.street;
        _detailPengantaran = result.details.isNotEmpty
            ? '(${result.details})'
            : '';

        _usedCurrentLocation = true;
      });
    } catch (_) {
      // Biarkan fallback
    }
  }

  @override
  void didPopNext() {
    // Dipanggil saat kembali ke halaman ini dari halaman lain
    if (mounted) {
      setState(() {
        searchController.clear();
      });
      // Jika belum pernah berhasil pakai lokasi saat ini, coba lagi
      if (!_usedCurrentLocation) {
        _locationHandled = false;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _maybeRequestLocationAndFill();
        });
      }
    }
  }

  @override
  void dispose() {
    _searchFocus.dispose();
    searchController.dispose();
    _serviceSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (!mounted) return;
    if (state == AppLifecycleState.resumed) {
      // Saat kembali dari Settings, cek layanan & izin, lalu refresh alamat bila memungkinkan
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      final perm = await Geolocator.checkPermission();
      if (serviceEnabled &&
          (perm == LocationPermission.always ||
              perm == LocationPermission.whileInUse)) {
        await _fetchAndSetCurrentAddress();
      }
    }
  }

  Future<void> _fetchUserAddress() async {
    final res = await HomePageService.fetchUserAddress();
    if (!mounted) return;
    setState(() {
      if (res.hasAddress && res.address != null) {
        _buildingName = res.address!.buildingName;
        _detailPengantaran = res.address!.detailPengantaran;
      } else {
        _buildingName = 'Tambah Alamat Disini';
        _detailPengantaran = '';
      }
    });
  }

  Future<void> _fetchRestaurants({
    double? minRating,
    String? priceLabel,
  }) async {
    setState(() {
      _loadingRestaurants = true;
      _errorRestaurants = false;
    });
    final res = await HomePageService.fetchRestaurants(
      minRating: minRating,
      priceLabel: priceLabel,
    );
    if (!mounted) return;
    setState(() {
      _restaurants = res.restaurants
          .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
          .toList();
      _errorRestaurants = !res.success;
      _loadingRestaurants = false;
    });
  }

  String _formatRupiah(dynamic value) {
    if (value == null) return '-';
    int? v;
    if (value is int) {
      v = value;
    } else if (value is String) {
      v = int.tryParse(value);
    }
    if (v == null) return '-';
    final s = v.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final pos = s.length - i;
      buf.write(s[i]);
      if (pos > 1 && pos % 3 == 1) buf.write('.');
    }
    return 'Rp${buf.toString()}';
  }

  // Filter function (menggunakan data dari API)
  List<Map<String, dynamic>> get filteredRestaurants {
    List<Map<String, dynamic>> restos = List<Map<String, dynamic>>.from(
      _restaurants,
    );

    // Filter rating
    if (selectedRating != null && selectedRating == '4.5') {
      restos = restos.where((r) => (r['rating'] ?? 0) >= 4.5).toList();
    }

    // Filter price range
    if (selectedPrice != null && selectedPrice!.contains('-')) {
      final range = selectedPrice!.split('-');
      final min = int.tryParse(range[0].replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      final max =
          int.tryParse(range[1].replaceAll(RegExp(r'[^0-9]'), '')) ?? 1000000;
      restos = restos.where((resto) {
        final etalase = resto['etalase'] as List<dynamic>?;
        if (etalase == null) return false;
        for (final e in etalase) {
          final menus = e['menus'] as List<dynamic>?;
          if (menus == null) continue;
          for (final m in menus) {
            final price = m['price'] as int?;
            if (price != null && price >= min && price <= max) {
              return true;
            }
          }
        }
        return false;
      }).toList();
    } else if (selectedPrice != null && selectedPrice!.contains('>')) {
      final min =
          int.tryParse(selectedPrice!.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      restos = restos.where((resto) {
        final etalase = resto['etalase'] as List<dynamic>?;
        if (etalase == null) return false;
        for (final e in etalase) {
          final menus = e['menus'] as List<dynamic>?;
          if (menus == null) continue;
          for (final m in menus) {
            final price = m['price'] as int?;
            if (price != null && price > min) {
              return true;
            }
          }
        }
        return false;
      }).toList();
    }

    return restos;
  }

  @override
  Widget build(BuildContext context) {
    // Listen to AddressStore so AppBar updates when address changes
    final store = AddressStore.instance;
    return GradientBackground(
      child: Scaffold(
        extendBody: true,
        backgroundColor: Colors.transparent,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(90),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
            toolbarHeight: 90,
            title: AnimatedBuilder(
              animation: store,
              builder: (context, _) {
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () async {
                    final result = await Navigator.pushNamed(
                      context,
                      '/address',
                    );
                    if (result is DummyAddress) {
                      store.select(result);
                      setState(() {
                        _buildingName =
                            result.alamatLengkapMaps?.isNotEmpty == true
                            ? result.alamatLengkapMaps!
                            : result.namaGedung;
                        _detailPengantaran = result.detailPengantaran;
                      });
                    }
                  },
                  child: Padding(
                    // Beri jarak kanan agar tidak mentok dengan ikon keranjang
                    padding: const EdgeInsets.fromLTRB(0, 0, 72, 0),
                    child: Transform.translate(
                      offset: const Offset(0, -21),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Alamat Pengantaran',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Builder(
                                  builder: (_) {
                                    final displayAddress =
                                        _buildingName.trim().isNotEmpty
                                        ? _buildingName
                                        : 'Tambah Alamat Disini';
                                    return Text(
                                      displayAddress,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF602829),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.keyboard_arrow_down,
                                size: 20,
                                color: Color(0xFF602829),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          if (_detailPengantaran.isNotEmpty)
                            Text(
                              _detailPengantaran,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black45,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            actions: [
              Transform.translate(
                offset: const Offset(0, -18),
                child: Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CartPage()),
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFD53D3D), Color(0xFFB03056)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFFD53D3D,
                            ).withValues(alpha: 0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.shopping_cart_outlined,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        body: SafeArea(
          bottom: false,
          child: Transform.translate(
            offset: const Offset(0, -30),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // Jarak bawah header alamat
                  const SizedBox(height: 0), // Lebih dekat ke AppBar
                  // Search Field - minimal, modern, animated
                  Builder(
                    builder: (context) {
                      final bool focused =
                          _searchFocus.hasFocus ||
                          searchController.text.isNotEmpty;
                      final gradientColors = const [
                        Color(0xFFD53D3D),
                        Color(0xFFB03056),
                      ];
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.symmetric(horizontal: 0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: (focused
                                  ? const Color(
                                      0xFFD53D3D,
                                    ).withValues(alpha: 0.18)
                                  : const Color(
                                      0xFFD53D3D,
                                    ).withValues(alpha: 0.10)),
                              blurRadius: focused ? 18 : 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(2.6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: focused
                                ? LinearGradient(
                                    colors: gradientColors,
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : LinearGradient(
                                    colors: [
                                      const Color(
                                        0xFFD53D3D,
                                      ).withValues(alpha: 0.30),
                                      const Color(
                                        0xFFB03056,
                                      ).withValues(alpha: 0.30),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                          ),
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: focused
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.98),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.search,
                                  size: 22,
                                  color: focused
                                      ? const Color(0xFFD53D3D)
                                      : Colors.black38,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    focusNode: _searchFocus,
                                    controller: searchController,
                                    textInputAction: TextInputAction.search,
                                    decoration: const InputDecoration(
                                      hintText: 'Lagi Pengen Makan Apa?',
                                      hintStyle: TextStyle(
                                        color: Colors.black38,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      isDense: true,
                                      border: InputBorder.none,
                                    ),
                                    onSubmitted: (val) {
                                      final query = val.trim();
                                      if (query.isEmpty) return;
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              SearchPage(initialQuery: query),
                                        ),
                                      ).then((_) {
                                        if (mounted) {
                                          setState(() {
                                            searchController.clear();
                                            _searchFocus.unfocus();
                                          });
                                        }
                                      });
                                    },
                                  ),
                                ),
                                if (searchController.text.isNotEmpty)
                                  GestureDetector(
                                    onTap: () {
                                      searchController.clear();
                                      _searchFocus.requestFocus();
                                    },
                                    child: Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        size: 16,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // Filter chips (modern, full-bleed horizontally scrollable)
                  SizedBox(
                    height: 52,
                    width: double.infinity,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      clipBehavior: Clip.none, // allow bounce paint outside
                      // Gutter kiri & kanan supaya bounce terlihat (visual ruang minimal)
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: [
                        const SizedBox(width: 4), // extra left gutter
                        _FilterPill(
                          label: 'Bintang 4.5+',
                          selected: selectedRating != null,
                          leading: const Icon(
                            Icons.star,
                            size: 18,
                            color: Colors.amber,
                          ),
                          onTap: () {
                            final willSelect = selectedRating == null;
                            setState(
                              () => selectedRating = willSelect ? '4.5' : null,
                            );
                            if (willSelect) {
                              _fetchRestaurants(minRating: 4.5);
                            } else {
                              _fetchRestaurants();
                            }
                          },
                        ),
                        _FilterSpacing(),
                        _FilterPill(
                          label: selectedPrice ?? 'Rentang harga',
                          selected: selectedPrice != null,
                          leading: const Icon(
                            Icons.monetization_on,
                            size: 18,
                            color: Color(0xFFD53D3D),
                          ),
                          onTap: () async {
                            final result = await showModalBottomSheet<String>(
                              context: context,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(24),
                                ),
                              ),
                              builder: (_) =>
                                  FilterPriceSheet(initialValue: selectedPrice),
                            );
                            setState(() => selectedPrice = result);
                            if (result != null) {
                              _fetchRestaurants(priceLabel: result);
                            } else {
                              if (selectedRating != null) {
                                _fetchRestaurants(minRating: 4.5);
                              } else {
                                _fetchRestaurants();
                              }
                            }
                          },
                          onClear: selectedPrice != null
                              ? () {
                                  setState(() => selectedPrice = null);
                                  if (selectedRating != null) {
                                    _fetchRestaurants(minRating: 4.5);
                                  } else {
                                    _fetchRestaurants();
                                  }
                                }
                              : null,
                        ),
                        _FilterSpacing(),
                        _FilterPill(
                          label: selectedCategory ?? 'Kuliner',
                          selected: selectedCategory != null,
                          leading: const Icon(
                            Icons.category_outlined,
                            size: 18,
                            color: Color(0xFFD53D3D),
                          ),
                          onTap: () async {
                            final result = await showModalBottomSheet<String>(
                              context: context,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(24),
                                ),
                              ),
                              builder: (_) => FilterCategorySheet(
                                initialValue: selectedCategory,
                              ),
                            );
                            setState(() => selectedCategory = result);
                          },
                          onClear: selectedCategory != null
                              ? () => setState(() => selectedCategory = null)
                              : null,
                        ),
                        const SizedBox(
                          width: 16,
                        ), // right gutter for overscroll space
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // List restoran (scroll)
                  Expanded(
                    child: _loadingRestaurants
                        ? const Center(child: CircularProgressIndicator())
                        : _errorRestaurants
                        ? Center(
                            child: TextButton(
                              onPressed: _fetchRestaurants,
                              child: const Text('Gagal memuat. Coba lagi'),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.only(
                              bottom: kBottomNavigationBarHeight + 16,
                            ),
                            itemCount: filteredRestaurants.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, idx) {
                              final resto = filteredRestaurants[idx];
                              return InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => RestaurantDetailPage(
                                        restaurantId: resto['id'].toString(),
                                      ),
                                    ),
                                  );
                                },
                                child: CustomEmptyCard(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child:
                                              (resto['profilePic'] != null &&
                                                  (resto['profilePic']
                                                          as String)
                                                      .isNotEmpty)
                                              ? Image.network(
                                                  resto['profilePic'],
                                                  width: 75,
                                                  height: 75,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) =>
                                                      Container(
                                                        width: 75,
                                                        height: 75,
                                                        color: Colors.black12,
                                                        child: const Icon(
                                                          Icons.store,
                                                          color: Colors.black38,
                                                        ),
                                                      ),
                                                )
                                              : Container(
                                                  width: 75,
                                                  height: 75,
                                                  color: Colors.black12,
                                                  child: const Icon(
                                                    Icons.store,
                                                    color: Colors.black38,
                                                  ),
                                                ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                (resto['name'] ?? '')
                                                    .toString(),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.star,
                                                    color: Colors.amber,
                                                    size: 18,
                                                  ),
                                                  const SizedBox(width: 2),
                                                  Text(
                                                    "${resto['rating']}",
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 2),
                                                  Text(
                                                    "(${resto['ratingCount']})",
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      color: Colors.black54,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  const Icon(
                                                    Icons.monetization_on,
                                                    color: Colors.grey,
                                                    size: 16,
                                                  ),
                                                  if (resto['minPrice'] !=
                                                          null &&
                                                      resto['maxPrice'] != null)
                                                    Text(
                                                      "${_formatRupiah(resto['minPrice'])} – ${_formatRupiah(resto['maxPrice'])}",
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                (resto['desc'] ?? '')
                                                    .toString(),
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: _MinimalBottomNav(currentIndex: 0),
      ),
    );
  }
}

class _MinimalBottomNav extends StatelessWidget {
  final int currentIndex; // 0 home,1 history,2 favorit,3 profile
  const _MinimalBottomNav({required this.currentIndex});

  Color get _primary => const Color(0xFFD53D3D);

  @override
  Widget build(BuildContext context) {
    Widget buildItem({required IconData icon, required int index}) {
      final bool active = index == currentIndex;
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: active
              ? null
              : () {
                  switch (index) {
                    case 0:
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const HomePage()),
                      );
                      break;
                    case 1:
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const HistoryPage()),
                      );
                      break;
                    case 2:
                      Navigator.pushReplacementNamed(context, '/favorit');
                      break;
                    case 3:
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const ProfilePage()),
                      );
                      break;
                  }
                },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: active
                    ? LinearGradient(
                        colors: [_primary, _primary.withValues(alpha: 0.75)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: active ? null : Colors.transparent,
              ),
              child: Icon(
                icon,
                size: 26,
                color: active ? Colors.white : _primary.withValues(alpha: 0.7),
              ),
            ),
          ),
        ),
      );
    }

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
        ),
        child: Row(
          children: [
            buildItem(icon: Icons.home_rounded, index: 0),
            buildItem(icon: Icons.history_rounded, index: 1),
            buildItem(icon: Icons.favorite_rounded, index: 2),
            buildItem(icon: Icons.person_rounded, index: 3),
          ],
        ),
      ),
    );
  }
}

class _FilterSpacing extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const SizedBox(width: 10);
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  final Widget? leading;
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
    this.onClear,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? const LinearGradient(colors: [Color(0xFFD53D3D), Color(0xFFB03056)])
        : const LinearGradient(colors: [Colors.white, Colors.white]);
    final borderColor = selected
        ? const Color(0xFFD53D3D)
        : Colors.grey.shade300;
    final textColor = selected ? Colors.white : const Color(0xFF602829);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: EdgeInsets.symmetric(
              horizontal: selected ? 16 : 18,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              gradient: bg,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: borderColor, width: 1.2),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: const Color(0xFFD53D3D).withValues(alpha: 0.28),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (leading != null) ...[
                  IconTheme(
                    data: IconThemeData(
                      color: selected
                          ? Colors.white
                          : leading is Icon
                          ? (leading as Icon).color
                          : null,
                      size: 18,
                    ),
                    child: leading!,
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    letterSpacing: 0.2,
                  ),
                ),
                if (onClear != null) ...[
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: onClear,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: selected ? Colors.white24 : Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        size: 14,
                        color: selected ? Colors.white : Colors.black54,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OutOfRangeModernDialog extends StatelessWidget {
  const _OutOfRangeModernDialog();

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFFD53D3D);
    const secondary = Color(0xFFB03056);
    return Dialog(
      elevation: 0,
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [primary, secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(
                Icons.location_off_rounded,
                color: Colors.white,
                size: 34,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Lokasi Anda Berada Diluar Jangkauan Komplek DPR/MPR RI.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF602829),
              ),
            ),
            const SizedBox(height: 18),
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: double.infinity,
                height: 46,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [primary, secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.28),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const Text(
                  'Tutup',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EnableLocationBottomSheet extends StatelessWidget {
  final VoidCallback onOpenSettings;
  final VoidCallback onLater;
  const _EnableLocationBottomSheet({
    required this.onOpenSettings,
    required this.onLater,
  });

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFFD53D3D);
    const secondary = Color(0xFFB03056);
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [primary, secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(
                Icons.location_searching_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Aktifkan Layanan Lokasi',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF602829),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Untuk mengisi alamat otomatis, mohon nyalakan GPS/Location Services.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onLater,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      minimumSize: const Size(0, 46),
                    ),
                    child: const Text('Nanti Saja'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onOpenSettings,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      minimumSize: const Size(0, 46),
                    ),
                    child: const Text(
                      'Buka Pengaturan',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}
