import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// WIDGETS
import '../widgets/header_section.dart';
import '../widgets/finance_card.dart';
import '../widgets/menu_button.dart';
import '../widgets/schedule_card.dart';
import '../widgets/task_card.dart';
import '../widgets/custom_bottom_nav.dart';

// SCREENS
import 'materi_screen.dart';
import 'tugas_screen.dart';
import 'jadwal_screen.dart';
import 'kas_screen.dart';
import 'cek_kas_screen.dart';
import 'profile_screen.dart';
import 'lecturer_screen.dart'; // Jangan lupa import ini
import 'classmate_screen.dart'; // Import ini juga

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _supabase = Supabase.instance.client;

  Map<String, dynamic>? _profileData;
  List<Map<String, dynamic>> _birthdayMates = [];
  bool _showBirthdayBanner = true;
  bool _isLoading = true;

  // --- DATA DUMMY JADWAL (DATABASE SEMENTARA) ---
  // day: 1=Senin, 2=Selasa, 3=Rabu, 4=Kamis, 5=Jumat, 6=Sabtu, 7=Minggu
  final List<Map<String, dynamic>> _allSchedules = [
    {
      "day": 1, // Senin
      "title": "Upacara Bendera",
      "subtitle": "Lapangan Merah",
      "time": "07:00 - 08:00",
      "room": "Lapangan",
      "lecturer": "-",
    },
    {
      "day": 1, // Senin
      "title": "Logika Algoritma",
      "subtitle": "Flowchart Dasar",
      "time": "08:00 - 10:00",
      "room": "B.203",
      "lecturer": "Dr. Budi",
    },
    {
      "day": 2, // Selasa
      "title": "Basis Data",
      "subtitle": "ERD & Normalisasi",
      "time": "10:00 - 12:00",
      "room": "Lab Database",
      "lecturer": "Siti Aminah",
    },
    {
      "day": 3, // Rabu
      "title": "Workshop Web",
      "subtitle": "Flutter Layout",
      "time": "13:00 - 15:00",
      "room": "Lab Multimedia",
      "lecturer": "Pak Dika",
    },
    // ... Tambahkan jadwal lain
  ];

  @override
  void initState() {
    super.initState();
    _loadDataWithCache();
  }

  // --- FUNGSI LOAD DATA (TETAP SAMA) ---
  Future<void> _loadDataWithCache() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = _supabase.auth.currentUser?.id;

    if (userId == null) return;

    final cachedProfile = prefs.getString('cached_profile');
    final cachedBirthday = prefs.getString('cached_birthday');

    if (cachedProfile != null) {
      if (mounted) {
        setState(() {
          _profileData = jsonDecode(cachedProfile);
          if (cachedBirthday != null) {
            _birthdayMates = List<Map<String, dynamic>>.from(
              jsonDecode(cachedBirthday),
            );
          }
          _isLoading = false;
        });
      }
    }

    try {
      final profileRes = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId);
      final birthdayRes = await _supabase.rpc('get_birthday_mates');

      if (mounted) {
        setState(() {
          if (profileRes.isNotEmpty) {
            _profileData = profileRes.first;
          }
          _birthdayMates = List<Map<String, dynamic>>.from(birthdayRes);
          _isLoading = false;
        });

        await prefs.setString('cached_profile', jsonEncode(profileRes.first));
        await prefs.setString('cached_birthday', jsonEncode(birthdayRes));
      }
    } catch (e) {
      debugPrint("Offline Mode: $e");
      if (mounted && _profileData == null) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _refreshData() async {
    await _loadDataWithCache();
  }

  String _getGreeting() {
    var hour = DateTime.now().hour;
    if (hour >= 4 && hour < 11) return "Selamat Pagi";
    if (hour >= 11 && hour < 15) return "Selamat Siang";
    if (hour >= 15 && hour < 18) return "Selamat Sore";
    return "Selamat Malam";
  }

  // Helper: Tanggal Hari Ini (Contoh: "Senin, 14 Okt")
  String _getTodayDateString() {
    final now = DateTime.now();
    List<String> days = [
      "Senin",
      "Selasa",
      "Rabu",
      "Kamis",
      "Jumat",
      "Sabtu",
      "Minggu",
    ];
    List<String> months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "Mei",
      "Jun",
      "Jul",
      "Agu",
      "Sep",
      "Okt",
      "Nov",
      "Des",
    ];
    return "${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}";
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryBlue = const Color(0xFF4C6EF5);
    final Color cardBlue = const Color(0xFF7B94FF);
    final Color yellowAccent = const Color(0xFFFFCE31);
    final Color redAccent = const Color(0xFFFF8B8B);

    if (_isLoading && _profileData == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF9F8F4),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    String fullName = _profileData?['full_name'] ?? "Mahasiswa";
    String nrp = _profileData?['nrp'] ?? "-";
    String? photoUrl = _profileData?['photo_url'];
    int kasTotal = _profileData?['kas_total'] ?? 150000;
    int kasPaid = _profileData?['kas_paid'] ?? 0;

    String displayName = fullName.split(" ")[0];
    if (_profileData?['nickname'] != null &&
        _profileData!['nickname'].toString().isNotEmpty) {
      displayName = _profileData!['nickname'];
    }

    // --- LOGIC FILTER JADWAL HARI INI ---
    int todayIndex = DateTime.now().weekday;
    // UNTUK TESTING (Ganti angka 1-7 untuk cek tampilan hari lain):
    // todayIndex = 1;

    final List<Map<String, dynamic>> todaysSchedule = _allSchedules
        .where((s) => s['day'] == todayIndex)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF9F8F4),
      body: Stack(
        fit: StackFit.expand,
        children: [
          RefreshIndicator(
            onRefresh: _refreshData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      HeaderSection(
                        fullName: displayName,
                        nrp: nrp,
                        greeting: _getGreeting(),
                        photoUrl: photoUrl,
                      ),
                      Positioned(
                        bottom: -60,
                        left: 24,
                        right: 24,
                        child: FinanceCard(
                          paidAmount: kasPaid,
                          totalAmount: kasTotal,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const KasScreen(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 75),

                  if (_birthdayMates.isNotEmpty && _showBirthdayBanner)
                    _buildBirthdayBanner(),

                  // GRID MENU
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 35,
                      vertical: 15,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // 1. CEK KAS
                        MenuButton(
                          icon: Icons.account_balance_wallet,
                          label: "Cek Kas",
                          color: primaryBlue,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CekKasScreen(),
                            ),
                          ),
                        ),

                        // 2. TUGAS (KEMBALI KE TUGAS)
                        MenuButton(
                          icon: Icons.assignment, // Icon Tugas
                          label: "Tugas", // Label Tugas
                          color: primaryBlue,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              // Arahkan ke TugasScreen lagi
                              builder: (context) => const TugasScreen(),
                            ),
                          ),
                        ),

                        // 3. JADWAL
                        MenuButton(
                          icon: Icons.calendar_today_rounded,
                          label: "Jadwal",
                          color: primaryBlue,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const JadwalScreen(),
                            ),
                          ),
                        ),

                        // 4. MATERI
                        MenuButton(
                          icon: Icons.folder,
                          label: "Materi",
                          color: primaryBlue,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MateriScreen(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // --- HEADER SECTION JADWAL ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Jadwal Hari ini",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _getTodayDateString(),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: primaryBlue,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // --- LOGIC TAMPILAN JADWAL ---
                  if (todaysSchedule.isEmpty)
                    _buildEmptyScheduleState() // TAMPILAN KOSONG
                  else
                    _buildJadwalList(
                      todaysSchedule,
                      cardBlue,
                      yellowAccent,
                    ), // TAMPILAN ADA JADWAL

                  const SizedBox(height: 30),
                  _buildSectionTitle(
                    "Tugas Mendekati Deadline",
                    showArrows: false,
                  ),
                  _buildTugasList(redAccent, cardBlue),
                ],
              ),
            ),
          ),

          Positioned(
            bottom: 30,
            left: 24,
            right: 24,
            child: CustomBottomNav(
              activeColor: primaryBlue,
              onProfileTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                ).then((_) => _loadDataWithCache());
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildEmptyScheduleState() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF4C6EF5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.weekend_rounded,
              size: 30,
              color: const Color(0xFF4C6EF5),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "Tidak ada jadwal hari ini",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJadwalList(
    List<Map<String, dynamic>> schedules,
    Color cardBlue,
    Color yellowAccent,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: schedules.map((schedule) {
          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ScheduleCard(
              time: schedule['time'],
              title: schedule['title'],
              subtitle: schedule['subtitle'],
              room: schedule['room'],
              lecturer: schedule['lecturer'],
              color: cardBlue,
              accentColor: yellowAccent,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTugasList(Color redAccent, Color cardBlue) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: TaskCard(
        title: "Logika dan Algoritma",
        desc: "Membuat Flowchart",
        startDate: "Senin, 13 Okt",
        endDate: "Selasa, 21 Okt",
        status: "Kerjakan",
        statusColor: redAccent,
        cardColor: cardBlue,
      ),
    );
  }

  Widget _buildBirthdayBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF9A9E), Color(0xFFFECFEF)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.cake, color: Colors.white, size: 40),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                "Today is ${_birthdayMates.map((e) => e['nickname'] ?? e['full_name']).join(", ")}'s birthday!",
                style: const TextStyle(color: Colors.white),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => setState(() => _showBirthdayBanner = false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, {required bool showArrows}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          if (showArrows)
            const Row(
              children: [
                Icon(Icons.arrow_back, size: 20, color: Colors.grey),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, size: 20, color: Colors.blue),
              ],
            ),
        ],
      ),
    );
  }
}
