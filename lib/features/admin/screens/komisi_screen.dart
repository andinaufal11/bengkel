import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/bengkel_app_bar.dart';

class KomisiScreen extends StatefulWidget {
  const KomisiScreen({super.key});

  @override
  State<KomisiScreen> createState() => _KomisiScreenState();
}

class _KomisiScreenState extends State<KomisiScreen> {
  int _selectedTab = 0; // 0 = Aturan, 1 = Riwayat

  final _rules = [
    _KomisiRule(name: 'Komisi Standar', rate: '8%', range: '≤ Rp500Rb', isActive: true, isPercent: true),
    _KomisiRule(name: 'Komisi Menengah', rate: '7%', range: 'Rp500Rb – Rp2.0Jt', isActive: true, isPercent: true),
    _KomisiRule(name: 'Komisi Premium', rate: '6%', range: 'Rp2.0Jt – tidak terbatas', isActive: true, isPercent: true),
    _KomisiRule(name: 'Komisi Flat Mini', rate: 'Rp5Rb', range: '≤ Rp50Rb', isActive: false, isPercent: false),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const BengkelAppBar(subtitle: 'Manajemen Komisi'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Responsive.isWeb(context)
            ? _buildWebLayout()
            : _buildMobileLayout(),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 14),
        _buildSummaryCards(),
        const SizedBox(height: 14),
        _buildInfoBanner(),
        const SizedBox(height: 14),
        _buildTabToggle(),
        const SizedBox(height: 14),
        ..._rules.map((r) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _KomisiCard(rule: r),
        )),
      ],
    );
  }

  Widget _buildWebLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _buildSummaryCards()),
          ],
        ),
        const SizedBox(height: 14),
        _buildInfoBanner(),
        const SizedBox(height: 14),
        _buildTabToggle(),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 2.5,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: _rules.map((r) => _KomisiCard(rule: r)).toList(),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text('Manajemen Komisi', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        SizedBox(height: 2),
        Text('Atur parameter komisi otomatis per transaksi',
            style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
      ],
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.trending_up_rounded, color: AppColors.primary, size: 18),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('7.0%', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    Text('Rata-rata', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.secondaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.attach_money_rounded, color: AppColors.secondary, size: 20),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Rp48,3Jt', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    Text('Bulan Ini', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Komisi dihitung otomatis saat transaksi selesai berdasarkan nilai dan rentang yang berlaku.',
              style: TextStyle(fontSize: 12, color: Color(0xFF1E40AF)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabToggle() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _RuleTabBtn(
            label: 'Aturan Komisi',
            isSelected: _selectedTab == 0,
            onTap: () => setState(() => _selectedTab = 0),
          ),
          _RuleTabBtn(
            label: 'Riwayat',
            isSelected: _selectedTab == 1,
            onTap: () => setState(() => _selectedTab = 1),
          ),
        ],
      ),
    );
  }
}

class _RuleTabBtn extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _RuleTabBtn({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.textPrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _KomisiRule {
  final String name, rate, range;
  final bool isActive, isPercent;
  _KomisiRule({required this.name, required this.rate, required this.range, required this.isActive, required this.isPercent});
}

class _KomisiCard extends StatelessWidget {
  final _KomisiRule rule;
  const _KomisiCard({required this.rule});

  @override
  Widget build(BuildContext context) {
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
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: rule.isActive ? AppColors.secondary : AppColors.textMuted,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(rule.name,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: rule.isActive ? AppColors.secondaryLight : AppColors.background,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  rule.isActive ? 'Aktif' : 'Nonaktif',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: rule.isActive ? AppColors.secondary : AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            rule.rate,
            style: TextStyle(
              fontSize: rule.isPercent ? 28 : 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          Text(rule.range, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text('Edit', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down_rounded, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}