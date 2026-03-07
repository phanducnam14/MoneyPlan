import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  static String get baseUrl {
    if (kIsWeb) {
      // Web - use localhost instead of 127.0.0.1 to avoid CORS issues
      return 'http://localhost:3000';
    }

    // Android emulator
    return 'http://10.0.2.2:3000';
  }
}