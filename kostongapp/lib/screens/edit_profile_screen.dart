import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/profile_view_model.dart';

class EditProfileScreen extends StatelessWidget {
  final ProfileTabViewModel viewModel;

  const EditProfileScreen({Key? key, required this.viewModel}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: viewModel,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Edit Profil'),
        ),
        body: Consumer<ProfileTabViewModel>(
          builder: (context, vm, child) {
            final isPrivate = vm.isProfilePrivate;
            return ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildTextField(
                  context,
                  label: 'Nama Lengkap',
                  controller: vm.fullNameController,
                  isPrivate: isPrivate,
                ),
                const SizedBox(height: 16),
                _buildGenderPicker(context, vm, isPrivate),
                const SizedBox(height: 16),
                _buildDatePicker(context, vm, isPrivate),
                const SizedBox(height: 16),
                _buildTextField(
                  context,
                  label: 'Nomor Telepon',
                  controller: vm.phoneController,
                  isPrivate: isPrivate,
                  keyboardType: TextInputType.phone
                ),
                const SizedBox(height: 16),
                 _buildTextField(
                  context,
                  label: 'Email',
                  controller: vm.emailController,
                  isPrivate: isPrivate,
                  enabled: false,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Simpan Perubahan'),
                  onPressed: () {
                    vm.saveProfile();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profil berhasil disimpan!'), backgroundColor: Colors.green),
                    );
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTextField(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    bool isPrivate = false,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled && !isPrivate,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
           borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[200]!, width: 0.5),
        )
      ),
      style: isPrivate ? const TextStyle(color: Colors.grey) : null,
    );
  }

  Widget _buildGenderPicker(BuildContext context, ProfileTabViewModel viewModel, bool isPrivate) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Jenis Kelamin', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Laki-laki'),
                value: 'Laki-laki',
                groupValue: viewModel.selectedGender,
                onChanged: isPrivate ? null : (val) => viewModel.setGender(val),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Perempuan'),
                value: 'Perempuan',
                groupValue: viewModel.selectedGender,
                onChanged: isPrivate ? null : (val) => viewModel.setGender(val),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDatePicker(BuildContext context, ProfileTabViewModel viewModel, bool isPrivate) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tanggal Lahir', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        InkWell(
          onTap: isPrivate ? null : () async {
            final pickedDate = await showDatePicker(
              context: context,
              initialDate: viewModel.selectedDate ?? DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
            );
            if (pickedDate != null) {
              viewModel.setDate(pickedDate);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[400]!),
              borderRadius: BorderRadius.circular(8),
              color: isPrivate ? Colors.grey[100] : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isPrivate
                    ? '***'
                    : viewModel.selectedDate == null 
                        ? 'Pilih tanggal'
                        : '${viewModel.selectedDate!.day}/${viewModel.selectedDate!.month}/${viewModel.selectedDate!.year}',
                  style: TextStyle(fontSize: 16),
                ),
                const Icon(Icons.calendar_today_outlined),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
