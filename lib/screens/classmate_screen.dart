import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ClassmateScreen extends StatefulWidget {
  const ClassmateScreen({super.key});

  @override
  State<ClassmateScreen> createState() => _ClassmateScreenState();
}

class _ClassmateScreenState extends State<ClassmateScreen> {
  final _supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _allStudents = [];
  List<Map<String, dynamic>> _filteredStudents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchClassmates();
  }

  // --- LOGIC DATABASE (TETAP SAMA) ---
  Future<void> _fetchClassmates() async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .order('full_name', ascending: true);

      setState(() {
        _allStudents = List<Map<String, dynamic>>.from(response);
        _filteredStudents = _allStudents;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching classmates: $e");
      setState(() => _isLoading = false);
    }
  }

  void _runFilter(String keyword) {
    List<Map<String, dynamic>> results = [];
    if (keyword.isEmpty) {
      results = _allStudents;
    } else {
      results = _allStudents.where((user) {
        final name = user['full_name'].toString().toLowerCase();
        final nrp = user['nrp'].toString().toLowerCase();
        final search = keyword.toLowerCase();
        return name.contains(search) || nrp.contains(search);
      }).toList();
    }
    setState(() => _filteredStudents = results);
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return "-";
    try {
      final date = DateTime.parse(dateString);
      const months = [
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
      return "${date.day} ${months[date.month - 1]} ${date.year}";
    } catch (e) {
      return dateString;
    }
  }

  // --- UI BARU ---
  @override
  Widget build(BuildContext context) {
    final Color primaryBlue = const Color(0xFF4C6EF5);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F8F4),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.black87, size: 28),
        ),
        title: const Text(
          "Teman Sekelas",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // SEARCH BAR (Modern Look)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 20),
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
                decoration: InputDecoration(
                  hintText: "Cari nama atau NRP...",
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: Icon(Icons.search, color: primaryBlue),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),

          // JUMLAH MEMBER
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Text(
                  "Total Siswa",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "${_filteredStudents.length}",
                    style: TextStyle(
                      color: primaryBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // LIST MEMBER
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: primaryBlue))
                : _filteredStudents.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 80,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Tidak ditemukan",
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(24, 10, 24, 40),
                    itemCount: _filteredStudents.length,
                    itemBuilder: (context, index) {
                      final student = _filteredStudents[index];
                      return _buildModernStudentCard(student, primaryBlue);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // --- KARTU SISWA MODERN ---
  Widget _buildModernStudentCard(
    Map<String, dynamic> student,
    Color primaryBlue,
  ) {
    final String name = student['full_name'] ?? "No Name";
    final String nrp = student['nrp'] ?? "-";
    final String? photoUrl = student['photo_url'];
    final String birthDate = _formatDate(student['birth_date']);
    final String gender = student['gender'] ?? "-";

    // Setup Warna & Icon Gender
    Color genderBgColor = Colors.grey.shade100;
    Color genderTextColor = Colors.grey;
    IconData genderIcon = Icons.help_outline;
    String genderLabel = "-";

    if (gender == 'L') {
      genderBgColor = const Color(0xFFE3F2FD); // Biru Muda
      genderTextColor = const Color(0xFF1E88E5); // Biru Tua
      genderIcon = Icons.male;
      genderLabel = "Laki-laki";
    } else if (gender == 'P') {
      genderBgColor = const Color(0xFFFCE4EC); // Pink Muda
      genderTextColor = const Color(0xFFD81B60); // Pink Tua
      genderIcon = Icons.female;
      genderLabel = "Perempuan";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // ROW ATAS: FOTO & NAMA
          Row(
            children: [
              // Foto dengan Border Tipis
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade200, width: 2),
                ),
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.grey[100],
                  backgroundImage: photoUrl != null
                      ? NetworkImage(photoUrl)
                      : null,
                  child: photoUrl == null
                      ? Icon(Icons.person, color: Colors.grey[400], size: 28)
                      : null,
                ),
              ),
              const SizedBox(width: 16),

              // Nama & NRP
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "NRP: $nrp",
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          // GARIS PEMISAH TIPIS
          Divider(color: Colors.grey[100], height: 1),
          const SizedBox(height: 12),

          // ROW BAWAH: TAG GENDER & TANGGAL LAHIR
          Row(
            children: [
              // Gender Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: genderBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(genderIcon, size: 14, color: genderTextColor),
                    const SizedBox(width: 4),
                    Text(
                      genderLabel,
                      style: TextStyle(
                        color: genderTextColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(), // Dorong Tgl Lahir ke Kanan
              // Tanggal Lahir
              Row(
                children: [
                  Icon(Icons.cake_outlined, size: 16, color: Colors.blue[600]),
                  const SizedBox(width: 6),
                  Text(
                    birthDate,
                    style: TextStyle(
                      color: Colors.blue[600],
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
