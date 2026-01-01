import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'add_jadwal_screen.dart'; // Jangan lupa import ini

class JadwalScreen extends StatefulWidget {
  const JadwalScreen({super.key});

  @override
  State<JadwalScreen> createState() => _JadwalScreenState();
}

class _JadwalScreenState extends State<JadwalScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;

  int _selectedDay = DateTime.now().weekday > 6 ? 1 : DateTime.now().weekday;

  // Kita pisah list-nya
  List<Map<String, dynamic>> _mainSchedules = [];
  List<Map<String, dynamic>> _replacementSchedules = [];

  @override
  void initState() {
    super.initState();
    _fetchSchedules();
  }

  Future<void> _fetchSchedules() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .from('schedules')
          .select()
          .eq('day', _selectedDay)
          .order('time_start', ascending: true);

      final data = List<Map<String, dynamic>>.from(response);

      if (mounted) {
        setState(() {
          // PISAHKAN DATA BERDASARKAN 'is_replacement'
          _replacementSchedules = data
              .where((item) => item['is_replacement'] == true)
              .toList();
          _mainSchedules = data
              .where((item) => item['is_replacement'] != true)
              .toList(); // Default false/null
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onDaySelected(int day) {
    setState(() => _selectedDay = day);
    _fetchSchedules();
  }

  String _formatTime(String timeStr) {
    try {
      final parts = timeStr.split(':');
      return "${parts[0]}:${parts[1]}";
    } catch (e) {
      return timeStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F8F4),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Jadwal Kuliah",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final res = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddJadwalScreen()),
          );
          if (res == true) _fetchSchedules();
        },
        backgroundColor: Colors.blueAccent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Tambah Jadwal",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),

      body: Column(
        children: [
          // 1. SELECTOR HARI
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: Row(
              children: [
                _buildDayChip(1, "Senin"),
                _buildDayChip(2, "Selasa"),
                _buildDayChip(3, "Rabu"),
                _buildDayChip(4, "Kamis"),
                _buildDayChip(5, "Jumat"),
                _buildDayChip(6, "Sabtu"),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // 2. ISI KONTEN (PENGGANTI & UTAMA)
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : (_mainSchedules.isEmpty && _replacementSchedules.isEmpty)
                ? _buildEmptyState()
                : ListView(
                    padding: const EdgeInsets.fromLTRB(
                      24,
                      0,
                      24,
                      80,
                    ), // Bottom padding buat FAB
                    children: [
                      // --- BAGIAN KELAS PENGGANTI ---
                      if (_replacementSchedules.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.orange,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                "Kelas Pengganti / Tambahan",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ..._replacementSchedules.map(
                          (item) =>
                              _buildScheduleCard(item, isReplacement: true),
                        ),
                        const SizedBox(height: 24), // Jarak ke jadwal utama
                      ],

                      // --- BAGIAN JADWAL UTAMA ---
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Text(
                          "Jadwal Utama",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ),

                      if (_mainSchedules.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Text(
                            "Tidak ada jadwal utama hari ini.",
                            style: TextStyle(
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        )
                      else
                        ..._mainSchedules.map(
                          (item) =>
                              _buildScheduleCard(item, isReplacement: false),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(
    Map<String, dynamic> item, {
    required bool isReplacement,
  }) {
    // Styling Card: Kalau pengganti, border orange. Kalau normal, sesuai tipe (Praktek/Teori)
    final isPraktek = item['type'] == 'Praktek';

    // Warna Card
    Color cardColor;
    if (isReplacement) {
      cardColor = Colors.orange.shade50; // Agak orange dikit
    } else {
      cardColor = isPraktek ? const Color(0xFF7B94FF) : Colors.white;
    }

    // Warna Text
    Color textColor;
    if (isReplacement) {
      textColor = Colors.brown.shade800;
    } else {
      textColor = isPraktek ? Colors.white : Colors.black;
    }

    Color subColor = isReplacement
        ? Colors.brown.shade400
        : (isPraktek ? Colors.white70 : Colors.grey);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: isReplacement
            ? Border.all(color: Colors.orange.shade200)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // JAM (KIRI)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _formatTime(item['time_start']),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              Text(
                _formatTime(item['time_end']),
                style: TextStyle(fontSize: 14, color: subColor),
              ),
            ],
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            height: 40,
            width: 1,
            color: subColor.withOpacity(0.3),
          ),
          // DETAIL (KANAN)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isReplacement
                        ? Colors.white54
                        : (isPraktek ? Colors.white24 : Colors.grey.shade100),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isReplacement ? "PENGGANTI" : (item['type'] ?? 'Teori'),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item['matkul'],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: subColor),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        "${item['room']} • ${item['lecturer']}",
                        style: TextStyle(fontSize: 12, color: subColor),
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
  }

  Widget _buildDayChip(int dayIndex, String label) {
    bool isSelected = _selectedDay == dayIndex;
    return GestureDetector(
      onTap: () => _onDaySelected(dayIndex),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4C6EF5) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF4C6EF5) : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.weekend, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            "Tidak ada jadwal kuliah",
            style: TextStyle(color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}
