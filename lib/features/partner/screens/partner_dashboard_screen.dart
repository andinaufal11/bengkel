import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bengkel/features/auth/models/user_model.dart';
import 'package:bengkel/features/auth/screens/login_screen.dart';
import 'partner_mechanic_screen.dart';
import 'partner_inventory_screen.dart';
import 'partner_orders_screen.dart';
import 'partner_finance_screen.dart';

class PartnerDashboardScreen extends StatefulWidget {
  final UserModel user;
  const PartnerDashboardScreen({super.key, required this.user});

  @override
  State<PartnerDashboardScreen> createState() => _PartnerDashboardScreenState();
}

class _PartnerDashboardScreenState extends State<PartnerDashboardScreen> {
  int _currentIndex = 0;
  Map<String, dynamic>? _bengkelData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBengkelData();
  }

  Future<void> _fetchBengkelData() async {
    try {
      final data = await Supabase.instance.client
          .from('bengkels')
          .select()
          .eq('owner_id', widget.user.id)
          .maybeSingle();
      if (mounted) {
        setState(() {
          _bengkelData = data;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint("Error fetching bengkel data in PartnerDashboardScreen: $e");
      debugPrint(stackTrace.toString());
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF2563EB))),
      );
    }

    final bool isApproved = _bengkelData?['status'] == 'approved';
    final String bengkelId = _bengkelData?['id']?.toString() ?? '';
    final String bengkelName = _bengkelData?['name'] ?? 'Bengkel Anda';

    final List<Widget> screens = [
      _PartnerHomeTab(
        bengkelData: _bengkelData,
        user: widget.user,
        isApproved: isApproved,
        onTabChange: (i) => setState(() => _currentIndex = i),
      ),
      isApproved
          ? PartnerMechanicScreen(bengkelId: bengkelId, bengkelName: bengkelName)
          : _LockedTab(featureName: 'Kelola Mekanik'),
      isApproved
          ? PartnerInventoryScreen(bengkelId: bengkelId)
          : _LockedTab(featureName: 'Inventaris Sparepart'),
      isApproved
          ? PartnerOrdersScreen(bengkelId: bengkelId)
          : _LockedTab(featureName: 'Manajemen Pesanan'),
      isApproved
          ? PartnerFinanceScreen(bengkelId: bengkelId)
          : _LockedTab(featureName: 'Keuangan'),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: screens[_currentIndex],
      bottomNavigationBar: _buildBottomNav(isApproved),
    );
  }

  Widget _buildBottomNav(bool isApproved) {
    const items = [
      {'icon': Icons.home_rounded, 'label': 'Beranda'},
      {'icon': Icons.people_rounded, 'label': 'Mekanik'},
      {'icon': Icons.inventory_2_rounded, 'label': 'Inventaris'},
      {'icon': Icons.receipt_long_rounded, 'label': 'Pesanan'},
      {'icon': Icons.account_balance_wallet_rounded, 'label': 'Keuangan'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -3))
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(items.length, (i) {
              final isSelected = _currentIndex == i;
              final isLocked = i > 0 && !isApproved;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _currentIndex = i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(
                            items[i]['icon'] as IconData,
                            size: 22,
                            color: isSelected
                                ? const Color(0xFF2563EB)
                                : (isLocked ? Colors.grey.shade300 : Colors.grey.shade500),
                          ),
                          if (isLocked)
                            Positioned(
                              right: -4,
                              top: -4,
                              child: Icon(Icons.lock, size: 10, color: Colors.grey.shade400),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        items[i]['label'] as String,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? const Color(0xFF2563EB)
                              : (isLocked ? Colors.grey.shade300 : Colors.grey.shade500),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ─────────────────── HOME TAB ────────────────────────────────────────────────
class _PartnerHomeTab extends StatefulWidget {
  final Map<String, dynamic>? bengkelData;
  final UserModel user;
  final bool isApproved;
  final Function(int) onTabChange;

  const _PartnerHomeTab({
    required this.bengkelData,
    required this.user,
    required this.isApproved,
    required this.onTabChange,
  });

  @override
  State<_PartnerHomeTab> createState() => _PartnerHomeTabState();
}

class _PartnerHomeTabState extends State<_PartnerHomeTab> {
  Map<String, int> _stats = {'total_orders': 0, 'pending_orders': 0, 'total_mechanics': 0};
  bool _loadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final bengkelId = widget.bengkelData?['id']?.toString() ?? '';
    if (bengkelId.isEmpty) {
      if (mounted) setState(() => _loadingStats = false);
      return;
    }
    try {
      final orders = await Supabase.instance.client
          .from('orders')
          .select('id, status')
          .eq('bengkel_id', bengkelId);
      final mechanics = await Supabase.instance.client
          .from('mechanics')
          .select('id')
          .eq('bengkels_id', bengkelId);
      if (mounted) {
        final orderList = List<Map<String, dynamic>>.from(orders);
        setState(() {
          _stats = {
            'total_orders': orderList.length,
            'pending_orders': orderList.where((o) => o['status'] == 'pending' || o['status'] == 'Pending').length,
            'total_mechanics': (mechanics as List).length,
          };
          _loadingStats = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingStats = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isApproved = widget.isApproved;
    final bengkelName = widget.bengkelData?['name'] ?? 'Bengkel Anda';
    // status already used in isApproved logic above

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        color: const Color(0xFF2563EB),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 160,
              floating: false,
              pinned: true,
              automaticallyImplyLeading: false,
              backgroundColor: const Color(0xFF1E3A5F),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1E3A5F), Color(0xFF2563EB)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Panel Mitra Bengkel',
                                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    bengkelName,
                                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              GestureDetector(
                                onTap: () async {
                                  await Supabase.instance.client.auth.signOut();
                                  if (context.mounted) {
                                    Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                                      (r) => false,
                                    );
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isApproved
                                  ? Colors.green.withValues(alpha: 0.2)
                                  : Colors.orange.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isApproved ? Colors.green.shade300 : Colors.orange.shade300,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isApproved ? Icons.verified_rounded : Icons.hourglass_empty_rounded,
                                  color: isApproved ? Colors.greenAccent : Colors.orangeAccent,
                                  size: 14,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isApproved ? 'TERVERIFIKASI' : 'MENUNGGU VERIFIKASI',
                                  style: TextStyle(
                                    color: isApproved ? Colors.greenAccent : Colors.orangeAccent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isApproved)
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFFED7AA)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, color: Color(0xFFF97316), size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Akun Menunggu Persetujuan Admin',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF9A3412)),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Dokumen Anda sedang ditinjau. Fitur manajemen akan aktif setelah disetujui.',
                                    style: TextStyle(fontSize: 12, color: Colors.orange.shade800, height: 1.4),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Stats Row
                    const Text(
                      'Ringkasan Hari Ini',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 12),
                    _loadingStats
                        ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
                        : Row(
                            children: [
                              Expanded(child: _buildStatCard('Total Pesanan', _stats['total_orders'].toString(), Icons.receipt_long_rounded, const Color(0xFF2563EB))),
                              const SizedBox(width: 12),
                              Expanded(child: _buildStatCard('Menunggu', _stats['pending_orders'].toString(), Icons.pending_actions_rounded, const Color(0xFFF59E0B))),
                              const SizedBox(width: 12),
                              Expanded(child: _buildStatCard('Mekanik', _stats['total_mechanics'].toString(), Icons.engineering_rounded, const Color(0xFF10B981))),
                            ],
                          ),
                    const SizedBox(height: 24),

                    const Text(
                      'Menu Utama',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.5,
                      children: [
                        _buildMenuCard(
                          icon: Icons.people_rounded,
                          title: 'Kelola Mekanik',
                          subtitle: 'Tambah & atur mekanik',
                          color: const Color(0xFF2563EB),
                          isLocked: !isApproved,
                          onTap: () => widget.onTabChange(1),
                        ),
                        _buildMenuCard(
                          icon: Icons.inventory_2_rounded,
                          title: 'Inventaris',
                          subtitle: 'Stok spare part',
                          color: const Color(0xFF7C3AED),
                          isLocked: !isApproved,
                          onTap: () => widget.onTabChange(2),
                        ),
                        _buildMenuCard(
                          icon: Icons.receipt_long_rounded,
                          title: 'Pesanan Masuk',
                          subtitle: 'Kelola order pelanggan',
                          color: const Color(0xFFF59E0B),
                          isLocked: !isApproved,
                          onTap: () => widget.onTabChange(3),
                        ),
                        _buildMenuCard(
                          icon: Icons.account_balance_wallet_rounded,
                          title: 'Keuangan',
                          subtitle: 'Pendapatan & withdraw',
                          color: const Color(0xFF10B981),
                          isLocked: !isApproved,
                          onTap: () => widget.onTabChange(4),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isLocked,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: isLocked ? () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fitur ini tersedia setelah bengkel Anda diverifikasi admin.'),
            backgroundColor: Color(0xFF1E293B),
          ),
        );
      } : onTap,
      child: Opacity(
        opacity: isLocked ? 0.4 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 3))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 10),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
              Text(subtitle, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────── LOCKED TAB ──────────────────────────────────────────────
class _LockedTab extends StatelessWidget {
  final String featureName;
  const _LockedTab({required this.featureName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_rounded, size: 48, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 20),
            Text(
              featureName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Fitur ini hanya tersedia setelah bengkel Anda diverifikasi oleh Admin.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}