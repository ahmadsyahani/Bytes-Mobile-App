import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class ClassmateScreen extends StatefulWidget {
  const ClassmateScreen({super.key});

  @override
  State<ClassmateScreen> createState() => _ClassmateScreenState();
}

class _ClassmateScreenState extends State<ClassmateScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;

  List<Map<String, dynamic>> _allStudents = [];
  List<Map<String, dynamic>> _filteredStudents = [];

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .order('full_name', ascending: true);

      if (mounted) {
        setState(() {
          _allStudents = List<Map<String, dynamic>>.from(response);
          _filteredStudents = _allStudents;
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
      results = _allStudents;
    } else {
      results = _allStudents
          .where(
            (user) =>
                user['full_name'].toLowerCase().contains(
                  keyword.toLowerCase(),
                ) ||
                (user['nrp'] ?? '').toString().contains(keyword),
          )
          .toList();
    }
    setState(() {
      _filteredStudents = results;
    });
  }

  Future<void> _launchWA(String? phone) async {
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Nomor HP belum diisi")));
      return;
    }

    String formattedPhone = phone;
    if (phone.startsWith('0')) {
      formattedPhone = '62${phone.substring(1)}';
    }

    final url = Uri.parse("https://wa.me/$formattedPhone");
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Gagal membuka WhatsApp")));
      }
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
          "Teman Sekelas",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // 1. SEARCH BAR
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
                  hintText: "Cari Nama atau NRP...",
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),

          // 2. TOTAL TEMAN
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                Text(
                  "${_filteredStudents.length} Mahasiswa",
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // 3. LIST MAHASISWA
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredStudents.isEmpty
                ? Center(
                    child: Text(
                      "Tidak ditemukan",
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: _filteredStudents.length,
                    itemBuilder: (context, index) {
                      final student = _filteredStudents[index];

                      // Data Extraction
                      final name = student['full_name'] ?? "No Name";
                      final nrp = student['nrp'] ?? "-";
                      final photoUrl = student['photo_url'];
                      final initial = name.isNotEmpty
                          ? name[0].toUpperCase()
                          : "?";

                      final gender = student['gender'] ?? 'Laki-laki';
                      final isFemale =
                          gender.toString().contains('Perempuan') ||
                          gender.toString().contains('Wanita');

                      String birthday = "-";
                      if (student['birth_date'] != null) {
                        try {
                          final date = DateTime.parse(student['birth_date']);
                          birthday = DateFormat(
                            'd MMM yyyy',
                            'id',
                          ).format(date);
                        } catch (e) {
                          birthday = student['birth_date'];
                        }
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(
                          16,
                        ), // Padding diperbesar biar lega
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(
                            20,
                          ), // Lebih rounded
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.start, // Align top
                          children: [
                            // --- AVATAR ---
                            Container(
                              width: 55,
                              height: 55,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE3F2FD),
                                borderRadius: BorderRadius.circular(
                                  16,
                                ), // Squircle
                                image: photoUrl != null
                                    ? DecorationImage(
                                        image: NetworkImage(photoUrl),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: photoUrl == null
                                  ? Center(
                                      child: Text(
                                        initial,
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF4C6EF5),
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 16),

                            // --- CONTENT TENGAH ---
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 1. NAMA
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.black87,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),

                                  // 2. NRP BOX (YANG DIMINTA)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFFEef2FF,
                                      ), // Biru sangat muda
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: const Color(0xFFDAE0F2),
                                      ), // Border tipis
                                    ),
                                    child: Text(
                                      nrp,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF4C6EF5), // Teks Biru
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 8),

                                  // 3. ROW INFO (Gender & Birthday)
                                  Row(
                                    children: [
                                      // Gender
                                      Icon(
                                        isFemale
                                            ? Icons.female_rounded
                                            : Icons.male_rounded,
                                        size: 14,
                                        color: isFemale
                                            ? Colors.pinkAccent
                                            : Colors.blue,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isFemale ? "Perempuan" : "Laki-Laki",
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),

                                      // Divider Kecil
                                      Container(
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                        ),
                                        width: 1,
                                        height: 10,
                                        color: Colors.grey.shade300,
                                      ),

                                      // Birthday
                                      const Icon(
                                        Icons.cake_rounded,
                                        size: 13,
                                        color: Colors.orangeAccent,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        birthday,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // --- TOMBOL WA (KANAN) ---
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: IconButton(
                                onPressed: () => _launchWA(student['phone']),
                                icon: const Icon(
                                  Icons.chat_bubble_rounded,
                                  size: 20,
                                ),
                                color: Colors.white,
                                style: IconButton.styleFrom(
                                  backgroundColor: const Color(
                                    0xFF25D366,
                                  ), // Warna Resmi WA
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.all(10),
                                ),
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
}
