import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart'; // Pastikan import ini ada

// IMPORT SCREENS
import 'screens/login_screen.dart';
import 'screens/homepage.dart';
import 'screens/onboarding_screen.dart';

void main() async {
  // 1. MODIFIKASI DISINI: Tangkap WidgetsBinding
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // 2. TAHAN SPLASH SCREEN (Biar ga langsung ilang)
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // SETUP SUPABASE
  await Supabase.initialize(
    url: 'https://ogpxkluvzzvfryrxkzpo.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9ncHhrbHV2enp2ZnJ5cnhrenBvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjY4MzU2NjksImV4cCI6MjA4MjQxMTY2OX0.X1MVHrhpOmPha7yPKbhdRvBVJKRXRuyvT-UgP64wZKk',
  );

  await initializeDateFormatting('id', null);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bytes App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4C6EF5)),
        useMaterial3: true,
        fontFamily: 'MonaSans',
      ),
      // Arahkan ke Widget Pengecekan (Satpam)
      home: const AuthCheck(),
    );
  }
}

// --- WIDGET LOGIC PENGECEKAN (SATPAM) ---
class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  bool _isLoading = true;
  bool _hasSeenOnboarding = false;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    // 1. Cek apakah sudah pernah lihat Onboarding (Shared Preferences)
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('has_seen_onboarding') ?? false;

    // 2. Cek apakah user sedang Login (Supabase)
    final session = Supabase.instance.client.auth.currentSession;

    // Simulasi delay dikit biar splash screen ga kedip kecepetan (Optional)
    // await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      // 3. HILANGKAN SPLASH SCREEN DISINI
      // Karena data udah siap, kita suruh native splash minggir
      FlutterNativeSplash.remove();

      setState(() {
        _hasSeenOnboarding = seen;
        _isLoggedIn = session != null;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tampilkan Loading putih bersih saat sedang mengecek
    // (Sebenernya user ga bakal liat ini lagi karena ketutupan Splash Screen, tapi biarin aja buat safety)
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // --- LOGIC PERCABANGAN UTAMA ---

    // 1. Kalau belum pernah liat Onboarding -> Ke Onboarding Screen
    if (!_hasSeenOnboarding) {
      return const OnboardingScreen();
    }

    // 2. Kalau sudah Onboarding & Sudah Login -> Ke Home
    if (_isLoggedIn) {
      return const HomeScreen();
    }

    // 3. Kalau sudah Onboarding tapi Belum Login -> Ke Login
    return const LoginScreen();
  }
}
