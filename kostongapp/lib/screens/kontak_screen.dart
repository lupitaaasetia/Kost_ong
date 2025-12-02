import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class KontakScreen extends StatelessWidget {
  // Data bisa berupa data 'booking' atau data 'kost'
  final Map<String, dynamic> data;

  const KontakScreen({Key? key, required this.data}) : super(key: key);

  // Fungsi untuk membuka WhatsApp
  Future<void> _launchWhatsApp(BuildContext context) async {
    // Ambil nomor telepon dari data
    String phoneNumber =
        data['no_telepon'] ??
        data['no_telp'] ??
        data['owner_phone'] ??
        '081234567890';

    String kostName = data['nama_kost'] ?? 'Kost';

    // Format nomor HP: Ubah 08xx menjadi 628xx
    if (phoneNumber.startsWith('0')) {
      phoneNumber = '62${phoneNumber.substring(1)}';
    }

    // Pesan otomatis
    String message =
        "Halo Admin *$kostName*,\n\nSaya tertarik untuk bertanya lebih lanjut mengenai kost ini.\nTerima kasih.";

    final Uri whatsappUrl = Uri.parse(
      "https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}",
    );

    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(whatsappUrl, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka WhatsApp')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hubungi Pemilik'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),

            // Icon WhatsApp
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const FaIcon(
                FontAwesomeIcons.whatsapp,
                color: Colors.green,
                size: 60,
              ),
            ),

            const SizedBox(height: 24),

            // Judul
            Text(
              "Hubungi ${data['nama_kost'] ?? 'Pemilik Kost'}",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            const Text(
              "Anda akan dialihkan ke WhatsApp untuk chatting langsung dengan pemilik/pengelola kost.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),

            const Spacer(),

            // Tombol Chat
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _launchWhatsApp(context),
                icon: const Icon(Icons.chat),
                label: const Text("Chat Sekarang"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
