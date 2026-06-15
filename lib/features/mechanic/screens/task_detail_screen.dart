import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bengkel/core/constants/app_colors.dart';
import 'package:bengkel/features/mechanic/models/task_model.dart';
import 'package:bengkel/features/mechanic/repository/mechanic_repository.dart';
import 'package:bengkel/features/mechanic/screens/live_tracking_screen.dart';

class TaskDetailScreen extends StatefulWidget {
  final TaskModel task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final MechanicRepository _repository = MechanicRepository();
  bool _isAccepted = false;
  bool _isLoading = false;
  late final RealtimeChannel _detailChannel;
  late TaskModel _currentTask;

  @override
  void initState() {
    super.initState();
    _currentTask = widget.task;
    _isAccepted =
        widget.task.status == 'Accepted' || widget.task.status == 'On-the-way';
    _subscribeToThisTask();
  }

  Future<void> _acceptTask() async {
    setState(() => _isLoading = true);
    try {
      final mechanicId = Supabase.instance.client.auth.currentUser?.id;
      if (mechanicId != null) {
        await _repository.acceptTask(_currentTask.id, mechanicId);
        if (mounted) {
          setState(() => _isAccepted = true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tugas berhasil diterima!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
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

  void _startJourney() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LiveTrackingScreen(task: _currentTask),
      ),
    );
  }

  void _subscribeToThisTask() {
    _detailChannel = Supabase.instance.client
        .channel('task-detail-${_currentTask.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'home_service_tasks',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: _currentTask.id,
          ),
          callback: (payload) {
            if (mounted) {
              final newStatus = payload.newRecord['status'] as String?;
              setState(() {
                _isAccepted =
                    newStatus == 'Accepted' || newStatus == 'On-the-way';
              });
            }
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _detailChannel.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Detail Tugas',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        color: AppColors.secondary,
        onRefresh: () async {
          try {
            final updatedTask = await _repository.getTaskById(_currentTask.id);
            if (mounted && updatedTask != null) {
              setState(() {
                _currentTask = updatedTask;
                _isAccepted =
                    updatedTask.status == 'Accepted' ||
                    updatedTask.status == 'On-the-way';
              });
            }
          } catch (e) {
            debugPrint('Gagal refresh: $e');
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Informasi Pelanggan ──────────────────────────────────
              const Text(
                'Informasi Pelanggan',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textGrey,
                ),
              ),
              const SizedBox(height: 8),
              _buildInfoCard(
                title: _currentTask.customerName,
                subtitle: _currentTask.address,
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 20),

              // ── Informasi Kendaraan ──────────────────────────────────
              if (_currentTask.vehicleInfo != null &&
                  _currentTask.vehicleInfo!.isNotEmpty) ...[
                const Text(
                  'Informasi Kendaraan',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textGrey,
                  ),
                ),
                const SizedBox(height: 8),
                _buildInfoCard(
                  title: _currentTask.vehicleInfo!,
                  subtitle: 'Kendaraan yang akan diservis',
                  icon: Icons.directions_car_outlined,
                ),
                const SizedBox(height: 20),
              ],

              // ── Detail Servis ────────────────────────────────────────
              const Text(
                'Detail Servis',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textGrey,
                ),
              ),
              const SizedBox(height: 8),
              _buildInfoCard(
                // FIX: serviceName (bukan serviceType — field itu tidak ada di model)
                title: _currentTask.serviceName,
                // FIX: notes nullable — tampilkan teks default jika kosong
                subtitle: (_currentTask.notes != null &&
                        _currentTask.notes!.isNotEmpty)
                    ? _currentTask.notes!
                    : 'Tidak ada catatan tambahan',
                icon: Icons.build_outlined,
              ),
              const SizedBox(height: 20),

              // ── Jadwal ───────────────────────────────────────────────
              const Text(
                'Jadwal',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textGrey,
                ),
              ),
              const SizedBox(height: 8),
              _buildInfoCard(
                title: '${_currentTask.date}  •  ${_currentTask.time}',
                subtitle: 'Waktu servis yang dijadwalkan',
                icon: Icons.calendar_today_outlined,
              ),
              const SizedBox(height: 20),

              // ── Status Badge ─────────────────────────────────────────
              Row(
                children: [
                  const Text(
                    'Status: ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textGrey,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _isAccepted
                          ? AppColors.success.withOpacity(0.1)
                          : AppColors.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _currentTask.status,
                      style: TextStyle(
                        color: _isAccepted
                            ? AppColors.success
                            : AppColors.secondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: _isAccepted
            ? ElevatedButton(
                onPressed: _startJourney,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Mulai Perjalanan (Live Tracking)',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              )
            : Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _isLoading ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: AppColors.error),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Tolak',
                        style: TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _acceptTask,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Terima Tugas',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.secondary, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}