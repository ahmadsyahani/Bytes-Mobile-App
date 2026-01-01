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
    _fetchPreviewData(); // Ambil data saat pertama buka
  }

  // --- 1. FUNGSI AMBIL DATA DARI SUPABASE ---
  Future<void> _fetchPreviewData() async {
    setState(() {
      _isLoadingPreview = true;
      _previewData = [];
      _previewMasuk = 0;
      _previewKeluar = 0;
    });

    try {
      // Logic filter tanggal (Awal bulan s/d Akhir bulan)
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

      // Hitung Total
      int tMasuk = 0;
      int tKeluar = 0;

      for (var item in data) {
        if (item['type'] == 'IN') {
          tMasuk += (item['amount'] as int);
        } else {
          tKeluar += (item['amount'] as int);
        }
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

  // --- 2. LOGIC PRINT PDF (FIXED & PROFESSIONAL) ---
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

      // --- DEFINISI WARNA PDF (HARDCODE HEX) ---
      final PdfColor primaryColor = PdfColor.fromInt(0xFF4C6EF5);
      final PdfColor accentColor = PdfColor.fromInt(0xFFF0F4FF);
      final PdfColor greyColor = PdfColors.grey600;
      // Warna border transparan (Alpha 20% = 0x33)
      final PdfColor lightBorderColor = PdfColor.fromInt(0x334C6EF5);

      // Format Rupiah Helper
      String toRupiah(int amount) {
        return NumberFormat.currency(
          locale: 'id_ID',
          symbol: 'Rp ',
          decimalDigits: 0,
        ).format(amount);
      }

      // Siapkan Data Tabel
      final tableData = _previewData.map((t) {
        final date = DateFormat(
          'dd/MM/yyyy',
        ).format(DateTime.parse(t['created_at']).toLocal());
        final title = t['title'] ?? '-';
        final payer = t['payer_name'] ?? '-';
        final type = t['type'];
        final category = t['category'] ?? '-';
        final amount = t['amount'] ?? 0;

        String description = type == 'IN'
            ? "Pemasukan: $category"
            : "Pengeluaran";
        String mainName = type == 'IN' ? payer : title;

        return [
          date,
          mainName,
          description,
          type == 'IN' ? toRupiah(amount) : '-',
          type == 'OUT' ? toRupiah(amount) : '-',
        ];
      }).toList();

      pdf.addPage(
        pw.MultiPage(
          pageTheme: pw.PageTheme(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(40),
            buildBackground: (context) =>
                pw.FullPage(ignoreMargins: true, child: pw.Container()),
          ),
          header: (context) => pw.Column(
            children: [
              // Header Atas (Logo & Periode)
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        "LAPORAN KAS KELAS",
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        "S.Tr Teknik Informatika B - PENS",
                        style: pw.TextStyle(
                          fontSize: 12,
                          color: greyColor,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        "PERIODE",
                        style: pw.TextStyle(fontSize: 10, color: greyColor),
                      ),
                      pw.Text(
                        "${_namaBulan(_selectedMonth).toUpperCase()} $_selectedYear",
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        "Dicetak: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}",
                        style: pw.TextStyle(fontSize: 9, color: greyColor),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Divider(color: primaryColor, thickness: 2),
              pw.SizedBox(height: 20),
            ],
          ),
          footer: (context) => pw.Column(
            children: [
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    "Bytes Mobile App",
                    style: pw.TextStyle(fontSize: 10, color: greyColor),
                  ),
                  pw.Text(
                    "Halaman ${context.pageNumber} dari ${context.pagesCount}",
                    style: pw.TextStyle(fontSize: 10, color: greyColor),
                  ),
                ],
              ),
            ],
          ),
          build: (pw.Context context) {
            return [
              // Tabel Data Modern (Tanpa Grid Vertikal)
              pw.TableHelper.fromTextArray(
                context: context,
                headers: [
                  'TANGGAL',
                  'NAMA / JUDUL',
                  'KATEGORI',
                  'MASUK',
                  'KELUAR',
                ],
                data: tableData,
                border: null,
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                  fontSize: 10,
                ),
                headerDecoration: pw.BoxDecoration(
                  color: primaryColor,
                  borderRadius: const pw.BorderRadius.vertical(
                    top: pw.Radius.circular(4),
                  ),
                ),
                rowDecoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
                  ),
                ),
                cellStyle: const pw.TextStyle(fontSize: 10),
                cellPadding: const pw.EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.centerLeft,
                  3: pw.Alignment.centerRight,
                  4: pw.Alignment.centerRight,
                },
              ),

              pw.SizedBox(height: 25),

              // Summary Section (Total Box)
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Container(
                    width: 250,
                    padding: const pw.EdgeInsets.all(15),
                    decoration: pw.BoxDecoration(
                      color: accentColor,
                      borderRadius: pw.BorderRadius.circular(8),
                      // FIX: Pakai lightBorderColor (bukan .withOpacity)
                      border: pw.Border.all(color: lightBorderColor),
                    ),
                    child: pw.Column(
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              "Total Pemasukan",
                              style: const pw.TextStyle(fontSize: 10),
                            ),
                            pw.Text(
                              toRupiah(_previewMasuk),
                              style: const pw.TextStyle(
                                fontSize: 10,
                                color: PdfColors.green700,
                              ),
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 5),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              "Total Pengeluaran",
                              style: const pw.TextStyle(fontSize: 10),
                            ),
                            pw.Text(
                              toRupiah(_previewKeluar),
                              style: const pw.TextStyle(
                                fontSize: 10,
                                color: PdfColors.red700,
                              ),
                            ),
                          ],
                        ),
                        pw.Divider(color: PdfColors.grey400),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              "SISA SALDO",
                              style: pw.TextStyle(
                                fontSize: 12,
                                fontWeight: pw.FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                            pw.Text(
                              toRupiah(_previewMasuk - _previewKeluar),
                              style: pw.TextStyle(
                                fontSize: 14,
                                fontWeight: pw.FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 30),

              // Kolom Tanda Tangan
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.SizedBox(),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text(
                        "Surabaya, ${DateFormat('d MMMM yyyy', 'id_ID').format(DateTime.now())}",
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.SizedBox(height: 50),
                      pw.Text(
                        "( Bendahara Kelas )",
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
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
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  // --- Helpers ---
  String _formatRupiah(int number) => NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  ).format(number);
  String _formatCompact(int number) =>
      NumberFormat.compactCurrency(locale: 'id_ID', symbol: '').format(number);

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

  // --- UI UTAMA ---
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
                            _fetchPreviewData();
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
                            _fetchPreviewData();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 2. LIVE DOCUMENT PREVIEW (Miniatur di Layar)
            Expanded(
              child: Center(
                child: _isLoadingPreview
                    ? const CircularProgressIndicator()
                    : _buildLiveDocumentPreview(primaryBlue),
              ),
            ),

            const SizedBox(height: 20),

            // 3. TOMBOL DOWNLOAD / PRINT
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

  // --- Widget Helper UI Layar ---
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

  Widget _buildLiveDocumentPreview(Color color) {
    if (_previewData.isEmpty) {
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
      height: 380,
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
