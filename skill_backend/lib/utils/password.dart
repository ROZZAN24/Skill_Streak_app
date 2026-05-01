import 'package:bcrypt/bcrypt.dart';

class PasswordUtil {
  static String hash(String password) {
    return BCrypt.hashpw(password, BCrypt.gensalt());
  }

  static bool verify(String password, String hash) {
    return BCrypt.checkpw(password, hash);
  }
}
