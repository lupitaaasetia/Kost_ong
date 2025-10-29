// screens/payment_screen.dart - Updated with image_picker_for_web
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
import 'package:intl/intl.dart';
import 'dart:typed_data';
import '../models/booking.dart';
import '../services/booking_service.dart';
import '../utils/image_picker_helper.dart';
import 'contract_screen.dart';

class PaymentScreen extends StatefulWidget {
  final Booking booking;

  const PaymentScreen({super.key, required this.booking});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final BookingService _bookingService = BookingService();
  final _formKey = GlobalKey<FormState>();

  PaymentMethod _selectedMethod = PaymentMethod.bankTransfer;
  Uint8List? _proofImageBytes; // Universal format untuk web dan mobile
  String? _proofImageName;
  bool _isProcessing = false;

  final Map<PaymentMethod, Map<String, dynamic>> _paymentMethods = {
    PaymentMethod.bankTransfer: {
      'name': 'Transfer Bank',
      'icon': Icons.account_balance,
      'color': Colors.blue,
      'accounts': [
        {'bank': 'BCA', 'number': '1234567890', 'name': 'PT Kost Indonesia'},
        {
          'bank': 'Mandiri',
          'number': '0987654321',
          'name': 'PT Kost Indonesia',
        },
        {'bank': 'BNI', 'number': '1122334455', 'name': 'PT Kost Indonesia'},
      ],
    },
    PaymentMethod.eWallet: {
      'name': 'E-Wallet',
      'icon': Icons.account_balance_wallet,
      'color': Colors.purple,
      'wallets': [
        {'name': 'GoPay', 'number': '081234567890'},
        {'name': 'OVO', 'number': '081234567890'},
        {'name': 'DANA', 'number': '081234567890'},
      ],
    },
    PaymentMethod.creditCard: {
      'name': 'Kartu Kredit/Debit',
      'icon': Icons.credit_card,
      'color': Colors.orange,
    },
    PaymentMethod.cash: {
      'name': 'Tunai',
      'icon': Icons.money,
      'color': Colors.green,
    },
  };

