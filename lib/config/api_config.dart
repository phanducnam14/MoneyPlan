import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  // Production API URL - Update after deploying to Railway
  static const String productionApiUrl = 'https://smart-finance-api.railway.app';
  
  // Development/Local API URLs
  static const String devApiUrlWeb = 'http://localhost:3000';
  static const String devApiUrlAndroid = 'http://10.0.2.2:3000';
  
  // Switch between production and development
  // Set isProduction = true when deployed to production
  static const bool isProduction = false; // Change to true for production
  
  static String get baseUrl {
    if (isProduction) {
      return productionApiUrl;
    }
    
    if (kIsWeb) {
      // Web development
      return devApiUrlWeb;
    }

    // Android emulator development
    return devApiUrlAndroid;
  }
}