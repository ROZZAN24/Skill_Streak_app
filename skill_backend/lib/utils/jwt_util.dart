import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

class JwtUtil {
  static const _secret = 'SKILLSTREAK_SECRET_KEY';

  static String generate(String userId) {
    final jwt = JWT(
      {'userId': userId},
      issuer: 'skillstreak-backend',
    );

    return jwt.sign(
      SecretKey(_secret),
      expiresIn: const Duration(days: 7),
    );
  }
}
