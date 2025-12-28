import 'package:flutter/material.dart';

class FinanceCard extends StatelessWidget {
  final int paidAmount;
  final int totalAmount;
  final VoidCallback? onTap; // 1. Variabel buat aksi klik

  const FinanceCard({
    super.key,
    required this.paidAmount,
    required this.totalAmount,
    this.onTap, // 2. Masukkan ke constructor
  });

  String _formatRupiah(int number) {
    String str = number.toString();
    RegExp regEx = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    String result = str.replaceAllMapped(regEx, (Match m) => '${m[1]}.');
    return "Rp $result";
  }

  @override
  Widget build(BuildContext context) {
    int remainingAmount = totalAmount - paidAmount;
    if (remainingAmount < 0) remainingAmount = 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // BAGIAN KIRI (Info)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.credit_card, size: 18, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Text(
                    "ByteCash",
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Sudah dibayar",
                        style: TextStyle(fontSize: 12, color: Colors.grey[800]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatRupiah(paidAmount),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Container(height: 30, width: 1, color: Colors.grey[500]),
                  const SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Tunggakan",
                        style: TextStyle(fontSize: 12, color: Colors.grey[800]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatRupiah(remainingAmount),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          // BAGIAN KANAN (TOMBOL BAYAR)
          // 3. Bungkus pakai GestureDetector biar bisa diklik
          GestureDetector(
            onTap: onTap, // Panggil fungsi onTap pas ditekan
            child: Column(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4C6EF5),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4C6EF5).withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Bayar Kas",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
