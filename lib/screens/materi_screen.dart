import 'dart:ui'; // Wajib buat efek Blur
import 'package:flutter/material.dart';

class MateriScreen extends StatefulWidget {
  const MateriScreen({super.key});

  @override
  State<MateriScreen> createState() => _MateriScreenState();
}

class _MateriScreenState extends State<MateriScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.85);
  final TextEditingController _searchController = TextEditingController();

  int _currentPage = 0;
  bool _isSearchActive = false;

  // STATE BARU: Menyimpan Matkul apa yang sedang dipilih (Null = Tampilkan Daftar Matkul)
  String? _selectedMatkul;

  // Data Master
  final List<Map<String, String>> _allMateri = [
    {
      "matkul": "Konsep Teknologi Informasi",
      "title": "Netiquette & IaC",
      "desc": "Pelajari etika internet dan dasar Infrastructure as Code.",
      "progress": "40%",
      "type": "PDF",
    },
    {
      "matkul": "Konsep Pemrograman",
      "title": "Struktur Data Dasar",
      "desc": "Memahami Array, Struct, dan Pointer dalam C.",
      "progress": "75%",
      "type": "Video",
    },
    {
      "matkul": "Logika & Algoritma",
      "title": "Flowchart & Pseudocode",
      "desc": "Dasar-dasar logika pemrograman visual.",
      "progress": "10%",
      "type": "PDF",
    },
    {
      "matkul": "Basis Data",
      "title": "Normalisasi Database",
      "desc": "Teknik normalisasi 1NF, 2NF, hingga 3NF.",
      "progress": "0%",
      "type": "Modul",
    },
    {
      "matkul": "Konsep Teknologi Informasi",
      "title": "Cloud Computing Basics",
      "desc": "Pengenalan AWS, Azure, dan Google Cloud.",
      "progress": "0%",
      "type": "Video",
    },
    {
      "matkul": "Agama",
      "title": "Etika Profesi",
      "desc": "Pentingnya etika dalam dunia kerja IT.",
      "progress": "100%",
      "type": "PDF",
    },
  ];

  // Helper: Ambil daftar Matkul yang unik dari data materi
  List<String> get _uniqueMatkuls =>
      _allMateri.map((e) => e['matkul']!).toSet().toList();

  // Helper: Ambil materi sesuai matkul yang dipilih
  List<Map<String, String>> get _materialsBySubject =>
      _allMateri.where((e) => e['matkul'] == _selectedMatkul).toList();

  // Hasil Filter Search
  List<Map<String, String>> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _searchResults = _allMateri;
  }

  void _runFilter(String keyword) {
    List<Map<String, String>> results = [];
    if (keyword.isEmpty) {
      results = _allMateri;
    } else {
      results = _allMateri.where((item) {
        final titleLower = item["title"]!.toLowerCase();
        final matkulLower = item["matkul"]!.toLowerCase();
        final searchLower = keyword.toLowerCase();
        return titleLower.contains(searchLower) ||
            matkulLower.contains(searchLower);
      }).toList();
    }
    setState(() => _searchResults = results);
  }

  // Handle Back Button Hardware (Android)
  Future<bool> _onWillPop() async {
    if (_selectedMatkul != null) {
      // Kalau lagi buka folder matkul, back-nya tutup folder dulu
      setState(() => _selectedMatkul = null);
      return false; // Jangan keluar app/screen
    }
    return true; // Keluar screen (pop)
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryBlue = const Color(0xFF4C6EF5);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F8F4),
        body: Stack(
          children: [
            // --- LAYER 1: KONTEN UTAMA ---
            Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  onPressed: () async {
                    if (await _onWillPop()) {
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                  icon: const Icon(
                    Icons.arrow_back,
                    size: 28,
                    color: Colors.black87,
                  ),
                ),
                title: Text(
                  _selectedMatkul != null
                      ? "Detail Materi"
                      : "Materi Kuliah", // Judul Dinamis
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                centerTitle: false,
                actions: [
                  IconButton(
                    onPressed: () => setState(() => _isSearchActive = true),
                    icon: const Icon(
                      Icons.search,
                      size: 28,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
              ),
              body: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // JIKA BELUM PILIH MATKUL (TAMPILAN AWAL)
                    if (_selectedMatkul == null) ...[
                      // 1. CAROUSEL HIGHLIGHT
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: const Text(
                          "Lanjutkan Belajar",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 220,
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: 3,
                          onPageChanged: (int index) =>
                              setState(() => _currentPage = index),
                          itemBuilder: (context, index) {
                            return _buildCarouselCard(
                              _allMateri[index],
                              index == _currentPage,
                            );
                          },
                        ),
                      ),
                      // Indikator
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          3,
                          (index) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: _currentPage == index ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _currentPage == index
                                  ? primaryBlue
                                  : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // 2. DAFTAR MATA KULIAH (FOLDER)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: const Text(
                          "Pilih Mata Kuliah",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: _uniqueMatkuls.length,
                        itemBuilder: (context, index) {
                          return _buildMatkulFolder(_uniqueMatkuls[index]);
                        },
                      ),
                    ]
                    // JIKA SUDAH PILIH MATKUL (TAMPILAN DETAIL)
                    else ...[
                      // Header Kecil info Matkul
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: primaryBlue.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: primaryBlue.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.library_books,
                                  color: primaryBlue,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Mata Kuliah",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      _selectedMatkul!,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          "Daftar Materi (${_materialsBySubject.length})",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // LIST MATERI SESUAI MATKUL
                      ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: _materialsBySubject.length,
                        itemBuilder: (context, index) {
                          return _buildListItem(_materialsBySubject[index]);
                        },
                      ),
                    ],

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            // --- LAYER 2: SEARCH OVERLAY (TETAP GLOBAL) ---
            if (_isSearchActive)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    setState(() => _isSearchActive = false);
                    FocusScope.of(context).unfocus();
                  },
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                    child: Container(
                      color: Colors.black.withOpacity(0.2),
                      child: Column(
                        children: [
                          const SizedBox(height: 60), // Spacer atas
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Material(
                              elevation: 10,
                              shadowColor: const Color(
                                0xFF4C6EF5,
                              ).withOpacity(0.3),
                              borderRadius: BorderRadius.circular(20),
                              child: TextField(
                                controller: _searchController,
                                autofocus: true,
                                onChanged: (value) => _runFilter(value),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                                decoration: InputDecoration(
                                  hintText: "Cari semua materi...",
                                  prefixIcon: const Icon(
                                    Icons.search,
                                    color: Color(0xFF4C6EF5),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                      _runFilter('');
                                    },
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),
                            ),
                          ),

                          // HASIL PENCARIAN
                          if (_searchController.text.isNotEmpty)
                            Expanded(
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 20,
                                ),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: ListView.builder(
                                  itemCount: _searchResults.length,
                                  itemBuilder: (context, index) {
                                    final item = _searchResults[index];
                                    return ListTile(
                                      leading: Icon(
                                        item['type'] == 'Video'
                                            ? Icons.play_circle_fill
                                            : Icons.description,
                                        color: item['type'] == 'Video'
                                            ? Colors.red
                                            : const Color(0xFF4C6EF5),
                                      ),
                                      title: Text(
                                        item['title']!,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Text(
                                        item['matkul']!,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      onTap: () {
                                        // Aksi kalau hasil search diklik (Opsional: Bisa buka file/detail)
                                        print("Buka ${item['title']}");
                                      },
                                    );
                                  },
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // WIDGET FOLDER MATKUL (Tampilan Awal)
  Widget _buildMatkulFolder(String matkulName) {
    // Hitung jumlah materi di matkul ini
    int count = _allMateri.where((e) => e['matkul'] == matkulName).length;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMatkul = matkulName;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF4C6EF5).withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(
                Icons.folder,
                color: Color(0xFF4C6EF5),
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    matkulName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "$count Materi",
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // WIDGET ITEM LIST (Tampilan Detail Materi)
  Widget _buildListItem(Map<String, String> item) {
    IconData typeIcon;
    Color typeColor;

    switch (item['type']) {
      case 'Video':
        typeIcon = Icons.play_circle_fill;
        typeColor = Colors.redAccent;
        break;
      case 'PDF':
        typeIcon = Icons.picture_as_pdf;
        typeColor = Colors.orangeAccent;
        break;
      default:
        typeIcon = Icons.article;
        typeColor = const Color(0xFF4C6EF5);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
        ), // Border tipis biar beda sama folder
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: typeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(typeIcon, color: typeColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['title']!,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                // Tampilkan deskripsi pendek di sini
                Text(
                  item['desc']!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
          const Icon(Icons.download_rounded, color: Colors.grey),
        ],
      ),
    );
  }

  // WIDGET CAROUSEL (Tetap Sama)
  Widget _buildCarouselCard(Map<String, String> data, bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      transform: Matrix4.identity()..scale(isActive ? 1.0 : 0.95),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF4C6EF5), Color(0xFF6C88F7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: const Color(0xFF4C6EF5).withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 8),
                ),
              ]
            : [],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                data['matkul']!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Spacer(),
            Text(
              data['title']!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              data['desc']!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value:
                          double.parse(data['progress']!.replaceAll('%', '')) /
                          100,
                      backgroundColor: Colors.black.withOpacity(0.1),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  data['progress']!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
