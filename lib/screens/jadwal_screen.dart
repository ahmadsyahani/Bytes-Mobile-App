import 'package:flutter/material.dart';

class JadwalScreen extends StatefulWidget {
  const JadwalScreen({super.key});

  @override
  State<JadwalScreen> createState() => _JadwalScreenState();
}

class _JadwalScreenState extends State<JadwalScreen> {
  int selectedIndex = 0; // Index hari yang dipilih (0 = Hari ini)

  // Generate 14 hari ke depan mulai dari sekarang
  final List<DateTime> dates = List.generate(
    14,
    (index) => DateTime.now().add(Duration(days: index)),
  );

  // Helper simpel buat nama hari (biar gak perlu plugin intl)
  String _getDayName(int weekday) {
    const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    // DateTime weekday itu 1-7, array kita 0-6
    return days[weekday - 1];
  }

  // Helper format subtitle tanggal (contoh: Senin, 28 Okt)
  String _getFullDateString(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    String dayName = _getDayName(date.weekday);
    // Ubah nama hari pendek jadi panjang dikit buat subtitle header
    switch (dayName) {
      case 'Sen':
        dayName = "Senin";
        break;
      case 'Sel':
        dayName = "Selasa";
        break;
      case 'Rab':
        dayName = "Rabu";
        break;
      case 'Kam':
        dayName = "Kamis";
        break;
      case 'Jum':
        dayName = "Jumat";
        break;
      case 'Sab':
        dayName = "Sabtu";
        break;
      case 'Min':
        dayName = "Minggu";
        break;
    }
    return "$dayName, ${date.day} ${months[date.month - 1]}";
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryBlue = const Color(0xFF4C6EF5);
    final Color bgScreen = const Color(0xFFF9F8F4);

    return Scaffold(
      backgroundColor: bgScreen,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.black87, size: 28),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Jadwal Kuliah",
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            Text(
              _getFullDateString(
                dates[selectedIndex],
              ), // Tanggal Header Dinamis
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // --- DAY SELECTOR (SCROLLABLE / SLIDE) ---
            SizedBox(
              height: 80, // Tinggi area scroll
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                scrollDirection: Axis.horizontal, // KUNCI: Biar bisa di-slide
                itemCount: dates.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final date = dates[index];
                  return _buildPillDaySelector(
                    index,
                    _getDayName(date.weekday),
                    date.day.toString(),
                    primaryBlue,
                  );
                },
              ),
            ),

            const SizedBox(height: 25),

            // --- SCHEDULE LIST ---
            Expanded(child: _buildScheduleList(primaryBlue)),
          ],
        ),
      ),
    );
  }

  // Logic tampilan jadwal berdasarkan hari yang dipilih
  Widget _buildScheduleList(Color primaryBlue) {
    // CONTOH LOGIC SIMPEL:
    // Kalau index 0 (Hari ini) -> Tampilkan jadwal penuh
    // Kalau index lain -> Tampilkan jadwal beda/kosong (Buat demo slide)

    if (selectedIndex == 0) {
      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          _buildScheduleItemRedesigned(
            timeStart: "11:20",
            timeEnd: "13:50",
            title: "Agama",
            subtitle: "Keutamaan Sholat",
            lecturer: "Dr. SI Imoet",
            room: "B.203",
            isActive: true,
            primaryBlue: primaryBlue,
          ),
          _buildScheduleItemRedesigned(
            timeStart: "14:40",
            timeEnd: "16:20",
            title: "Dasar Sistem Komputer",
            subtitle: "Aljabar Boolean",
            lecturer: "Ir. Rusdi",
            room: "SAW 6.7",
            isActive: false,
            primaryBlue: primaryBlue,
          ),
          _buildScheduleItemRedesigned(
            timeStart: "16:30",
            timeEnd: "18:00",
            title: "Workshop Desain Web",
            subtitle: "Responsive Layout",
            lecturer: "Pak Dika",
            room: "Lab Kom 1",
            isActive: false,
            primaryBlue: primaryBlue,
            isLast: true,
          ),
          const SizedBox(height: 40),
        ],
      );
    } else if (selectedIndex == 1 || selectedIndex == 3) {
      // Contoh jadwal hari lain (Selasa/Kamis)
      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          _buildScheduleItemRedesigned(
            timeStart: "08:00",
            timeEnd: "10:00",
            title: "Matematika 1",
            subtitle: "Kalkulus Dasar",
            lecturer: "Bu Susi",
            room: "A.301",
            isActive: false,
            primaryBlue: primaryBlue,
            isLast: true,
          ),
        ],
      );
    } else {
      // Contoh Hari Libur/Kosong
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.holiday_village_rounded,
              size: 60,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              "Tidak ada jadwal",
              style: TextStyle(
                color: Colors.grey[500],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }
  }

  // --- WIDGET SELECTOR (PILL) ---
  Widget _buildPillDaySelector(
    int index,
    String day,
    String date,
    Color activeColor,
  ) {
    bool isSelected = selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => selectedIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        // Hapus margin di sini karena udah dihandle ListView.separated
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : Colors.grey.shade200,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              day,
              style: TextStyle(
                color: isSelected ? Colors.white.withOpacity(0.9) : Colors.grey,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              date,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET ITEM JADWAL (REDESIGNED) ---
  Widget _buildScheduleItemRedesigned({
    required String timeStart,
    required String timeEnd,
    required String title,
    required String subtitle,
    required String lecturer,
    required String room,
    required bool isActive,
    required Color primaryBlue,
    bool isLast = false,
  }) {
    const double indicatorSize = 18;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. KOLOM WAKTU
          SizedBox(
            width: 55,
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    timeStart,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: isActive ? primaryBlue : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeEnd,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. TIMELINE INDICATOR
          SizedBox(
            width: indicatorSize + 16,
            child: Column(
              children: [
                Container(
                  width: indicatorSize,
                  height: indicatorSize,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive ? primaryBlue : Colors.white,
                    border: Border.all(
                      color: isActive ? primaryBlue : Colors.grey.shade300,
                      width: isActive ? 4 : 2,
                    ),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: primaryBlue.withOpacity(0.4),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // 3. KARTU JADWAL
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                gradient: isActive
                    ? LinearGradient(
                        colors: [primaryBlue, const Color(0xFF6C88F7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isActive ? null : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: isActive
                    ? null
                    : Border.all(color: Colors.grey.shade200, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: isActive
                        ? primaryBlue.withOpacity(0.3)
                        : Colors.black.withOpacity(0.03),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isActive
                          ? Colors.white.withOpacity(0.9)
                          : Colors.grey[600],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _buildInfoChip(Icons.person_outline, lecturer, isActive),
                      const SizedBox(width: 16),
                      _buildInfoChip(
                        Icons.location_on_outlined,
                        room,
                        isActive,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, bool isActive) {
    final Color contentColor = isActive
        ? Colors.white.withOpacity(0.9)
        : Colors.grey[700]!;
    return Row(
      children: [
        Icon(icon, color: contentColor, size: 16),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: contentColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
