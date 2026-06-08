class MechanicModel {
  final String id;
  final String bengkelId;
  final String fullName;
  final String operationalStatus; // 'Available', 'On-Duty', 'Offline' 

  MechanicModel({
    required this.id,
    required this.bengkelId,
    required this.fullName,
    required this.operationalStatus,
  });

  // Fungsi untuk mengubah data JSON dari Supabase menjadi object Dart
factory MechanicModel.fromJson(Map<String, dynamic> json) {
  return MechanicModel(
    id: json['id'] as String? ?? '', // Lebih aman jika diberi default value atau ditangani bertahap
    bengkelId: (json['bengkels_id'] ?? json['bengkel_id'] ?? '').toString(), // <-- Menangkap 'bengkels_id' dari database
    fullName: json['full_name'] as String? ?? '',
    operationalStatus: json['operational_status'] as String? ?? 'Offline',
  );
}
}