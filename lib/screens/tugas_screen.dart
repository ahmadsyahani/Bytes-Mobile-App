import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'add_tugas_screen.dart';

class TugasScreen extends StatefulWidget {
  // Tambah parameter ini
  final bool isReadOnly;

  // Default isReadOnly = false (berarti bisa edit) kalau tidak diisi
  const TugasScreen({super.key, this.isReadOnly = false});

  @override
  State<TugasScreen> createState() => _TugasScreenState();
}

class _TugasScreenState extends State<TugasScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;

  List<Map<String, dynamic>> _allTasks = [];
  List<Map<String, dynamic>> _filteredTasks = [];

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  Future<void> _fetchTasks() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .from('tasks')
          .select()
          .gte(
            'deadline',
            DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
          )
          .order('deadline', ascending: true);

      if (mounted) {
        setState(() {
          _allTasks = List<Map<String, dynamic>>.from(response);
          _filteredTasks = _allTasks;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _runFilter(String keyword) {
    List<Map<String, dynamic>> results = [];
    if (keyword.isEmpty) {
      results = _allTasks;
    } else {
      results = _allTasks
          .where(
            (task) =>
                task['matkul'].toLowerCase().contains(keyword.toLowerCase()) ||
                task['title'].toLowerCase().contains(keyword.toLowerCase()),
          )
          .toList();
    }
    setState(() {
      _filteredTasks = results;
    });
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
        'bg': Colors.red.shade50,
      };
    if (difference == 1)
      return {'text': 'BESOK', 'color': Colors.red, 'bg': Colors.red.shade50};
    if (difference < 3)
      return {
        'text': 'H-$difference',
        'color': Colors.red,
        'bg': Colors.red.shade50,
      };
    if (difference < 7)
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

  Future<void> _deleteTask(String id) async {
    // Safety check tambahan
    if (widget.isReadOnly) return;

    await _supabase.from('tasks').delete().eq('id', id);
    _fetchTasks(); // Refresh
    if (mounted)
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Tugas dihapus")));
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

      // --- LOGIC FAB: HILANG KALAU BUKAN ADMIN ---
      floatingActionButton: widget.isReadOnly
          ? null
          : FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddTugasScreen(),
                  ),
                );
                if (result == true) _fetchTasks();
              },
              backgroundColor: const Color(0xFF4C6EF5),
              label: const Text(
                "Tambah Tugas",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              icon: const Icon(Icons.add, color: Colors.white),
            ),

      body: Column(
        children: [
          // SEARCH BAR
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _runFilter,
                decoration: const InputDecoration(
                  hintText: "Cari Mata Kuliah...",
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),

          // LIST TUGAS
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredTasks.isEmpty
                ? Center(
                    child: Text(
                      "Tidak ada tugas ditemukan",
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(24, 10, 24, 80),
                    itemCount: _filteredTasks.length,
                    itemBuilder: (context, index) {
                      final task = _filteredTasks[index];
                      final deadlineInfo = _getDeadlineInfo(task['deadline']);

                      final dateObj = DateTime.parse(task['deadline']);
                      final dayStr = dateObj.day.toString();
                      final monthStr = DateFormat(
                        'MMM',
                        'id',
                      ).format(dateObj).toUpperCase();

                      return GestureDetector(
                        // --- LOGIC ON TAP: ADMIN ONLY ---
                        onTap: widget.isReadOnly
                            ? null // Kalau bukan admin, gak bisa diklik
                            : () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        AddTugasScreen(taskToEdit: task),
                                  ),
                                );
                                if (result == true) _fetchTasks();
                              },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(
                              24,
                            ), // Lebih rounded biar modern
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // 1. TANGGAL (KIRI)
                              Container(
                                width: 60,
                                height: 75, // Agak tinggi dikit
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F6FA),
                                  borderRadius: BorderRadius.circular(18),
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

                              // 2. KONTEN (TENGAH)
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Chip Tipe (Kecil di atas judul)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: task['type'] == 'Kelompok'
                                            ? Colors.purple.shade50
                                            : Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(8),
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
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),

                              // 3. KOLOM KANAN (DEADLINE & EDIT)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  // Indikator H- (Di Atas)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: deadlineInfo['bg'],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      deadlineInfo['text'],
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: deadlineInfo['color'],
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  if (!widget.isReadOnly)
                                    GestureDetector(
                                      onTap: () async {
                                        final result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                AddTugasScreen(
                                                  taskToEdit: task,
                                                ),
                                          ),
                                        );
                                        if (result == true) _fetchTasks();
                                      },
                                      child: Container(
                                        width: 40,
                                        height: 30,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ), // Squircle
                                          border: Border.all(
                                            color: Colors.grey.shade200,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.grey.shade100,
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.edit_note_rounded, // Icon Pena
                                          size: 18,
                                          color: Color(0xFF4C6EF5),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
