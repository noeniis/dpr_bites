import 'package:dpr_bites/common/utils/prefs_helper.dart';
import 'package:flutter/material.dart';
import 'package:dpr_bites/app/gradient_background.dart';
import 'package:dpr_bites/common/widgets/custom_widgets.dart';
import 'package:dpr_bites/common/data/dummy_users.dart';
import 'package:dpr_bites/features/auth/pages/logout.dart';
import 'package:dpr_bites/features/user/pages/home/home_page.dart';
import 'package:dpr_bites/features/user/pages/favorit/favorit.dart';
import 'package:dpr_bites/features/user/pages/history/history_page.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, String> user = {};
  bool isEditing = false;
  String editingField = '';
  bool isUploadingPhoto = false;
  final nameController = TextEditingController();
  final usernameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    fetchUserProfile();
  }

  Future<void> fetchUserProfile() async {
    final idUsers = await Prefs.getUserIdString();
    if (idUsers == null) return; // Belum login

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2/dpr_bites_api/get_user_profile.php'),
        body: jsonEncode({'id_users': idUsers}),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        debugPrint('fetchUserProfile: HTTP ${response.statusCode}');
        return;
      }

      final result = jsonDecode(response.body);
      if (result is! Map) {
        debugPrint('fetchUserProfile: Unexpected JSON structure');
        return;
      }

      if (result['success'] != true) {
        debugPrint(
          'fetchUserProfile: success == false -> ${result['message']}',
        );
        return;
      }

      // Backend PHP returns key 'user' (not 'data'). Support both for flexibility.
      final data = result['user'] ?? result['data'];
      if (data == null) {
        debugPrint(
          'fetchUserProfile: data/user key missing, full json: ${response.body}',
        );
        return;
      }

      // Some APIs may use different field names; map them defensively.
      final String fullName = (data['nama_lengkap'] ?? data['nama'] ?? '')
          .toString();
      final String username = (data['username'] ?? '').toString();
      final String phone = (data['no_hp'] ?? data['no_telp'] ?? '').toString();
      final String email = (data['email'] ?? '').toString();
      final String photo = (data['photo_path'] ?? data['photo'] ?? '')
          .toString();

      setState(() {
        user = {
          'name': fullName,
          'username': username,
          'phone': phone,
          'email': email,
          'password': '********',
          'photo': photo,
        };
        nameController.text = user['name'] ?? '';
        usernameController.text = user['username'] ?? '';
        phoneController.text = user['phone'] ?? '';
        emailController.text = user['email'] ?? '';
        passwordController.text = '********';
      });
    } catch (e, st) {
      debugPrint('fetchUserProfile exception: $e\n$st');
    }
  }

  // Helper: upload file ke Cloudinary dan kembalikan secure_url
  Future<String?> _uploadToCloudinary(File file) async {
    try {
      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/dip8i3f6x/image/upload',
      );
      final req = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = 'dpr_bites'
        ..files.add(await http.MultipartFile.fromPath('file', file.path));
      final res = await req.send();
      final body = await res.stream.bytesToString();
      if (res.statusCode == 200) {
        final data = jsonDecode(body);
        return data['secure_url'] ?? data['url'];
      } else {
        debugPrint('Cloudinary upload failed ${res.statusCode}: ' + body);
        return null;
      }
    } catch (e) {
      debugPrint('Cloudinary exception: ' + e.toString());
      return null;
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    if (isUploadingPhoto) return;
    final xfile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (xfile == null) return;
    setState(() => isUploadingPhoto = true);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Mengunggah foto...')));
    final url = await _uploadToCloudinary(File(xfile.path));
    if (url != null && mounted) {
      setState(() {
        user['photo'] = url;
      });
      // Simpan photo_path ke server bersama data lain yang wajib
      final prefs = await SharedPreferences.getInstance();
      String? idUsers;
      final idInt = prefs.getInt('id_users');
      if (idInt != null) {
        idUsers = idInt.toString();
      } else {
        idUsers = prefs.getString('id_users');
      }
      if (idUsers != null) {
        final response = await http.post(
          Uri.parse('http://10.0.2.2/dpr_bites_api/edit_user_profile.php'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'id_users': idUsers,
            'nama_lengkap': user['name'],
            'username': user['username'],
            'no_hp': user['phone'],
            'email': user['email'],
            'photo_path': user['photo'],
          }),
        );
        final result = jsonDecode(response.body);
        if (result['success'] == true) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Foto profil diperbarui')),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'Gagal memperbarui foto'),
              ),
            );
          }
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Gagal mengunggah foto')));
      }
    }
    if (mounted) setState(() => isUploadingPhoto = false);
  }

  void startEdit(String field) {
    setState(() {
      isEditing = true;
      editingField = field;
    });
  }

  Future<void> saveEdit() async {
    // Validasi local sebelum mengubah state & kirim
    if ((nameController.text).trim().isEmpty ||
        (usernameController.text).trim().isEmpty ||
        (phoneController.text).trim().isEmpty ||
        (emailController.text).trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama, Username, No HP, dan Email wajib diisi'),
        ),
      );
      return;
    }
    setState(() {
      if (editingField == 'name') user['name'] = nameController.text;
      if (editingField == 'username')
        user['username'] = usernameController.text;
      if (editingField == 'phone') user['phone'] = phoneController.text;
      if (editingField == 'email') user['email'] = emailController.text;
      if (editingField == 'password')
        user['password'] = passwordController.text;
      isEditing = false;
      editingField = '';
      dummyUser.clear();
      dummyUser.addAll(user);
    });

    // Kirim ke API edit profil
    final prefs = await SharedPreferences.getInstance();
    String? idUsers;
    final idInt = prefs.getInt('id_users');
    if (idInt != null) {
      idUsers = idInt.toString();
    } else {
      idUsers = prefs.getString('id_users');
    }
    if (idUsers == null) return;
    final Map<String, dynamic> body = {
      'id_users': idUsers,
      'nama_lengkap': user['name'],
      'username': user['username'],
      'no_hp': user['phone'],
      'email': user['email'],
      // Sertakan photo_path agar tidak menjadi null di server jika tidak diubah
      'photo_path': user['photo'],
    };
    // Jika password diisi dan bukan bintang, kirim ke API
    if (passwordController.text.isNotEmpty &&
        passwordController.text != '********') {
      body['password'] = passwordController.text;
    }
    final response = await http.post(
      Uri.parse('http://10.0.2.2/dpr_bites_api/edit_user_profile.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    final result = jsonDecode(response.body);
    if (result['success'] == true) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Perubahan disimpan')));
      // Refresh data dari server agar sinkron (misal password tak disimpan di sini, atau foto berubah di sisi lain)
      fetchUserProfile();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Gagal menyimpan perubahan'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: const Text(
            'Profil Pengguna',
            style: TextStyle(
              color: Color(0xFF602829),
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          actions: [
            if (isEditing)
              GestureDetector(
                onTap: saveEdit,
                child: const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: Text(
                    'Simpan',
                    style: TextStyle(
                      color: Color(0xFFB03056),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  const SizedBox(height: 18),
                  Center(
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black26, width: 2),
                          ),
                          child: ClipOval(
                            child:
                                user['photo'] != null &&
                                    user['photo']!.isNotEmpty
                                ? Image.network(
                                    user['photo']!,
                                    width: 90,
                                    height: 90,
                                    fit: BoxFit.cover,
                                  )
                                : Image.asset(
                                    'lib/assets/images/iconUser.png',
                                    width: 90,
                                    height: 90,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),
                        Positioned(
                          bottom: 6,
                          right: 6,
                          child: GestureDetector(
                            onTap: _pickAndUploadPhoto,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: isUploadingPhoto
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Image.asset(
                                        'lib/assets/images/iconCamera.png',
                                        width: 18,
                                        height: 18,
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  GestureDetector(
                    onTap: () => startEdit('name'),
                    child: AbsorbPointer(
                      absorbing: !(isEditing && editingField == 'name'),
                      child: TextFieldLine(
                        label: 'Nama',
                        value: user['name'] ?? '',
                        controller: nameController,
                        editable: isEditing && editingField == 'name',
                        underlineColor: Colors.black,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => startEdit('username'),
                    child: AbsorbPointer(
                      absorbing: !(isEditing && editingField == 'username'),
                      child: TextFieldLine(
                        label: 'Username',
                        value: user['username'] ?? '',
                        controller: usernameController,
                        editable: isEditing && editingField == 'username',
                        underlineColor: Colors.black,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => startEdit('phone'),
                    child: AbsorbPointer(
                      absorbing: !(isEditing && editingField == 'phone'),
                      child: TextFieldLine(
                        label: 'No HP',
                        value: user['phone'] ?? '',
                        controller: phoneController,
                        editable: isEditing && editingField == 'phone',
                        underlineColor: Colors.black,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => startEdit('email'),
                    child: AbsorbPointer(
                      absorbing: !(isEditing && editingField == 'email'),
                      child: TextFieldLine(
                        label: 'Email',
                        value: user['email'] ?? '',
                        controller: emailController,
                        editable: isEditing && editingField == 'email',
                        underlineColor: Colors.black,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => startEdit('password'),
                    child: AbsorbPointer(
                      absorbing: !(isEditing && editingField == 'password'),
                      child: TextFieldLine(
                        label: 'Password',
                        value: user['password'] ?? '',
                        controller: passwordController,
                        editable: isEditing && editingField == 'password',
                        obscure: true,
                        underlineColor: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  CustomButtonKotak(
                    text: 'Logout',
                    onPressed: () async {
                      await logout(context);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFFD53D3D),
          unselectedItemColor: Colors.black54,
          currentIndex: 3,
          selectedFontSize: 14,
          unselectedFontSize: 13,
          iconSize: 30,
          type: BottomNavigationBarType.fixed,
          onTap: (i) {
            if (i == 0) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomePage()),
              );
            } else if (i == 1) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HistoryPage()),
              );
            } else if (i == 2) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const FavoritPage()),
              );
            } else if (i == 3) {
              // Already on Profile
            }
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
            BottomNavigationBarItem(icon: Icon(Icons.history), label: ''),
            BottomNavigationBarItem(icon: Icon(Icons.favorite), label: ''),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: "Profil",
            ),
          ],
        ),
      ),
    );
  }
}
