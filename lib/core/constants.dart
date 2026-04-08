import 'package:flutter/foundation.dart';

class AppConstants {
  static const String baseUrl = kIsWeb 
    ? 'http://localhost:3000/api' 
    : 'http://10.0.2.2:3000/api';
  
  // Storage Keys
  static const String tokenKey = 'jwt_token';
  static const String userKey = 'cached_user';
}
