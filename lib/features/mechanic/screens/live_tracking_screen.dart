import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:bengkel/core/constants/app_colors.dart';
import 'package:bengkel/features/mechanic/screens/report_submission_screen.dart'; // Nanti kita buat file ini
import 'package:bengkel/features/shared_features/chat/chat_screen.dart';


class LiveTrackingScreen extends StatefulWidget {
  final String taskId;

  const LiveTrackingScreen({super.key, required this.taskId});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  final MapController _mapController = MapController();
  
  // Koordinat default (Misal: Pusat Jakarta) jika GPS belum didapatkan
  LatLng _mechanicPosition = const LatLng(-6.200000, 106.816666);
  
  // Koordinat pelanggan (Nanti didapat dari database berdasarkan taskId)
  final LatLng _customerPosition = const LatLng(-6.210000, 106.820000); 

  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  // Fungsi untuk meminta izin dan mengambil lokasi GPS mekanik
  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showError('GPS dinonaktifkan. Harap nyalakan GPS Anda.');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showError('Izin lokasi ditolak.');
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      _showError('Izin lokasi ditolak permanen. Ubah di pengaturan HP.');
      return;
    }

    // Ambil lokasi saat ini
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high
    );

    setState(() {
      _mechanicPosition = LatLng(position.latitude, position.longitude);
      _isLoadingLocation = false;
    });

    // Pindahkan kamera peta ke lokasi mekanik
    _mapController.move(_mechanicPosition, 16.0);

    // TODO: [FR-MKN-04] Di sini tempatnya mengirim koordinat secara berkala 
    // ke Supabase Realtime agar aplikasi Pelanggan bisa melihat pergerakan.
  }

  void _showError(String message) {
    setState(() => _isLoadingLocation = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

    void _openChat() {
     // FR-MKN-05: Navigasi ke halaman In-App Chat
     Navigator.push(
       context,
       MaterialPageRoute(
         builder: (context) => const ChatScreen(customerName: 'Budi Santoso'),
       ),
     );
   }

  void _finishTask() {
    // Navigasi ke halaman Laporan Servis (FR-MKN-06)
    // Gunakan push agar mekanik bisa kembali jika salah klik
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportSubmissionScreen(taskId: widget.taskId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // 1. Layer Peta (Map)
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _mechanicPosition,
              initialZoom: 15.0,
            ),
            children: [
              // Menggunakan OpenStreetMap (Gratis)
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.otoretail.bengkel',
              ),
              MarkerLayer(
                markers: [
                  // Marker Lokasi Pelanggan (Merah)
                  Marker(
                    point: _customerPosition,
                    width: 50,
                    height: 50,
                    child: const Icon(Icons.location_on, color: AppColors.error, size: 40),
                  ),
                  // Marker Lokasi Mekanik (Biru)
                  if (!_isLoadingLocation)
                    Marker(
                      point: _mechanicPosition,
                      width: 50,
                      height: 50,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.navigation, color: AppColors.secondary, size: 30),
                      ),
                    ),
                ],
              ),
            ],
          ),

          // 2. Tombol Kembali di Pojok Kiri Atas
          Positioned(
            top: 40,
            left: 16,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // 3. Panel Informasi di Bagian Bawah
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Indikator Status
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('Menuju Lokasi', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                      const Spacer(),
                      const Text('Est. 12 Menit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Info Pelanggan
                  Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: AppColors.border,
                        child: Icon(Icons.person, color: AppColors.textGrey),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('Budi Santoso', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('Toyota Avanza 2021', style: TextStyle(color: AppColors.textGrey, fontSize: 13)),
                          ],
                        ),
                      ),
                      // Tombol Chat (FR-MKN-05)
                      IconButton(
                        onPressed: _openChat,
                        icon: const Icon(Icons.chat_bubble_outline),
                        color: AppColors.secondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Tombol Selesaikan Pekerjaan (Menuju FR-MKN-06)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _finishTask,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Selesaikan Servis & Buat Laporan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. Indikator Loading di Tengah jika sedang mencari GPS
          if (_isLoadingLocation)
            const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: AppColors.secondary),
                      SizedBox(height: 16),
                      Text('Mencari sinyal GPS...'),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}