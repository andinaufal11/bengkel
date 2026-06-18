import 'package:flutter/material.dart';
import 'package:bengkel/core/constants/app_colors.dart';
import 'package:bengkel/core/utils/responsive.dart';
import 'package:bengkel/features/shared_features/widgets/bengkel_app_bar.dart';
import 'package:bengkel/core/service/admin_service.dart';

class _TabData {
  final String label;
  final String statusKey;
  _TabData({required this.label, required this.statusKey});
}

class WithdrawalApprovalScreen extends StatefulWidget {
  const WithdrawalApprovalScreen({super.key});

  @override
  State<WithdrawalApprovalScreen> createState() => _WithdrawalApprovalScreenState();
}

class _WithdrawalApprovalScreenState extends State<WithdrawalApprovalScreen> {
  final AdminService _service = AdminService();
  int _selectedTab = 0;
  bool _isLoading = true;
  List<Map<String, dynamic>> _items = [];

  final _tabs = [
    _TabData(label: 'Menunggu', statusKey: 'pending'),
    _TabData(label: 'Semua', statusKey: 'semua'),
    _TabData(label: 'Disetujui', statusKey: 'approved'),
    _TabData(label: 'Ditolak', statusKey: 'rejected'),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final status = _tabs[_selectedTab].statusKey;
      final data = await _service.getWithdrawals(status: status);
      setState(() {
        _items = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data: $e'), backgroundColor: AppColors.danger),
      );
    }
  }

  Future<void> _updateStatus(String id, String status, {String? reason}) async {
    try {
      await _service.updateWithdrawalStatus(id, status, reason: reason);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Penarikan dana berhasil ${status == 'approved' ? 'disetujui' : 'ditolak'}!'),
          backgroundColor: status == 'approved' ? AppColors.secondary : AppColors.danger,
        ),
      );
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memperbarui status: $e'), backgroundColor: AppColors.danger),
      );
    }
  }

  void _showRejectDialog(String id) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tolak Penarikan Dana', style: TextStyle(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: reasonController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Alasan Penolakan',
              hintText: 'Saldo tidak mencukupi, informasi rekening salah, dll...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                final reason = reasonController.text.trim();
                if (reason.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Alasan penolakan tidak boleh kosong'), backgroundColor: AppColors.warning),
                  );
                  return;
                }
                Navigator.pop(context);
                _updateStatus(id, 'rejected', reason: reason);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
              child: const Text('Tolak', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  String _formatRupiah(int price) {
    final buffer = StringBuffer("Rp");
    final str = price.toString();
    for (int i = 0; i < str.length; i++) {
      buffer.write(str[i]);
      if ((str.length - i - 1) % 3 == 0 && i < str.length - 1) {
        buffer.write(".");
      }
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const BengkelAppBar(subtitle: 'Penarikan Dana'),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildTabs(),
            Expanded(child: _buildList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('Persetujuan Penarikan Dana',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          SizedBox(height: 2),
          Text('Tinjau & proses pengajuan penarikan dana dari mitra bengkel',
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
              onTap: () {
                setState(() {
                  _selectedTab = i;
                });
                _loadData();
              },
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
                child: Text(
                  _tabs[i].label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
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

  Widget _buildList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.monetization_on_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'Tidak ada pengajuan penarikan dana',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    if (Responsive.isWeb(context)) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 2.2,
          ),
          itemCount: _items.length,
          itemBuilder: (_, i) => _buildWithdrawalCard(_items[i]),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: _items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _buildWithdrawalCard(_items[i]),
    );
  }

  Widget _buildWithdrawalCard(Map<String, dynamic> item) {
    final status = (item['status'] ?? 'pending').toString();
    final amount = (item['amount'] as num?)?.toInt() ?? 0;
    final id = item['id'].toString();
    final bankName = item['bank_name'] ?? '';
    final accountNumber = item['account_number'] ?? '';
    final accountName = item['account_name'] ?? '';
    final bengkelName = item['bengkels']?['name'] ?? 'Bengkel Mitra';
    final rejectionReason = item['rejection_reason'] as String?;

    Color statusColor = AppColors.warning;
    Color statusBg = AppColors.warningLight;
    String statusLabel = 'Menunggu';

    if (status == 'approved') {
      statusColor = AppColors.secondary;
      statusBg = AppColors.secondaryLight;
      statusLabel = 'Disetujui';
    } else if (status == 'rejected') {
      statusColor = AppColors.danger;
      statusBg = AppColors.dangerLight;
      statusLabel = 'Ditolak';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                bengkelName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),
          
          // Bank details
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
                child: const Icon(Icons.account_balance_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$bankName — $accountNumber', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text('a.n. $accountName', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Amount Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Jumlah Penarikan', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text(
                _formatRupiah(amount),
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textPrimary),
              ),
            ],
          ),

          if (status == 'rejected' && rejectionReason != null && rejectionReason.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.dangerLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Alasan: $rejectionReason',
                style: const TextStyle(color: AppColors.danger, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
          ],

          if (status == 'pending') ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showRejectDialog(id),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text('Tolak', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _updateStatus(id, 'approved'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      elevation: 0,
                    ),
                    child: const Text('Setujui', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
