// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:bengkel/main.dart';

void main() {
  testWidgets('App UI load smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame (Menggunakan BengkelApp, bukan MyApp).
    await tester.pumpWidget(const BengkelApp());

    // Tunggu semua proses render dan animasi (seperti inisialisasi) selesai
    await tester.pumpAndSettle();

    // Verifikasi bahwa layar Login berhasil dimuat 
    // dengan mencari teks 'Selamat Datang' yang ada di AuthHeader
    expect(find.text('Selamat Datang'), findsOneWidget);
  });
}