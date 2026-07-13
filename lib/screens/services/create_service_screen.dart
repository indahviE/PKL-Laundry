import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/service.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/service_repository.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_input.dart';

class CreateServiceScreen extends ConsumerStatefulWidget {
  const CreateServiceScreen({super.key});

  @override
  ConsumerState<CreateServiceScreen> createState() => _CreateServiceScreenState();
}

class _CreateServiceScreenState extends ConsumerState<CreateServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _durationController;
  
  PricingType _selectedPricingType = PricingType.perKg;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _priceController = TextEditingController();
    _durationController = TextEditingController(text: '24');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // FIX: authStateProvider berbasis Stream (authStateChanges), sehingga
      // ref.read(...).value bisa sesaat null saat token sedang refresh /
      // provider baru rebuild (race condition), walau user sebenarnya masih
      // login. FirebaseAuth.instance.currentUser bersifat sinkron dan selalu
      // mencerminkan sesi login terkini, jadi lebih aman dipakai di sini.
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

      if (userId.isEmpty) {
        throw Exception('Sesi pengguna tidak ditemukan. Silakan login kembali.');
      }

      // Sesuai blueprint: setiap dokumen di users/{user_id}/service_types/
      // wajib memiliki company_id (lihat 3.3.3 Manajemen Jenis Layanan).
      // Karena MVP mengasumsikan 1 user = 1 company (alur onboarding
      // setup_company_screen), company_id diambil dari
      // users/{user_id}/companies/{company_id} yang pertama dibuat.
      final companySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('companies')
          .limit(1)
          .get();

      if (companySnapshot.docs.isEmpty) {
        throw Exception(
          'Perusahaan belum dibuat. Selesaikan proses onboarding (setup perusahaan) terlebih dahulu.',
        );
      }

      final companyId = companySnapshot.docs.first.id;

      final serviceRepository = ServiceRepository(userId: userId);
      final priceValue = double.parse(_priceController.text.trim());

      final newService = Service(
        id: '', 
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        companyId: companyId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        pricingType: _selectedPricingType,
        pricePerKg: _selectedPricingType == PricingType.perKg ? priceValue : null,
        pricePerItem: _selectedPricingType == PricingType.perItem ? priceValue : null,
        estimatedDuration: int.parse(_durationController.text.trim()),
        isActive: true,
        sortOrder: 0,
      );

      await serviceRepository.addService(newService);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Layanan berhasil ditambahkan!'),
            backgroundColor: Colors.green[600],
          ),
        );
        context.pop(); 
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menambahkan layanan: $e'),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Tambah Layanan Baru',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Detail Layanan Laundry',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Masukkan informasi jenis paket jasa laundry yang kamu sediakan.',
                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),

                AppInput(
                  controller: _nameController,
                  hintText: 'Contoh: Cuci Kering Setrika Reguler',
                  label: 'Nama Layanan',
                  keyboardType: TextInputType.text,
                  validator: (val) => val == null || val.isEmpty ? 'Nama layanan tidak boleh kosong' : null,
                ),
                const SizedBox(height: 16),

                AppInput(
                  controller: _descriptionController,
                  hintText: 'Contoh: Proses cuci, pengeringan mesin, dan setrika rapi.',
                  label: 'Deskripsi (Opsional)',
                  keyboardType: TextInputType.text,
                  maxLines: 3,
                ),
                const SizedBox(height: 16),

                Text(
                  'Metode Perhitungan Harga',
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[700]),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: Center(
                          child: Text(
                            'Per Kilogram (Kg)',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                          ),
                        ),
                        selected: _selectedPricingType == PricingType.perKg,
                        onSelected: (selected) {
                          if (selected) setState(() => _selectedPricingType = PricingType.perKg);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ChoiceChip(
                        label: Center(
                          child: Text(
                            'Per Satuan Item',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                          ),
                        ),
                        selected: _selectedPricingType == PricingType.perItem,
                        onSelected: (selected) {
                          if (selected) setState(() => _selectedPricingType = PricingType.perItem);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                AppInput(
                  controller: _priceController,
                  hintText: 'Contoh: 10000',
                  label: _selectedPricingType == PricingType.perKg ? 'Harga per Kg (Rp)' : 'Harga per Item (Rp)',
                  keyboardType: TextInputType.number,
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Harga tidak boleh kosong';
                    if (double.tryParse(val) == null) return 'Masukkan angka yang valid';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                AppInput(
                  controller: _durationController,
                  hintText: 'Contoh: 24',
                  label: 'Estimasi Waktu Pengerjaan (Dalam Jam)',
                  keyboardType: TextInputType.number,
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Estimasi durasi pengerjaan tidak boleh kosong';
                    if (int.tryParse(val) == null) return 'Masukkan angka bulat jam yang valid';
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                AppButton(
                  label: 'Simpan Layanan',
                  onPressed: _handleSubmit,
                  isLoading: _isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}