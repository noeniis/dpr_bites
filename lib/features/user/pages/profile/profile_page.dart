import 'package:flutter/material.dart';
import 'package:dpr_bites/app/gradient_background.dart';
import 'package:dpr_bites/common/widgets/custom_widgets.dart';
import 'package:dpr_bites/common/data/dummy_users.dart';
import 'package:dpr_bites/features/auth/pages/logout.dart';
import 'package:dpr_bites/features/user/pages/home/home_page.dart';
import 'package:dpr_bites/features/user/pages/favorit/favorit.dart';
import 'package:dpr_bites/features/user/pages/history/history_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Map<String, Object>
  user; // Menggunakan Map<String, Object> untuk konsistensi
  bool isEditing = false;
  String editingField = '';

  // Controllers untuk inputan
  final nameController = TextEditingController();
  final usernameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nikController = TextEditingController();
  final ttlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    user = Map<String, Object>.from(dummyUser); // Menyesuaikan tipe data
    nameController.text = user['name'] as String;
    usernameController.text = user['username'] as String;
    phoneController.text = (user['phone'] as List<String>).join(', ');
    emailController.text = user['email'] as String;
    passwordController.text = user['password'] as String;
    nikController.text = user['nik'] as String;
    ttlController.text = user['ttl'] as String;
  }

  void startEdit(String field) {
    setState(() {
      isEditing = true;
      editingField = field;
    });
  }

  void saveEdit() {
    setState(() {
      if (editingField == 'name') {
        user['name'] = nameController.text;
      }
      if (editingField == 'username') {
        user['username'] = usernameController.text;
      }
      if (editingField == 'phone') {
        user['phone'] = phoneController.text.split(', ');
      }
      if (editingField == 'email') {
        user['email'] = emailController.text;
      }
      if (editingField == 'password') {
        user['password'] = passwordController.text;
      }
      if (editingField == 'nik') {
        user['nik'] = nikController.text;
      }
      if (editingField == 'ttl') {
        user['ttl'] = ttlController.text;
      }

      isEditing = false;
      editingField = '';
      // Update dummyUser dengan data yang sudah diedit
      dummyUser.clear();
      dummyUser.addAll(user);
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Perubahan disimpan')));
  }

  @override
  Widget build(BuildContext context) {
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
                            child: Image.asset(
                              user['photo'] as String? ??
                                  'lib/assets/images/iconUser.png',
                              width: 90,
                              height: 90,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Nama
                  GestureDetector(
                    onTap: () => startEdit('name'),
                    child: AbsorbPointer(
                      absorbing: !(isEditing && editingField == 'name'),
                      child: TextFieldLine(
                        label: 'Nama',
                        value: user['name'] as String? ?? '',
                        controller: nameController,
                        editable: isEditing && editingField == 'name',
                        underlineColor: Colors.black,
                      ),
                    ),
                  ),
                  // Username
                  GestureDetector(
                    onTap: () => startEdit('username'),
                    child: AbsorbPointer(
                      absorbing: !(isEditing && editingField == 'username'),
                      child: TextFieldLine(
                        label: 'Username',
                        value: user['username'] as String? ?? '',
                        controller: usernameController,
                        editable: isEditing && editingField == 'username',
                        underlineColor: Colors.black,
                      ),
                    ),
                  ),
                  // Phone (Multiple Numbers)
                  GestureDetector(
                    onTap: () => startEdit('phone'),
                    child: AbsorbPointer(
                      absorbing: !(isEditing && editingField == 'phone'),
                      child: TextFieldLine(
                        label: 'No HP',
                        value: (user['phone'] as List<String>).join(', '),
                        controller: phoneController,
                        editable: isEditing && editingField == 'phone',
                        underlineColor: Colors.black,
                      ),
                    ),
                  ),
                  // Email
                  GestureDetector(
                    onTap: () => startEdit('email'),
                    child: AbsorbPointer(
                      absorbing: !(isEditing && editingField == 'email'),
                      child: TextFieldLine(
                        label: 'Email',
                        value: user['email'] as String? ?? '',
                        controller: emailController,
                        editable: isEditing && editingField == 'email',
                        underlineColor: Colors.black,
                      ),
                    ),
                  ),
                  // NIK
                  GestureDetector(
                    onTap: () => startEdit('nik'),
                    child: AbsorbPointer(
                      absorbing: !(isEditing && editingField == 'nik'),
                      child: TextFieldLine(
                        label: 'NIK',
                        value: user['nik'] as String? ?? '',
                        controller: nikController,
                        editable: isEditing && editingField == 'nik',
                        underlineColor: Colors.black,
                      ),
                    ),
                  ),
                  // TTL
                  GestureDetector(
                    onTap: () => startEdit('ttl'),
                    child: AbsorbPointer(
                      absorbing: !(isEditing && editingField == 'ttl'),
                      child: TextFieldLine(
                        label: 'Tanggal Lahir',
                        value: user['ttl'] as String? ?? '',
                        controller: ttlController,
                        editable: isEditing && editingField == 'ttl',
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
