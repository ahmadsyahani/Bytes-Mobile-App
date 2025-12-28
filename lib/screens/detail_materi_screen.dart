import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class DetailMateriScreen extends StatefulWidget {
  final String matkulName;

  const DetailMateriScreen({super.key, required this.matkulName});

  @override
  State<DetailMateriScreen> createState() => _DetailMateriScreenState();
}

class _DetailMateriScreenState extends State<DetailMateriScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _materials = [];

  @override
  void initState() {
    super.initState();
    _fetchMaterials();
  }

  Future<void> _fetchMaterials() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .from('materials')
          .select()
          .eq('matkul', widget.matkulName)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _materials = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- LOGIC TAMBAH MATERI (OPTIMALISASI KEYBOARD) ---
  void _showAddSheet() {
    final titleController = TextEditingController();
    final urlController = TextEditingController();

    // Default selected type
    String selectedType = 'Link';
    final List<String> fileTypes = [
      'Link',
      'PDF',
      'Drive',
      'Youtube',
      'Github',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Wajib true biar keyboard gak nutupin
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(
              context,
            ).viewInsets.bottom, // Padding dinamis keyboard
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Biar tinggi menyesuaikan isi
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Upload Materi Baru",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  "Matkul: ${widget.matkulName}",
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),

                // --- INPUT JUDUL ---
                _buildLabel("Judul Materi"), // LABEL DI ATAS
                TextField(
                  controller: titleController,
                  decoration: _inputDecor("Contoh: Ebook Modul 1"),
                ),
                const SizedBox(height: 16),

                // --- INPUT LINK ---
                _buildLabel("Masukkan Link"), // LABEL DI ATAS
                TextField(
                  controller: urlController,
                  decoration: _inputDecor("https://..."),
                ),
                const SizedBox(height: 20),

                // --- INPUT TIPE ---
                _buildLabel("Tipe File"), // LABEL DI ATAS
                const SizedBox(height: 8),

                // TOMBOL PILIHAN TIPE (Pakai StatefulBuilder biar Keyboard ga lag)
                StatefulBuilder(
                  builder: (context, setSheetState) {
                    return Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: fileTypes.map((type) {
                        final isSelected = selectedType == type;
                        return ChoiceChip(
                          label: Text(type),
                          selected: isSelected,
                          selectedColor: const Color(0xFF4C6EF5),
                          backgroundColor: Colors.grey.shade100,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                          // Trik: setSheetState cuma update bagian tombol ini aja
                          onSelected: (val) {
                            setSheetState(() {
                              selectedType = type;
                            });
                          },
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected
                                  ? const Color(0xFF4C6EF5)
                                  : Colors.transparent,
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),

                const SizedBox(height: 30),

                // TOMBOL SIMPAN
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (titleController.text.isEmpty ||
                          urlController.text.isEmpty)
                        return;
                      Navigator.pop(context); // Tutup sheet dulu biar smooth

                      try {
                        await _supabase.from('materials').insert({
                          'title': titleController.text,
                          'url': urlController.text,
                          'type': selectedType,
                          'matkul': widget.matkulName,
                        });

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Berhasil disimpan"),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                        _fetchMaterials(); // Refresh list
                      } catch (e) {
                        // Error handling
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4C6EF5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Simpan Materi",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Gagal membuka link")));
    }
  }

  // Helper Widget buat Label biar rapi
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  InputDecoration _inputDecor(String hint) => InputDecoration(
    hintText: hint,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF4C6EF5), width: 2),
    ),
  );

  Widget _getTypeIcon(String type) {
    switch (type) {
      case 'PDF':
        return const Icon(Icons.picture_as_pdf, color: Colors.redAccent);
      case 'Drive':
        return const Icon(Icons.add_to_drive, color: Colors.green);
      case 'Youtube':
        return const Icon(Icons.play_circle_fill, color: Colors.red);
      case 'Github':
        return const Icon(Icons.code, color: Colors.black);
      default:
        return const Icon(Icons.link, color: Colors.blue);
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
        title: Text(
          widget.matkulName,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSheet,
        backgroundColor: const Color(0xFF4C6EF5),
        label: const Text(
          "Upload",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        icon: const Icon(Icons.upload_file, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _materials.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.folder_off_rounded,
                      size: 50,
                      color: Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Folder ini masih kosong",
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: _materials.length,
              itemBuilder: (context, index) {
                final item = _materials[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F6FA),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _getTypeIcon(item['type']),
                    ),
                    title: Text(
                      item['title'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Text(
                      item['type'],
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    trailing: const Icon(
                      Icons.arrow_outward,
                      size: 18,
                      color: Colors.grey,
                    ),
                    onTap: () => _launchURL(item['url']),
                  ),
                );
              },
            ),
    );
  }
}
