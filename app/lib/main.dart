import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/ar_camera_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL', defaultValue: 'http://10.0.2.2:54321'),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: ''),
  );

  runApp(const SunSunGardenApp());
}

class SunSunGardenApp extends StatelessWidget {
  const SunSunGardenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SunSun Garden Genie',
      theme: ThemeData(
        primaryColor: const Color(0xFF1B3F22),
        scaffoldBackgroundColor: const Color(0xFFF8FAF8),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B3F22),
          primary: const Color(0xFF1B3F22),
        ),
      ),
      home: const ARCameraScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
