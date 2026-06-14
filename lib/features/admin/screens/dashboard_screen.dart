import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bengkel/core/constants/app_colors.dart';
import 'package:bengkel/core/utils/responsive.dart';
import 'package:bengkel/features/shared_features/widgets/bengkel_app_bar.dart';
import 'package:bengkel/core/service/admin_service.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const BengkelAppBar(subtitle: 'Dashboard'),
      body: Responsive.isWeb(context)
          ? _buildWebBody(context)
          : _buildMobileBody(context),
    );
  }

  // ─── MOBILE ───────────────────────────────────────────────────────────────
  Widget _buildMobileBody(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGreeting(),
          const SizedBox(height: 16),
          _buildStatCards(context),
          const SizedBox(height: 16),
          _buildChart(),
          const SizedBox(height: 16),
          _buildRecentActivity(),
        ],
      ),
    );
  }

  // ─── WEB ──────────────────────────────────────────────────────────────────
  Widget _buildWebBody(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGreeting(),
          const SizedBox(height: 20),
          _buildStatCards(context),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: _buildChart()),
              const SizedBox(width: 20),
              Expanded(flex: 2, child: _buildRecentActivity()),
            ],
          ),
        ],
      ),
    );
  }

  // ─── GREETING ─────────────────────────────────────────────────────────────
  Widget _buildGreeting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Senin, 8 Juni 2026',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w400,
          ),
        ),
        SizedBox(height: 4),
        Row(
          children: [
            Text(
              'Selamat Datang, Admin ',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Text('👋', style: TextStyle(fontSize: 22)),
          ],
        ),
      ],
    );
  }

  // ─── STAT CARDS ───────────────────────────────────────────────────────────
  Widget _buildStatCards(BuildContext context) {
    final cards = [
      _StatCardData(
        icon: Icons.shield_rounded,
        iconBg: const Color(0xFFFEF9C3),
        iconColor: const Color(0xFFCA8A04),
        value: '7',
        label: 'Mitra Pending',
        trend: '↑ +2 hari ini',
        trendColor: AppColors.secondary,
      ),
      _StatCardData(
        icon: Icons.people_alt_rounded,
        iconBg: const Color(0xFFDBEAFE),
        iconColor: AppColors.primary,
        value: '12.847',
        label: 'Total Pengguna',
        trend: '↑ +134 minggu ini',
        trendColor: AppColors.secondary,
      ),
      _StatCardData(
        icon: Icons.trending_up_rounded,
        iconBg: const Color(0xFFDCFCE7),
        iconColor: AppColors.secondary,
        value: 'Rp48,3Jt',
        label: 'Komisi Bulan Ini',
        trend: '↑ +12% vs lalu',
        trendColor: AppColors.secondary,
      ),
      _StatCardData(
        icon: Icons.warning_amber_rounded,
        iconBg: const Color(0xFFFEE2E2),
        iconColor: AppColors.danger,
        value: '3',
        label: 'Dispute Aktif',
        trend: '↓ -1 dari kemarin',
        trendColor: AppColors.danger,
      ),
    ];

    if (Responsive.isWeb(context)) {
      return Row(
        children: cards
            .map((c) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _StatCard(data: c),
                  ),
                ))
            .toList(),
      );
    }

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.3,
      children: cards.map((c) => _StatCard(data: c)).toList(),
    );
  }

  // ─── CHART ────────────────────────────────────────────────────────────────
  Widget _buildChart() {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun'];
    final values = [0.45, 0.52, 0.48, 0.40, 0.60, 0.80];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Komisi 6 Bulan Terakhir',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(months.length, (i) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: 130 * values[i],
                          decoration: BoxDecoration(
                            color: i == months.length - 1
                                ? AppColors.primary
                                : const Color(0xFF93C5FD),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          months[i],
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // ─── RECENT ACTIVITY ──────────────────────────────────────────────────────
  Widget _buildRecentActivity() {
    final activities = [
      _ActivityData(
        color: AppColors.warning,
        text: 'Bengkel Maju Jaya mengajukan verifikasi',
        time: '5 menit lalu',
      ),
      _ActivityData(
        color: AppColors.danger,
        text: 'Dispute #D-2024-089 diajukan Budi S.',
        time: '23 menit lalu',
      ),
      _ActivityData(
        color: AppColors.secondary,
        text: 'Komisi diperbarui menjadi 8%',
        time: '1 jam lalu',
      ),
      _ActivityData(
        color: AppColors.purple,
        text: 'Akun Auto Kencana disuspend',
        time: '2 jam lalu',
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Aktivitas Terbaru',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...activities.map((a) => _ActivityTile(data: a)),
        ],
      ),
    );
  }
}

// ─── SUB WIDGETS ────────────────────────────────────────────────────────────

class _StatCardData {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String value;
  final String label;
  final String trend;
  final Color trendColor;

  _StatCardData({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.trend,
    required this.trendColor,
  });
}

class _StatCard extends StatelessWidget {
  final _StatCardData data;
  const _StatCard({required this.data});

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
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: data.iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(data.icon, color: data.iconColor, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            data.value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            data.label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            data.trend,
            style: TextStyle(
              fontSize: 11,
              color: data.trendColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityData {
  final Color color;
  final String text;
  final String time;
  _ActivityData({required this.color, required this.text, required this.time});
}

class _ActivityTile extends StatelessWidget {
  final _ActivityData data;
  const _ActivityTile({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: data.color,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.text,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded,
                        size: 11, color: AppColors.textMuted),
                    const SizedBox(width: 3),
                    Text(
                      data.time,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

final dashboardProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final adminService = AdminService();
  return await adminService.getDashboardStats();
});

// Di dalam widget
class DashboardWeb extends ConsumerWidget {
  const DashboardWeb({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardData = ref.watch(dashboardProvider);

    return dashboardData.when(
      data: (data) => DashboardContent(data: data),
      loading: () => const CircularProgressIndicator(),
      error: (e, _) => Text('Error: $e'),
    );
  }
}

class DashboardContent extends StatelessWidget {
  final Map<String, dynamic> data;
  const DashboardContent({required this.data, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text('Dashboard loaded: ${data.length} items');
  }
}
