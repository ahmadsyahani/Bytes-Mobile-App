import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // PERLU INI BUAT FORMATTER
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart'; // PERLU PACKAGE INTL (Pastikan sudah ada di pubspec.yaml)

class KasScreen extends StatefulWidget {
  const KasScreen({super.key});

  @override
  State<KasScreen> createState() => _KasScreenState();
}

class _KasScreenState extends State<KasScreen> {
  final _supabase = Supabase.instance.client;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  bool _isLoading = false;

  // Pilihan Nominal Cepat
  final List<int> _quickAmounts = [10000, 20000, 50000, 100000];

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // --- LOGIC FORMATTER MANUAL (Biar tombol Chips juga ada titiknya) ---
  String _formatNumber(int number) {
    final formatter = NumberFormat.decimalPattern('id'); // Format Indo (10.000)
    return formatter.format(number);
  }

  // --- LOGIC KIRIM KE SUPABASE ---
  Future<void> _submitPayment() async {
    // 1. Validasi Input
    if (_amountController.text.isEmpty || _noteController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Harap isi nominal dan keterangan"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // PENTING: Hapus titik sebelum kirim ke database (10.000 -> 10000)
      final String cleanAmount = _amountController.text.replaceAll('.', '');
      final int amount = int.parse(cleanAmount);
      final String note = _noteController.text;

      // 2. Insert ke Tabel 'kas_transactions'
      await _supabase.from('kas_transactions').insert({
        'title': note,
        'amount': amount,
        'type': 'IN', // Pemasukan
        'category': 'Uang Kas',
        'created_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Pembayaran Berhasil Disimpan!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _selectQuickAmount(int amount) {
    // Set text dengan format titik
    _amountController.text = _formatNumber(amount);
    // Pindahkan kursor ke paling belakang biar enak
    _amountController.selection = TextSelection.fromPosition(
      TextPosition(offset: _amountController.text.length),
    );
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
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Bayar Kas",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Mau bayar berapa hari ini?",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),

            // --- INPUT NOMINAL BESAR ---
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
                  const Text(
                    "Rp",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
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
                      // --- LOGIC FORMATTER DISINI ---
                      inputFormatters: [
                        FilteringTextInputFormatter
                            .digitsOnly, // Cuma boleh angka
                        CurrencyInputFormatter(), // Formatter Custom (Class di bawah)
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // --- PILIHAN CEPAT (CHIPS) ---
            const Text(
              "Pilihan Cepat",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              children: _quickAmounts.map((amount) {
                return ActionChip(
                  label: Text("Rp ${amount ~/ 1000}rb"), // Tampilan: 20rb
                  backgroundColor: Colors.white,
                  surfaceTintColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  onPressed: () => _selectQuickAmount(amount),
                );
              }).toList(),
            ),

            const SizedBox(height: 30),

            // --- INPUT KETERANGAN ---
            const Text(
              "Untuk Pembayaran Apa?",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                hintText: "Contoh: Kas Januari, Denda Telat...",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(20),
              ),
            ),

            const SizedBox(height: 40),

            // --- TOMBOL BAYAR ---
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 5,
                  shadowColor: primaryBlue.withOpacity(0.4),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Bayar Sekarang",
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

// --- CLASS FORMATTER UANG (TITIK OTOMATIS) ---
class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // 1. Kalau kosong, biarin kosong
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // 2. Bersihkan input (hanya angka)
    // Cegah user copas huruf/simbol
    String newText = newValue.text.replaceAll(RegExp('[^0-9]'), '');

    // 3. Parse ke integer
    int value = int.tryParse(newText) ?? 0;

    // 4. Format balik jadi String pakai Titik (Locale ID)
    final formatter = NumberFormat.decimalPattern('id');
    String newString = formatter.format(value);

    // 5. Kembalikan text baru dengan posisi kursor di ujung
    return newValue.copyWith(
      text: newString,
      selection: TextSelection.collapsed(offset: newString.length),
    );
  }
}
