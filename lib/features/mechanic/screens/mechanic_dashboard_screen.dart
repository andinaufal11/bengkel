import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bengkel/core/constants/app_colors.dart';
import 'package:bengkel/features/mechanic/models/mechanic_model.dart';
import 'package:bengkel/features/mechanic/repository/mechanic_repository.dart';
import 'package:bengkel/features/mechanic/widgets/status_toggle.dart';
import 'package:bengkel/features/mechanic/widgets/task_card.dart';
import 'package:bengkel/features/mechanic/models/task_model.dart';
import 'package:bengkel/features/auth/screens/login_screen.dart';
import 'package:bengkel/features/mechanic/widgets/history_detail_bottom_sheet.dart';

class MechanicDashboardScreen extends StatefulWidget {
  final String? mechanicUserId;

  const MechanicDashboardScreen({super.key, this.mechanicUserId});

  @override
  State<MechanicDashboardScreen> createState() =>
      _MechanicDashboardScreenState();
}

class _MechanicDashboardScreenState extends State<MechanicDashboardScreen> {
  final MechanicRepository _repository = MechanicRepository();
  final TextEditingController _reasonController = TextEditingController();

  RealtimeChannel? _taskChannel;

  bool _isLoading = false;
  String _currentStatus = 'Available';
  int _currentIndex = 0;
  late final String _mechanicUserId;
  MechanicModel? _mechanicProfile;

  List<TaskModel> _activeTasks = [];
  List<TaskModel> _historyTasks = [];
  bool _isTasksLoading = true;

  Map<String, dynamic> _stats = {
    'completedMonthly': 0,
    'averageRating': 0.0,
    'totalServices': 0,
  };

  @override
  void initState() {
    super.initState();
    _mechanicUserId =
        widget.mechanicUserId ??
        Supabase.instance.client.auth.currentUser?.id ??
        '';
    _loadMechanicProfile();
    _fetchTasks();
    _loadStats();
    _subscribeToTaskUpdates();
  }

  // ==========================================
  // FUNGSI PENGAMBILAN DATA (API / SUPABASE)
  // ==========================================

  Future<void> _loadMechanicProfile() async {
    if (_mechanicUserId.isEmpty) return;
    try {
      final mechanic = await _repository.getMechanicByUserId(_mechanicUserId);
      if (!mounted) return;
      setState(() {
        _mechanicProfile = mechanic;
        if (mechanic != null) _currentStatus = mechanic.operationalStatus;
      });
    } catch (_) {
      // profile gagal dimuat, biarkan null
    }
  }

