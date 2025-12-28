import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'add_tugas_screen.dart'; // Import halaman tambah tadi

class TugasScreen extends StatefulWidget {
  const TugasScreen({super.key});

  @override
  State<TugasScreen> createState() => _TugasScreenState();
}

class _TugasScreenState extends State<TugasScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _tasks = [];

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  Future<void> _fetchTasks() async {
    setState(() => _isLoading = true);
    try {
      // Ambil tugas yang deadline-nya BELUM LEWAT (Hari ini atau masa depan)
      final response = await _supabase
          .from('tasks')
          .select()
          .gte('deadline', DateTime.now().toIso8601String())
          .order('deadline', ascending: true); // Urutkan dari yang paling mepet

      if (mounted) {
        setState(() {
          _tasks = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // LOGIC WARNA & TEKS DEADLINE
  Map<String, dynamic> _getDeadlineInfo(String dateString) {
    final deadline = DateTime.parse(dateString);
    final now = DateTime.now();
    // Reset jam menit detik biar hitungan hari akurat
    final dDate = DateTime(deadline.year, deadline.month, deadline.day);
    final nDate = DateTime(now.year, now.month, now.day);

    final difference = dDate.difference(nDate).inDays;

    if (difference == 0) {
      return {
        'text': 'HARI INI',
        'color': Colors.red,
        'bg': Colors.red.shade50,
      };
    } else if (difference == 1) {
      return {'text': 'BESOK', 'color': Colors.red, 'bg': Colors.red.shade50};
    } else if (difference < 3) {
      return {
        'text': 'H-$difference',
        'color': Colors.red,
        'bg': Colors.red.shade50,
      };
    } else if (difference < 7) {
      return {
        'text': 'H-$difference',
        'color': Colors.orange,
        'bg': Colors.orange.shade50,
      };
    } else {
      return {
        'text': 'H-$difference',
        'color': const Color(0xFF4C6EF5),
        'bg': const Color(0xFFE3F2FD),
      };
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
          "Daftar Tugas",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddTugasScreen()),
          );
          if (result == true) _fetchTasks(); // Refresh kalau ada data baru
        },
        backgroundColor: const Color(0xFF4C6EF5),
        label: const Text(
          "Tambah Tugas",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        icon: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tasks.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _fetchTasks,
              child: ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: _tasks.length,
                itemBuilder: (context, index) {
                  final task = _tasks[index];
                  final deadlineInfo = _getDeadlineInfo(task['deadline']);

                  // Parse tanggal buat tampilan "12 OKT"
                  final dateObj = DateTime.parse(task['deadline']);
                  final dayStr = dateObj.day.toString();
                  final monthStr = DateFormat(
                    'MMM',
                    'id_ID',
                  ).format(dateObj).toUpperCase();

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // KOTAK TANGGAL KIRI
                        Container(
                          width: 60,
                          height: 70,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F6FA),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                dayStr,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                monthStr,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),

                        // KONTEN TENGAH
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // CHIP TIPE TUGAS
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: task['type'] == 'Kelompok'
                                      ? Colors.purple.shade50
                                      : Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  task['type'],
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: task['type'] == 'Kelompok'
                                        ? Colors.purple
                                        : Colors.blue,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                task['title'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                task['matkul'],
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // INDIKATOR H- MINUS (KANAN)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: deadlineInfo['bg'],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            deadlineInfo['text'],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: deadlineInfo['color'],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.task_alt, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            "Hore! Tidak ada tugas",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const Text(
            "Santai dulu gak sih? ☕",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
