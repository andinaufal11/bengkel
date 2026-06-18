import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bengkel/core/constants/app_colors.dart';
import 'package:bengkel/features/mechanic/models/task_model.dart';
import 'package:bengkel/features/mechanic/screens/report_submission_screen.dart';
import 'package:bengkel/features/shared_features/chat/chat_screen.dart';

class LiveTrackingScreen extends StatefulWidget {
  final TaskModel task;

  const LiveTrackingScreen({super.key, required this.task});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  final MapController _mapController = MapController();

  // Posisi default mekanik sebelum GPS ditemukan (Pusat Jakarta)
  LatLng _mechanicPosition = const LatLng(-6.200000, 106.816666);

  // Koordinat pelanggan — diambil dari TaskModel jika tersedia
  late final LatLng _customerPosition;

  bool _isLoadingLocation = true;
  StreamSubscription<Position>? _positionStream;
  String _mechanicId = '';

  @override
  void initState() {
    super.initState();
    _mechanicId = Supabase.instance.client.auth.currentUser?.id ?? '';

    _customerPosition =
        (widget.task.latitude != null && widget.task.longitude != null)
            ? LatLng(widget.task.latitude!, widget.task.longitude!)
            : const LatLng(-6.210000, 106.820000);

    _determinePosition();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

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
      _showError('Izin lokasi ditolak permanen. Ubah di Pengaturan HP.');
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _mechanicPosition = LatLng(position.latitude, position.longitude);
          _isLoadingLocation = false;
        });
        _mapController.move(_mechanicPosition, 16.0);
      }

      // FR-MKN-04: Kirim koordinat ke Supabase Realtime secara live
      _startBroadcastingLocation();
    } catch (e) {
      _showError('Gagal mendapatkan lokasi: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() => _isLoadingLocation = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  void _startBroadcastingLocation() {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // update tiap 10 meter
      ),
    ).listen((Position position) async {
      if (mounted) {
        setState(() {
          _mechanicPosition = LatLng(position.latitude, position.longitude);
        });
        _mapController.move(_mechanicPosition, 15.0);
      }
      // Update ke Supabase
      if (_mechanicId.isNotEmpty) {
        try {
          await Supabase.instance.client.from('mechanics').update({
            'current_latitude': position.latitude,
            'current_longitude': position.longitude,
          }).eq('user_id', _mechanicId);
        } catch (_) {} // GPS update bisa gagal tanpa blocking UI
      }
    });
  }

  void _openChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          customerName: widget.task.customerName,
          taskId: widget.task.id,
        ),
      ),
    );
  }

  void _finishTask() {
    _positionStream?.cancel(); // Stop GPS broadcast
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportSubmissionScreen(
          taskId: widget.task.id,
          mechanicId: _mechanicId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── 1. Layer Peta ──────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _mechanicPosition,
              initialZoom: 15.0,
            ),
            children: [
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
                    child: const Icon(
                      Icons.location_on,
                      color: AppColors.error,
                      size: 40,
                    ),
                  ),
                  // Marker Lokasi Mekanik (Biru) — tampil setelah GPS didapat
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
                        child: const Icon(
                          Icons.navigation,
                          color: AppColors.secondary,
                          size: 30,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),

          // ── 2. Tombol Kembali ──────────────────────────────────────
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

          // ── 3. Panel Informasi Bawah ───────────────────────────────
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
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status & estimasi
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Menuju Lokasi',
                          style: TextStyle(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const Spacer(),
                      // TODO: Hitung estimasi waktu secara dinamis
                      const Text(
                        'Est. 12 Menit',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Info Pelanggan — dari TaskModel
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
                          children: [
                            Text(
                              widget.task.customerName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              widget.task.vehicleInfo ??
                                  'Info kendaraan tidak tersedia',
                              style: const TextStyle(
                                color: AppColors.textGrey,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Tombol Chat (FR-MKN-05)
                      IconButton(
                        onPressed: _openChat,
                        icon: const Icon(Icons.chat_bubble_outline),
                        color: AppColors.secondary,
                        tooltip: 'Chat dengan pelanggan',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Tombol Selesaikan Servis (FR-MKN-06)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _finishTask,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Selesaikan Servis & Buat Laporan',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── 4. Loading GPS ─────────────────────────────────────────
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