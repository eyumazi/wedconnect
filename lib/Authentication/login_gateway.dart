import 'dart:convert';

import 'package:http/http.dart' as http;

const _loginGatewayUrl =
    'https://us-central1-wedconnect-auth.cloudfunctions.net/loginWithLockout';

class LoginGatewayException implements Exception {
  final String code;
  final int? retryAfterSeconds;

  const LoginGatewayException(this.code, {this.retryAfterSeconds});
}

Future<String> signInThroughLockoutGateway({
  required String email,
  required String password,
}) async {
  final response = await http
      .post(
        Uri.parse(_loginGatewayUrl),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email.trim(), 'password': password}),
      )
      .timeout(const Duration(seconds: 20));

  Map<String, dynamic> body = const {};
  if (response.body.isNotEmpty) {
    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      body = decoded;
    }
  }

  if (response.statusCode == 423) {
    throw LoginGatewayException(
      'account-locked',
      retryAfterSeconds: body['retryAfterSeconds'] as int?,
    );
  }
  if (response.statusCode == 401) {
    throw const LoginGatewayException('invalid-credentials');
  }
  if (response.statusCode != 200 || body['customToken'] is! String) {
    throw const LoginGatewayException('authentication-unavailable');
  }

  return body['customToken'] as String;
}
