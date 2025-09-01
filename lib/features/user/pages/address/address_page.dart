import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../app/gradient_background.dart';
import '../../../../app/app_theme.dart';
import 'address_add_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Data model yang mencerminkan struktur alamat dari API
class ApiAddress {
  final int? id;
  final String namaPenerima;
  final String namaGedung;
  final String detailPengantaran;
  final String noHp;
  bool isDefault;

  ApiAddress({
    this.id,
    required this.namaPenerima,
    required this.namaGedung,
    required this.detailPengantaran,
    required this.noHp,
    this.isDefault = false,
  });

  factory ApiAddress.fromMap(Map<String, dynamic> m) {
    return ApiAddress(
      id: (m['id'] ?? m['id_alamat']) is int
          ? (m['id'] ?? m['id_alamat']) as int
          : int.tryParse((m['id'] ?? m['id_alamat'] ?? '').toString()),
      namaPenerima: (m['nama_penerima'] ?? '').toString(),
      namaGedung: (m['nama_gedung'] ?? '').toString(),
      detailPengantaran: (m['detail_pengantaran'] ?? '').toString(),
      noHp: (m['no_hp'] ?? '').toString(),
      isDefault:
          (m['alamat_utama'] == 1 ||
          m['alamat_utama'] == true ||
          (m['alamat_utama']?.toString() == '1')),
    );
  }
}

class AddressPage extends StatefulWidget {
  final bool popOnPick; // if true, pop with result on pick (used by Checkout)
  final int? selectedAddressId; // id alamat yang sudah terpilih (dari Checkout)
  const AddressPage({
    super.key,
    this.popOnPick = false,
    this.selectedAddressId,
  });

  @override
  State<AddressPage> createState() => _AddressPageState();
}

