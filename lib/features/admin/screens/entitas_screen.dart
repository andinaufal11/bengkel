import 'package:flutter/material.dart';
import 'package:bengkel/core/constants/app_colors.dart';
import 'package:bengkel/core/utils/responsive.dart';
import 'package:bengkel/features/shared_features/widgets/bengkel_app_bar.dart';

class EntitasScreen extends StatefulWidget {
  const EntitasScreen({super.key});

  @override
  State<EntitasScreen> createState() => _EntitasScreenState();
}

class _EntitasScreenState extends State<EntitasScreen> {
  int _selectedTab = 0; // 0 = Pengguna, 1 = Bengkel
  final _searchController = TextEditingController();

  final _users = [
    _UserItem(name: 'Budi Santoso', email: 'budi.s@gmail.com', city: 'Jakarta', trx: 12, status: 'Aktif', note: null),
    _UserItem(name: 'Siti Rahayu', email: 'siti.rahayu@yahoo.com', city: 'Surabaya', trx: 5, status: 'Aktif', note: null),
    _UserItem(name: 'Ahmad Hidayat', email: 'a.hidayat@gmail.com', city: 'Bandung', trx: 8, status: 'Suspended', note: 'Penipuan transaksi - laporan x3'),
    _UserItem(name: 'Rina Wati', email: 'rina.w@hotmail.com', city: 'Medan', trx: 3, status: 'Aktif', note: null),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const BengkelAppBar(subtitle: 'Manajemen Entitas'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildTabToggle(),
          _buildSearchBar(),
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
          Text('Manajemen Entitas',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          SizedBox(height: 2),
          Text('Kelola akun pengguna dan bengkel',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _buildTabToggle() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            _TabButton(
              label: 'Pengguna',
              icon: Icons.people_rounded,
              isSelected: _selectedTab == 0,
              onTap: () => setState(() => _selectedTab = 0),
            ),
            _TabButton(
              label: 'Bengkel',
              icon: Icons.vpn_key_rounded,
              isSelected: _selectedTab == 1,
              onTap: () => setState(() => _selectedTab = 1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Cari pengguna...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _users.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _UserCard(user: _users[i]),
    );
  }

  Widget _buildWebList() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Expanded(flex: 3, child: Text('Nama', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted))),
                Expanded(flex: 2, child: Text('Kota', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted))),
                Expanded(flex: 1, child: Text('Transaksi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted))),
                Expanded(flex: 1, child: Text('Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted))),
                SizedBox(width: 40),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              itemCount: _users.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _UserCardWeb(user: _users[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? Colors.white : AppColors.textMuted),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserItem {
  final String name, email, city, status;
  final int trx;
  final String? note;
  _UserItem({required this.name, required this.email, required this.city, required this.trx, required this.status, this.note});
}

class _UserCard extends StatelessWidget {
  final _UserItem user;
  const _UserCard({required this.user});

  Color get _avatarColor {
    final colors = [AppColors.primary, AppColors.secondary, const Color(0xFFF59E0B), AppColors.danger];
    return colors[user.name.codeUnitAt(0) % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final isSuspended = user.status == 'Suspended';
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _avatarColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      user.name[0],
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      Text(user.email, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      Text('${user.city}  ·  ${user.trx} transaksi',
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isSuspended ? const Color(0xFFFEF3C7) : AppColors.secondaryLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        user.status,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isSuspended ? const Color(0xFFD97706) : AppColors.secondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 18),
                  ],
                ),
              ],
            ),
          ),
          if (user.note != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: const BoxDecoration(
                color: Color(0xFFFEFCE8),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Text(
                user.note!,
                style: const TextStyle(fontSize: 12, color: Color(0xFFB45309)),
              ),
            ),
        ],
      ),
    );
  }
}

class _UserCardWeb extends StatelessWidget {
  final _UserItem user;
  const _UserCardWeb({required this.user});

  Color get _avatarColor {
    final colors = [AppColors.primary, AppColors.secondary, const Color(0xFFF59E0B), AppColors.danger];
    return colors[user.name.codeUnitAt(0) % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final isSuspended = user.status == 'Suspended';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: _avatarColor, shape: BoxShape.circle),
                  child: Center(child: Text(user.name[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    Text(user.email, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
              ],
            ),
          ),
          Expanded(flex: 2, child: Text(user.city, style: const TextStyle(fontSize: 13))),
          Expanded(flex: 1, child: Text('${user.trx}', style: const TextStyle(fontSize: 13))),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isSuspended ? const Color(0xFFFEF3C7) : AppColors.secondaryLight,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                user.status,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isSuspended ? const Color(0xFFD97706) : AppColors.secondary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 40, child: Icon(Icons.chevron_right_rounded, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}