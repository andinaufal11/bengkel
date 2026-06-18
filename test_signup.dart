import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final url = Uri.parse('https://ixbmizuwheraqnipcmwl.supabase.co/auth/v1/signup');
  final response = await http.post(
    url,
    headers: {
      'apikey': 'sb_publishable_EI7xZVFyja5D-N4YwsTHUA_cXGfB5-T',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'email': 'test_user_12345@bengkel.com',
      'password': 'password1234',
    }),
  );
  
  print('Status Code: ${response.statusCode}');
  print('Body: ${response.body}');
}
