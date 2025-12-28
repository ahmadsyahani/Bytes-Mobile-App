import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class AddTugasScreen extends StatefulWidget {
  // Parameter Opsional: Kalau null berarti Mode Tambah, kalau ada isi berarti Mode Edit
  final Map<String, dynamic>? taskToEdit;

  const AddTugasScreen({super.key, this.taskToEdit});

  @override
  State<AddTugasScreen> createState() => _AddTugasScreenState();
}

class _AddTugasScreenState extends State<AddTugasScreen> {
  final _supabase = Supabase.instance.client;

  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _linkController = TextEditingController();

  final List<String> _daftarMatkul = [
    'Pemrograman Mobile',
    'Basis Data',
    'Algoritma & Struktur Data',
    'Jaringan Komputer',
    'Sistem Operasi',
    'Matematika Diskrit',
    'Bahasa Inggris',
    'Pancasila',
    'Lainnya',
  ];

  String? _selectedMatkul;
  DateTime? _selectedDate;
  String _selectedType = 'Individu';
  bool _isLoading = false;

  // Cek apakah ini mode edit?
  bool get _isEditMode => widget.taskToEdit != null;

  @override
  void initState() {
    super.initState();
    // --- LOGIC PRE-FILL DATA (JIKA EDIT) ---
    if (_isEditMode) {
      final task = widget.taskToEdit!;
      _titleController.text = task['title'] ?? '';
      _descController.text = task['description'] ?? '';
      _linkController.text = task['link_url'] ?? '';
      _selectedMatkul = task['matkul']; // Pastikan teks sama persis dengan list
      _selectedType = task['type'] ?? 'Individu';

      try {
        _selectedDate = DateTime.parse(task['deadline']);
      } catch (e) {
        _selectedDate = DateTime.now();
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  // ... (Fungsi _showCustomDatePicker dan _showCustomPicker SAMA SEPERTI SEBELUMNYA) ...
  // Biar hemat tempat, copy paste fungsi _showCustomDatePicker dan _showCustomPicker dari code sebelumnya kesini ya
  // ATAU PAKAI CODE FULL DI BAWAH KALAU MAU LANGSUNG JADI

  void _showCustomDatePicker() {
    DateTime tempPickedDate = _selectedDate ?? DateTime.now();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return Container(
          height: 500,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "Batal",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  const Text(
                    "Pilih Deadline",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, tempPickedDate),
                    child: const Text(
                      "Pilih",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4C6EF5),
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: Color(0xFF4C6EF5),
                    ),
                  ),
                  child: CalendarDatePicker(
                    initialDate: tempPickedDate,
                    firstDate: DateTime.now().subtract(
                      const Duration(days: 365),
                    ), // Bisa edit tugas masa lalu
                    lastDate: DateTime(2030),
                    onDateChanged: (newDate) => tempPickedDate = newDate,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ).then((value) {
      if (value != null && value is DateTime)
        setState(() => _selectedDate = value);
    });
  }

  void _showCustomPicker({
    required String title,
    required List<String> items,
    required Function(String) onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
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
                        onSelected(items[index]);
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

  // --- LOGIC SIMPAN (INSERT / UPDATE) ---
  Future<void> _submitTask() async {
    if (_titleController.text.isEmpty ||
        _selectedMatkul == null ||
        _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Lengkapi data yang wajib!"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final taskData = {
        'title': _titleController.text,
        'matkul': _selectedMatkul,
        'description': _descController.text,
        'deadline': DateFormat('yyyy-MM-dd').format(_selectedDate!),
        'type': _selectedType,
        'link_url': _linkController.text,
      };

      if (_isEditMode) {
        // --- LOGIC UPDATE ---
        await _supabase
            .from('tasks')
            .update(taskData)
            .eq('id', widget.taskToEdit!['id']); // Cari berdasarkan ID
      } else {
        // --- LOGIC INSERT ---
        await _supabase.from('tasks').insert(taskData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditMode
                  ? "Tugas berhasil diubah!"
                  : "Tugas berhasil ditambahkan!",
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
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

  Widget _buildCustomSelector({
    required String hint,
    required String? value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              value ?? hint,
              style: TextStyle(
                color: value == null ? Colors.grey : Colors.black,
                fontSize: 16,
              ),
            ),
            Icon(
              hint.contains("Tanggal")
                  ? Icons.calendar_today_outlined
                  : Icons.keyboard_arrow_down,
              color: const Color(0xFF4C6EF5),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
  );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        // Ubah Judul Dinamis
        title: Text(
          _isEditMode ? "Edit Tugas" : "Tambah Tugas Baru",
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
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
            _buildLabel("Mata Kuliah"),
            _buildCustomSelector(
              hint: "Pilih Mata Kuliah",
              value: _selectedMatkul,
              onTap: () => _showCustomPicker(
                title: "Pilih Mata Kuliah",
                items: _daftarMatkul,
                onSelected: (val) => setState(() => _selectedMatkul = val),
              ),
            ),
            const SizedBox(height: 20),

            _buildLabel("Judul Tugas"),
            TextField(
              controller: _titleController,
              decoration: _inputDecor("Contoh: Laporan Praktikum Modul 1"),
            ),
            const SizedBox(height: 20),

            _buildLabel("Deadline"),
            _buildCustomSelector(
              hint: "Pilih Tanggal Deadline",
              value: _selectedDate == null
                  ? null
                  : DateFormat(
                      'EEEE, d MMMM yyyy',
                      'id',
                    ).format(_selectedDate!),
              onTap: _showCustomDatePicker,
            ),
            const SizedBox(height: 20),

            _buildLabel("Tipe Tugas"),
            _buildCustomSelector(
              hint: "Pilih Tipe",
              value: _selectedType,
              onTap: () => _showCustomPicker(
                title: "Tipe Tugas",
                items: ['Individu', 'Kelompok'],
                onSelected: (val) => setState(() => _selectedType = val),
              ),
            ),
            const SizedBox(height: 20),

            _buildLabel("Deskripsi (Opsional)"),
            TextField(
              controller: _descController,
              maxLines: 3,
              decoration: _inputDecor("Detail tugas..."),
            ),

            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitTask,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4C6EF5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    // Text tombol juga dinamis
                    : Text(
                        _isEditMode ? "Simpan Perubahan" : "Simpan Tugas",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
