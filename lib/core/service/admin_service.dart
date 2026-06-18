import 'package:supabase_flutter/supabase_flutter.dart';

class AdminService {
  final _client = Supabase.instance.client;

  // =============================================
  // DASHBOARD
  // =============================================

  Future<Map<String, dynamic>> getDashboardStats() async {
    final totalUsers = await _client
        .from('profiles')
        .select('id')
        .neq('role', 'admin');

    final mitraPending = await _client
        .from('mitra_verifikasi')
        .select('id')
        .eq('status', 'menunggu');

    final disputeAktif = await _client
        .from('disputes')
        .select('id')
        .eq('status', 'dibuka');

    final komisiAktif = await _client
        .from('komisi_rules')
        .select('nilai')
        .eq('is_active', true);

    double totalKomisi = 0;
    for (var k in komisiAktif) {
      totalKomisi += (k['nilai'] as num).toDouble();
    }

    return {
      'total_users': totalUsers.length,
      'mitra_pending': mitraPending.length,
      'dispute_aktif': disputeAktif.length,
      'komisi_bulan': totalKomisi,
    };
  }

  Future<List<Map<String, dynamic>>> getRecentActivity() async {
    final response = await _client
        .from('activity_logs')
        .select('*')
        .order('created_at', ascending: false)
        .limit(10);
    return List<Map<String, dynamic>>.from(response);
  }

  // =============================================
  // VERIFIKASI MITRA
  // =============================================

  Future<List<Map<String, dynamic>>> getMitraVerifikasi({String? status}) async {
    var query = _client.from('mitra_verifikasi').select('*');
    if (status != null && status != 'semua') {
      query = query.eq('status', status);
    }
    final response = await query.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> updateStatusMitra(String id, String status, {String? catatan}) async {
    await _client.from('mitra_verifikasi').update({
      'status': status,
      'catatan': catatan,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);

    // Also update status in public.bengkels
    final isApproved = status == 'disetujui';
    await _client.from('bengkels').update({
      'status': isApproved ? 'approved' : 'rejected',
      'is_verified': isApproved,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('owner_id', id);

    // Log aktivitas
    await _client.from('activity_logs').insert({
      'pesan': 'Status mitra diperbarui menjadi $status',
      'tipe': 'verifikasi',
    });
  }

  // =============================================
  // ENTITAS (USERS)
  // =============================================

  Future<List<Map<String, dynamic>>> getAllUsers({String? role}) async {
    var query = _client.from('profiles').select('*');
    if (role != null) {
      query = query.eq('role', role);
    }
    final response = await query.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> updateUserStatus(String id, String status) async {
    await _client.from('profiles').update({
      'status': status,
    }).eq('id', id);

    await _client.from('activity_logs').insert({
      'pesan': 'Status akun diperbarui menjadi $status',
      'tipe': 'akun',
    });
  }

  // =============================================
  // KOMISI
  // =============================================

  Future<List<Map<String, dynamic>>> getKomisiRules() async {
    final response = await _client
        .from('komisi_rules')
        .select('*')
        .order('min_transaksi', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> updateKomisiRule(String id, Map<String, dynamic> data) async {
    await _client.from('komisi_rules').update({
      ...data,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);

    await _client.from('activity_logs').insert({
      'pesan': 'Komisi diperbarui',
      'tipe': 'komisi',
    });
  }

  Future<void> toggleKomisiStatus(String id, bool isActive) async {
    await _client.from('komisi_rules').update({
      'is_active': isActive,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  // =============================================
  // MASTER DATA - MEREK KENDARAAN
  // =============================================

  Future<List<Map<String, dynamic>>> getMerekKendaraan() async {
    final response = await _client
        .from('merek_kendaraan')
        .select('*')
        .order('nomor_urut', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> tambahMerek(String nama, String kode, String nomorUrut) async {
    await _client.from('merek_kendaraan').insert({
      'nama': nama,
      'kode': kode,
      'nomor_urut': nomorUrut,
      'is_active': true,
    });
  }

  Future<void> updateMerek(String id, Map<String, dynamic> data) async {
    await _client.from('merek_kendaraan').update(data).eq('id', id);
  }

  Future<void> toggleMerekStatus(String id, bool isActive) async {
    await _client.from('merek_kendaraan').update({
      'is_active': isActive,
    }).eq('id', id);
  }

  Future<void> deleteMerek(String id) async {
    await _client.from('merek_kendaraan').delete().eq('id', id);
  }

  // =============================================
  // DISPUTE
  // =============================================

  Future<List<Map<String, dynamic>>> getDisputes({String? status}) async {
    var query = _client.from('disputes').select('''
      *,
      profiles!pelapor_id(name, email)
    ''');
    if (status != null && status != 'semua') {
      query = query.eq('status', status);
    }
    final response = await query.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> updateDisputeStatus(String id, String status) async {
    await _client.from('disputes').update({
      'status': status,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);

    await _client.from('activity_logs').insert({
      'pesan': 'Dispute diperbarui menjadi $status',
      'tipe': 'dispute',
    });
  }

  // =============================================
  // WITHDRAWALS (PENARIKAN DANA MITRA)
  // =============================================

  Future<List<Map<String, dynamic>>> getWithdrawals({String? status}) async {
    var query = _client.from('withdrawals').select('*, bengkels(name)');
    if (status != null && status != 'semua') {
      query = query.eq('status', status);
    }
    final response = await query.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> updateWithdrawalStatus(String id, String status, {String? reason}) async {
    await _client.from('withdrawals').update({
      'status': status,
      'rejection_reason': reason,
      'processed_at': DateTime.now().toIso8601String(),
    }).eq('id', id);

    await _client.from('activity_logs').insert({
      'pesan': 'Status penarikan dana diperbarui menjadi $status',
      'tipe': 'finance',
    });
  }
}