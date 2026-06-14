import 'package:flutter/material.dart';
import 'package:bengkel/core/constants/app_colors.dart';
import 'package:bengkel/core/utils/responsive.dart';
import 'package:bengkel/features/shared_features/widgets/bengkel_app_bar.dart';
import 'package:bengkel/core/service/admin_service.dart';

class MasterScreen extends StatefulWidget {
  const MasterScreen({super.key});
  @override
  State<MasterScreen> createState() => _MasterScreenState();
}
 
class _MasterScreenState extends State<MasterScreen> {
  final _service = AdminService();
  List<Map<String, dynamic>> _brands = [];
  bool _isLoading = true;
 
  @override
  void initState() { super.initState(); _loadData(); }
 
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _service.getMerekKendaraan();
      setState(() { _brands = data; _isLoading = false; });
    } catch (e) { setState(() => _isLoading = false); }
  }
 
  Future<void> _toggleStatus(String id, bool current) async {
    await _service.toggleMerekStatus(id, !current);
    _loadData();
  }
 
  Future<void> _deleteMerek(String id) async {
    await _service.deleteMerek(id);
    _loadData();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Merek dihapus'), backgroundColor: AppColors.danger));
  }
 
  void _showTambahDialog() {
    final namaController = TextEditingController();
    final kodeController = TextEditingController();
    final nomorController = TextEditingController();
 
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tambah Merek', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: namaController, decoration: const InputDecoration(labelText: 'Nama Merek')),
          TextField(controller: kodeController, decoration: const InputDecoration(labelText: 'Kode (3 huruf)')),
          TextField(controller: nomorController, decoration: const InputDecoration(labelText: 'Nomor Urut (MRK-00X)')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              await _service.tambahMerek(namaController.text, kodeController.text, nomorController.text);
              Navigator.pop(context);
              _loadData();
            },
            child: const Text('Simpan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const BengkelAppBar(subtitle: 'Master Data'),
      body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(children: [
            const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Master Data', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              Text('Kelola data referensi sistem', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
            ]),
            const Spacer(),
            GestureDetector(
              onTap: _showTambahDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
                child: const Row(children: [
                  Icon(Icons.add_rounded, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text('Tambah', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _brands.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final b = _brands[i];
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(children: [
                          Container(width: 8, height: 8,
                            decoration: BoxDecoration(
                              color: b['is_active'] == true ? AppColors.secondary : AppColors.textMuted,
                              shape: BoxShape.circle)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                Text(b['nama'] ?? '', style: TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13,
                                  color: b['is_active'] == true ? AppColors.textPrimary : AppColors.textMuted)),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(4)),
                                  child: Text(b['kode'] ?? '',
                                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
                                ),
                              ]),
                              Text(b['nomor_urut'] ?? '', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                            ]),
                          ),
                          GestureDetector(
                            onTap: () => _toggleStatus(b['id'], b['is_active'] == true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: b['is_active'] == true ? AppColors.secondaryLight : AppColors.background,
                                borderRadius: BorderRadius.circular(6)),
                              child: Text(b['is_active'] == true ? 'Aktif' : 'Off',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                                  color: b['is_active'] == true ? AppColors.secondary : AppColors.textMuted)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _deleteMerek(b['id']),
                            child: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.danger),
                          ),
                        ]),
                      );
                    },
                  ),
                ),
        ),
      ]),
    );
  }
}