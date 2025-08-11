import 'package:flutter/material.dart';
import '../../../../app/gradient_background.dart';
import '../../../../app/app_theme.dart';
import '../../../../common/data/dummy_address.dart';
import 'address_add_page.dart';

class AddressPage extends StatefulWidget {
  const AddressPage({super.key});

  @override
  State<AddressPage> createState() => _AddressPageState();
}

class _AddressPageState extends State<AddressPage> {
  late List<DummyAddress> _addresses;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Make a mutable copy so we can re-order / toggle default locally
    _addresses = List<DummyAddress>.from(dummyAddresses);
    _sortWithDefaultOnTop();
  }

  void _sortWithDefaultOnTop() {
    _addresses.sort((a, b) {
      if (a.isDefault == b.isDefault) return 0;
      return a.isDefault ? -1 : 1;
    });
  }

  void _makeDefault(int index) {
    final target = _addresses[index];
    _addresses = _addresses
        .map(
          (a) => DummyAddress(
            namaPenerima: a.namaPenerima,
            namaGedung: a.namaGedung,
            detailPengantaran: a.detailPengantaran,
            noHp: a.noHp,
            isDefault: a == target,
          ),
        )
        .toList();
    _sortWithDefaultOnTop();
    setState(() {});
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

  void _hapus(int index) {
    final removed = _addresses.removeAt(index);
    _sortWithDefaultOnTop();
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Alamat "${removed.namaGedung}" dihapus'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _confirmHapus(int index) async {
    final a = _addresses[index];
    final bool? ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Alamat'),
        content: Text('Apakah Anda yakin ingin menghapus "${a.namaGedung}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Hapus',
              style: TextStyle(color: AppTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
    if (ok == true) {
      _hapus(index);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AddressAddPage(),
                          ),
                        );
                        if (result is DummyAddress) {
                          setState(() {
                            _addresses.add(result);
                            // If new address is default, clear previous defaults
                            if (result.isDefault) {
                              _addresses = _addresses
                                  .map(
                                    (a) => DummyAddress(
                                      namaPenerima: a.namaPenerima,
                                      namaGedung: a.namaGedung,
                                      detailPengantaran: a.detailPengantaran,
                                      noHp: a.noHp,
                                      isDefault: a == result,
                                    ),
                                  )
                                  .toList();
                            }
                            _sortWithDefaultOnTop();
                          });
                        }
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
                            final borderColor = isDefault
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
                                        // Top line: Nama Gedung + (Utama badge if default)
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Flexible(
                                              child: Text(
                                                a.namaGedung,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppTheme.textColor,
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
                                                  color: AppTheme.primaryColor,
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: const Text(
                                                  'Utama',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
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
                                            color: Colors.black.withOpacity(
                                              0.55,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),

                                        // Actions
                                        if (isDefault)
                                          Align(
                                            alignment: Alignment.centerLeft,
                                            child: TextButton(
                                              onPressed: () async {
                                                final updated =
                                                    await Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (_) =>
                                                            AddressAddPage(
                                                              initial: a,
                                                            ),
                                                      ),
                                                    );
                                                if (updated is DummyAddress) {
                                                  setState(() {
                                                    _addresses[index] = updated;
                                                    if (updated.isDefault) {
                                                      _addresses = _addresses
                                                          .map(
                                                            (
                                                              aa,
                                                            ) => DummyAddress(
                                                              namaPenerima: aa
                                                                  .namaPenerima,
                                                              namaGedung:
                                                                  aa.namaGedung,
                                                              detailPengantaran:
                                                                  aa.detailPengantaran,
                                                              noHp: aa.noHp,
                                                              isDefault:
                                                                  aa == updated,
                                                            ),
                                                          )
                                                          .toList();
                                                    }
                                                    _sortWithDefaultOnTop();
                                                  });
                                                }
                                              },
                                              child: const Text('Ubah'),
                                            ),
                                          )
                                        else
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              TextButton(
                                                onPressed: () =>
                                                    _makeDefault(index),
                                                child: const Text(
                                                  'Jadikan Alamat Utama',
                                                  style: TextStyle(
                                                    color:
                                                        AppTheme.primaryColor,
                                                  ),
                                                ),
                                              ),
                                              TextButton(
                                                onPressed: () =>
                                                    _confirmHapus(index),
                                                child: const Text('Hapus'),
                                              ),
                                              TextButton(
                                                onPressed: () async {
                                                  final updated =
                                                      await Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (_) =>
                                                              AddressAddPage(
                                                                initial: a,
                                                              ),
                                                        ),
                                                      );
                                                  if (updated is DummyAddress) {
                                                    setState(() {
                                                      _addresses[index] =
                                                          updated;
                                                      if (updated.isDefault) {
                                                        _addresses = _addresses
                                                            .map(
                                                              (
                                                                aa,
                                                              ) => DummyAddress(
                                                                namaPenerima: aa
                                                                    .namaPenerima,
                                                                namaGedung: aa
                                                                    .namaGedung,
                                                                detailPengantaran:
                                                                    aa.detailPengantaran,
                                                                noHp: aa.noHp,
                                                                isDefault:
                                                                    aa ==
                                                                    updated,
                                                              ),
                                                            )
                                                            .toList();
                                                      }
                                                      _sortWithDefaultOnTop();
                                                    });
                                                  }
                                                },
                                                child: const Text('Ubah'),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                // Ribbon top-right for default address
                                if (isDefault)
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
