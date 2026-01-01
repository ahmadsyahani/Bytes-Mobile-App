import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class CatatPengeluaranScreen extends StatefulWidget {
  const CatatPengeluaranScreen({super.key});

  @override
  State<CatatPengeluaranScreen> createState() => _CatatPengeluaranScreenState();
}

class _CatatPengeluaranScreenState extends State<CatatPengeluaranScreen> {
  final _supabase = Supabase.instance.client;

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _submitExpense() async {
    // 1. VALIDASI
    if (_amountController.text.isEmpty ||
        _titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Isi nominal dan keterangan dulu ya!"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw "User tidak login.";

      // Ambil Nama Bendahara (Yang login)
      final userProfile = await _supabase
          .from('profiles')
          .select('full_name')
          .eq('id', user.id)
          .single();
      String myName = userProfile['full_name'] ?? 'Bendahara';

      // Parse Nominal
      final String cleanAmount = _amountController.text.replaceAll(
        RegExp('[^0-9]'),
        '',
      );
      final int amount = int.parse(cleanAmount);

      // 2. SIMPAN KE DATABASE
      // Perhatikan: type = 'OUT', status = 'SUCCESS' (Langsung sukses karena uang tunai)
      await _supabase.from('kas_transactions').insert({
        'user_id': user.id,
        'payer_name': myName, // Nama yang mencatat
        'title': _titleController.text.trim(),
        'amount': amount,
        'type': 'OUT', // PENGELUARAN
        'category': 'Pengeluaran',
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'status': 'SUCCESS',
        'order_id':
            "EXP-${DateTime.now().millisecondsSinceEpoch}", // ID Unik Expense
      });

      if (mounted) {
        // Tampilkan Sukses & Kembali
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Pengeluaran berhasil dicatat!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Balik ke halaman sebelumnya (refresh)
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryRed = const Color(0xFFE53935); // Warna Merah Pengeluaran
    final Color bgScreen = const Color(0xFFF9F8F4);

    return Scaffold(
      backgroundColor: bgScreen,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(
          color: Colors.black,
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Catat Pengeluaran",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Keluar uang buat apa?",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            // Input Keterangan
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: "Contoh: Beli Spidol, Fotokopi...",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(20),
                prefixIcon: const Icon(Icons.edit_note, color: Colors.grey),
              ),
            ),

            const SizedBox(height: 24),
            const Text(
              "Nominalnya berapa?",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            // Input Nominal
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Text(
                    "Rp",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: primaryRed,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      decoration: const InputDecoration(
                        hintText: "0",
                        border: InputBorder.none,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        CurrencyInputFormatter(),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Tombol Simpan
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitExpense,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryRed,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 5,
                  shadowColor: primaryRed.withOpacity(0.4),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Simpan Pengeluaran",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
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

// Formatter Rupiah (Sama kayak di halaman Bayar)
class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue.copyWith(text: '');
    String newText = newValue.text.replaceAll(RegExp('[^0-9]'), '');
    int value = int.tryParse(newText) ?? 0;
    final formatter = NumberFormat.decimalPattern('id');
    String newString = formatter.format(value);
    return newValue.copyWith(
      text: newString,
      selection: TextSelection.collapsed(offset: newString.length),
    );
  }
}
