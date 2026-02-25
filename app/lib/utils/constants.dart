import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF1B3F22);
  static const Color accent = Color(0xFF4CAF50);
  static const Color background = Color(0xFFF8FAF8);
  static const Color darkBackground = Color(0xFF2D2D2D);
}

class ApiConfig {
  // For Android emulator, use 10.0.2.2 to access host machine
  // For iOS simulator, use 127.0.0.1
  // For physical device, use your computer's IP address
  static const String baseUrl = 'http://10.0.2.2:8000';

  static String get generateDesignUrl => '$baseUrl/generate-design';
}
