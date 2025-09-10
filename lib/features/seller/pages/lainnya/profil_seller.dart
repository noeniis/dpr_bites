import 'package:flutter/material.dart';
import '../../../../app/gradient_background.dart';
import '../../../../common/widgets/custom_widgets.dart';
import '../../../auth/pages/forgot_password.dart';
import '../../models/lainnya/profil_seller_model.dart';
import '../../services/lainnya/profil_seller_service.dart';

class ProfilSellerPage extends StatefulWidget {
  const ProfilSellerPage({Key? key}) : super(key: key);

  @override
  State<ProfilSellerPage> createState() => _ProfilSellerPageState();
}

class _ProfilSellerPageState extends State<ProfilSellerPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  String _nama = '';
  String _role = '';
  String? _errorPassword;
  bool _isLoadingProfile = false;
  bool _isLoadingPassword = false;
  String? _idUsers;
  bool _isEditingEmail = false;
  bool _isEditingPhone = false;
  bool _isLoadingUpdateProfile = false;
  ProfilSellerModel? _profil;
  final ProfilSellerService _service = ProfilSellerService();

  Future<void> _updateProfileField({String? email, String? noTelp}) async {
    if (_idUsers == null) return;
    setState(() { _isLoadingUpdateProfile = true; });
    try {
      await _service.updateProfileField(idUsers: _idUsers!, email: email, noTelp: noTelp);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil berhasil diperbarui')),
      );
      setState(() {
        if (email != null) _isEditingEmail = false;
        if (noTelp != null) _isEditingPhone = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() { _isLoadingUpdateProfile = false; });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserIdAndFetchProfile();
  }

  Future<void> _loadUserIdAndFetchProfile() async {
    final idUsers = await _service.getUserId();
    setState(() {
      _idUsers = idUsers;
    });
    if (idUsers != null) {
      await _fetchProfile(idUsers);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User belum login')),
      );
    }
  }

  Future<void> _fetchProfile(String idUsers) async {
    setState(() {
      _isLoadingProfile = true;
    });
    try {
      final profil = await _service.fetchProfile(idUsers);
      setState(() {
        _profil = profil;
        _nama = profil?.nama ?? '';
        _role = profil?.role ?? 'Owner';
        _emailController.text = profil?.email ?? '';
        _phoneController.text = profil?.noTelp ?? '';
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() {
        _isLoadingProfile = false;
      });
    }
  }

  Future<void> _updatePassword() async {
    setState(() {
      _isLoadingPassword = true;
      _errorPassword = null;
    });

    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();

    if (currentPassword.isEmpty || newPassword.isEmpty) {
      setState(() {
        _errorPassword = 'Semua kolom wajib diisi';
        _isLoadingPassword = false;
      });
      return;
    }

    if (_idUsers == null) {
      setState(() {
        _errorPassword = 'User belum login';
        _isLoadingPassword = false;
      });
      return;
    }

    try {
      await _service.updatePassword(idUsers: _idUsers!, currentPassword: currentPassword, newPassword: newPassword);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kata sandi berhasil diubah')),
      );
      _currentPasswordController.clear();
      _newPasswordController.clear();
    } catch (e) {
      setState(() {
        _errorPassword = e.toString();
      });
    } finally {
      setState(() {
        _isLoadingPassword = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Profil Pengguna'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          foregroundColor: Colors.black,
        ),
        body: _isLoadingProfile
            ? const Center(child: CircularProgressIndicator())
            : LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Nama
                            CustomEmptyCard(
                              margin: const EdgeInsets.only(bottom: 18),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_nama.isNotEmpty ? _nama : '-', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                  ],
                                ),
                              ),
                            ),
                            // Info Kontak
                            CustomEmptyCard(
                              margin: const EdgeInsets.only(bottom: 18),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: _emailController,
                                            enabled: _isEditingEmail,
                                            decoration: const InputDecoration(
                                              labelText: 'Email',
                                              border: InputBorder.none,
                                            ),
                                          ),
                                        ),
                                        _isEditingEmail
                                            ? IconButton(
                                                icon: _isLoadingUpdateProfile
                                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                                    : const Icon(Icons.send, color: Colors.green),
                                                onPressed: _isLoadingUpdateProfile
                                                    ? null
                                                    : () => _updateProfileField(email: _emailController.text.trim()),
                                              )
                                            : IconButton(
                                                icon: const Icon(Icons.edit, color: Colors.grey),
                                                onPressed: () {
                                                  setState(() { _isEditingEmail = true; });
                                                },
                                              ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: _phoneController,
                                            enabled: _isEditingPhone,
                                            decoration: const InputDecoration(
                                              labelText: 'No. Telp',
                                              border: InputBorder.none,
                                            ),
                                          ),
                                        ),
                                        _isEditingPhone
                                            ? IconButton(
                                                icon: _isLoadingUpdateProfile
                                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                                    : const Icon(Icons.send, color: Colors.green),
                                                onPressed: _isLoadingUpdateProfile
                                                    ? null
                                                    : () => _updateProfileField(noTelp: _phoneController.text.trim()),
                                              )
                                            : IconButton(
                                                icon: const Icon(Icons.edit, color: Colors.grey),
                                                onPressed: () {
                                                  setState(() { _isEditingPhone = true; });
                                                },
                                              ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Ganti Kata Sandi
                            CustomEmptyCard(
                              margin: const EdgeInsets.only(bottom: 18),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Ganti Kata Sandi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    const SizedBox(height: 12),
                                    CustomInputField(
                                      hintText: 'Kata sandi saat ini',
                                      controller: _currentPasswordController,
                                      obscureText: _obscureCurrent,
                                      suffixIcon: IconButton(
                                        icon: Icon(_obscureCurrent ? Icons.visibility_off : Icons.visibility),
                                        onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    CustomInputField(
                                      hintText: 'Kata sandi baru',
                                      controller: _newPasswordController,
                                      obscureText: _obscureNew,
                                      suffixIcon: IconButton(
                                        icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility),
                                        onPressed: () => setState(() => _obscureNew = !_obscureNew),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    if (_errorPassword != null) ...[
                                      Text(_errorPassword!, style: const TextStyle(color: Colors.red)),
                                      const SizedBox(height: 8),
                                    ],
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(builder: (context) => const ForgotPasswordPage()),
                                          );
                                        },
                                        child: const Text('Forgot Password?'),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    CustomButtonOval(
                                      text: _isLoadingPassword ? 'Menyimpan...' : 'Ubah Kata Sandi',
                                      onPressed: _isLoadingPassword ? null : _updatePassword,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            CustomButtonKotak(
                              text: 'Hapus Akun',
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Konfirmasi Hapus Akun'),
                                    content: const Text('Yakin ingin menghapus/menutup akun? Semua data akun dan gerai akan hilang secara permanen.'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('Batal'),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                        ),
                                        onPressed: () => Navigator.pop(context, true),
                                        child: const Text('Hapus Akun'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true && _idUsers != null) {
                                  final success = await _deleteAccount(_idUsers!);
                                  if (success) {
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Akun berhasil dihapus')),);
                                    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                                  }
                                }
                              },
                            ),

                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Future<bool> _deleteAccount(String idUsers) async {
    try {
      await _service.deleteAccount(idUsers);
      return true;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
      return false;
    }
  }
}
