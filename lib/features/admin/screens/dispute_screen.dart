import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/bengkel_app_bar.dart';

class DisputeScreen extends StatefulWidget {
  const DisputeScreen({super.key});

  @override
  State<DisputeScreen> createState() => _DisputeScreenState();
}

class _DisputeScreenState extends State<DisputeScreen> {
  int _selectedTab = 0;
  final _tabs = ['Semua', 'Dibuka', 'Ditinjau', 'Selesai', 'Ditutup'];

  final _disputes = [
    _DisputeItem(
      id: 'D-2024-089', trx: 'TRX-8821', title: 'Ganti Oli Mesin',
      desc: 'Oli yang diganti tidak sesuai spesifikasi kendaraan. Sudah komplain ke bengkel tapi tidak ada respon.',
      user: 'Budi Santoso', amount: 'Rp 250.000', date: '31/5/2024', status: 'Dibuka',
    ),
    _DisputeItem(
      id: 'D-2024-087', trx: 'TRX-8790', title: 'Servis Rem',
      desc: 'Rem masih berbunyi setelah servis. Bengkel menolak perbaikan ulang tanpa biaya tambahan.',
      user: 'Rina Wati', amount: 'Rp 450.000', date: '29/5/2024', status: 'Ditinjau',
    ),
    _DisputeItem(
      id: 'D-2024-085', trx: 'TRX-8755', title: 'Tune Up Berkala',
      desc: 'Tune up tidak menyelesaikan masalah starter.',
      user: 'Ahmad Hidayat', amount: 'Rp 350.000', date: '27/5/2024', status: 'Selesai (Pengguna)',
    ),
    _DisputeItem(
      id: 'D-2024-083', trx: 'TRX-8711', title: 'Balancing & Spooring',
      desc: 'Masalah komunikasi jadwal.',
      user: 'Siti Rahayu', amount: 'Rp 200.000', date: '25/5/2024', status: 'Ditutup',
    ),
  ];

  Color _statusColor(String status) {
    if (status.contains('Dibuka')) return AppColors.danger;
    if (status.contains('Ditinjau')) return AppColors.warning;
    if (status.contains('Selesai')) return AppColors.secondary;
    return AppColors.textMuted;
  }

  Color _statusBg(String status) {
    if (status.contains('Dibuka')) return AppColors.dangerLight;
    if (status.contains('Ditinjau')) return AppColors.warningLight;
    if (status.contains('Selesai')) return AppColors.secondaryLight;
    return AppColors.background;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const BengkelAppBar(subtitle: 'Resolution Center'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildAlert(),
          _buildTabs(),
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
          Text('Resolution Center',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          SizedBox(height: 2),
          Text('Tangani dispute transaksi bermasalah',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _buildAlert() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.dangerLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.danger.withOpacity(0.3)),
        ),
        child: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 18),
            SizedBox(width: 8),
            Text(
              '2 dispute memerlukan perhatian segera',
              style: TextStyle(fontSize: 13, color: AppColors.danger, fontWeight: FontWeight.w500),
            ),
          ],
        ),
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
                  color: isSelected ? AppColors.textPrimary : AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? AppColors.textPrimary : AppColors.border),
                ),
                child: Text(
                  _tabs[i],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildMobileList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _disputes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _DisputeCard(
        item: _disputes[i],
        statusColor: _statusColor(_disputes[i].status),
        statusBg: _statusBg(_disputes[i].status),
      ),
    );
  }

  Widget _buildWebList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 2.2,
        ),
        itemCount: _disputes.length,
        itemBuilder: (_, i) => _DisputeCard(
          item: _disputes[i],
          statusColor: _statusColor(_disputes[i].status),
          statusBg: _statusBg(_disputes[i].status),
        ),
      ),
    );
  }
}

class _DisputeItem {
  final String id, trx, title, desc, user, amount, date, status;
  _DisputeItem({
    required this.id, required this.trx, required this.title,
    required this.desc, required this.user, required this.amount,
    required this.date, required this.status,
  });
}

class _DisputeCard extends StatelessWidget {
  final _DisputeItem item;
  final Color statusColor;
  final Color statusBg;

  const _DisputeCard({required this.item, required this.statusColor, required this.statusBg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(item.id,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(width: 6),
              Text(item.trx,
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(item.status,
                    style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600, color: statusColor)),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Text(item.title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 4),
          Text(item.desc,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person_outline_rounded, size: 13, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(item.user, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              const SizedBox(width: 10),
              const Icon(Icons.attach_money_rounded, size: 13, color: AppColors.textMuted),
              Text(item.amount, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              const Spacer(),
              const Icon(Icons.access_time_rounded, size: 12, color: AppColors.textMuted),
              const SizedBox(width: 3),
              Text(item.date, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ],
          ),
        ],
      ),
    );
  }
}