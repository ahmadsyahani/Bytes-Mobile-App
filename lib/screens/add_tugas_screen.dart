import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class AddTugasScreen extends StatefulWidget {
  const AddTugasScreen({super.key});

  @override
  State<AddTugasScreen> createState() => _AddTugasScreenState();
}

class _AddTugasScreenState extends State<AddTugasScreen> {
  final _supabase = Supabase.instance.client;
  final _titleController = TextEditingController();
  final _matkulController = TextEditingController();
  final _descController = TextEditingController();
  final _linkController = TextEditingController();

  DateTime? _selectedDate;
  String _selectedType = 'Individu';
  bool _isLoading = false;

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _submitTask() async {
    if (_titleController.text.isEmpty ||
        _matkulController.text.isEmpty ||
        _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Judul, Matkul, dan Deadline wajib diisi!"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _supabase.from('tasks').insert({
        'title': _titleController.text,
        'matkul': _matkulController.text,
        'description': _descController.text,
        'deadline': DateFormat('yyyy-MM-dd').format(_selectedDate!),
        'type': _selectedType,
        'link_url': _linkController.text,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Tugas berhasil ditambahkan!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Balik dan refresh
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Tambah Tugas Baru",
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
            _buildLabel("Mata Kuliah"),
            TextField(
              controller: _matkulController,
              decoration: _inputDecor("Contoh: Basis Data"),
            ),
            const SizedBox(height: 20),

            _buildLabel("Judul Tugas"),
            TextField(
              controller: _titleController,
              decoration: _inputDecor("Contoh: Laporan Praktikum Modul 1"),
            ),
            const SizedBox(height: 20),

            _buildLabel("Deadline"),
            GestureDetector(
              onTap: _selectDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedDate == null
                          ? "Pilih Tanggal"
                          : DateFormat(
                              'EEEE, d MMMM yyyy',
                              'id_ID',
                            ).format(_selectedDate!),
                      style: TextStyle(
                        color: _selectedDate == null
                            ? Colors.grey
                            : Colors.black,
                      ),
                    ),
                    const Icon(
                      Icons.calendar_today,
                      size: 20,
                      color: Colors.blue,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            _buildLabel("Tipe Tugas"),
            DropdownButtonFormField<String>(
              value: _selectedType,
              items: [
                'Individu',
                'Kelompok',
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _selectedType = v!),
              decoration: _inputDecor(""),
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
                    : const Text(
                        "Simpan Tugas",
                        style: TextStyle(
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
  );
}
