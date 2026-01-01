import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart'; // 1. IMPORT INI WAJIB

// WIDGETS
import '../widgets/header_section.dart';
import '../widgets/finance_card.dart';
import '../widgets/menu_button.dart';
import '../widgets/custom_bottom_nav.dart';

// SCREENS
import 'materi_screen.dart';
import 'tugas_screen.dart';
import 'jadwal_screen.dart';
import 'kas_screen.dart';
import 'cek_kas_screen.dart';
import 'profile_screen.dart';

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

  // VARIABLE KHUSUS KAS
  int _myTotalKasPaid = 0;
  bool _isLoadingKas = true;

  String _userRole = 'member';
  bool _showBirthdayBanner = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDataWithCache();
  }

  // --- LOGIC UTAMA: FETCH DATA & HILANGKAN SPLASH SCREEN ---
  Future<void> _loadDataWithCache() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = _supabase.auth.currentUser?.id;

    if (userId == null) return;

    // 1. Load Cache (Biar user liat sesuatu pas loading)
    final cachedProfile = prefs.getString('cached_profile');
    if (cachedProfile != null) {
      if (mounted) {
        setState(() {
          _profileData = jsonDecode(cachedProfile);
          _userRole = _profileData?['role'] ?? 'member';
        });
      }
    }

    try {
      // 2. FETCH SEMUA DATA DARI SUPABASE (WAITING...)

      // A. Profil
      final profileRes = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId);

      // B. Ulang Tahun
      final birthdayRes = await _supabase.rpc('get_birthday_mates');

      // C. Tugas H-5
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

      // D. Jadwal Hari Ini
      int todayIndex = DateTime.now().weekday;
      final scheduleRes = await _supabase
          .from('schedules')
          .select()
          .eq('day', todayIndex)
          .order('time_start', ascending: true);

      // E. Hitung Kas
      final kasRes = await _supabase
          .from('kas_transactions')
          .select('amount')
          .eq('user_id', userId)
          .eq('type', 'IN')
          .eq('status', 'SUCCESS');

      int totalBayar = 0;
      for (var item in kasRes) {
        totalBayar += (item['amount'] as int);
      }

      // 3. SETELAH DATA DAPAT, UPDATE UI & HILANGKAN SPLASH
      if (mounted) {
        setState(() {
          if (profileRes.isNotEmpty) {
            _profileData = profileRes.first;
            _userRole = _profileData?['role'] ?? 'member';
          }
          _birthdayMates = List<Map<String, dynamic>>.from(birthdayRes);
          _upcomingTasks = List<Map<String, dynamic>>.from(tasksRes);
          _todaysSchedule = List<Map<String, dynamic>>.from(scheduleRes);

          _myTotalKasPaid = totalBayar;
          _isLoadingKas = false;
          _isLoading = false;
        });

        // Simpan Cache
        await prefs.setString('cached_profile', jsonEncode(profileRes.first));
        await prefs.setString('cached_birthday', jsonEncode(birthdayRes));

        // --- INI KUNCINYA BRO ---
        // Hapus Splash Screen Native karena data udah siap ditampilkan
        FlutterNativeSplash.remove();
      }
    } catch (e) {
      debugPrint("Error Fetch Data: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        // Kalau error pun, tetep hapus splash biar ga nge-stuck
        FlutterNativeSplash.remove();
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

    if (_isLoading && _profileData == null) {
      // Fallback UI (biasanya ga keliatan karena ketutupan splash screen native)
      return const Scaffold(
        backgroundColor: Color(0xFFF9F8F4),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    String fullName = _profileData?['full_name'] ?? "Mahasiswa";
    String nrp = _profileData?['nrp'] ?? "-";
    String? photoUrl = _profileData?['photo_url'];
    int kasTotalTarget = _profileData?['kas_total'] ?? 200000;

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
                  // --- HEADER SECTION (CLEAN VERSION) ---
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      HeaderSection(
                        fullName: displayName,
                        nrp: nrp,
                        greeting: _getGreeting(),
                        photoUrl: photoUrl,
                      ),

                      // CARD KAS
                      Positioned(
                        bottom: -60,
                        left: 24,
                        right: 24,
                        child: _isLoadingKas
                            ? Container(
                                height: 100,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            : FinanceCard(
                                paidAmount: _myTotalKasPaid,
                                totalAmount: kasTotalTarget,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const KasScreen(),
                                  ),
                                ).then((_) => _refreshData()),
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
                        MenuButton(
                          icon: Icons.assignment,
                          label: "Tugas",
                          color: primaryBlue,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  TugasScreen(isReadOnly: _userRole != 'admin'),
                            ),
                          ).then((_) => _refreshData()),
                        ),
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

                  // JUDUL JADWAL
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Jadwal Hari ini",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // JADWAL LIST (MODERN BLUE STYLE)
                  if (_todaysSchedule.isEmpty)
                    _buildEmptyScheduleState()
                  else
                    _buildModernScheduleList(_todaysSchedule, primaryBlue),

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
                                builder: (context) => TugasScreen(
                                  isReadOnly: _userRole != 'admin',
                                ),
                              ),
                            ).then((_) => _refreshData());
                          },
                          child: const Text(
                            "Lihat Semua",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
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

  Widget _buildModernScheduleList(
    List<Map<String, dynamic>> schedules,
    Color primaryBlue,
  ) {
    return SizedBox(
      height: 170,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        scrollDirection: Axis.horizontal,
        itemCount: schedules.length,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final schedule = schedules[index];
          final isReplacement = schedule['is_replacement'] == true;

          Color cardColor = isReplacement
              ? const Color(0xFFFF9800)
              : primaryBlue;

          return Container(
            width: 300,
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: cardColor.withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                // HIASAN
                Positioned(
                  top: -20,
                  right: -20,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  bottom: -30,
                  left: -10,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                // KONTEN
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Header Card (Waktu)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.access_time_rounded,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "${_formatTime(schedule['time_start'])} - ${_formatTime(schedule['time_end'])}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Badge Tipe
                          if (isReplacement || schedule['type'] == 'Praktek')
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isReplacement ? "PENGGANTI" : "PRAKTEK",
                                style: TextStyle(
                                  color: cardColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),

                      // Nama Matkul
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            schedule['matkul'],
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            schedule['lecturer'] ?? "Dosen Pengampu",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),

                      // Lokasi
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 16,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              schedule['room'],
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

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
