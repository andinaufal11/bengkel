class UserModel {
  final String id;
  final String name;
  final String email;
  final String role; // 'customer', 'partner', 'mechanic', 'admin'
  final String? phoneNumber;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phoneNumber,
  });

  // Mengubah data dari database (Supabase json) menjadi objek Dart
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'customer',
      phoneNumber: json['phone_number'],
    );
  }

  // Mengubah objek Dart menjadi format json untuk dikirim ke database
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'phone_number': phoneNumber,
    };
  }
}