import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bengkel/features/mechanic/models/mechanic_model.dart';
import 'package:bengkel/features/mechanic/models/task_model.dart';

class MechanicRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<MechanicModel?> getMechanicByUserId(String userId) async {
    final response = await _supabase
        .from('mechanics')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) return null;
    return MechanicModel.fromJson(response);
  }

  // FR-MKN-02: Update Status (Available, On-Duty, Offline)
  Future<void> updateOperationalStatus(String userId, String status) async {
    await _supabase
        .from('mechanics')
        .update({'operational_status': status}).eq('user_id', userId);
  }

  // FR-MKN-03: Ambil Tugas Home Service yang belum selesai
  Future<List<TaskModel>> getActiveTasks(String mechanicId) async {
    final response = await _supabase
        .from('home_service_tasks')
        .select()
        .eq('mechanic_id', mechanicId)
        .neq('status', 'Completed');

    final List<dynamic> data = response;
    return data.map((json) => TaskModel.fromJson(json)).toList();
  }

  // FR-MKN-06: Submit Laporan Servis
  Future<void> submitServiceReport({
    required String taskId,
    required String mechanicId,
    required String description,
    String? photoUrl,
  }) async {
    await _supabase.from('service_reports').insert({
      'task_id': taskId,
      'mechanic_id': mechanicId,
      'description': description,
      'photo_url': photoUrl,
    });

    await _supabase
        .from('home_service_tasks')
        .update({'status': 'Completed'}).eq('id', taskId);
  }

  // Menerima Tugas
  Future<void> acceptTask(String taskId, String mechanicId) async {
    await _supabase.from('home_service_tasks').update({
      'status': 'Accepted',
      'mechanic_id': mechanicId,
    }).eq('id', taskId);
  }

  // FIX: Menolak Tugas — update status ke 'Rejected' dan simpan alasan
  // Pastikan kolom 'rejection_reason' sudah ada di tabel home_service_tasks kamu.
  // Jika belum, jalankan migration ini di Supabase SQL Editor:
  //   ALTER TABLE home_service_tasks ADD COLUMN rejection_reason TEXT;
  Future<void> rejectTask(String taskId, String reason) async {
    await _supabase.from('home_service_tasks').update({
      'status': 'Rejected',
      'rejection_reason': reason,
    }).eq('id', taskId);
  }

  // Mengambil SEMUA tugas: Pending (baru masuk) dan Accepted (sedang dikerjakan)
  Future<List<TaskModel>> getDashboardTasks(String mechanicId) async {
    final response = await _supabase
        .from('home_service_tasks')
        .select()
        .or('status.eq.Pending,and(status.eq.Accepted,mechanic_id.eq.$mechanicId)');

    final List<dynamic> data = response;
    return data.map((json) => TaskModel.fromJson(json)).toList();
  }

  // Mengambil Riwayat Tugas (Selesai / Ditolak)
  Future<List<TaskModel>> getHistoryTasks(String mechanicId) async {
    final response = await _supabase
        .from('home_service_tasks')
        .select()
        .eq('mechanic_id', mechanicId)
        .inFilter('status', ['Completed', 'Rejected']);

    final List<dynamic> data = response;
    return data.map((json) => TaskModel.fromJson(json)).toList();
  }

  // Mengambil statistik berdasarkan data real
  Future<Map<String, dynamic>> getMechanicStats(String mechanicId) async {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1).toIso8601String();

    final response = await _supabase
        .from('home_service_tasks')
        .select('id, rating, created_at')
        .eq('mechanic_id', mechanicId)
        .eq('status', 'Completed');

    final List<dynamic> data = response;

    int completedMonthly = 0;
    double totalRating = 0;
    int ratedTasksCount = 0;

    for (var task in data) {
      DateTime createdAt = DateTime.parse(task['created_at']);

      if (createdAt.isAfter(DateTime.parse(firstDayOfMonth))) {
        completedMonthly++;
      }

      if (task['rating'] != null) {
        totalRating += (task['rating'] as num).toDouble();
        ratedTasksCount++;
      }
    }

    return {
      'completedMonthly': completedMonthly,
      'averageRating':
          ratedTasksCount > 0 ? (totalRating / ratedTasksCount) : 0.0,
      'totalServices': data.length,
    };
  }

  Future<TaskModel?> getTaskById(String taskId) async {
    final response = await _supabase
        .from('home_service_tasks')
        .select()
        .eq('id', taskId)
        .maybeSingle();

    if (response == null) return null;
    return TaskModel.fromJson(response);
  }
}