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

    if (response == null) {
      return null;
    }

    return MechanicModel.fromJson(response);
  }

  // FR-MKN-02: Update Status (Available, On-Duty, Offline)
  Future<void> updateOperationalStatus(String userId, String status) async {
    await _supabase
        .from('mechanics')
        .update({'operational_status': status})
        .eq('user_id', userId);
  }

  // FR-MKN-03: Ambil Tugas Home Service yang statusnya 'Pending'
  Future<List<TaskModel>> getActiveTasks(String mechanicId) async {
    final response = await _supabase
        .from('home_service_tasks')
        .select()
        .eq('mechanic_id', mechanicId)
        .neq('status', 'Completed'); // Ambil tugas yang belum selesai

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

    // Update status tugas menjadi 'Completed'
    await _supabase
        .from('home_service_tasks')
        .update({'status': 'Completed'})
        .eq('id', taskId);
  }
}
