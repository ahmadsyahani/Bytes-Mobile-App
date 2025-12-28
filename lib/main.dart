import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/login_screen.dart';
import 'screens/homepage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // SETUP SUPABASE (GANTI DENGAN KUNCI DARI DASHBOARD KAMU)
  await Supabase.initialize(
    url: 'https://ogpxkluvzzvfryrxkzpo.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9ncHhrbHV2enp2ZnJ5cnhrenBvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjY4MzU2NjksImV4cCI6MjA4MjQxMTY2OX0.X1MVHrhpOmPha7yPKbhdRvBVJKRXRuyvT-UgP64wZKk', // Ganti ini
  );

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
      home: Supabase.instance.client.auth.currentUser == null
          ? const LoginScreen()
          : const HomeScreen(),
    );
  }
}
