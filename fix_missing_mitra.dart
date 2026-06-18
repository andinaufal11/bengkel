import 'dart:convert';
import 'dart:io';

const supabaseUrl = 'https://ixbmizuwheraqnipcmwl.supabase.co';
const anonKey = 'sb_publishable_EI7xZVFyja5D-N4YwsTHUA_cXGfB5-T';

void main() async {
  final client = HttpClient();
  
  // Login as admin to satisfy RLS write permissions if needed
  final loginUri = Uri.parse('$supabaseUrl/auth/v1/token?grant_type=password');
  final loginReq = await client.postUrl(loginUri);
  loginReq.headers.add('apikey', anonKey);
  loginReq.headers.add('Content-Type', 'application/json');
  loginReq.write(jsonEncode({
    'email': 'admin@bengkelku.com',
    'password': 'admin123',
  }));
  final loginRes = await loginReq.close();
  final loginBody = await loginRes.transform(utf8.decoder).join();
  if (loginRes.statusCode != 200) {
    print('Failed to authenticate as admin.');
    client.close();
    return;
  }
  final jwt = jsonDecode(loginBody)['access_token'] as String;
  
  // Insert missing entry for '9cd2e095-7aaa-41e0-80b0-6431807afe67'
  final targetId = '9cd2e095-7aaa-41e0-80b0-6431807afe67';
  print('Inserting missing verification record for $targetId...');
  
  final insertUri = Uri.parse('$supabaseUrl/rest/v1/mitra_verifikasi');
  final insertReq = await client.postUrl(insertUri);
  insertReq.headers.add('apikey', anonKey);
  insertReq.headers.add('Authorization', 'Bearer $jwt');
  insertReq.headers.add('Content-Type', 'application/json');
  insertReq.write(jsonEncode({
    'id': targetId,
    'nama_bengkel': 'bengkel abiyu',
    'nama_pemilik': 'abiyu',
    'kota': 'Bandung',
    'jumlah_dokumen': 3,
    'status': 'menunggu',
  }));
  
  final insertRes = await insertReq.close();
  final insertBody = await insertRes.transform(utf8.decoder).join();
  print('Insert Response Status: ${insertRes.statusCode}');
  print('Insert Response Body: $insertBody');
  
  client.close();
}
