class TaskModel {
  final String id;
  final String customerId;
  final String status;
  final bool isSos;
  final String serviceName;
  final String date;
  final String time;
  final String customerName;
  final String address;
  final double? income;
  final String? vehicleInfo;

  // Field baru
  final String? notes;
  final double? latitude;
  final double? longitude;

  TaskModel({
    required this.id,
    required this.customerId,
    required this.status,
    required this.isSos,
    this.serviceName = 'Servis Umum',
    this.date = 'Belum diatur',
    this.time = '00:00',
    this.customerName = 'Pelanggan',
    this.address = 'Lokasi belum tersedia',
    this.income,
    this.vehicleInfo,
    this.notes,
    this.latitude,
    this.longitude,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String? ?? '',
      customerId: json['customer_id'] as String? ?? '',
      status: json['status'] as String? ?? 'Pending',
      isSos: json['is_sos'] as bool? ?? false,
      serviceName: json['service_name'] as String? ?? 'Servis Umum',
      date: json['date'] as String? ?? 'Belum diatur',
      time: json['time'] as String? ?? '00:00',
      customerName: json['customer_name'] as String? ?? 'Pelanggan',
      address: json['address'] as String? ?? 'Lokasi belum tersedia',
      income: json['income'] != null
          ? (json['income'] as num).toDouble()
          : json['price'] != null
              ? (json['price'] as num).toDouble()
              : null,
      vehicleInfo:
          json['vehicle_info'] as String? ?? _buildVehicleInfo(json),
      notes: json['notes'] as String?,
      // Supabase menyimpan koordinat sebagai numeric/float8
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : null,
    );
  }

  static String? _buildVehicleInfo(Map<String, dynamic> json) {
    final brand = json['vehicle_brand'] as String?;
    final type = json['vehicle_type'] as String?;
    final plate = json['vehicle_plate'] as String?;

    final parts = [
      if (brand != null && brand.isNotEmpty) brand,
      if (type != null && type.isNotEmpty) type,
      if (plate != null && plate.isNotEmpty) '($plate)',
    ];

    return parts.isNotEmpty ? parts.join(' ') : null;
  }
}