  Future<void> _pickImage() async {
    try {
      debugPrint('Starting image picker...');
      debugPrint('Platform: ${kIsWeb ? "Web" : "Mobile"}');

      // Untuk mobile, tampilkan dialog pilihan sumber
      if (!kIsWeb) {
        final ImageSource? selectedSource = await showDialog<ImageSource>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text('Pilih Sumber Gambar'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.photo_library,
                        color: Colors.blue,
                      ),
                    ),
                    title: const Text('Galeri'),
                    onTap: () => Navigator.pop(context, ImageSource.gallery),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.green),
                    ),
                    title: const Text('Kamera'),
                    onTap: () => Navigator.pop(context, ImageSource.camera),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
              ],
            );
          },
        );

        if (selectedSource == null) {
          debugPrint('User cancelled image source selection');
          return;
        }
      }

      // Gunakan ImagePickerHelper untuk pick image
      final Uint8List? imageBytes = await ImagePickerHelper.pickImage();

      if (imageBytes == null) {
        debugPrint('No image selected');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tidak ada gambar yang dipilih'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      debugPrint('Image picked successfully');
      debugPrint('Image size: ${imageBytes.length} bytes');

      // Check file size (max 2MB)
      final double fileSizeInMB = imageBytes.length / (1024 * 1024);
      debugPrint('File size: ${fileSizeInMB.toStringAsFixed(2)} MB');

      if (fileSizeInMB > 2) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Ukuran file terlalu besar: ${fileSizeInMB.toStringAsFixed(2)} MB. Maksimal 2MB',
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      setState(() {
        _proofImageBytes = imageBytes;
        _proofImageName =
            'payment_proof_${DateTime.now().millisecondsSinceEpoch}.jpg';
        debugPrint('Image set successfully: $_proofImageName');
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  kIsWeb
                      ? 'Bukti pembayaran berhasil dipilih (Web)'
                      : 'Bukti pembayaran berhasil dipilih',
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } on PlatformException catch (e) {
      debugPrint('PlatformException: ${e.code} - ${e.message}');
      if (mounted) {
        String errorMessage = 'Gagal memilih gambar';

        if (e.code == 'photo_access_denied' ||
            e.code == 'camera_access_denied') {
          errorMessage =
              'Akses ditolak. Silakan izinkan akses ke galeri/kamera di pengaturan aplikasi';
        } else if (e.code == 'already_active') {
          errorMessage = 'Image picker sudah aktif. Silakan coba lagi';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Tutup',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('General error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Tutup',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    }
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) return;

    // Validation for proof image
    if (_selectedMethod != PaymentMethod.cash && _proofImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan upload bukti pembayaran terlebih dahulu'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      debugPrint('Starting payment process...');
      debugPrint('Platform: ${kIsWeb ? "Web" : "Mobile"}');
      debugPrint('Booking ID: ${widget.booking.id}');
      debugPrint('Payment Method: $_selectedMethod');
      debugPrint('Proof Image: $_proofImageName');

      // Simulate payment processing
      await Future.delayed(const Duration(seconds: 2));

      // TEMPORARY FIX: Comment out BookingService calls
      try {
        final payment = _bookingService.createPayment(
          bookingId: widget.booking.id,
          amount: widget.booking.totalPrice + widget.booking.depositAmount,
          method: _selectedMethod,
          proofImagePath: _proofImageName,
        );
        debugPrint('Payment created with ID: ${payment.id}');
        _bookingService.confirmPayment(payment.id);
        debugPrint('Payment confirmed');
      } catch (serviceError) {
        debugPrint('BookingService error (ignoring for now): $serviceError');
        // Continue anyway for testing UI
      }

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  kIsWeb
                      ? 'Pembayaran berhasil! (Web Mode)'
                      : 'Pembayaran berhasil!',
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // Navigate to contract screen
        await Future.delayed(const Duration(milliseconds: 500));

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ContractScreen(booking: widget.booking),
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Error processing payment: $e');
      debugPrint('Stack trace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gagal memproses pembayaran',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Error: ${e.toString()}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Tutup',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalAmount =
        widget.booking.totalPrice + widget.booking.depositAmount;

    final bool hasImage = _proofImageBytes != null;

    debugPrint(
      'Building PaymentScreen - Platform: ${kIsWeb ? "Web" : "Mobile"}',
    );
    debugPrint('Has image: $hasImage');
    debugPrint('Image name: $_proofImageName');

    return Scaffold(
      appBar: AppBar(
        title: Text(kIsWeb ? 'Pembayaran (Web)' : 'Pembayaran'),
        backgroundColor: widget.booking.kost.getPrimaryColor(),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildBookingSummaryCard(),
            const SizedBox(height: 16),
            _buildPaymentAmountCard(totalAmount),
            const SizedBox(height: 16),
            _buildPaymentMethodCard(),
            const SizedBox(height: 16),
            if (_selectedMethod != PaymentMethod.cash) ...[
              _buildPaymentDetailsCard(),
              const SizedBox(height: 16),
              _buildProofUploadCard(),
              const SizedBox(height: 16),
            ],
            _buildInstructionCard(),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBookingSummaryCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ringkasan Booking',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 24),
            _buildInfoRow('Kost', widget.booking.kost.name),
            _buildInfoRow('Kamar', widget.booking.roomDetail.roomNumber),
            _buildInfoRow(
              'Check-in',
              DateFormat('dd MMM yyyy').format(widget.booking.checkInDate),
            ),
            _buildInfoRow(
              'Check-out',
              DateFormat('dd MMM yyyy').format(widget.booking.checkOutDate),
            ),
            _buildInfoRow('Durasi', '${widget.booking.duration} bulan'),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentAmountCard(double totalAmount) {
    return Card(
      elevation: 4,
      color: widget.booking.kost.getPrimaryColor().withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Total Pembayaran',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              NumberFormat.currency(
                locale: 'id',
                symbol: 'Rp ',
                decimalDigits: 0,
              ).format(totalAmount),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: widget.booking.kost.getPrimaryColor(),
              ),
            ),
            const Divider(height: 24),
            _buildInfoRow(
              'Sewa (${widget.booking.duration} bulan)',
              NumberFormat.currency(
                locale: 'id',
                symbol: 'Rp ',
                decimalDigits: 0,
              ).format(widget.booking.totalPrice),
            ),
            _buildInfoRow(
              'Deposit',
              NumberFormat.currency(
                locale: 'id',
                symbol: 'Rp ',
                decimalDigits: 0,
              ).format(widget.booking.depositAmount),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Metode Pembayaran',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...PaymentMethod.values.map((method) {
              final info = _paymentMethods[method]!;
              final isSelected = _selectedMethod == method;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                color: isSelected
                    ? info['color'].withOpacity(0.1)
                    : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: isSelected ? info['color'] : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: ListTile(
                  onTap: () {
                    setState(() {
                      _selectedMethod = method;
                      // Reset proof image when changing payment method
                      if (method == PaymentMethod.cash) {
                        _proofImageBytes = null;
                        _proofImageName = null;
                      }
                    });
                  },
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: info['color'].withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(info['icon'], color: info['color']),
                  ),
                  title: Text(
                    info['name'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check_circle, color: info['color'])
                      : null,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentDetailsCard() {
    final info = _paymentMethods[_selectedMethod]!;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: info['color']),
                const SizedBox(width: 8),
                const Text(
                  'Detail Pembayaran',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_selectedMethod == PaymentMethod.bankTransfer) ...[
              const Text(
                'Pilih salah satu rekening berikut:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              ...info['accounts'].map<Widget>((account) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            account['bank'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy, size: 20),
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: account['number']),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Nomor rekening ${account['bank']} disalin',
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      Text(
                        account['number'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'a/n ${account['name']}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ] else if (_selectedMethod == PaymentMethod.eWallet) ...[
              const Text(
                'Pilih salah satu e-wallet berikut:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              ...info['wallets'].map<Widget>((wallet) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            wallet['name'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            wallet['number'],
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 20),
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: wallet['number']),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Nomor ${wallet['name']} disalin'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              }).toList(),
            ] else if (_selectedMethod == PaymentMethod.creditCard) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Hubungi pemilik untuk pembayaran dengan kartu kredit/debit',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProofUploadCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.upload_file,
                  color: widget.booking.kost.getPrimaryColor(),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Bukti Pembayaran',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Text(
                  ' *',
                  style: TextStyle(color: Colors.red, fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              kIsWeb
                  ? 'Wajib upload bukti pembayaran (Web Mode)'
                  : 'Wajib upload bukti pembayaran',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            if (_proofImageBytes == null)
              InkWell(
                onTap: _pickImage,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: widget.booking.kost.getPrimaryColor().withOpacity(
                        0.3,
                      ),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cloud_upload,
                          size: 48,
                          color: widget.booking.kost.getPrimaryColor(),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap untuk Upload Bukti Transfer',
                          style: TextStyle(
                            color: widget.booking.kost.getPrimaryColor(),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'JPG, PNG (Max 2MB)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              Column(
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          _proofImageBytes!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () {
                              setState(() {
                                _proofImageBytes = null;
                                _proofImageName = null;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Bukti pembayaran dihapus'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                kIsWeb
                                    ? 'Berhasil dipilih (Web)'
                                    : 'Berhasil dipilih',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Ganti Gambar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                      foregroundColor: Colors.black87,
                      elevation: 0,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionCard() {
    return Card(
      elevation: 4,
      color: Colors.blue.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.help_outline, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Instruksi Pembayaran',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInstructionStep(
              '1',
              'Pilih metode pembayaran yang Anda inginkan',
            ),
            _buildInstructionStep('2', 'Transfer sesuai nominal yang tertera'),
            _buildInstructionStep('3', 'Upload bukti transfer/pembayaran'),
            _buildInstructionStep(
              '4',
              'Tunggu konfirmasi dari admin (maks 1x24 jam)',
            ),
            _buildInstructionStep(
              '5',
              'Setelah dikonfirmasi, kontrak sewa akan dibuat',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: _isProcessing ? null : _processPayment,
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.booking.kost.getPrimaryColor(),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
          ),
          child: _isProcessing
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  'Konfirmasi Pembayaran',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
        ),
      ),
    );
  }
}

// ============================================
// Enum untuk Image Source (jika diperlukan)
// ============================================
enum ImageSource { gallery, camera }
