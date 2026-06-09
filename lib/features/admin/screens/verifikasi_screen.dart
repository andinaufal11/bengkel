import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/bengkel_app_bar.dart';

class VerifikasiScreen extends StatefulWidget {
  const VerifikasiScreen({super.key});

  @override
  State<VerifikasiScreen> createState() => _VerifikasiScreenState();
}

class _VerifikasiScreenState extends State<VerifikasiScreen> {
  int _selectedTab = 0;

  final _tabs = [
    _TabData(label: 'Menunggu', count: 5),
    _TabData(label: 'Semua', count: 7),
    _TabData(label: 'Disetujui', count: 1),
    _TabData(label: 'Ditolak', count: 1),
  ];

  final _items = [
    _VerifItem(name: 'Bengkel Maju Jaya', owner: 'Hendra Kusuma', city: 'Jakarta Timur', docs: 4, status: 'Menunggu'),
    _VerifItem(name: 'Auto Kencana Service', owner: 'Ratna Dewi', city: 'Surabaya', docs: 3, status: 'Menunggu'),
    _VerifItem(name: 'Bengkel Prima Motor', owner: 'Agus Santoso', city: 'Bandung', docs: 4, status: 'Menunggu'),
    _VerifItem(name: 'Karya Teknik Auto', owner: 'Sari Indah', city: 'Yogyakarta', docs: 5, status: 'Menunggu'),
    _VerifItem(name: 'Bengkel Nusantara', owner: 'Joko Widodo', city: 'Makassar', docs: 2, status: 'Menunggu'),
  ];

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
              itemBuilder: (_, i) => _VerifCard(item: _items[i]),
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
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: _items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _VerifCard(item: _items[i]),
    );
  }
}

class _TabData {
  final String label;
  final int count;
  _TabData({required this.label, required this.count});
}

class _VerifItem {
  final String name, owner, city, status;
  final int docs;
  _VerifItem({required this.name, required this.owner, required this.city, required this.docs, required this.status});
}

class _VerifCard extends StatelessWidget {
  final _VerifItem item;
  const _VerifCard({required this.item});

  @override
  Widget build(BuildContext context) {
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
                Text(item.name,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text(item.owner,
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, size: 11, color: AppColors.textMuted),
                    const SizedBox(width: 2),
                    Text(item.city,
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    const SizedBox(width: 10),
                    Text('${item.docs} dok',
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('Menunggu',
                          style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFFD97706),
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
        ],
      ),
    );
  }
}