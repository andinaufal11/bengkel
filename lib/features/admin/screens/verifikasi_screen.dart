import 'package:flutter/material.dart';
import 'package:bengkel/core/constants/app_colors.dart';
import 'package:bengkel/core/utils/responsive.dart';
import 'package:bengkel/features/shared_features/widgets/bengkel_app_bar.dart';
import 'package:bengkel/core/service/admin_service.dart';

class _TabData {
  final String label;
  final int count;
  _TabData({required this.label, required this.count});
}

class VerifikasiScreen extends StatefulWidget {
  const VerifikasiScreen({super.key});

  @override
  State<VerifikasiScreen> createState() => _VerifikasiScreenState();
}

class _VerifikasiScreenState extends State<VerifikasiScreen> {
  final AdminService _service = AdminService();
  int _selectedTab = 0;
  bool _isLoading = true;
  List<Map<String, dynamic>> _items = [];

  final _tabs = [
    _TabData(label: 'Menunggu', count: 0),
    _TabData(label: 'Semua', count: 0),
    _TabData(label: 'Disetujui', count: 0),
    _TabData(label: 'Ditolak', count: 0),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _service.getMitraVerifikasi();
      setState(() {
        _items = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(String id, String status) async {
    await _service.updateStatusMitra(id, status);
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const BengkelAppBar(subtitle: 'Verifikasi Mitra'),
      body: Responsive.isWeb(context) ? _buildWeb() : _buildMobile(),
    );
  }

  Widget _buildMobile() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        _buildTabs(),
        Expanded(child: _buildList()),
      ],
    );
  }

  Widget _buildWeb() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        _buildTabs(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 3,
              ),
              itemCount: _items.length,
              itemBuilder: (_, i) {
                final item = _items[i];
                final status = (item['status'] ?? '').toString();
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.store_rounded, color: AppColors.primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['nama_bengkel'] ?? '',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            Text(item['nama_pemilik'] ?? '',
                                style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.location_on_rounded, size: 11, color: AppColors.textMuted),
                                const SizedBox(width: 2),
                                Text(item['kota'] ?? '',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                const SizedBox(width: 10),
                                Text('${item['jumlah_dokumen'] ?? 0} dok',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: status.toLowerCase().contains('menunggu') ? const Color(0xFFFEF3C7) : AppColors.background,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(status.isEmpty ? '—' : status,
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                            onPressed: () async {
                              final id = item['id'].toString();
                              await _updateStatus(id, 'disetujui');
                            },
                            child: const Text('Setujui', style: TextStyle(color: Colors.white)),
                          ),
                          const SizedBox(height: 6),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
                            onPressed: () async {
                              final id = item['id'].toString();
                              await _updateStatus(id, 'ditolak');
                            },
                            child: const Text('Tolak'),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('Verifikasi Mitra',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          SizedBox(height: 2),
          Text('Tinjau pendaftaran bengkel mitra',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(_tabs.length, (i) {
            final isSelected = i == _selectedTab;
            return GestureDetector(
              onTap: () => setState(() => _selectedTab = i),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      _tabs[i].label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    if (_tabs[i].count > 0) ...[
                      const SizedBox(width: 5),
                      Text(
                        '${_tabs[i].count}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white70 : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: _items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final item = _items[i];
        final status = (item['status'] ?? '').toString();
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.store_rounded, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['nama_bengkel'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    Text(item['nama_pemilik'] ?? '',
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, size: 11, color: AppColors.textMuted),
                        const SizedBox(width: 2),
                        Text(item['kota'] ?? '',
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        const SizedBox(width: 10),
                        Text('${item['jumlah_dokumen'] ?? 0} dok',
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: status.toLowerCase().contains('menunggu') ? const Color(0xFFFEF3C7) : AppColors.background,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(status.isEmpty ? '—' : status,
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    onPressed: () async {
                      final id = item['id'].toString();
                      await _updateStatus(id, 'disetujui');
                    },
                    child: const Text('Setujui', style: TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(height: 6),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
                    onPressed: () async {
                      final id = item['id'].toString();
                      await _updateStatus(id, 'ditolak');
                    },
                    child: const Text('Tolak'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
