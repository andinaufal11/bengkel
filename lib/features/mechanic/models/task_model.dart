class TaskModel {
  final String id;
  final String customerId;
  final String status; // 'Pending', 'Accepted', 'On-the-way', 'Completed'
  final bool isSos;    // Untuk membedakan jenis urgensi
  
  // TAMBAHAN UNTUK POIN 2
  final String serviceName; 
  final String date;
  final String time;

  TaskModel({
    required this.id,
    required this.customerId,
    required this.status,
    required this.isSos,
    this.serviceName = 'Servis Umum', // Default value agar tidak eror
    this.date = 'Belum diatur',       // Default value
    this.time = '00:00',              // Default value
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String? ?? '',
      customerId: json['customer_id'] as String? ?? '',
      status: json['status'] as String? ?? 'Pending',
      isSos: json['is_sos'] as bool? ?? false,
      // Mapping dari database nantinya
      serviceName: json['service_name'] as String? ?? 'Servis Umum',
      date: json['date'] as String? ?? 'Belum diatur',
      time: json['time'] as String? ?? '00:00',
    );
  }
}