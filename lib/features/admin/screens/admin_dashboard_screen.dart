// Contoh provider untuk Admin Dashboard
final dashboardProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final adminService = AdminService();
  return await adminService.getDashboardData();
});

// Di dalam widget
class DashboardWeb extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardData = ref.watch(dashboardProvider);

    return dashboardData.when(
      data: (data) => DashboardContent(data: data),
      loading: () => CircularProgressIndicator(),
      error: (e, _) => Text('Error: $e'),
    );
  }
}