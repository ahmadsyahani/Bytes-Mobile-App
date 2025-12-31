import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

// WIDGETS
import '../widgets/header_section.dart';
import '../widgets/finance_card.dart';
import '../widgets/menu_button.dart';
import '../widgets/schedule_card.dart';
import '../widgets/custom_bottom_nav.dart';

// SCREENS
import 'materi_screen.dart';
import 'tugas_screen.dart';
import 'jadwal_screen.dart';
import 'kas_screen.dart';
import 'cek_kas_screen.dart'; // Pastikan ini ada
import 'profile_screen.dart';
// import 'classmate_screen.dart'; // Gak perlu di import di sini kalau cuma ada di Navbar

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _supabase = Supabase.instance.client;

  Map<String, dynamic>? _profileData;
  List<Map<String, dynamic>> _birthdayMates = [];

  // VARIABLE DATA DINAMIS
  List<Map<String, dynamic>> _upcomingTasks = [];
  List<Map<String, dynamic>> _todaysSchedule = [];

  // ROLE USER (Default member)
  String _userRole = 'member';

  bool _showBirthdayBanner = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDataWithCache();
  }

  // --- FUNGSI LOAD DATA ---
  Future<void> _loadDataWithCache() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = _supabase.auth.currentUser?.id;

    if (userId == null) return;

    // 1. Load Cache Profil
    final cachedProfile = prefs.getString('cached_profile');
    if (cachedProfile != null) {
      if (mounted) {
        setState(() {
          _profileData = jsonDecode(cachedProfile);
          // Ambil role dari cache kalau ada
          _userRole = _profileData?['role'] ?? 'member';
        });
      }
    }

    try {
      // 2. Fetch Data Segar dari Supabase

      // A. Profil & Role
      final profileRes = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId);

      // B. Ulang Tahun
      final birthdayRes = await _supabase.rpc('get_birthday_mates');

      // C. TUGAS TERDEKAT (LOGIC FILTER H-5)
      final now = DateTime.now();
      final todayStart = DateTime(
        now.year,
        now.month,
        now.day,
      ).toIso8601String();
      final fiveDaysLater = now.add(const Duration(days: 5)).toIso8601String();

      final tasksRes = await _supabase
          .from('tasks')
          .select()
          .gte('deadline', todayStart)
          .lte('deadline', fiveDaysLater)
          .order('deadline', ascending: true);

      // D. JADWAL HARI INI
      int todayIndex = DateTime.now().weekday; // 1=Senin

      final scheduleRes = await _supabase
          .from('schedules')
          .select()
          .eq('day', todayIndex)
          .order('time_start', ascending: true);

      if (mounted) {
        setState(() {
          if (profileRes.isNotEmpty) {
            _profileData = profileRes.first;
            // UPDATE ROLE DARI DATABASE
            _userRole = _profileData?['role'] ?? 'member';
          }
          _birthdayMates = List<Map<String, dynamic>>.from(birthdayRes);
          _upcomingTasks = List<Map<String, dynamic>>.from(tasksRes);
          _todaysSchedule = List<Map<String, dynamic>>.from(scheduleRes);

          _isLoading = false;
        });

        // Simpan cache
        await prefs.setString('cached_profile', jsonEncode(profileRes.first));
        await prefs.setString('cached_birthday', jsonEncode(birthdayRes));
      }
    } catch (e) {
      debugPrint("Error Fetch Data: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _refreshData() async {
    await _loadDataWithCache();
  }

  // --- HELPER LOGIC ---
  String _getGreeting() {
    var hour = DateTime.now().hour;
    if (hour >= 4 && hour < 11) return "Selamat Pagi";
    if (hour >= 11 && hour < 15) return "Selamat Siang";
    if (hour >= 15 && hour < 18) return "Selamat Sore";
    return "Selamat Malam";
  }

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

  String _formatTime(String timeStr) {
    try {
      final parts = timeStr.split(':');
      return "${parts[0]}:${parts[1]}";
    } catch (e) {
      return timeStr;
    }
  }

  Map<String, dynamic> _getDeadlineInfo(String dateString) {
    final deadline = DateTime.parse(dateString);
    final now = DateTime.now();
    final dDate = DateTime(deadline.year, deadline.month, deadline.day);
    final nDate = DateTime(now.year, now.month, now.day);
    final difference = dDate.difference(nDate).inDays;

    if (difference < 0)
      return {
        'text': 'LEWAT',
        'color': Colors.grey,
        'bg': Colors.grey.shade200,
      };
    if (difference == 0)
      return {
        'text': 'HARI INI',
        'color': Colors.red,
        'bg': Colors.red.shade100,
      };
    if (difference == 1)
      return {'text': 'BESOK', 'color': Colors.red, 'bg': Colors.red.shade50};
    if (difference < 3)
      return {
        'text': 'H-$difference',
        'color': Colors.orange,
        'bg': Colors.orange.shade50,
      };
    return {
      'text': 'H-$difference',
      'color': const Color(0xFF4C6EF5),
      'bg': const Color(0xFFE3F2FD),
    };
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryBlue = const Color(0xFF4C6EF5);
    final Color cardBlue = const Color(0xFF7B94FF);
    final Color yellowAccent = const Color(0xFFFFCE31);

    if (_isLoading && _profileData == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF9F8F4),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    String fullName = _profileData?['full_name'] ?? "Mahasiswa";
    String nrp = _profileData?['nrp'] ?? "-";
    String? photoUrl = _profileData?['photo_url'];
    int kasTotal = _profileData?['kas_total'] ?? 0;
    int kasPaid = _profileData?['kas_paid'] ?? 0;

    String displayName = fullName.split(" ")[0];
    if (_profileData?['nickname'] != null &&
        _profileData!['nickname'].toString().isNotEmpty) {
      displayName = _profileData!['nickname'];
    }

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
                  // HEADER
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
                        // MENU 1: CEK KAS (BALIK LAGI)
                        MenuButton(
                          icon: Icons.account_balance_wallet_rounded,
                          label: "Cek Kas",
                          color: primaryBlue,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CekKasScreen(),
                            ),
                          ),
                        ),

                        // MENU 2: TUGAS (LOGIC ADMIN)
                        MenuButton(
                          icon: Icons.assignment,
                          label: "Tugas",
                          color: primaryBlue,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              // Kirim parameter: kalau BUKAN admin, berarti ReadOnly (Gak bisa edit)
                              builder: (context) =>
                                  TugasScreen(isReadOnly: _userRole != 'admin'),
                            ),
                          ).then((_) => _refreshData()),
                        ),

                        // MENU 3: JADWAL
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

                        // MENU 4: MATERI
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

                  // JADWAL HARI INI
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

                  if (_todaysSchedule.isEmpty)
                    _buildEmptyScheduleState()
                  else
                    _buildJadwalList(_todaysSchedule, cardBlue, yellowAccent),

                  const SizedBox(height: 30),

                  // TUGAS MENDEKATI DEADLINE
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Tugas Mendekati Deadline",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                // Pas klik 'Lihat Semua' juga kirim logic admin
                                builder: (context) => TugasScreen(
                                  isReadOnly: _userRole != 'admin',
                                ),
                              ),
                            ).then((_) => _refreshData());
                          },
                          child: const Text("Lihat Semua"),
                        ),
                      ],
                    ),
                  ),

                  _buildDynamicTaskList(),
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

  // --- WIDGETS BUILDER ---

  Widget _buildDynamicTaskList() {
    if (_upcomingTasks.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check, color: Colors.green.shade400),
            ),
            const SizedBox(width: 16),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Aman Terkendali!",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  "Tidak ada tugas mendesak (H-5).",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 140,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemCount: _upcomingTasks.length,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final task = _upcomingTasks[index];
          final deadlineInfo = _getDeadlineInfo(task['deadline']);
          final dateObj = DateTime.parse(task['deadline']);

          return Container(
            width: 260,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade100),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        task['matkul'],
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: deadlineInfo['bg'],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        deadlineInfo['text'],
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: deadlineInfo['color'],
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  task['title'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 12,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('d MMM yyyy', 'id').format(dateObj),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

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
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.weekend_rounded,
              size: 30,
              color: Color(0xFF4C6EF5),
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
              time:
                  "${_formatTime(schedule['time_start'])} - ${_formatTime(schedule['time_end'])}",
              title: schedule['matkul'],
              subtitle: schedule['type'] ?? 'Teori',
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
}
