import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart'; // PERLU INI BUAT BUKA LINK

class KasScreen extends StatefulWidget {
  const KasScreen({super.key});

  @override
  State<KasScreen> createState() => _KasScreenState();
}

class _KasScreenState extends State<KasScreen> {
  final _supabase = Supabase.instance.client;

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _customNoteController = TextEditingController();

  bool _isLoading = false;

  final List<String> _categories = ["Uang Kas", "Denda", "Lainnya"];
  String _selectedCategory = "Uang Kas";

  final List<int> _quickAmounts = [10000, 20000, 50000, 100000];

  @override
  void dispose() {
    _amountController.dispose();
    _customNoteController.dispose();
    super.dispose();
  }

  // --- FUNGSI BUKA BROWSER ---
  Future<void> _launchPaymentUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Tidak bisa membuka link pembayaran: $url';
    }
  }

  // --- DIALOG MENUNGGU (SETELAH BROWSER DITUTUP) ---
  void _showWaitingDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.payment, color: Colors.blue, size: 50),
                const SizedBox(height: 20),
                const Text(
                  "Selesaikan Pembayaran",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Silakan selesaikan pembayaran di browser/aplikasi yang terbuka.\n\nJika sudah, saldo akan otomatis bertambah di sini.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Tutup Dialog
                      Navigator.of(context).pop(true); // Kembali ke Home
                    },
                    child: const Text("Saya Sudah Bayar / Tutup"),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _submitPayment() async {
    // 1. VALIDASI INPUT
    String finalTitle = "";
    String finalCategory = "Uang Kas";

    if (_selectedCategory == "Lainnya") {
      if (_customNoteController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Harap isi keterangan"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      finalTitle = _customNoteController.text.trim();
      finalCategory = "Umum";
    } else {
      finalTitle = _selectedCategory;
      finalCategory = _selectedCategory;
    }

    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Isi nominal dulu bro"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw "User tidak login.";

      // Ambil Nama
      final userProfile = await _supabase
          .from('profiles')
          .select('full_name')
          .eq('id', user.id)
          .single();
      String myName = userProfile['full_name'] ?? 'Tanpa Nama';

      // Parse Nominal
      final String cleanAmount = _amountController.text.replaceAll('.', '');
      final int amount = int.parse(cleanAmount);

      // Generate Order ID Unik
      String orderId = "KAS-${DateTime.now().millisecondsSinceEpoch}";

      // 2. SIMPAN DATA KE DB (STATUS: PENDING)
      await _supabase.from('kas_transactions').insert({
        'user_id': user.id,
        'payer_name': myName,
        'title': finalTitle,
        'amount': amount,
        'type': 'IN',
        'category': finalCategory,
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'status': 'PENDING',
        'order_id': orderId,
      });

      // 3. PANGGIL ROBOT KASIR (EDGE FUNCTION) 🤖
      // Ini request link bayar ke server yang barusan kita deploy
      final functionResponse = await _supabase.functions.invoke(
        'midtrans-payment',
        body: {'order_id': orderId, 'gross_amount': amount},
      );

      // Cek Error dari Server
      if (functionResponse.status != 200) {
        throw "Gagal minta link bayar. Server error.";
      }

      final data = functionResponse.data;
      final String? paymentUrl = data['redirect_url']; // Link dari Midtrans

      if (paymentUrl != null) {
        // 4. BUKA LINK PEMBAYARAN DI BROWSER
        await _launchPaymentUrl(paymentUrl);

        if (mounted) {
          _showWaitingDialog(); // Tampilkan instruksi
        }
      } else {
        throw "Link pembayaran tidak ditemukan.";
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

  // --- UI WIDGETS ---
  String _formatNumber(int number) {
    final formatter = NumberFormat.decimalPattern('id');
    return formatter.format(number);
  }

  void _selectQuickAmount(int amount) {
    _amountController.text = _formatNumber(amount);
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
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        CurrencyInputFormatter(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Pilihan Cepat",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              children: _quickAmounts.map((amount) {
                return ActionChip(
                  label: Text("Rp ${amount ~/ 1000}rb"),
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
            const Text(
              "Untuk Pembayaran Apa?",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _categories.map((category) {
                bool isSelected = _selectedCategory == category;
                return InkWell(
                  onTap: () => setState(() => _selectedCategory = category),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? primaryBlue : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? primaryBlue : Colors.grey.shade300,
                        width: isSelected ? 0 : 1.5,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: primaryBlue.withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [],
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            if (_selectedCategory == "Lainnya") ...[
              const SizedBox(height: 20),
              TextField(
                controller: _customNoteController,
                decoration: InputDecoration(
                  hintText: "Tulis keterangan...",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(20),
                ),
              ),
            ],
            const SizedBox(height: 40),
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
