import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/custom_bottom_nav.dart';

class CekKasScreen extends StatefulWidget {
  const CekKasScreen({super.key});

  @override
  State<CekKasScreen> createState() => _CekKasScreenState();
}

class _CekKasScreenState extends State<CekKasScreen> {
  final _supabase = Supabase.instance.client;

  // State Variables
  bool _isLoading = true;
  int _totalSaldo = 0;
  int _pemasukanBulanIni = 0;
  int _pengeluaranBulanIni = 0;
  List<Map<String, dynamic>> _historyList = [];

  // Data Grafik (12 Bulan, nilai 0.0 - 1.0 untuk persentase tinggi batang)
  List<double> _monthlyChartData = List.filled(12, 0.0);

  @override
  void initState() {
    super.initState();
    _fetchKasData();
  }

  // --- LOGIC UTAMA: AMBIL & HITUNG DATA ---
  Future<void> _fetchKasData() async {
    try {
      // 1. Ambil semua transaksi urut dari yang terbaru
      final response = await _supabase
          .from('kas_transactions')
          .select()
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;

      int tempSaldo = 0;
      int tempMasuk = 0;
      int tempKeluar = 0;

      // Keranjang untuk grafik 12 bulan (Jan-Des)
      List<double> rawMonthlyIncomes = List.filled(12, 0.0);

      final now = DateTime.now();

      // 2. Loop Data
      for (var item in data) {
        int amount = item['amount'] ?? 0;
        String type = item['type'] ?? 'IN'; // 'IN' atau 'OUT'

        // Safety Parse Date
        DateTime date;
        try {
          date = DateTime.parse(item['created_at']);
        } catch (_) {
          date = now;
        }

        // A. Hitung Saldo Total (Semua Waktu)
        if (type == 'IN') {
          tempSaldo += amount;
        } else {
          tempSaldo -= amount;
        }

        // B. Hitung Statistik BULAN INI Saja (Buat Kartu Kecil)
        if (date.month == now.month && date.year == now.year) {
          if (type == 'IN')
            tempMasuk += amount;
          else
            tempKeluar += amount;
        }

        // C. Data Grafik (Pemasukan per Bulan di Tahun Ini)
        if (date.year == now.year && type == 'IN') {
          // date.month = 1 (Jan) -> index 0
          rawMonthlyIncomes[date.month - 1] += amount.toDouble();
        }
      }

      // 3. Normalisasi Data Grafik (Skala 0.0 - 1.0)
      // Cari nilai tertinggi buat jadi patokan 100%
      double maxVal = 0.0;
      for (var val in rawMonthlyIncomes) {
        if (val > maxVal) maxVal = val;
      }

      // Konversi ke persentase biar grafik barnya proporsional
      List<double> normalizedData = List.filled(12, 0.0);
      if (maxVal > 0) {
        for (int i = 0; i < 12; i++) {
          normalizedData[i] = rawMonthlyIncomes[i] / maxVal;
        }
      }

      // 4. Update UI
      if (mounted) {
        setState(() {
          _totalSaldo = tempSaldo;
          _pemasukanBulanIni = tempMasuk;
          _pengeluaranBulanIni = tempKeluar;
          _historyList = List<Map<String, dynamic>>.from(data);
          _monthlyChartData = normalizedData;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetch kas: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- HELPER FORMATTER ---
  String _formatCurrency(int amount) {
    String str = amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return "Rp $str";
  }

  String _formatDate(String dateString) {
    try {
      DateTime date = DateTime.parse(dateString);
      const months = [
        "Jan",
        "Feb",
        "Mar",
        "Apr",
        "Mei",
        "Jun",
        "Jul",
        "Agu",
        "Sep",
        "Okt",
        "Nov",
        "Des",
      ];
      return "${date.day} ${months[date.month - 1]} ${date.year}";
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryBlue = const Color(0xFF4C6EF5);
    final Color bgWhite = Colors.white;
    final Color bgScreen = const Color(0xFFF9F8F4);

    return Scaffold(
      backgroundColor: bgScreen,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Cek Kas",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: () {
              setState(() => _isLoading = true);
              _fetchKasData();
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryBlue))
          : Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 10, 24, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. SUB-HEADER
                      const Text(
                        "Total keseluruhan\nKas yang terkumpul.",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 2. CHART CARD (GRAFIK DINAMIS 12 BULAN)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: bgWhite,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Total Saldo Saat Ini",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // TOTAL SALDO REAL
                            Text(
                              _formatCurrency(_totalSaldo),
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: primaryBlue,
                              ),
                            ),
                            const SizedBox(height: 30),

                            const Text(
                              "Grafik Pemasukan (Setahun)",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 15),

                            // AREA GRAFIK BATANG (SCROLLABLE 12 BULAN)
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: List.generate(12, (index) {
                                  const months = [
                                    "Jan",
                                    "Feb",
                                    "Mar",
                                    "Apr",
                                    "Mei",
                                    "Jun",
                                    "Jul",
                                    "Agu",
                                    "Sep",
                                    "Okt",
                                    "Nov",
                                    "Des",
                                  ];
                                  // Highlight bulan sekarang biar user tau posisi waktunya
                                  bool isCurrentMonth =
                                      (index + 1) == DateTime.now().month;

                                  return Padding(
                                    padding: const EdgeInsets.only(right: 12.0),
                                    child: _buildBarChart(
                                      months[index],
                                      _monthlyChartData[index],
                                      isCurrentMonth
                                          ? const Color(0xFF2D4CC8)
                                          : primaryBlue, // Warna beda buat bulan ini
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 3. KARTU STATISTIK BULANAN
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoCard(
                              title: "Pemasukan (Bln Ini)",
                              amount: _formatCurrency(_pemasukanBulanIni),
                              icon: Icons.north_east,
                              isIncome: true,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildInfoCard(
                              title: "Pengeluaran (Bln Ini)",
                              amount: _formatCurrency(_pengeluaranBulanIni),
                              icon: Icons.south_west,
                              isIncome: false,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      // 4. HISTORY TRANSAKSI
                      const Text(
                        "History Transaksi",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 15),

                      _historyList.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Text(
                                  "Belum ada transaksi",
                                  style: TextStyle(color: Colors.grey[400]),
                                ),
                              ),
                            )
                          : Column(
                              children: _historyList.map((item) {
                                return _buildHistoryItem(
                                  title: item['title'] ?? "Transaksi",
                                  date: _formatDate(item['created_at']),
                                  amount: item['amount'] ?? 0,
                                  category: item['category'] ?? "Umum",
                                  type: item['type'] ?? 'IN',
                                );
                              }).toList(),
                            ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // --- WIDGET COMPONENTS ---

  Widget _buildBarChart(String label, double heightPercentage, Color color) {
    const double maxHeight = 100.0; // Tinggi maksimal batang

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Tooltip(
          message: "$label: ${(heightPercentage * 100).toStringAsFixed(0)}%",
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 1000),
            curve: Curves.elasticOut,
            width: 24, // Lebar batang
            // Tinggi min 2% biar ada visualnya dikit kalo 0
            height:
                maxHeight * (heightPercentage <= 0 ? 0.02 : heightPercentage),
            decoration: BoxDecoration(
              color: heightPercentage > 0 ? color : Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String amount,
    required IconData icon,
    required bool isIncome,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
              Icon(icon, size: 16, color: isIncome ? Colors.green : Colors.red),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            child: Text(
              amount,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isIncome ? Colors.green : Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem({
    required String title,
    required String date,
    required int amount,
    required String category,
    required String type,
  }) {
    bool isIncome = type == 'IN';
    // Logic Icon Sederhana
    IconData iconData = Icons.attach_money;
    if (category.toLowerCase().contains("makan") ||
        category.toLowerCase().contains("konsumsi"))
      iconData = Icons.restaurant;
    else if (category.toLowerCase().contains("print") ||
        category.toLowerCase().contains("alat"))
      iconData = Icons.print;
    else if (category.toLowerCase().contains("jalan") ||
        category.toLowerCase().contains("transport"))
      iconData = Icons.directions_bus;
    else if (category.toLowerCase().contains("event") ||
        category.toLowerCase().contains("acara"))
      iconData = Icons.event;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isIncome
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              iconData,
              color: isIncome ? Colors.green : Colors.red,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${isIncome ? '+' : '-'} ${_formatCurrency(amount)}",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isIncome ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                category,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