class _AddressPageState extends State<AddressPage> {
  List<ApiAddress> _addresses = [];
  ApiAddress? _selected;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchAddresses();
  }

  bool _isSame(ApiAddress a, ApiAddress? b) {
    if (b == null) return false;
    return a.namaGedung == b.namaGedung &&
        a.namaPenerima == b.namaPenerima &&
        a.noHp == b.noHp &&
        a.detailPengantaran == b.detailPengantaran;
  }

  void _sortWithSelectedFirst() {
    final selected = _selected;
    _addresses.sort((a, b) {
      final aSel = _isSame(a, selected);
      final bSel = _isSame(b, selected);
      if (aSel && !bSel) return -1;
      if (!aSel && bSel) return 1;
      if (a.isDefault != b.isDefault) return a.isDefault ? -1 : 1;
      return 0;
    });
  }

  Future<bool> _setDefaultOnServer(ApiAddress target) async {
    final int idUsers = await _getCurrentUserId();
    if (target.id == null) return false;
    final url = Uri.parse(
      'http://10.0.2.2/dpr_bites_api/set_default_address.php', // server should update alamat_utama
    );
    try {
      final res = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-User-Id': idUsers.toString(),
        },
        body: jsonEncode({'id_users': idUsers, 'id_alamat': target.id}),
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        return body['success'] == true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _fetchAddresses() async {
    final int idUsers = await _getCurrentUserId();
    if (idUsers <= 0) {
      // tidak ada user login, kosongkan list
      setState(() => _addresses = []);
      return;
    }
    final url = Uri.parse(
      'http://10.0.2.2/dpr_bites_api/get_user_addresses.php',
    );
    try {
      final res = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-User-Id': idUsers.toString(),
        },
        body: jsonEncode({'id_users': idUsers}),
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final list = (body['addresses'] as List?) ?? [];
        final fetched = list
            .map((e) => ApiAddress.fromMap(e as Map<String, dynamic>))
            .toList();
        setState(() {
          _addresses = fetched;
          // Prioritas: selectedAddressId -> default -> none
          if (widget.selectedAddressId != null) {
            _selected = _addresses.firstWhere(
              (a) => a.id == widget.selectedAddressId,
              orElse: () => _addresses.firstWhere(
                (a) => a.isDefault,
                orElse: () => _addresses.isNotEmpty
                    ? _addresses.first
                    : ApiAddress(
                        namaPenerima: '',
                        namaGedung: '',
                        detailPengantaran: '',
                        noHp: '',
                      ),
              ),
            );
          } else {
            _selected = _addresses
                .where((a) => a.isDefault)
                .cast<ApiAddress?>()
                .firstOrNull;
          }
          _sortWithSelectedFirst();
        });
      } else {
        setState(() => _addresses = []);
      }
    } catch (_) {
      setState(() => _addresses = []);
    }
  }

  Future<void> _makeDefault(int index) async {
    final target = _addresses[index];
    // Optimistic update (UI instant), then sync with server
    for (final a in _addresses) {
      a.isDefault = identical(a, target);
    }
    _selected = target;
    _sortWithSelectedFirst();
    setState(() {});

    final ok = await _setDefaultOnServer(target);
    if (!ok) {
      // Revert by refetching to ensure consistency
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menjadikan alamat utama')),
      );
    }
    await _fetchAddresses();

    // After UI updates, scroll to top to highlight the new default card
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<bool> _deleteOnServer(ApiAddress target) async {
    final int idUsers = await _getCurrentUserId();
    if (target.id == null) return false;
    final url = Uri.parse('http://10.0.2.2/dpr_bites_api/delete_address.php');
    try {
      final res = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-User-Id': idUsers.toString(),
        },
        body: jsonEncode({'id_users': idUsers, 'id_alamat': target.id}),
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        return body['success'] == true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _confirmHapus(int index) async {
    final a = _addresses[index];
    final bool? ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        bool deleting = false;
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 28),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0x1AE53935),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.delete_outline,
                        color: Color(0xFFE53935),
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Hapus alamat?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Yakin ingin menghapus "${a.namaGedung}"? Tindakan ini tidak dapat dibatalkan.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: deleting
                                ? null
                                : () => Navigator.of(ctx).pop(false),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: Colors.black.withOpacity(0.2),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Tidak',
                              style: TextStyle(
                                color: AppTheme.textColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: deleting
                                ? null
                                : () async {
                                    setLocal(() => deleting = true);
                                    final success = await _deleteOnServer(a);
                                    Navigator.of(ctx).pop(success);
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE53935),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 0,
                            ),
                            child: deleting
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    'Ya, Hapus',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    if (ok == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Alamat "${a.namaGedung}" dihapus')),
      );
      await _fetchAddresses();
    } else if (ok == false) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Gagal menghapus alamat')));
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<int> _getCurrentUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Cek dulu int, fallback ke string jika tidak ada
      int? id = prefs.getInt('id_users');
      if (id != null) return id;
      final s = prefs.getString('id_users');
      if (s == null) return 0;
      final v = int.tryParse(s);
      return v ?? 0;
    } catch (_) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Transform.translate(
                      offset: const Offset(-10, 0),
                      child: Row(
                        children: const [
                          // The inline back button is a const StatelessWidget
                          _BackButtonInline(),
                          SizedBox(width: 4),
                          Text(
                            'Daftar Alamat',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AddressAddPage(),
                          ),
                        );
                        await _fetchAddresses();
                      },
                      child: Row(
                        children: const [
                          Icon(Icons.add, color: AppTheme.primaryColor),
                          SizedBox(width: 4),
                          Text(
                            'Tambah Alamat',
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // List alamat
                Expanded(
                  child: _addresses.isEmpty
                      ? const Center(child: Text('Belum ada alamat'))
                      : ListView.separated(
                          controller: _scrollController,
                          itemCount: _addresses.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final a = _addresses[index];
                            final bool isDefault = a.isDefault;
                            final bool isSelected = _isSame(a, _selected);
                            final borderColor = isSelected
                                ? AppTheme.primaryColor
                                : const Color(0xFF767070);
                            return Stack(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: borderColor,
                                      width: 1.5,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x1A000000),
                                        blurRadius: 8,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      14,
                                      14,
                                      14,
                                      10,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Top content gets extra right padding when Pilih is visible
                                        Padding(
                                          padding: EdgeInsets.only(
                                            right: isSelected ? 0 : 84,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // Top line: Nama Gedung + (Utama badge if default)
                                              Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      a.namaGedung,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color:
                                                            AppTheme.textColor,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  if (isDefault)
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 4,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: AppTheme
                                                            .primaryColor,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              6,
                                                            ),
                                                      ),
                                                      child: const Text(
                                                        'Utama',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              // Penerima - No HP
                                              Text(
                                                '${a.namaPenerima} - ${a.noHp}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 14,
                                                  color: AppTheme.textColor,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              // Detail pengantaran
                                              Text(
                                                a.detailPengantaran,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.black
                                                      .withOpacity(0.55),
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                            ],
                                          ),
                                        ),

                                        // Actions
                                        if (isDefault)
                                          Align(
                                            alignment: Alignment.center,
                                            child: TextButton(
                                              onPressed: () async {
                                                await Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        AddressAddPage(
                                                          idAlamat: a.id,
                                                        ),
                                                  ),
                                                );
                                                await _fetchAddresses();
                                              },
                                              child: const Text('Ubah'),
                                            ),
                                          )
                                        else
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Align(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: TextButton(
                                                    onPressed: () =>
                                                        _makeDefault(index),
                                                    child: const Text(
                                                      'Jadikan Alamat Utama',
                                                      style: TextStyle(
                                                        color: AppTheme
                                                            .primaryColor,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  if (!isSelected)
                                                    TextButton(
                                                      onPressed: () =>
                                                          _confirmHapus(index),
                                                      child: const Text(
                                                        'Hapus',
                                                      ),
                                                    ),
                                                  if (!isSelected)
                                                    const SizedBox(width: 12),
                                                  TextButton(
                                                    onPressed: () async {
                                                      await Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (_) =>
                                                              AddressAddPage(
                                                                idAlamat: a.id,
                                                              ),
                                                        ),
                                                      );
                                                      await _fetchAddresses();
                                                    },
                                                    child: const Text('Ubah'),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                // 'Pilih' button shows only on non-selected addresses
                                if (!isSelected)
                                  Positioned(
                                    right: 16,
                                    top: 40,
                                    child: OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(
                                          color: AppTheme.primaryColor,
                                          width: 1.6,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 8,
                                        ),
                                      ),
                                      onPressed: () {
                                        _selected = a;
                                        if (widget.popOnPick) {
                                          Navigator.of(context).pop(a);
                                        } else {
                                          setState(() {
                                            _sortWithSelectedFirst();
                                          });
                                        }
                                      },
                                      child: const Text(
                                        'Pilih',
                                        style: TextStyle(
                                          color: AppTheme.primaryColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                // Ribbon top-right for selected address
                                if (isSelected)
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF2D6CDF),
                                        borderRadius: BorderRadius.only(
                                          topRight: Radius.circular(12),
                                          bottomLeft: Radius.circular(12),
                                        ),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      child: const Text(
                                        'Alamat Terpilih',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BackButtonInline extends StatelessWidget {
  const _BackButtonInline();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => Navigator.maybePop(context),
      child: const Padding(
        padding: EdgeInsets.all(4.0),
        child: Icon(Icons.arrow_back, color: AppTheme.textColor),
      ),
    );
  }
}
