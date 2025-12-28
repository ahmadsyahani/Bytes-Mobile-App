import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class JadwalScreen extends StatefulWidget {
  const JadwalScreen({super.key});

  @override
  State<JadwalScreen> createState() => _JadwalScreenState();
}

class _JadwalScreenState extends State<JadwalScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;

  // 1 = Senin, ..., 5 = Jumat
  int _selectedDay = DateTime.now().weekday > 5 ? 1 : DateTime.now().weekday;

  List<Map<String, dynamic>> _schedules = [];

  @override
  void initState() {
    super.initState();
    _fetchSchedules();
  }

  // --- FETCH DATA SESUAI HARI YANG DIPILIH ---
  Future<void> _fetchSchedules() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .from('schedules')
          .select()
          .eq('day', _selectedDay) // Filter by Hari
          .order('time_start', ascending: true);

      if (mounted) {
        setState(() {
          _schedules = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onDaySelected(int day) {
    setState(() {
      _selectedDay = day;
    });
    _fetchSchedules();
  }

  // Helper konversi "10:00:00" jadi "10:00"
  String _formatTime(String timeStr) {
    try {
      // Supabase ngasih format HH:mm:ss
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
      body: Column(
        children: [
          // 1. SELECTOR HARI (Horizontal Scroll)
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

          // 2. LIST JADWAL
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _schedules.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                    itemCount: _schedules.length,
                    itemBuilder: (context, index) {
                      final item = _schedules[index];
                      // Tentukan warna berdasarkan tipe
                      final isPraktek = item['type'] == 'Praktek';
                      final cardColor = isPraktek
                          ? const Color(0xFF7B94FF)
                          : Colors.white;
                      final textColor = isPraktek ? Colors.white : Colors.black;
                      final subColor = isPraktek ? Colors.white70 : Colors.grey;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(24),
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
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: subColor,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              height: 40,
                              width: 1,
                              color: subColor.withOpacity(0.3),
                            ),
                            // DETAIL (KANAN)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Label Tipe (Kecil)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isPraktek
                                          ? Colors.white24
                                          : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      item['type'] ?? 'Teori',
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
                                      Icon(
                                        Icons.location_on,
                                        size: 14,
                                        color: subColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        "${item['room']} • ${item['lecturer']}",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: subColor,
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
