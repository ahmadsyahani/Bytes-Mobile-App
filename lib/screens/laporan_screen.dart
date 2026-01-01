import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class LaporanScreen extends StatefulWidget {
  const LaporanScreen({super.key});

  @override
  State<LaporanScreen> createState() => _LaporanScreenState();
}

class _LaporanScreenState extends State<LaporanScreen> {
  final _supabase = Supabase.instance.client;

  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  // State untuk Preview & Generate
  bool _isGenerating = false;
  bool _isLoadingPreview = false;

  // Data untuk Preview
  List<Map<String, dynamic>> _previewData = [];
  int _previewMasuk = 0;
  int _previewKeluar = 0;

  @override
  void initState() {
    super.initState();
    // Otomatis ambil data pas layar dibuka
    _fetchPreviewData();
  }

  // --- 1. FUNGSI AMBIL DATA (Dipake buat Preview & Print) ---
  Future<void> _fetchPreviewData() async {
    setState(() {
      _isLoadingPreview = true;
      _previewData = []; // Kosongkan dulu
      _previewMasuk = 0;
      _previewKeluar = 0;
    });

    try {
      final startDate = DateTime(_selectedYear, _selectedMonth, 1);
      final endDate = DateTime(
        _selectedYear,
        _selectedMonth + 1,
        0,
        23,
        59,
        59,
      );

      final response = await _supabase
          .from('kas_transactions')
          .select()
          .eq('status', 'SUCCESS')
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String())
          .order('created_at', ascending: true);

      final List<dynamic> data = response as List<dynamic>;

      // Hitung Total buat Preview
      int tMasuk = 0;
      int tKeluar = 0;

      for (var item in data) {
        if (item['type'] == 'IN')
          tMasuk += (item['amount'] as int);
        else
          tKeluar += (item['amount'] as int);
      }

      if (mounted) {
        setState(() {
          _previewData = List<Map<String, dynamic>>.from(data);
          _previewMasuk = tMasuk;
          _previewKeluar = tKeluar;
          _isLoadingPreview = false;
        });
      }
    } catch (e) {
      debugPrint("Error preview: $e");
      if (mounted) setState(() => _isLoadingPreview = false);
    }
  }

  // --- 2. LOGIC PRINT PDF (Pake data yang udah ditarik aja biar cepet) ---
  Future<void> _generateAndPrintPdf() async {
    if (_previewData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Data kosong, tidak bisa cetak."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final pdf = pw.Document();

      // Siapkan Data Tabel untuk PDF Library
      final tableData = _previewData.map((t) {
        final date = DateFormat(
          'dd/MM',
        ).format(DateTime.parse(t['created_at']).toLocal());
        final title = t['title'] ?? '-';
        final payer =
            t['payer_name'] ??
            '-'; // Bisa ganti logika mau nampilin nama/kategori
        final type = t['type'];
        final amount = t['amount'] ?? 0;

        return [
          date,
          // Kalau ini pengeluaran, tampilin judulnya di kolom nama biar jelas
          type == 'OUT' ? title : payer,
          type == 'IN' ? title : (t['category'] ?? '-'),
          type == 'IN' ? _formatRupiah(amount) : '-',
          type == 'OUT' ? _formatRupiah(amount) : '-',
        ];
      }).toList();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      "Laporan Kas Kelas",
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      "${_namaBulan(_selectedMonth)} $_selectedYear",
                      style: const pw.TextStyle(
                        fontSize: 18,
                        color: PdfColors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                context: context,
                headers: ['Tgl', 'Nama', 'Keterangan', 'Masuk', 'Keluar'],
                data: tableData,
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.blue),
                rowDecoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.grey300),
                  ),
                ),
                cellAlignment: pw.Alignment.centerLeft,
                cellAlignments: {
                  3: pw.Alignment.centerRight,
                  4: pw.Alignment.centerRight,
                },
              ),
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        "Total Pemasukan: ${_formatRupiah(_previewMasuk)}",
                        style: const pw.TextStyle(color: PdfColors.green),
                      ),
                      pw.Text(
                        "Total Pengeluaran: ${_formatRupiah(_previewKeluar)}",
                        style: const pw.TextStyle(color: PdfColors.red),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        "Sisa Saldo: ${_formatRupiah(_previewMasuk - _previewKeluar)}",
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                "Dicetak otomatis oleh Aplikasi Kas Kelas",
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
              ),
            ];
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Laporan_Kas_${_namaBulan(_selectedMonth)}_$_selectedYear',
      );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  String _formatRupiah(int number) => NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  ).format(number);
  String _formatCompact(int number) => NumberFormat.compactCurrency(
    locale: 'id_ID',
    symbol: '',
  ).format(number); // Versi pendek buat preview mini

  String _namaBulan(int month) {
    const months = [
      "Januari",
      "Februari",
      "Maret",
      "April",
      "Mei",
      "Juni",
      "Juli",
      "Agustus",
      "September",
      "Oktober",
      "November",
      "Desember",
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryBlue = const Color(0xFF4C6EF5);
    final Color bgScreen = const Color(0xFFF9F8F4);

    return Scaffold(
      backgroundColor: bgScreen,
      appBar: AppBar(
        title: const Text(
          "Cetak Laporan",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(
          color: Colors.black,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // 1. FILTER DROPDOWN
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Pilih Periode",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: _buildModernDropdown(
                          value: _selectedMonth,
                          items: List.generate(
                            12,
                            (index) => DropdownMenuItem(
                              value: index + 1,
                              child: Text(_namaBulan(index + 1)),
                            ),
                          ),
                          onChanged: (val) {
                            setState(() => _selectedMonth = val!);
                            _fetchPreviewData(); // REFRESH DATA SAAT GANTI BULAN
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: _buildModernDropdown(
                          value: _selectedYear,
                          items: [2024, 2025, 2026, 2027]
                              .map(
                                (y) => DropdownMenuItem(
                                  value: y,
                                  child: Text("$y"),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            setState(() => _selectedYear = val!);
                            _fetchPreviewData(); // REFRESH DATA SAAT GANTI TAHUN
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 2. LIVE DOCUMENT PREVIEW (REAL DATA)
            Expanded(
              child: Center(
                child: _isLoadingPreview
                    ? const CircularProgressIndicator()
                    : _buildLiveDocumentPreview(primaryBlue),
              ),
            ),

            const SizedBox(height: 20),

            // 3. TOMBOL DOWNLOAD
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${_previewData.length} Transaksi Ditemukan",
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          "PDF A4",
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed:
                          (_isGenerating ||
                              _isLoadingPreview ||
                              _previewData.isEmpty)
                          ? null
                          : _generateAndPrintPdf,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: _isGenerating
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.print_rounded,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _previewData.isEmpty
                                      ? "Data Kosong"
                                      : "Cetak Sekarang",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET DROPDOWN ---
  Widget _buildModernDropdown<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          dropdownColor: Colors.white,
          elevation: 2,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.black54,
          ),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
          ),
          borderRadius: BorderRadius.circular(12),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  // --- WIDGET PREVIEW REAL (LIVE DATA) ---
  Widget _buildLiveDocumentPreview(Color color) {
    if (_previewData.isEmpty) {
      // Tampilan Kalau Kosong
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_off_outlined,
            size: 60,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 10),
          Text(
            "Tidak ada data di\n${_namaBulan(_selectedMonth)} $_selectedYear",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade400),
          ),
        ],
      );
    }

    return Container(
      height: 380, // Ukuran Kertas
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Biru
          Container(
            height: 10,
            width: double.infinity,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Judul Mini
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Laporan Kas",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "${_namaBulan(_selectedMonth)} $_selectedYear",
                        style: const TextStyle(fontSize: 8, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Table Header Mini
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    color: Colors.grey[100],
                    child: const Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            "Tgl",
                            style: TextStyle(
                              fontSize: 6,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 4,
                          child: Text(
                            "Ket",
                            style: TextStyle(
                              fontSize: 6,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            "Nominal",
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 6,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),

                  // LIST DATA TRANSAKSI (Scrollable inside paper)
                  Expanded(
                    child: ListView.builder(
                      itemCount: _previewData.length,
                      itemBuilder: (context, index) {
                        final item = _previewData[index];
                        final date = DateFormat(
                          'dd/MM',
                        ).format(DateTime.parse(item['created_at']).toLocal());
                        final type = item['type'];
                        final amount = item['amount'] ?? 0;
                        // Kalau masuk: Nama Pembayar, Kalau keluar: Judul Pengeluaran
                        final desc = type == 'IN'
                            ? (item['payer_name'] ?? '-')
                            : (item['title'] ?? '-');

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  date,
                                  style: const TextStyle(
                                    fontSize: 6,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 4,
                                child: Text(
                                  desc,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 6),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  _formatCompact(amount),
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontSize: 6,
                                    color: type == 'IN'
                                        ? Colors.green
                                        : Colors.red,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  const Divider(thickness: 0.5),

                  // Total Mini
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Sisa Saldo:",
                        style: TextStyle(
                          fontSize: 7,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _formatRupiah(_previewMasuk - _previewKeluar),
                        style: const TextStyle(
                          fontSize: 7,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
