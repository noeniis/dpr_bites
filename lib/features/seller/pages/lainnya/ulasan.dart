
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../app/gradient_background.dart';
import '../../../../app/app_theme.dart';
import '../../../../common/widgets/custom_widgets.dart';


class UlasanPage extends StatefulWidget {
  const UlasanPage({Key? key}) : super(key: key);

  @override
  State<UlasanPage> createState() => _UlasanPageState();
}

class _UlasanPageState extends State<UlasanPage> {
  String filterBalasan = 'Semua'; // 'Semua', 'Sudah Dibalas', 'Belum Dibalas'

  final Map<int, TextEditingController> replyControllers = {}; // id_ulasan -> controller
  int? replyingId; // id_ulasan yang sedang dibalas (untuk dialog)
  @override
  void dispose() {
    for (final c in replyControllers.values) {
      c.dispose();
    }
    super.dispose();
  }
  Set<int> isReplying = {}; // id_ulasan sedang submit

  Future<void> submitReply(int idUlasan, String reply) async {
    setState(() { isReplying.add(idUlasan); });
    try {
      final res = await http.post(
        Uri.parse('http://10.0.2.2/dpr_bites_api/reply_ulasan.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id_ulasan': idUlasan, 'balasan': reply}),
      );
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        replyControllers[idUlasan]?.clear();
        await fetchUlasan();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Balasan terkirim')));
      } else {
        throw data['message'] ?? 'Gagal membalas';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal membalas: $e')));
    } finally {
      setState(() { isReplying.remove(idUlasan); replyingId = null; });
    }
  }
  double rating = 0;
  int reviewCount = 0;
  List<Map<String, dynamic>> breakdown = List.generate(5, (i) => {'star': 5 - i, 'count': 0});
  List<dynamic> reviews = [];
  bool isLoading = true;
  String? errorMsg;

  Future<void> fetchUlasan() async {
    setState(() { isLoading = true; errorMsg = null; });
    try {
      final prefs = await SharedPreferences.getInstance();
      final idUsers = prefs.getString('id_users');
      if (idUsers == null) throw 'User belum login';
      // Ambil id_gerai
      final resGerai = await http.post(
        Uri.parse('http://10.0.2.2/dpr_bites_api/get_gerai_by_user.php'),
        body: {'id_users': idUsers},
      );
      if (resGerai.statusCode != 200) throw 'Gagal ambil id_gerai';
      final dataGerai = jsonDecode(resGerai.body);
      if (dataGerai['success'] != true || dataGerai['id_gerai'] == null) throw 'Gagal ambil id_gerai';
      final idGerai = dataGerai['id_gerai'];
      // Fetch ulasan
      final res = await http.get(Uri.parse('http://10.0.2.2/dpr_bites_api/get_restaurant_ratings.php?id=$idGerai'));
      if (res.statusCode != 200) throw 'Gagal fetch ulasan';
      final data = jsonDecode(res.body);
      if (data['success'] != true) throw 'Gagal fetch ulasan';
      final d = data['data'] ?? {};
      setState(() {
        rating = (d['rating'] ?? 0).toDouble();
        reviewCount = d['ratingCount'] ?? 0;
        breakdown = (d['breakdown'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? breakdown;
        reviews = d['reviews'] ?? [];
        isLoading = false;
      });
    } catch (e) {
      setState(() { errorMsg = e.toString(); isLoading = false; });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchUlasan();
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: AppTheme.primaryColor),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text('Ulasan', style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppTheme.primaryColor,
          )),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMsg != null
                ? Center(child: Text(errorMsg!, style: const TextStyle(color: Colors.red)))
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card rating summary
                        CustomEmptyCard(
                          margin: const EdgeInsets.only(bottom: 18),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.star, color: Colors.amber, size: 32),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('$rating', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
                                        const Text('/5', style: TextStyle(fontSize: 15)),
                                        Text('$reviewCount Review', style: const TextStyle(fontSize: 13, color: Colors.black54)),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // Rating distribution
                                ...breakdown.map((b) {
                                  int star = b['star'] ?? 0;
                                  int count = b['count'] ?? 0;
                                  double percent = reviewCount > 0 ? count / reviewCount : 0;
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 2),
                                    child: Row(
                                      children: [
                                        Text('$star', style: const TextStyle(fontSize: 13)),
                                        const SizedBox(width: 4),
                                        Icon(Icons.star, color: Colors.amber, size: 14),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: LinearProgressIndicator(
                                            value: percent,
                                            backgroundColor: Colors.grey[200],
                                            color: Colors.amber,
                                            minHeight: 8,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                        Text('Ulasan Pembeli', style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        )),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: Row(
                                  children: [
                                    ChoiceChip(
                                      label: const Text('Semua'),
                                      selected: filterBalasan == 'Semua',
                                      onSelected: (v) => setState(() { filterBalasan = 'Semua'; }),
                                    ),
                                    const SizedBox(width: 8),
                                    ChoiceChip(
                                      label: const Text('Sudah Dibalas'),
                                      selected: filterBalasan == 'Sudah Dibalas',
                                      onSelected: (v) => setState(() { filterBalasan = 'Sudah Dibalas'; }),
                                    ),
                                    const SizedBox(width: 8),
                                    ChoiceChip(
                                      label: const Text('Belum Dibalas'),
                                      selected: filterBalasan == 'Belum Dibalas',
                                      onSelected: (v) => setState(() { filterBalasan = 'Belum Dibalas'; }),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ...reviews.where((r) {
                          final balasan = (r['balasan'] ?? '').toString().trim();
                          if (filterBalasan == 'Sudah Dibalas') return balasan.isNotEmpty;
                          if (filterBalasan == 'Belum Dibalas') return balasan.isEmpty;
                          return true;
                        }).map((r) {
                          final idUlasan = r['id_ulasan'] ?? 0;
                          final balasan = (r['balasan'] ?? '').toString().trim();
                          if (!replyControllers.containsKey(idUlasan)) {
                            replyControllers[idUlasan] = TextEditingController();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: CustomEmptyCard(
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        CircleAvatar(
                                          radius: 28,
                                          backgroundImage: r['photo'] != null && r['photo'].toString().isNotEmpty
                                              ? NetworkImage(r['photo'])
                                              : const AssetImage('lib/assets/images/iconUser.png') as ImageProvider,
                                          backgroundColor: Colors.grey[200],
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(r['name'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                                              if ((r['pesanan'] ?? '').toString().isNotEmpty)
                                                Text(r['pesanan'], style: const TextStyle(fontSize: 13)),
                                              if ((r['komentar'] ?? '').toString().isNotEmpty)
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 2.0, bottom: 2.0),
                                                  child: Text(r['komentar'], style: const TextStyle(fontSize: 13, color: Colors.black87)),
                                                ),
                                              Row(
                                                children: [
                                                  ...List.generate(5, (i) => Icon(
                                                        Icons.star,
                                                        size: 15,
                                                        color: i < (r['rating'] ?? 0) ? Colors.amber : Colors.grey[300],
                                                      )),
                                                  const SizedBox(width: 6),
                                                  Text('${r['rating']}/5', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    if (balasan.isNotEmpty)
                                      Container(
                                        margin: const EdgeInsets.only(left: 8, top: 2, bottom: 2),
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.green[50],
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text.rich(
                                          TextSpan(
                                            style: const TextStyle(fontSize: 13, color: Colors.green, fontWeight: FontWeight.w500),
                                            children: [
                                              const TextSpan(text: 'Balasan Seller: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                              TextSpan(text: balasan, style: const TextStyle(fontWeight: FontWeight.normal)),
                                            ],
                                          ),
                                        ),
                                      )
                                    else
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: ElevatedButton.icon(
                                          icon: const Icon(Icons.reply, size: 18),
                                          label: const Text('Balas Ulasan'),
                                          onPressed: () {
                                            setState(() { replyingId = idUlasan; });
                                            replyControllers[idUlasan]?.text = '';
                                            // Tambahkan listener agar tombol Kirim update saat mengetik
                                            void listener() => setState(() {});
                                            replyControllers[idUlasan]?.removeListener(listener);
                                            replyControllers[idUlasan]?.addListener(listener);
                                            showDialog(
                                              context: context,
                                              builder: (ctx) {
                                                return StatefulBuilder(
                                                  builder: (context, setStateDialog) {
                                                    return AlertDialog(
                                                      title: const Text('Balas Ulasan'),
                                                      content: TextField(
                                                        controller: replyControllers[idUlasan],
                                                        minLines: 2,
                                                        maxLines: 5,
                                                        decoration: const InputDecoration(hintText: 'Tulis balasan...'),
                                                        onChanged: (_) => setStateDialog(() {}),
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () {
                                                            Navigator.pop(ctx);
                                                            setState(() { replyingId = null; });
                                                          },
                                                          child: const Text('Batal'),
                                                        ),
                                                        ElevatedButton(
                                                          onPressed: isReplying.contains(idUlasan) || (replyControllers[idUlasan]?.text.trim().isEmpty ?? true)
                                                              ? null
                                                              : () async {
                                                                  Navigator.pop(ctx);
                                                                  await submitReply(idUlasan, replyControllers[idUlasan]!.text.trim());
                                                                },
                                                          child: isReplying.contains(idUlasan)
                                                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                                              : const Text('Kirim'),
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                );
                                              },
                                            );
                                          },
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
      ),
    );
  }
}
