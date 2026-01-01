import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import 'laporan_screen.dart';
import 'catat_pengeluaran_screen.dart';

class CekKasScreen extends StatefulWidget {
  const CekKasScreen({super.key});

  @override
  State<CekKasScreen> createState() => _CekKasScreenState();
}

class _CekKasScreenState extends State<CekKasScreen> {
  final _supabase = Supabase.instance.client;

  bool _isLoading = true;
  bool _isAdmin = false;

  // State Filter
  int _selectedYear = DateTime.now().year;
  String _filterType = 'ALL'; // Pilihan: 'ALL', 'IN', 'OUT'

  // Data Utama
  int _totalSaldoAllTime = 0;
  List<Map<String, dynamic>> _allTransactions = [];
  Map<String, String> _userNames = {};

  // Data Grafik & List
  List<double> _monthlyIncomeData = List.filled(12, 0.0);
  int _yearlyIncome = 0;
  int _yearlyExpense = 0;
  List<Map<String, dynamic>> _filteredHistoryList = [];
  int? _selectedBarIndex;

  @override
  void initState() {
    super.initState();
    _fetchKasData();
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        final data = await _supabase
            .from('profiles')
            .select('role')
            .eq('id', user.id)
            .single();
        if (mounted) setState(() => _isAdmin = (data['role'] == 'admin'));
      }
    } catch (e) {
      debugPrint("Gagal cek role: $e");
    }
  }

  Future<void> _fetchKasData() async {
    try {
      final profilesResponse = await _supabase
          .from('profiles')
          .select('id, full_name, nickname');
      final List<dynamic> profilesData = profilesResponse as List<dynamic>;
      Map<String, String> tempUserMap = {};
      for (var p in profilesData) {
        String name = p['full_name'] ?? p['nickname'] ?? '';
        if (name.isNotEmpty) tempUserMap[p['id']] = name;
      }

      final response = await _supabase
          .from('kas_transactions')
          .select()
          .order('created_at', ascending: true);

      final List<dynamic> data = response as List<dynamic>;

      int tempSaldo = 0;
      for (var item in data) {
        int amount = item['amount'] ?? 0;
        String type = item['type'] ?? 'IN';
        String status = item['status'] ?? 'SUCCESS';

        if (status == 'SUCCESS') {
          if (type == 'IN')
            tempSaldo += amount;
          else
            tempSaldo -= amount;
        }
      }

      if (mounted) {
        setState(() {
          _userNames = tempUserMap;
          _allTransactions = List<Map<String, dynamic>>.from(data);
          _totalSaldoAllTime = tempSaldo;
          _calculateDataForYear(_selectedYear);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetch kas: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _calculateDataForYear(int year) {
    List<double> monthlyIncomes = List.filled(12, 0.0);
    int tempMasuk = 0;
    int tempKeluar = 0;
    List<Map<String, dynamic>> tempHistory = [];

    for (var item in _allTransactions) {
      DateTime date =
          DateTime.tryParse(item['created_at'])?.toLocal() ?? DateTime.now();

      if (date.year == year) {
        int amount = item['amount'] ?? 0;
        String type = item['type'] ?? 'IN';
        String status = item['status'] ?? 'SUCCESS';

        // 1. Logic Grafik (Selalu Hitung Semua)
        if (status == 'SUCCESS') {
          if (type == 'IN') {
            tempMasuk += amount;
            monthlyIncomes[date.month - 1] += amount.toDouble();
          } else {
            tempKeluar += amount;
          }
        }

        // 2. Logic List Riwayat (Ikut Filter)
        bool matchesFilter = false;
        if (_filterType == 'ALL') {
          matchesFilter = true;
        } else if (_filterType == 'IN' && type == 'IN') {
          matchesFilter = true;
        } else if (_filterType == 'OUT' && type == 'OUT') {
          matchesFilter = true;
        }

        if (matchesFilter) {
          tempHistory.add(item);
        }
      }
    }

    setState(() {
      _selectedYear = year;
      _monthlyIncomeData = monthlyIncomes;
      _yearlyIncome = tempMasuk;
      _yearlyExpense = tempKeluar;
      _filteredHistoryList = tempHistory.reversed.toList();
    });
  }

  String _formatCurrency(num amount) => NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  ).format(amount);
  String _formatCompact(num amount) =>
      NumberFormat.compactCurrency(locale: 'id_ID', symbol: '').format(amount);
  String _formatDateTime(String dateString) {
    try {
      DateTime date = DateTime.parse(dateString).toLocal();
      return DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(date);
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryBlue = const Color(0xFF4C6EF5);
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
      ),

      floatingActionButton: _isAdmin
          ? FloatingActionButton.extended(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CatatPengeluaranScreen(),
                  ),
                );
                _fetchKasData();
              },
              backgroundColor: const Color(0xFFE53935),
              icon: const Icon(
                Icons.remove_circle_outline,
                color: Colors.white,
              ),
              label: const Text(
                "Pengeluaran",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,

      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryBlue))
          : RefreshIndicator(
              onRefresh: () async {
                _fetchKasData();
                _checkUserRole();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 10, 24, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- TOTAL SALDO ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          "Total Saldo Kas",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            setState(() => _isLoading = true);
                            _fetchKasData();
                            _checkUserRole();
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.refresh_rounded,
                              color: primaryBlue,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatCurrency(_totalSaldoAllTime),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- BAR CHART ---
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Pemasukan",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.chevron_left,
                                        size: 20,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () => _calculateDataForYear(
                                        _selectedYear - 1,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "$_selectedYear",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: primaryBlue,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.chevron_right,
                                        size: 20,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed:
                                          _selectedYear >= DateTime.now().year
                                          ? null
                                          : () => _calculateDataForYear(
                                              _selectedYear + 1,
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 150,
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                double maxVal = _monthlyIncomeData.reduce(max);
                                if (maxVal == 0) maxVal = 1;
                                return Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: List.generate(12, (index) {
                                    final double value =
                                        _monthlyIncomeData[index];
                                    final double heightRatio = value / maxVal;
                                    final bool isSelected =
                                        _selectedBarIndex == index;
                                    const months = [
                                      "J",
                                      "F",
                                      "M",
                                      "A",
                                      "M",
                                      "J",
                                      "J",
                                      "A",
                                      "S",
                                      "O",
                                      "N",
                                      "D",
                                    ];
                                    return GestureDetector(
                                      onTapDown: (_) => setState(
                                        () => _selectedBarIndex = index,
                                      ),
                                      onTapUp: (_) => setState(
                                        () => _selectedBarIndex = null,
                                      ),
                                      onTapCancel: () => setState(
                                        () => _selectedBarIndex = null,
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          if (isSelected)
                                            Container(
                                              margin: const EdgeInsets.only(
                                                bottom: 4,
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.black87,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                _formatCompact(value),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ),
                                          AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 300,
                                            ),
                                            curve: Curves.easeOut,
                                            width:
                                                (constraints.maxWidth / 12) - 6,
                                            height: 100 * heightRatio + 5,
                                            decoration: BoxDecoration(
                                              color: value > 0
                                                  ? (isSelected
                                                        ? primaryBlue
                                                              .withOpacity(0.7)
                                                        : primaryBlue)
                                                  : Colors.grey[200],
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            months[index],
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: value > 0
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                              color: value > 0
                                                  ? Colors.black87
                                                  : Colors.grey[400],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoCard(
                            title: "Pemasukan $_selectedYear",
                            amount: _formatCurrency(_yearlyIncome),
                            icon: Icons.arrow_downward_rounded,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildInfoCard(
                            title: "Pengeluaran $_selectedYear",
                            amount: _formatCurrency(_yearlyExpense),
                            icon: Icons.arrow_upward_rounded,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LaporanScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          side: const BorderSide(color: Colors.black12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(
                          Icons.print_rounded,
                          color: Colors.black,
                        ),
                        label: const Text(
                          "Cetak Laporan",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),
                    Text(
                      "Riwayat Transaksi $_selectedYear",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Filter
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterButton("Semua", "ALL", Colors.black87),
                          const SizedBox(width: 8),
                          _buildFilterButton("Pemasukan", "IN", Colors.green),
                          const SizedBox(width: 8),
                          _buildFilterButton("Pengeluaran", "OUT", Colors.red),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),

                    // --- LIST RIWAYAT ---
                    _filteredHistoryList.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(40.0),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.history_toggle_off,
                                    size: 40,
                                    color: Colors.grey[300],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    "Tidak ada data $_filterType di tahun $_selectedYear",
                                    style: TextStyle(color: Colors.grey[400]),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Column(
                            children: _filteredHistoryList.map((item) {
                              String userId = item['user_id'] ?? '';
                              String? knownName = _userNames[userId];
                              String title = item['title'] ?? "Transaksi";
                              String displayName = knownName ?? title;
                              String description = knownName != null
                                  ? title
                                  : (item['category'] ?? "Umum");
                              String status = item['status'] ?? 'SUCCESS';

                              return _buildHistoryItem(
                                displayName: displayName,
                                description: description,
                                date: _formatDateTime(item['created_at']),
                                amount: item['amount'] ?? 0,
                                type: item['type'] ?? 'IN',
                                status: status,
                              );
                            }).toList(),
                          ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildFilterButton(String label, String value, Color color) {
    bool isSelected = _filterType == value;
    return InkWell(
      onTap: () {
        setState(() {
          _filterType = value;
          _calculateDataForYear(_selectedYear);
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? color : Colors.grey.shade300),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[600],
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String amount,
    required IconData icon,
    required Color color,
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
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 14, color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            child: Text(
              amount,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem({
    required String displayName,
    required String description,
    required String date,
    required int amount,
    required String type,
    required String status,
  }) {
    bool isIncome = type == 'IN';
    bool isPending = status == 'PENDING';

    Color mainColor = isPending
        ? Colors.orange
        : (isIncome ? Colors.green : Colors.red);
    IconData iconData = isPending
        ? Icons.access_time_filled_rounded
        : (isIncome ? Icons.attach_money : Icons.shopping_bag_outlined);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: mainColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(iconData, color: mainColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        description,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[800],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
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
                  fontSize: 15,
                  color: mainColor,
                ),
              ),
              const SizedBox(height: 4),
              if (isPending)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    "Menunggu",
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else
                Text(
                  date,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
