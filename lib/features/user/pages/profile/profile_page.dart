import 'package:flutter/material.dart';
import 'package:dpr_bites/app/gradient_background.dart';
import 'package:dpr_bites/common/widgets/custom_widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dpr_bites/features/auth/pages/logout.dart';
import 'package:dpr_bites/features/user/pages/home/home_page.dart';
import 'package:dpr_bites/features/user/pages/favorit/favorit.dart';
import 'package:dpr_bites/features/user/pages/history/history_page.dart';

Future<bool> checkUserData() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  final userId = prefs.getString('userId') ?? '';
  if (userId.isEmpty) return false;
  final doc = await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .get();
  return doc.exists;
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic> user = {};
  bool isEditing = false;
  String editingField = '';
  void startEdit(String field) {
    setState(() {
      isEditing = true;
      editingField = field;
    });
  }

  void saveEdit() {
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
    });
    _saveUserDataToFirestore().then((_) => _loadUserData());
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Perubahan disimpan')));
  }

  final nameController = TextEditingController();
  final usernameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  String? photoPath;
  String? photoPublicId;
  Uint8List? photoBytes;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    photoBytes = null;
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? '';
    if (userId.isEmpty) {
      print('userId kosong di SharedPreferences');
      return;
    }
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();
    if (doc.exists) {
      print('Data user ditemukan: ' + doc.data().toString());
      setState(() {
        user = doc.data() ?? {};
        nameController.text = user['name'] ?? '';
        usernameController.text = user['username'] ?? '';
        phoneController.text = user['phone'] ?? '';
        emailController.text = user['email'] ?? '';
        passwordController.text = user['password'] ?? '';
        photoPath = user['photoPath'] ?? photoPath;
        photoPublicId = user['photoPublicId'] ?? photoPublicId;
        photoBytes = null;
      });
    } else {
      print(
        'Dokumen user tidak ditemukan di Firestore untuk userId: ' + userId,
      );
    }
  }

  Future<void> _autoSaveUserData() async {
    await _saveUserDataToFirestore();
    await _loadUserData();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Perubahan disimpan')));
  }

  Future<void> _saveUserDataToFirestore() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? '';
    if (userId.isEmpty) return;
    final dataToUpdate = {
      'name': nameController.text,
      'username': usernameController.text,
      'phone': phoneController.text,
      'email': emailController.text,
      'password': passwordController.text,
      'photoPath': photoPath,
      'photoPublicId': photoPublicId,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .update(dataToUpdate);
  }

  String? extractPublicIdFromUrl(String url) {
    // Contoh: https://res.cloudinary.com/dip8i3f6x/image/upload/v1754225276/y19zyp3ilczmezn3us93.jpg
    final uri = Uri.parse(url);
    final segments = uri.pathSegments;
    if (segments.isNotEmpty) {
      final last = segments.last;
      final dotIdx = last.lastIndexOf('.');
      if (dotIdx > 0) {
        return last.substring(0, dotIdx);
      }
      return last;
    }
    return null;
  }

  Future<void> _pickProfilePhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 400,
      maxHeight: 400,
      imageQuality: 90,
    );
    if (picked != null) {
      final file = File(picked.path);
      final bytes = await file.length();
      if (bytes > 2 * 1024 * 1024) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ukuran foto maksimal 2MB')),
        );
        return;
      }
      // Upload ke Cloudinary menggunakan http (unsigned preset)
      try {
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('https://api.cloudinary.com/v1_1/dip8i3f6x/image/upload'),
        );
        request.fields['upload_preset'] = 'dpr_bites';
        request.files.add(await http.MultipartFile.fromPath('file', file.path));
        var response = await request.send();
        if (response.statusCode == 200) {
          final resStr = await response.stream.bytesToString();
          final resJson = jsonDecode(resStr);
          final imageUrl = resJson['secure_url'];
          final publicId = resJson['public_id'];
          setState(() {
            photoPath = imageUrl;
            photoPublicId = publicId;
            photoBytes = null;
          });
          await _saveUserDataToFirestore();
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal upload foto ke Cloudinary')),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal upload foto ke Cloudinary: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user.isEmpty) {
      return FutureBuilder(
        future: checkUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || snapshot.data == false) {
            return const Center(
              child: Text('Data user tidak ditemukan. Silakan login ulang.'),
            );
          }
          // fallback loading
          return const Center(child: CircularProgressIndicator());
        },
      );
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
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.18),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: photoPath != null && photoPath!.isNotEmpty
                                ? Image.network(
                                    photoPath!,
                                    width: 90,
                                    height: 90,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Image.asset(
                                              'lib/assets/images/iconUser.png',
                                              width: 90,
                                              height: 90,
                                              fit: BoxFit.cover,
                                            ),
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
                            onTap: _pickProfilePhoto,
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
                                child: Image.asset(
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
                  TextFieldLine(
                    label: 'Nama',
                    value: user['name'] ?? '',
                    controller: nameController,
                    editable: true,
                    underlineColor: Colors.black,
                    onChanged: (val) {
                      startEdit('name');
                    },
                  ),
                  TextFieldLine(
                    label: 'Username',
                    value: user['username'] ?? '',
                    controller: usernameController,
                    editable: true,
                    underlineColor: Colors.black,
                    onChanged: (val) {
                      startEdit('username');
                    },
                  ),
                  TextFieldLine(
                    label: 'No HP',
                    value: user['phone'] ?? '',
                    controller: phoneController,
                    editable: true,
                    underlineColor: Colors.black,
                    onChanged: (val) {
                      startEdit('phone');
                    },
                  ),
                  TextFieldLine(
                    label: 'Email',
                    value: user['email'] ?? '',
                    controller: emailController,
                    editable: true,
                    underlineColor: Colors.black,
                    onChanged: (val) {
                      startEdit('email');
                    },
                  ),
                  TextFieldLine(
                    label: 'Password',
                    value: user['password'] ?? '',
                    controller: passwordController,
                    editable: true,
                    obscure: true,
                    underlineColor: Colors.black,
                    onChanged: (val) {
                      startEdit('password');
                    },
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
