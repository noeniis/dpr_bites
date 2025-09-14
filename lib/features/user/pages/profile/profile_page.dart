import 'package:flutter/material.dart';
import 'package:dpr_bites/common/widgets/custom_widgets.dart';
import 'package:dpr_bites/app/gradient_background.dart';
import 'package:dpr_bites/features/auth/pages/logout.dart';
import 'package:dpr_bites/features/user/pages/home/home_page.dart';
import 'package:dpr_bites/features/user/pages/favorit/favorit.dart';
import 'package:dpr_bites/features/user/pages/history/history_page.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:dpr_bites/features/user/services/profile_page_service.dart';
import 'package:dpr_bites/features/user/models/profile_page_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  ProfileModel? _profile;
  bool isEditing = false;
  String editingField = '';
  bool isUploadingPhoto = false;
  final _storage = const FlutterSecureStorage();
  final nameController = TextEditingController();
  final usernameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Remember this page as last route for simple restoration on restart
    _storage.write(key: 'last_route', value: '/profile');
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final data = await ProfileService.fetchUserProfile();
    if (!mounted) return;
    setState(() {
      _profile = data;
      nameController.text = _profile?.name ?? '';
      usernameController.text = _profile?.username ?? '';
      phoneController.text = _profile?.phone ?? '';
      emailController.text = _profile?.email ?? '';
      passwordController.text = '********';
    });
  }

  // Helper: upload file ke Cloudinary dan kembalikan secure_url
  Future<String?> _uploadToCloudinary(File file) =>
      ProfileService.uploadImageToCloudinary(file);

  Future<void> _pickAndUploadPhoto() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;
    if (mounted) setState(() => isUploadingPhoto = true);
    final url = await _uploadToCloudinary(File(picked.path));
    if (url != null) {
      if (mounted)
        setState(
          () => _profile =
              (_profile ??
                      ProfileModel(
                        name: '',
                        username: '',
                        phone: '',
                        email: '',
                        photo: '',
                      ))
                  .copyWith(photo: url),
        );
      await ProfileService.updateUserProfile(_profile!, password: null);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Foto profil diperbarui')));
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
      isEditing = true; // only selected field editable
      editingField = field;
    });
  }

  Future<void> saveEdit() async {
    // Validasi semua field wajib
    if (nameController.text.trim().isEmpty ||
        usernameController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama, Username, No HP, dan Email wajib diisi'),
        ),
      );
      return;
    }
    setState(() {
      _profile =
          (_profile ??
                  ProfileModel(
                    name: '',
                    username: '',
                    phone: '',
                    email: '',
                    photo: '',
                  ))
              .copyWith(
                name: editingField == 'name'
                    ? nameController.text
                    : _profile?.name,
                username: editingField == 'username'
                    ? usernameController.text
                    : _profile?.username,
                phone: editingField == 'phone'
                    ? phoneController.text
                    : _profile?.phone,
                email: editingField == 'email'
                    ? emailController.text
                    : _profile?.email,
              );
      isEditing = false;
      editingField = '';
    });

    final ok = await ProfileService.updateUserProfile(
      _profile!,
      password: passwordController.text,
    );
    if (ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Perubahan disimpan')));
      // Refresh data dari server agar sinkron (misal password tak disimpan di sini, atau foto berubah di sisi lain)
      _loadProfile();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menyimpan perubahan')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                pinned: true,
                expandedHeight: 210,
                stretch: true,
                automaticallyImplyLeading: false,
                title: AnimatedOpacity(
                  opacity: 1,
                  duration: const Duration(milliseconds: 300),
                  child: const Text(
                    'Profil',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                      color: Color(0xFF602829),
                    ),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 8),
                        _AvatarCard(
                          photoUrl: _profile?.photo ?? '',
                          uploading: isUploadingPhoto,
                          onChange: () => _pickAndUploadPhoto(),
                          name: _profile?.name ?? '',
                          username: _profile?.username ?? '',
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  if (isEditing)
                    IconButton(
                      tooltip: 'Simpan',
                      onPressed: saveEdit,
                      icon: const Icon(
                        Icons.check_rounded,
                        color: Color(0xFFB03056),
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                ],
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _SectionCard(
                      title: 'Informasi Akun',
                      children: [
                        _EditableField(
                          label: 'Nama',
                          controller: nameController,
                          fieldKey: 'name',
                          value: _profile?.name ?? '',
                          isActive: isEditing && editingField == 'name',
                          startEdit: startEdit,
                        ),
                        _EditableField(
                          label: 'Username',
                          controller: usernameController,
                          fieldKey: 'username',
                          value: _profile?.username ?? '',
                          isActive: isEditing && editingField == 'username',
                          startEdit: startEdit,
                        ),
                        _EditableField(
                          label: 'No HP',
                          controller: phoneController,
                          fieldKey: 'phone',
                          keyboardType: TextInputType.phone,
                          value: _profile?.phone ?? '',
                          isActive: isEditing && editingField == 'phone',
                          startEdit: startEdit,
                        ),
                        _EditableField(
                          label: 'Email',
                          controller: emailController,
                          fieldKey: 'email',
                          keyboardType: TextInputType.emailAddress,
                          value: _profile?.email ?? '',
                          isActive: isEditing && editingField == 'email',
                          startEdit: startEdit,
                        ),
                        _EditableField(
                          label: 'Password',
                          controller: passwordController,
                          fieldKey: 'password',
                          obscure: true,
                          value: '********',
                          isActive: isEditing && editingField == 'password',
                          startEdit: startEdit,
                        ),
                        const SizedBox(height: 8),
                        Divider(
                          height: 28,
                          thickness: 0.8,
                          color: Colors.grey.shade200,
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: double.infinity,
                          child: CustomButtonKotak(
                            text: 'Logout',
                            onPressed: () async => await logout(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: const _MinimalBottomNavProfile(currentIndex: 3),
        // FloatingActionButton removed as requested
      ),
    );
  }
}

class _MinimalBottomNavProfile extends StatelessWidget {
  final int currentIndex;
  const _MinimalBottomNavProfile({required this.currentIndex});
  Color get _primary => const Color(0xFFD53D3D);

  @override
  Widget build(BuildContext context) {
    Widget buildItem({required IconData icon, required int index}) {
      final active = index == currentIndex;
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
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const FavoritPage()),
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
                        colors: [_primary, _primary.withOpacity(0.75)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: active ? null : Colors.transparent,
              ),
              child: Icon(
                icon,
                size: 26,
                color: active ? Colors.white : _primary.withOpacity(0.7),
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

// =================== Sub Widgets ===================

class _AvatarCard extends StatelessWidget {
  final String photoUrl;
  final bool uploading;
  final VoidCallback onChange;
  final String name;
  final String username;
  const _AvatarCard({
    required this.photoUrl,
    required this.uploading,
    required this.onChange,
    required this.name,
    required this.username,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFEFF3), Color(0xFFFBE4EA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: ClipOval(
                child: photoUrl.isNotEmpty
                    ? Image.network(photoUrl, fit: BoxFit.cover)
                    : Image.asset(
                        'lib/assets/images/iconUser.png',
                        fit: BoxFit.cover,
                      ),
              ),
            ),
            Positioned(
              bottom: 4,
              right: 4,
              child: GestureDetector(
                onTap: onChange,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: uploading
                      ? const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(strokeWidth: 2.2),
                        )
                      : const Icon(
                          Icons.camera_alt_rounded,
                          size: 20,
                          color: Color(0xFFB03056),
                        ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          name.isEmpty ? 'Pengguna' : name,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: Color(0xFF602829),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          '@${(username.isEmpty ? 'username' : username)}',
          style: const TextStyle(
            fontSize: 13,
            letterSpacing: 0.3,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: Color(0xFF602829),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _EditableField extends StatelessWidget {
  final String label;
  final String fieldKey;
  final String value;
  final TextEditingController controller;
  final bool isActive;
  final bool obscure;
  final void Function(String fieldKey) startEdit;
  final TextInputType? keyboardType;
  const _EditableField({
    required this.label,
    required this.fieldKey,
    required this.value,
    required this.controller,
    required this.isActive,
    required this.startEdit,
    this.obscure = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isActive ? const Color(0xFFB03056) : Colors.transparent;
    return GestureDetector(
      onTap: () => startEdit(fieldKey),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F7F9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1.3),
        ),
        child: AnimatedCrossFade(
          duration: const Duration(milliseconds: 240),
          crossFadeState: isActive
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: _FieldDisplay(
            label: label,
            value: obscure ? '********' : value,
          ),
          secondChild: _FieldEditor(
            label: label,
            controller: controller,
            obscure: obscure,
            keyboardType: keyboardType,
          ),
        ),
      ),
    );
  }
}

class _FieldDisplay extends StatelessWidget {
  final String label;
  final String value;
  const _FieldDisplay({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value.isEmpty ? '-' : value,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF2E2E2E),
                ),
              ),
            ],
          ),
        ),
        // Removed per-field pencil icon
      ],
    );
  }
}

class _FieldEditor extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool obscure;
  final TextInputType? keyboardType;
  const _FieldEditor({
    required this.label,
    required this.controller,
    required this.obscure,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscure,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE0E3E7)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE0E3E7)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFFB03056),
                width: 1.4,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Ketuk tombol cek untuk simpan',
          style: TextStyle(fontSize: 10.5, color: Colors.grey.shade500),
        ),
      ],
    );
  }
}
