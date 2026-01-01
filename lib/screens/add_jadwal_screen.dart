import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddJadwalScreen extends StatefulWidget {
  const AddJadwalScreen({super.key});

  @override
  State<AddJadwalScreen> createState() => _AddJadwalScreenState();
}

class _AddJadwalScreenState extends State<AddJadwalScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;

  final _ruangController = TextEditingController();

  // Data Lokal
  final List<String> _daftarMatkul = [
    'Algoritma & Struktur Data',
    'Basis Data',
    'Pemrograman Mobile',
    'Jaringan Komputer',
    'Sistem Operasi',
    'Matematika Diskrit',
    'Bahasa Inggris',
    'Pancasila',
    'Kecerdasan Buatan',
    'Proyek Akhir',
    'Metodologi Penelitian',
    'Interaksi Manusia Komputer',
    'Statistika',
    'Lainnya',
  ];

  final List<String> _daftarHari = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
  ];

  // Data dari Database
  List<String> _daftarDosen = []; // Nanti diisi dari Supabase

  // State Pilihan
  String? _selectedMatkul;
  String? _selectedDosen; // Ganti controller jadi variabel ini
  String _selectedDayName = 'Senin';
  int _selectedDayIndex = 1;

  String _selectedType = 'Teori';
  TimeOfDay _startTime = const TimeOfDay(hour: 08, minute: 00);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 00);
  bool _isReplacement = false;

  @override
  void initState() {
    super.initState();
    _fetchLecturers(); // Ambil data dosen pas buka layar
  }

  @override
  void dispose() {
    _ruangController.dispose();
    super.dispose();
  }

  // --- AMBIL DATA DOSEN DARI SUPABASE ---
  Future<void> _fetchLecturers() async {
    try {
      final response = await _supabase
          .from('lecturers')
          .select('name') // Cuma butuh nama
          .order('name', ascending: true);

      final List<dynamic> data = response;
      if (mounted) {
        setState(() {
          // Masukin nama-nama dosen ke list
          _daftarDosen = data.map((e) => e['name'] as String).toList();
        });
      }
    } catch (e) {
      debugPrint("Gagal ambil dosen: $e");
    }
  }

  // --- LOGIC TIME PICKER (VERSI AMAN) ---
  Future<void> _selectTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4C6EF5),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF4C6EF5),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart)
          _startTime = picked;
        else
          _endTime = picked;
      });
    }
  }

  // --- LOGIC CUSTOM PICKER (REUSABLE) ---
  void _showCustomPicker({
    required String title,
    required List<String> items,
    required Function(String, int) onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return Container(
          height:
              500, // Kasih tinggi fix biar enak scrollnya kalau list panjang
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(),
              Expanded(
                // Pake Expanded biar ListView bisa scroll
                child: items.isEmpty
                    ? const Center(
                        child: Text(
                          "Belum ada data",
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 24,
                            ),
                            title: Text(items[index]),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 14,
                              color: Colors.grey,
                            ),
                            onTap: () {
                              onSelected(items[index], index);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveJadwal() async {
    // Validasi nambah Dosen juga
    if (_selectedMatkul == null ||
        _ruangController.text.isEmpty ||
        _selectedDosen == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Lengkapi data Matkul, Dosen & Ruangan!"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String formatTime(TimeOfDay t) =>
          '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

      await _supabase.from('schedules').insert({
        'day': _selectedDayIndex,
        'matkul': _selectedMatkul,
        'lecturer': _selectedDosen, // Simpan Nama Dosen yang dipilih
        'room': _ruangController.text,
        'type': _selectedType,
        'time_start': formatTime(_startTime),
        'time_end': formatTime(_endTime),
        'is_replacement': _isReplacement,
      });

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Jadwal berhasil disimpan!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- WIDGETS ---

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
  );

  InputDecoration _inputDecor(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Colors.grey.shade400),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    filled: true,
    fillColor: Colors.white,
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
      borderSide: const BorderSide(color: Color(0xFF4C6EF5), width: 1.5),
    ),
  );

  Widget _buildSelector({
    required String hint,
    required String? value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                value ?? hint,
                style: TextStyle(
                  color: value == null ? Colors.grey : Colors.black,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelector(String label, TimeOfDay time, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                time.format(context),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Icon(
                Icons.access_time_rounded,
                color: Color(0xFF4C6EF5),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(String label, Color color) {
    bool isSelected = _selectedType == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: 1.5,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Tambah Jadwal",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TOGGLE REPLACEMENT
            GestureDetector(
              onTap: () => setState(() => _isReplacement = !_isReplacement),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isReplacement
                      ? Colors.orange.shade50
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isReplacement
                        ? Colors.orange.shade200
                        : Colors.grey.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: _isReplacement ? Colors.orange : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Kelas Pengganti?",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _isReplacement
                                  ? Colors.orange[800]
                                  : Colors.black,
                            ),
                          ),
                          const Text(
                            "Aktifkan jika ini bukan jadwal rutin",
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isReplacement,
                      activeColor: Colors.orange,
                      onChanged: (val) => setState(() => _isReplacement = val),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            _buildLabel("Mata Kuliah"),
            _buildSelector(
              hint: "Pilih Mata Kuliah",
              value: _selectedMatkul,
              onTap: () => _showCustomPicker(
                title: "Pilih Mata Kuliah",
                items: _daftarMatkul,
                onSelected: (val, _) => setState(() => _selectedMatkul = val),
              ),
            ),

            const SizedBox(height: 20),

            // --- BAGIAN DOSEN PENGAMPU (BARU) ---
            _buildLabel("Dosen Pengampu"),
            _buildSelector(
              hint: "Pilih Dosen",
              value: _selectedDosen,
              onTap: () => _showCustomPicker(
                title: "Pilih Dosen",
                items: _daftarDosen, // List dari Supabase
                onSelected: (val, _) => setState(() => _selectedDosen = val),
              ),
            ),

            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel("Ruangan"),
                      TextField(
                        controller: _ruangController,
                        decoration: _inputDecor("C-101"),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel("Hari"),
                      _buildSelector(
                        hint: "Hari",
                        value: _selectedDayName,
                        onTap: () => _showCustomPicker(
                          title: "Pilih Hari",
                          items: _daftarHari,
                          onSelected: (val, index) => setState(() {
                            _selectedDayName = val;
                            _selectedDayIndex = index + 1;
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            _buildLabel("Waktu Kuliah"),
            Row(
              children: [
                _buildTimeSelector(
                  "Mulai",
                  _startTime,
                  () => _selectTime(true),
                ),
                const SizedBox(width: 16),
                const Text(
                  "-",
                  style: TextStyle(fontSize: 24, color: Colors.grey),
                ),
                const SizedBox(width: 16),
                _buildTimeSelector(
                  "Selesai",
                  _endTime,
                  () => _selectTime(false),
                ),
              ],
            ),

            const SizedBox(height: 20),
            _buildLabel("Tipe Kelas"),
            Row(
              children: [
                _buildTypeChip("Teori", const Color(0xFF4C6EF5)),
                const SizedBox(width: 12),
                _buildTypeChip("Praktek", Colors.purple),
              ],
            ),

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveJadwal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4C6EF5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Simpan Jadwal",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