  Future<void> _changeStatus(String newStatus) async {
    if (_currentStatus == newStatus) return;
    setState(() => _isLoading = true);
    try {
      await _repository.updateOperationalStatus(_mechanicUserId, newStatus);
      setState(() => _currentStatus = newStatus);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchTasks() async {
    setState(() => _isTasksLoading = true);
    try {
      final active = await _repository.getDashboardTasks(_mechanicUserId);
      final history = await _repository.getHistoryTasks(_mechanicUserId);
      if (mounted) {
        setState(() {
          _activeTasks = active;
          _historyTasks = history;
          _isTasksLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isTasksLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat tugas: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _loadStats() async {
    try {
      final statsData = await _repository.getMechanicStats(_mechanicUserId);
      if (mounted) setState(() => _stats = statsData);
    } catch (e) {
      debugPrint('Gagal memuat statistik: $e');
    }
  }

  Future<void> _refreshAll() async {
    await Future.wait([_loadMechanicProfile(), _fetchTasks(), _loadStats()]);
  }

  void _subscribeToTaskUpdates() {
    _taskChannel = Supabase.instance.client
        .channel('mechanic-tasks-$_mechanicUserId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'home_service_tasks',
          callback: (_) => _fetchTasks(),
        )
        .subscribe();
  }

  Future<void> _acceptPendingTask(String taskId) async {
    setState(() => _isLoading = true);
    try {
      await _repository.acceptTask(taskId, _mechanicUserId);
      await _fetchTasks();
      setState(() => _currentIndex = 0);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tugas berhasil diterima dan masuk ke Dashboard!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menerima tugas: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ==========================================
  // WIDGET DAN UI
  // ==========================================

  void _showRejectDialog(String taskId) {
    _reasonController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tolak Tugas',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Masukkan alasan penolakan tugas ini:',
              style: TextStyle(fontSize: 13, color: AppColors.textGrey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reasonController,
              decoration: InputDecoration(
                hintText: 'Contoh: Ban bocor, peralatan kurang...',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal',
                style: TextStyle(color: AppColors.textGrey)),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              if (_reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Alasan wajib diisi!'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }
              Navigator.pop(context);
              _executeRejection(taskId);
            },
            child: const Text('Kirim & Tolak',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _executeRejection(String taskId) async {
    setState(() => _isLoading = true);
    try {
      await _repository.rejectTask(taskId, _reasonController.text.trim());
      await _fetchTasks();
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            icon: const Icon(Icons.alt_route, color: Colors.orange, size: 40),
            title: const Text('Tugas Dialihkan'),
            content: Text(
              'Alasan dicatat: "${_reasonController.text}". Tugas telah ditolak dan dialihkan ke mekanik lain.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _reasonController.clear();
                  Navigator.pop(context);
                },
                child: const Text('Oke'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menolak tugas: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _taskChannel?.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildDashboardContent(),
          _buildTaskListContent(),
          _buildHistoryListContent(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ==========================================
  // INDEX 0: DASHBOARD CONTENT
  // ==========================================
  Widget _buildDashboardContent() {
    return RefreshIndicator(
      color: AppColors.secondary,
      onRefresh: _refreshAll,
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildStatusCard(),
              const SizedBox(height: 16),
              _buildStatusToggle(),
              const SizedBox(height: 24),
              _buildStatsGrid(),
              const SizedBox(height: 24),
              const Text(
                'TUGAS BERLANGSUNG',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.textGrey,
                ),
              ),
              const SizedBox(height: 8),
              _buildActiveTaskCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTaskCard() {
    if (_isTasksLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final TaskModel? activeTask = _activeTasks
        .cast<TaskModel?>()
        .firstWhere((t) => t?.status == 'Accepted', orElse: () => null);

    if (activeTask == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: Text(
            'Tidak ada tugas aktif berjalan.',
            style: TextStyle(color: AppColors.textGrey, fontSize: 13),
          ),
        ),
      );
    }

    return TaskCard(task: activeTask);
  }

  // ==========================================
  // INDEX 1: HALAMAN DAFTAR TUGAS
  // ==========================================
  Widget _buildTaskListContent() {
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Daftar Tugas Masuk',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: AppColors.textDark)),
          elevation: 0,
          automaticallyImplyLeading: false,
        ),
        body: RefreshIndicator(
          color: AppColors.secondary,
          onRefresh: _refreshAll,
          child: _buildTaskListBody(),
        ),
      ),
    );
  }

  Widget _buildTaskListBody() {
    if (_isTasksLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final sortedTasks = List<TaskModel>.from(_activeTasks)
      ..sort((a, b) => (b.isSos ? 1 : 0).compareTo(a.isSos ? 1 : 0));

    if (sortedTasks.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: _buildEmptyState(
            message: 'Belum ada tugas baru\nuntuk Anda saat ini.',
            icon: Icons.inbox_outlined,
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      itemCount: sortedTasks.length,
      itemBuilder: (context, index) {
        final task = sortedTasks[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: task.isSos
                ? AppColors.error.withOpacity(0.02)
                : AppColors.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: task.isSos ? AppColors.error : AppColors.border,
              width: task.isSos ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: task.isSos
                          ? AppColors.error
                          : AppColors.secondary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      task.isSos ? '⚠️ EMERGENCY SOS' : '🔧 HOME SERVICE',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  // Jarak akan diambil dari data real (task.distance) setelah
                  // field tersedia dari repository
                  const Text(
                    'Jarak: -',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textGrey),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(task.serviceName,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 14, color: AppColors.textGrey),
                  const SizedBox(width: 6),
                  Text(task.date,
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textGrey,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(width: 16),
                  const Icon(Icons.access_time,
                      size: 14, color: AppColors.textGrey),
                  const SizedBox(width: 6),
                  Text(task.time,
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textGrey,
                          fontWeight: FontWeight.w500)),
                ],
              ),
              const SizedBox(height: 16),
              if (task.status == 'Pending')
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.error),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => _showRejectDialog(task.id),
                        child: const Text('Tolak',
                            style: TextStyle(color: AppColors.error)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: task.isSos
                              ? AppColors.error
                              : AppColors.success,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => _acceptPendingTask(task.id),
                        child: const Text('Terima & Kerjakan',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                )
              else
                const Row(
                  children: [
                    Icon(Icons.directions_run,
                        color: AppColors.success, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Tugas ini sedang berjalan di halaman utama',
                      style: TextStyle(
                          color: AppColors.success,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // INDEX 2: HALAMAN RIWAYAT TUGAS
  // ==========================================
  Widget _buildHistoryListContent() {
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Riwayat Tugas Selesai',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: AppColors.textDark)),
          elevation: 0,
          automaticallyImplyLeading: false,
        ),
        body: RefreshIndicator(
          color: AppColors.secondary,
          onRefresh: _refreshAll,
          child: _buildHistoryListBody(),
        ),
      ),
    );
  }

  Widget _buildHistoryListBody() {
    if (_isTasksLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_historyTasks.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: _buildEmptyState(
            message: 'Belum ada riwayat tugas.\nSelesaikan tugasmu pertama!',
            icon: Icons.history_toggle_off,
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      itemCount: _historyTasks.length,
      itemBuilder: (context, index) {
        final task = _historyTasks[index];
        final isRejected = task.status == 'Rejected';

        final String incomeDisplay = isRejected
            ? 'Rp 0'
            : (task.income != null && task.income! > 0)
                ? 'Rp ${task.income!.toStringAsFixed(0)}'
                : 'Rp ---';

        final Map<String, dynamic> mappedHistoryData = {
          'id': task.id,
          'service': task.serviceName,
          'customer': task.customerName,
          'date': task.date,
          'time': task.time,
          'income': incomeDisplay,
          'vehicle': task.vehicleInfo ?? 'Data kendaraan belum tersedia',
          'status': task.status,
          'address': task.address,
        };

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _showHistoryDetailBottomSheet(mappedHistoryData),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(task.serviceName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 4),
                          Text('Pelanggan: ${task.customerName}',
                              style: const TextStyle(
                                  color: AppColors.textGrey, fontSize: 13)),
                          Text('Waktu: ${task.date} (${task.time})',
                              style: const TextStyle(
                                  color: AppColors.textGrey, fontSize: 11)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isRejected
                            ? AppColors.error.withOpacity(0.1)
                            : AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        incomeDisplay,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isRejected
                              ? AppColors.error
                              : AppColors.success,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showHistoryDetailBottomSheet(Map<String, dynamic> historyData) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => HistoryDetailBottomSheet(data: historyData),
    );
  }

  // ==========================================
  // WIDGETS DASHBOARD TETAP
  // ==========================================
  Widget _buildHeader() {
    final displayName = _mechanicProfile?.fullName ?? 'Mekanik';
    final avatarLetter =
        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'M';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.secondary,
              child:
                  Text(avatarLetter, style: const TextStyle(color: Colors.white)),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(displayName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 8,
                      color: _currentStatus == 'Available'
                          ? AppColors.success
                          : _currentStatus == 'On-Duty'
                              ? Colors.orange
                              : AppColors.error,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _currentStatus == 'Available'
                          ? 'Tersedia'
                          : _currentStatus == 'On-Duty'
                              ? 'Bertugas'
                              : 'Offline',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textGrey),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.logout, color: AppColors.error),
          onPressed: () async {
            try {
              await Supabase.instance.client.auth.signOut();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            } catch (e) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text('Gagal keluar: $e')));
            }
          },
        ),
      ],
    );
  }

  Widget _buildStatusCard() {
    final cardColor = _currentStatus == 'Available'
        ? AppColors.success
        : _currentStatus == 'On-Duty'
            ? Colors.orange
            : AppColors.error;
    final statusTitle = _currentStatus == 'Available'
        ? 'Tersedia'
        : _currentStatus == 'On-Duty'
            ? 'Bertugas'
            : 'Offline';
    final statusSubtitle = _currentStatus == 'Available'
        ? 'Siap menerima tugas'
        : _currentStatus == 'On-Duty'
            ? 'Sedang mengerjakan servis'
            : 'Tidak menerima tugas';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: cardColor, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Status Saya', style: TextStyle(color: Colors.white)),
          Text(statusTitle,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold)),
          Text(statusSubtitle,
              style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildStatusToggle() => StatusToggle(
        currentStatus: _currentStatus,
        isLoading: _isLoading,
        onStatusChanged: _changeStatus,
      );

  Widget _buildStatsGrid() {
    final rating = _stats['averageRating'] != null
        ? (_stats['averageRating'] as num).toDouble()
        : 0.0;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      childAspectRatio: 1.6,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      children: [
        _statItem(_stats['completedMonthly'].toString(), 'Selesai Bulan Ini',
            Icons.check_circle_outline),
        _statItem(rating.toStringAsFixed(1), 'Rating', Icons.star_border),
        _statItem(
            _stats['totalServices'].toString(), 'Total Servis', Icons.build),
      ],
    );
  }

  Widget _statItem(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.secondary, size: 18),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13)),
          Text(label,
              style:
                  const TextStyle(fontSize: 9, color: AppColors.textGrey),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
      {required String message, required IconData icon}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppColors.border),
          const SizedBox(height: 16),
          Text(message,
              style:
                  const TextStyle(color: AppColors.textGrey, fontSize: 14),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    final pendingCount =
        _activeTasks.where((t) => t.status == 'Pending').length;

    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) => setState(() => _currentIndex = index),
      selectedItemColor: AppColors.secondary,
      unselectedItemColor: AppColors.textGrey,
      items: [
        const BottomNavigationBarItem(
            icon: Icon(Icons.dashboard), label: 'Dashboard'),
        BottomNavigationBarItem(
          icon: Badge(
            isLabelVisible: pendingCount > 0,
            label: Text('$pendingCount'),
            child: const Icon(Icons.list_alt),
          ),
          label: 'Tugas',
        ),
        const BottomNavigationBarItem(
            icon: Icon(Icons.history), label: 'Riwayat'),
      ],
    );
  }
}