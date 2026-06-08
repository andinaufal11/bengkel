import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bengkel/core/constants/app_colors.dart';
import 'package:bengkel/features/mechanic/models/mechanic_model.dart';
import 'package:bengkel/features/mechanic/repository/mechanic_repository.dart';
import 'package:bengkel/features/mechanic/widgets/status_toggle.dart';
import 'package:bengkel/features/mechanic/widgets/task_card.dart';
import 'package:bengkel/features/mechanic/models/task_model.dart';
import 'package:bengkel/features/auth/screens/login_screen.dart';
// Import file Bottom Sheet Riwayat yang baru dibuat
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
  bool _isLoading = false;
  String _currentStatus = 'Available';
  int _currentIndex = 0;
  late final String _mechanicUserId;
  MechanicModel? _mechanicProfile;
  bool _isProfileLoading = true;

  // 1. DATA DUMMY TUGAS AKTIF & BARU (Versi Asli)
// 1. DATA DUMMY TUGAS AKTIF & BARU (Diperbarui dengan Waktu & Layanan)
  final List<TaskModel> _dummyTasks = [
    TaskModel(id: 'task_001', customerId: 'user_budi', status: 'Accepted', isSos: false, serviceName: 'Ganti Oli Mesin', date: 'Senin, 08 Juni 2026', time: '10:00 WIB'),
    TaskModel(id: 'task_002', customerId: 'user_andi', status: 'Pending', isSos: true, serviceName: 'Mogok & Pengecekan Aki', date: 'Senin, 08 Juni 2026', time: '11:00 WIB'),
    TaskModel(id: 'task_003', customerId: 'user_siti', status: 'Pending', isSos: false, serviceName: 'Service Ringan Matic', date: 'Selasa, 09 Juni 2026', time: '14:00 WIB'),
    TaskModel(id: 'task_004', customerId: 'user_rinto', status: 'Pending', isSos: true, serviceName: 'Tambal Ban Darurat', date: 'Senin, 08 Juni 2026', time: '10:30 WIB'),
  ];

  // 2. DATA DUMMY RIWAYAT TUGAS (Diperkaya untuk Poin 1)
  final List<Map<String, dynamic>> _completedTasksHistory = [
    {
      'id': 'task_old_1',
      'service': 'Ganti Aki GS Astra',
      'customer': 'Hendra Wijaya',
      'date': '05 Juni 2026',
      'time': '10:30 WIB',
      'income': 'Rp 150.000',
      'vehicle': 'Honda Vario 150 (B 4321 SFF)',
      'status': 'Completed',
      'address': 'Jl. Kemang Raya No. 12, Jakarta Selatan',
      'note': 'Ganti aki lancar, tegangan alternator normal 14.2V.',
    },
    {
      'id': 'task_old_2',
      'service': 'Tambal Ban Tubeless (SOS)',
      'customer': 'Rina Amelia',
      'date': '04 Juni 2026',
      'time': '21:15 WIB',
      'income': 'Rp 80.000',
      'vehicle': 'Yamaha NMAX (B 6789 KLS)',
      'status': 'Completed',
      'address': 'Pinggir Jalan Tol Dalam Kota Km 14',
      'note': 'Ban belakang terkena paku payung besar, sukses ditambal dua titik.',
    },
    {
      'id': 'task_old_3',
      'service': 'Service Ringan + Tune Up',
      'customer': 'Dedi Kurniawan',
      'date': '02 Juni 2026',
      'time': '14:00 WIB',
      'income': 'Rp 0 (Ditolak)',
      'vehicle': 'Toyota Avanza (B 1122 VCC)',
      'status': 'Rejected',
      'address': 'Gedung Cyber 1 Lt. 3, Kuningan',
      'reason': 'Peralatan kompresor portable mekanik sedang rusak ringan.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _mechanicUserId = widget.mechanicUserId ?? Supabase.instance.client.auth.currentUser?.id ?? '';
    _loadMechanicProfile();
  }

  Future<void> _loadMechanicProfile() async {
    if (_mechanicUserId.isEmpty) {
      if (mounted) setState(() => _isProfileLoading = false);
      return;
    }
    try {
      final mechanic = await _repository.getMechanicByUserId(_mechanicUserId);
      if (!mounted) return;
      setState(() {
        _mechanicProfile = mechanic;
        if (mechanic != null) _currentStatus = mechanic.operationalStatus;
        _isProfileLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isProfileLoading = false);
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
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

  void _acceptPendingTask(String taskId) {
    setState(() {
      final taskIndex = _dummyTasks.indexWhere((task) => task.id == taskId);
      if (taskIndex != -1) {
        _dummyTasks[taskIndex] = TaskModel(
          id: _dummyTasks[taskIndex].id,
          customerId: _dummyTasks[taskIndex].customerId,
          status: 'Accepted',
          isSos: _dummyTasks[taskIndex].isSos,
        );
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tugas berhasil diterima dan masuk ke Dashboard!'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _showRejectDialog(String taskId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tolak Tugas', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Masukkan alasan penolakan tugas ini:', style: TextStyle(fontSize: 13, color: AppColors.textGrey)),
            const SizedBox(height: 12),
            TextField(
              controller: _reasonController,
              decoration: InputDecoration(
                hintText: 'Contoh: Ban bocor, peralatan kurang...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: AppColors.textGrey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              if (_reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Alasan wajib diisi!'), backgroundColor: AppColors.error),
                );
                return;
              }
              Navigator.pop(context);
              _executeRejection(taskId);
            },
            child: const Text('Kirim & Tolak', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _executeRejection(String taskId) {
    setState(() {
      _dummyTasks.removeWhere((task) => task.id == taskId);
    });
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.alt_route, color: Colors.orange, size: 40),
        title: const Text('Tugas Dialihkan'),
        content: Text('Alasan dicatat: "${_reasonController.text}". Tugas ID $taskId sukses dialihkan ke mekanik terdekat kedua.'),
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

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      _buildDashboardContent(),
      _buildTaskListContent(),
      _buildHistoryListContent(), 
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ==========================================
  // INDEX 0: DASHBOARD CONTENT
  // ==========================================
  Widget _buildDashboardContent() {
    return SafeArea(
      child: SingleChildScrollView(
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
            const SizedBox(height: 24),
            _buildTargetProgress(),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTaskCard() {
    try {
      final activeTask = _dummyTasks.firstWhere((task) => task.status == 'Accepted');
      return TaskCard(task: activeTask);
    } catch (_) {
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
  }

  // ==========================================
  // INDEX 1: HALAMAN DAFTAR TUGAS
  // ==========================================
// ==========================================
  // INDEX 1: HALAMAN DAFTAR TUGAS (POIN 2: TAMBAH WAKTU & SOS TETAP DI ATAS)
  // ==========================================
  Widget _buildTaskListContent() {
    List<TaskModel> sortedTasks = List.from(_dummyTasks);
    // SOS Prioritas Atas
    sortedTasks.sort((a, b) => (b.isSos ? 1 : 0).compareTo(a.isSos ? 1 : 0));

    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text(
            'Daftar Tugas Masuk',
            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
          elevation: 0,
          automaticallyImplyLeading: false,
        ),
        body: sortedTasks.isEmpty
            ? const Center(
                child: Text('Belum ada tugas baru untuk Anda.', style: TextStyle(color: AppColors.textGrey)),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: sortedTasks.length,
                itemBuilder: (context, index) {
                  final task = sortedTasks[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: task.isSos ? AppColors.error.withOpacity(0.02) : AppColors.cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: task.isSos ? AppColors.error : AppColors.border,
                        width: task.isSos ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // HEADER LABEL & JARAK
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: task.isSos ? AppColors.error : AppColors.secondary,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                task.isSos ? '⚠️ EMERGENCY SOS' : '🔧 HOME SERVICE',
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Text(
                              task.isSos ? 'Jarak: 1.2 Km (Terdekat)' : 'Jarak: 4.5 Km',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textGrey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        // NAMA LAYANAN
                        Text(
                          task.serviceName, // Diambil dinamis dari model
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),

                        // DESAIN BARU: HARI, TANGGAL & JAM BOOKING
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 14, color: AppColors.textGrey),
                            const SizedBox(width: 6),
                            Text(
                              task.date,
                              style: const TextStyle(fontSize: 12, color: AppColors.textGrey, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(width: 16),
                            const Icon(Icons.access_time, size: 14, color: AppColors.textGrey),
                            const SizedBox(width: 6),
                            Text(
                              task.time,
                              style: const TextStyle(fontSize: 12, color: AppColors.textGrey, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),
                        
                        // TOMBOL AKSI
                        if (task.status == 'Pending')
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: AppColors.error),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onPressed: () => _showRejectDialog(task.id),
                                  child: const Text('Tolak', style: TextStyle(color: AppColors.error)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: task.isSos ? AppColors.error : AppColors.success,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onPressed: () => _acceptPendingTask(task.id),
                                  child: const Text('Terima & Kerjakan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          )
                        else
                          Row(
                            children: const [
                              Icon(Icons.directions_run, color: AppColors.success, size: 16),
                              SizedBox(width: 4),
                              Text('Tugas ini sedang berjalan di halaman utama', style: TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  // ==========================================
  // INDEX 2: HALAMAN RIWAYAT TUGAS (DIUBAH UNTUK POIN 1)
  // ==========================================
  Widget _buildHistoryListContent() {
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text(
            'Riwayat Tugas Selesai',
            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
          elevation: 0,
          automaticallyImplyLeading: false,
        ),
        body: ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: _completedTasksHistory.length,
          itemBuilder: (context, index) {
            final history = _completedTasksHistory[index];
            final isRejected = history['status'] == 'Rejected';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _showHistoryDetailBottomSheet(history),
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
                              Text(history['service']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              const SizedBox(height: 4),
                              Text('Pelanggan: ${history['customer']}', style: const TextStyle(color: AppColors.textGrey, fontSize: 13)),
                              Text('Waktu: ${history['date']} (${history['time']})', style: const TextStyle(color: AppColors.textGrey, fontSize: 11)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isRejected ? AppColors.error.withOpacity(0.1) : AppColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            history['income']!,
                            style: TextStyle(fontWeight: FontWeight.bold, color: isRejected ? AppColors.error : AppColors.success, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // FUNGSI MEMANGGIL FILE BOTTOM SHEET KUSTOM
  void _showHistoryDetailBottomSheet(Map<String, dynamic> historyData) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return HistoryDetailBottomSheet(data: historyData);
      },
    );
  }

  // ==========================================
  // WIDGETS DASHBOARD TETAP
  // ==========================================
  Widget _buildHeader() {
    final displayName = _mechanicProfile?.fullName ?? 'Mekanik';
    final avatarLetter = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'M';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.secondary,
              child: Text(avatarLetter, style: const TextStyle(color: Colors.white)),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 8,
                      color: _currentStatus == 'Available' ? AppColors.success : _currentStatus == 'On-Duty' ? Colors.orange : AppColors.error,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _currentStatus == 'Available' ? 'Tersedia' : _currentStatus == 'On-Duty' ? 'Bertugas' : 'Offline',
                      style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
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
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            } catch (e) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal keluar: $e')));
            }
          },
        ),
      ],
    );
  }

  Widget _buildStatusCard() {
    Color cardColor = _currentStatus == 'Available' ? AppColors.success : _currentStatus == 'On-Duty' ? Colors.orange : AppColors.error;
    String statusTitle = _currentStatus == 'Available' ? 'Tersedia' : _currentStatus == 'On-Duty' ? 'Bertugas' : 'Offline';
    String statusSubtitle = _currentStatus == 'Available' ? 'Siap menerima tugas' : _currentStatus == 'On-Duty' ? 'Sedang mengerjakan servis' : 'Tidak menerima tugas';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Status Saya', style: TextStyle(color: Colors.white)),
          Text(statusTitle, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
          Text(statusSubtitle, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildStatusToggle() => StatusToggle(
        currentStatus: _currentStatus,
        isLoading: _isLoading,
        onStatusChanged: (newStatus) => _changeStatus(newStatus),
      );

  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 2.5,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      children: [
        _statItem('6', 'Selesai Hari Ini', Icons.check_circle_outline),
        _statItem('4.9', 'Rating', Icons.star_border),
        _statItem('287', 'Total Servis', Icons.build),
        _statItem('480k', 'Pendapatan', Icons.show_chart),
      ],
    );
  }

  Widget _statItem(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, color: AppColors.secondary),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textGrey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTargetProgress() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text('Target Hari Ini', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Rp 480k / Rp 600k', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: const LinearProgressIndicator(value: 0.8, backgroundColor: AppColors.border, color: AppColors.secondary, minHeight: 8),
        ),
        const SizedBox(height: 8),
        const Text('80% dari target harian tercapai 🎉', style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
      ],
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) => setState(() => _currentIndex = index),
      selectedItemColor: AppColors.secondary,
      unselectedItemColor: AppColors.textGrey,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
        BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Tugas'),
        BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Riwayat'),
      ],
    );
  }
}