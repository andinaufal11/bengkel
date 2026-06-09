import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/bengkel_app_bar.dart';

class MasterScreen extends StatefulWidget {
  const MasterScreen({super.key});

  @override
  State<MasterScreen> createState() => _MasterScreenState();
}

class _MasterScreenState extends State<MasterScreen> {
  int _selectedTab = 0;

  final _tabItems = [
    _MasterTab(label: 'Merek Kendaraan', icon: Icons.directions_car_rounded, active: 7, total: 8),
    _MasterTab(label: 'Tipe Kendaraan', icon: Icons.layers_rounded, active: 7, total: 8),
    _MasterTab(label: 'Layanan', icon: Icons.build_circle_rounded, active: 5, total: 6),
  ];

  final _brands = [
    _BrandItem(name: 'Toyota', code: 'TYT', id: 'MRK-001', isActive: true),
    _BrandItem(name: 'Honda', code: 'HND', id: 'MRK-002', isActive: true),
    _BrandItem(name: 'Suzuki', code: 'SZK', id: 'MRK-003', isActive: true),
    _BrandItem(name: 'Daihatsu', code: 'DHT', id: 'MRK-004', isActive: true),
    _BrandItem(name: 'Yamaha', code: 'YMH', id: 'MRK-005', isActive: true),
    _BrandItem(name: 'Kawasaki', code: 'KWS', id: 'MRK-006', isActive: true),
    _BrandItem(name: 'Mitsubishi', code: 'MTS', id: 'MRK-007', isActive: true),
    _BrandItem(name: 'Nissan', code: 'NSN', id: 'MRK-008', isActive: false),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const BengkelAppBar(subtitle: 'Master Data'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildTabScroll(),
          _buildListHeader(),
          Expanded(
            child: Responsive.isWeb(context)
                ? _buildWebList()
                : _buildMobileList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('Master Data', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          SizedBox(height: 2),
          Text('Kelola data referensi sistem', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _buildTabScroll() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(_tabItems.length, (i) {
            final isSelected = i == _selectedTab;
            final tab = _tabItems[i];
            return GestureDetector(
              onTap: () => setState(() => _selectedTab = i),
              child: Container(
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(tab.icon, size: 18,
                        color: isSelected ? Colors.white : AppColors.textMuted),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tab.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : AppColors.textPrimary,
                            )),
                        Text('${tab.active}/${tab.total} aktif',
                            style: TextStyle(
                              fontSize: 10,
                              color: isSelected ? Colors.white70 : AppColors.textMuted,
                            )),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildListHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Text(
            '${_tabItems[_selectedTab].label} ${_brands.length}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.add_rounded, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text('Tambah', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _brands.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _BrandCard(item: _brands[i]),
    );
  }

  Widget _buildWebList() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 5,
        ),
        itemCount: _brands.length,
        itemBuilder: (_, i) => _BrandCard(item: _brands[i]),
      ),
    );
  }
}

class _MasterTab {
  final String label;
  final IconData icon;
  final int active, total;
  _MasterTab({required this.label, required this.icon, required this.active, required this.total});
}

class _BrandItem {
  final String name, code, id;
  final bool isActive;
  _BrandItem({required this.name, required this.code, required this.id, required this.isActive});
}

class _BrandCard extends StatelessWidget {
  final _BrandItem item;
  const _BrandCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: item.isActive ? AppColors.secondary : AppColors.textMuted,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Text(item.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: item.isActive ? AppColors.textPrimary : AppColors.textMuted,
                        )),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(item.code,
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
                    ),
                  ],
                ),
                Text(item.id,
                    style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: item.isActive ? AppColors.secondaryLight : AppColors.background,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              item.isActive ? 'Aktif' : 'Off',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: item.isActive ? AppColors.secondary : AppColors.textMuted,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {},
            child: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textMuted),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {},
            child: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.danger),
          ),
        ],
      ),
    );
  }
}