import 'package:flutter/material.dart';

class LecturerScreen extends StatefulWidget {
  const LecturerScreen({super.key});

  @override
  State<LecturerScreen> createState() => _LecturerScreenState();
}

class _LecturerScreenState extends State<LecturerScreen> {
  final TextEditingController _searchController = TextEditingController();

  // DATA DUMMY DOSEN (Tambah field 'room')
  final List<Map<String, String>> _allLecturers = [
    {
      "name": "Dr. Ir. Budi Santoso, M.Kom",
      "nip": "19820101 200501 1 001",
      "matkul": "Logika & Algoritma",
      "gender": "L",
      "photo": "https://i.pravatar.cc/150?u=budi",
      "room": "Ruang Dosen 1 (Gedung A)",
    },
    {
      "name": "Siti Aminah, S.T., M.T.",
      "nip": "19850315 200812 2 003",
      "matkul": "Basis Data",
      "gender": "P",
      "photo": "https://i.pravatar.cc/150?u=siti",
      "room": "Lab Database",
    },
    {
      "name": "Pak Dika, S.Kom",
      "nip": "19900520 201504 1 005",
      "matkul": "Workshop Desain Web",
      "gender": "L",
      "photo": "https://i.pravatar.cc/150?u=dika",
      "room": "Lab Multimedia",
    },
    {
      "name": "Prof. Ambasink",
      "nip": "19750817 199903 1 002",
      "matkul": "Konsep Pemrograman",
      "gender": "L",
      "photo": "https://i.pravatar.cc/150?u=amba",
      "room": "Ruang Kajur",
    },
    {
      "name": "Ibu Ratna Sari, M.Pd.",
      "nip": "19881110 201001 2 004",
      "matkul": "Bahasa Indonesia",
      "gender": "P",
      "photo": "https://i.pravatar.cc/150?u=ratna",
      "room": "Ruang Dosen Umum",
    },
  ];

  List<Map<String, String>> _filteredLecturers = [];

  @override
  void initState() {
    super.initState();
    _filteredLecturers = _allLecturers;
  }

  void _runFilter(String keyword) {
    List<Map<String, String>> results = [];
    if (keyword.isEmpty) {
      results = _allLecturers;
    } else {
      results = _allLecturers.where((item) {
        final name = item['name']!.toLowerCase();
        final matkul = item['matkul']!.toLowerCase();
        final room = item['room']!.toLowerCase();
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
          // SEARCH BAR MODERN
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
            child: _filteredLecturers.isEmpty
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

  // --- WIDGET KARTU DOSEN MODERN ---
  Widget _buildModernLecturerCard(Map<String, String> data, Color primaryBlue) {
    Color badgeBg = const Color(0xFFE3F2FD); // Default Biru Muda
    Color badgeText = const Color(0xFF1565C0); // Default Biru Tua

    // Warna Badge beda buat Dosen Cewek (Opsional)
    if (data['gender'] == 'P') {
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
              // FOTO DOSEN (FIX BUG)
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade200, width: 2),
                  image: DecorationImage(
                    image: NetworkImage(data['photo']!),
                    fit: BoxFit.cover,
                    // Error Handler: Kalau gambar gagal load, pake placeholder
                    onError: (exception, stackTrace) {
                      // Ini cuma handler internal flutter, visualnya nanti kosong/abu
                    },
                  ),
                ),
                // Fallback visual kalau gambar error (Opsional, bisa pakai Stack kalau mau expert)
              ),

              const SizedBox(width: 16),

              // INFO TEXT
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nama Dosen
                    Text(
                      data['name']!,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // NIP
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
                        "NIP: ${data['nip']}",
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

              // Chat Button Kecil
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
          // GARIS PEMISAH
          Divider(height: 1, color: Colors.grey[100]),
          const SizedBox(height: 12),

          // INFO BAWAH: MATKUL & RUANGAN
          Row(
            children: [
              // Badge Matkul
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.book, size: 16, color: Colors.grey[400]),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        data['matkul']!,
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

              // Lokasi Ruangan
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0), // Orange muda
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 14,
                      color: Color(0xFFEF6C00),
                    ), // Orange Tua
                    const SizedBox(width: 4),
                    Text(
                      data['room']!, // Ruangan
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
