import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/profile_view_model.dart';

class SettingsScreen extends StatelessWidget {
  final ProfileTabViewModel viewModel;

  const SettingsScreen({Key? key, required this.viewModel}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: viewModel,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pengaturan & Privasi'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 1,
        ),
        body: ListView(
          children: [
            _buildSectionHeader(context, 'Akun'),
            _buildListTile(
              context,
              title: 'Ubah Email',
              icon: Icons.email_outlined,
              onTap: () => _showChangeEmailDialog(context, viewModel),
            ),
            _buildListTile(
              context,
              title: 'Ubah Password',
              icon: Icons.lock_outline,
              onTap: () => _showChangePasswordDialog(context, viewModel),
            ),
            const Divider(),
            _buildSectionHeader(context, 'Privasi'),
            _buildSwitchTile(
              context,
              title: 'Profil Privat',
              subtitle: 'Hanya tampilkan nama panggilan',
              value: viewModel.isProfilePrivate,
              onChanged: (value) => viewModel.setPrivacy(value),
            ),
            const Divider(),
            _buildSectionHeader(context, 'Notifikasi'),
            _buildSwitchTile(
              context,
              title: 'Notifikasi Chat',
              value: true, // Placeholder
              onChanged: (val) {},
            ),
            _buildSwitchTile(
              context,
              title: 'Info Promo',
              value: false, // Placeholder
              onChanged: (val) {},
            ),
            const Divider(),
            _buildSectionHeader(context, 'Lainnya'),
            _buildListTile(
              context,
              title: 'Syarat & Ketentuan',
              icon: Icons.description_outlined,
              onTap: () {},
            ),
            _buildListTile(
              context,
              title: 'Kebijakan Privasi',
              icon: Icons.privacy_tip_outlined,
              onTap: () {},
            ),
            _buildListTile(
              context,
              title: 'Pusat Bantuan',
              icon: Icons.help_outline,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[700]),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12)) : null,
      value: value,
      onChanged: onChanged,
      activeColor: Theme.of(context).primaryColor,
    );
  }

  void _showChangeEmailDialog(BuildContext context, ProfileTabViewModel vm) {
    final emailController = TextEditingController(text: vm.user.email);
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubah Email'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email Baru'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Konfirmasi Password'),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (emailController.text.isNotEmpty && passwordController.text.isNotEmpty) {
                final success = await vm.changeEmail(
                  emailController.text,
                  passwordController.text,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Email berhasil diubah' : 'Gagal mengubah email'),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, ProfileTabViewModel vm) {
    final oldPassController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubah Password'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: oldPassController,
                decoration: const InputDecoration(labelText: 'Password Lama'),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newPassController,
                decoration: const InputDecoration(labelText: 'Password Baru'),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmPassController,
                decoration: const InputDecoration(labelText: 'Konfirmasi Password Baru'),
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newPassController.text != confirmPassController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password baru tidak cocok'), backgroundColor: Colors.red),
                );
                return;
              }

              if (oldPassController.text.isNotEmpty && newPassController.text.isNotEmpty) {
                // ✅ PERBAIKAN: Memanggil dengan 2 argumen sesuai definisi di ViewModel
                final success = await vm.changePassword(
                  oldPassController.text,
                  newPassController.text,
                );
                
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Password berhasil diubah' : 'Gagal mengubah password'),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}
