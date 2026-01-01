import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LecturerScreen extends StatefulWidget {
  const LecturerScreen({super.key});

  @override
  State<LecturerScreen> createState() => _LecturerScreenState();
}

class _LecturerScreenState extends State<LecturerScreen> {
  final _supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  List<Map<String, dynamic>> _allLecturers = [];
  List<Map<String, dynamic>> _filteredLecturers = [];

  @override
  void initState() {
    super.initState();
    _fetchLecturers();
  }

  // --- AMBIL DATA DARI SUPABASE ---
  Future<void> _fetchLecturers() async {
    try {
      final response = await _supabase
          .from('lecturers')
          .select()
          .order('name', ascending: true);

      if (mounted) {
        setState(() {
          _allLecturers = List<Map<String, dynamic>>.from(response);
          _filteredLecturers = _allLecturers;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetch dosen: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- FILTER PENCARIAN ---
  void _runFilter(String keyword) {
    List<Map<String, dynamic>> results = [];
    if (keyword.isEmpty) {
      results = _allLecturers;
    } else {
      results = _allLecturers.where((item) {
        final name = (item['name'] ?? '').toLowerCase();
        final matkul = (item['matkul'] ?? '').toLowerCase();
        final room = (item['room'] ?? '').toLowerCase();
        final search = keyword.toLowerCase();
        return name.contains(search) ||
            matkul.contains(search) ||
            room.contains(search);
      }).toList();
    }
    setState(() => _filteredLecturers = results);
  }

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
          "Daftar Dosen",
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
          // SEARCH BAR
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
                  hintText: "Cari dosen, matkul, ruangan...",
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: Icon(Icons.search, color: primaryBlue),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),

          // LIST DOSEN
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredLecturers.isEmpty
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
                          "Dosen tidak ditemukan",
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                    itemCount: _filteredLecturers.length,
                    itemBuilder: (context, index) {
                      return _buildModernLecturerCard(
                        _filteredLecturers[index],
                        primaryBlue,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET KARTU DOSEN ---
  Widget _buildModernLecturerCard(
    Map<String, dynamic> data,
    Color primaryBlue,
  ) {
    // Ambil data dengan aman (kasih default kalau null)
    final name = data['name'] ?? 'Tanpa Nama';
    final nip = data['nip'] ?? '-';
    final matkul = data['matkul'] ?? 'Umum';
    final room = data['room'] ?? '-';
    final gender = data['gender'] ?? 'L';
    final photoUrl = data['photo']; // Bisa null

    Color badgeBg = const Color(0xFFE3F2FD);
    Color badgeText = const Color(0xFF1565C0);

    if (gender == 'P') {
      badgeBg = const Color(0xFFFCE4EC);
      badgeText = const Color(0xFFC2185B);
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // FOTO DOSEN
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade200, width: 2),
                  color: Colors.grey.shade100, // Background kalau ga ada foto
                  image: photoUrl != null && photoUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(photoUrl),
                          fit: BoxFit.cover,
                          onError: (e, s) {}, // Handle error silent
                        )
                      : null,
                ),
                // Fallback kalau foto null: Tampilkan Inisial
                child: (photoUrl == null || photoUrl.isEmpty)
                    ? Center(
                        child: Text(
                          name.substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: primaryBlue,
                          ),
                        ),
                      )
                    : null,
              ),

              const SizedBox(width: 16),

              // INFO TEXT
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
                      maxLines: 2,
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
                        "NIP: $nip",
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Chat Button
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryBlue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.chat_bubble_outline,
                  color: primaryBlue,
                  size: 20,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Divider(height: 1, color: Colors.grey[100]),
          const SizedBox(height: 12),

          // INFO BAWAH
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.book, size: 16, color: Colors.grey[400]),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        matkul,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 14,
                      color: Color(0xFFEF6C00),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      room,
                      style: const TextStyle(
                        color: Color(0xFFEF6C00),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
