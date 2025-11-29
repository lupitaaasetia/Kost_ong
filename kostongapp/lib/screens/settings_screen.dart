import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/profile_view_model.dart';

class SettingsScreen extends StatelessWidget {
  final ProfileTabViewModel viewModel;

  const SettingsScreen({Key? key, required this.viewModel}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ProfileTabViewModel>.value(
      value: viewModel,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Pengaturan'),
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF667eea),
          elevation: 0,
        ),
        body: Consumer<ProfileTabViewModel>(
          builder: (context, vm, child) {
            return ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildSectionTitle(context, 'Akun'),
                _buildAccountSection(context, vm),
                const Divider(height: 32),

                _buildSectionTitle(context, 'Notifikasi'),
                _buildNotificationSection(context),
                const Divider(height: 32),

                _buildSectionTitle(context, 'Privasi & Keamanan'),
                _buildPrivacySection(context, vm),
                const SizedBox(height: 16),
                _buildDeleteAccountSection(context),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey[600]),
      ),
    );
  }

  Widget _buildAccountSection(BuildContext context, ProfileTabViewModel vm) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.email_outlined, color: Color(0xFF667eea)),
            title: Text('Ganti Email'),
            trailing: Icon(Icons.chevron_right),
            onTap: () => _showChangeEmailDialog(context, vm),
          ),
          Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: Icon(Icons.lock_outline, color: Color(0xFF667eea)),
            title: Text('Ganti Password'),
            trailing: Icon(Icons.chevron_right),
            onTap: () => _showChangePasswordDialog(context, vm),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSection(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          SwitchListTile(
            title: Text('Notifikasi Promo'),
            value: true,
            onChanged: (val) {},
            secondary: Icon(Icons.campaign_outlined, color: Color(0xFF667eea)),
          ),
          Divider(height: 1, indent: 16, endIndent: 16),
          SwitchListTile(
            title: Text('Update Aplikasi'),
            value: false,
            onChanged: (val) {},
            secondary: Icon(Icons.system_update_outlined, color: Color(0xFF667eea)),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacySection(BuildContext context, ProfileTabViewModel viewModel) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: SwitchListTile(
        title: const Text('Privasi Profil'),
        subtitle: const Text('Sembunyikan informasi data diri'),
        value: viewModel.isProfilePrivate,
        onChanged: (value) => viewModel.setPrivacy(value),
        secondary: const Icon(Icons.security_outlined, color: Color(0xFF667eea)),
      ),
    );
  }

  Widget _buildDeleteAccountSection(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.red.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.red[200]!),
      ),
      child: ListTile(
        leading: Icon(Icons.delete_forever_outlined, color: Colors.red),
        title: Text('Hapus Akun', style: TextStyle(color: Colors.red)),
        subtitle: Text('Hapus akun Anda secara permanen', style: TextStyle(color: Colors.redAccent)),
        onTap: () => _showDeleteConfirmDialog(context),
      ),
    );
  }

  void _showChangeEmailDialog(BuildContext context, ProfileTabViewModel vm) {
    final formKey = GlobalKey<FormState>();
    final newEmailController = TextEditingController();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ganti Email'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: newEmailController,
                  decoration: InputDecoration(
                    labelText: 'Email Baru',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (val) => (val?.isEmpty ?? true) || !val!.contains('@')
                      ? 'Email tidak valid'
                      : null,
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password Saat Ini',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (val) => (val?.isEmpty ?? true) ? 'Password tidak boleh kosong' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              newEmailController.dispose();
              passwordController.dispose();
              Navigator.pop(context);
            },
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                final success = await vm.changeEmail(
                  newEmailController.text,
                  passwordController.text,
                );
                Navigator.pop(context);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Email berhasil diubah!' : 'Gagal mengubah email.'),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                }
                newEmailController.dispose();
                passwordController.dispose();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF667eea)),
            child: Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, ProfileTabViewModel vm) {
    final formKey = GlobalKey<FormState>();
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ganti Password'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: oldPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Password Saat Ini',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (val) => (val?.isEmpty ?? true) ? 'Password tidak boleh kosong' : null,
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: newPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Password Baru',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (val) {
                    if (val?.isEmpty ?? true) return 'Password baru tidak boleh kosong';
                    if (val!.length < 6) return 'Minimal 6 karakter';
                    return null;
                  },
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Konfirmasi Password Baru',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (val) =>
                      val != newPasswordController.text ? 'Password tidak cocok' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              oldPasswordController.dispose();
              newPasswordController.dispose();
              confirmPasswordController.dispose();
              Navigator.pop(context);
            },
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                final success = await vm.changePassword(
                  oldPasswordController.text,
                  newPasswordController.text,
                  confirmPasswordController.text,
                );
                Navigator.pop(context);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Password berhasil diubah!' : 'Gagal mengubah password.'),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                }
                oldPasswordController.dispose();
                newPasswordController.dispose();
                confirmPasswordController.dispose();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF667eea)),
            child: Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hapus Akun'),
          content: const Text(
            'Apakah Anda yakin? Tindakan ini tidak dapat dibatalkan dan semua data Anda akan dihapus.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Ya, Hapus Akun'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                print("Account Deletion Confirmed");
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}