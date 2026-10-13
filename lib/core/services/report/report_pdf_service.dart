import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../../features/reports/report_calc.dart';
import '../../store/record_store.dart' show Rec;
import '../../utilities/currency_formatter.dart';


/// Membuat laporan PDF (penjualan & absensi) dan membagikannya
/// lewat menu share Android/iOS (WhatsApp, email, simpan, dll).
class ReportPdfService {
  static String _rp(num v) => CurrencyFormatter.format(v);
  static String _two(int n) => n.toString().padLeft(2, '0');
  static String _date(DateTime d) => '${_two(d.day)}/${_two(d.month)}/${d.year}';
  static String _time(DateTime d) => '${_two(d.hour)}:${_two(d.minute)}';

  static pw.Widget _kv(String k, String v, {bool bold = false}) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(k),
            pw.Text(v, style: pw.TextStyle(fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          ],
        ),
      );

  static pw.Widget _header(String title, String subtitle, String storeName) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(storeName, style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
          pw.Text(title, style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
          pw.Text(subtitle, style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
          pw.Divider(),
        ],
      );

  /// Laporan penjualan satu periode.
  static Future<File> salesReport({
    required ReportData data,
    required String title,
    required String rangeLabel,
    required int expenses,
    String storeName = 'Vecta POS',
  }) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (_) => [
          _header(title, rangeLabel, storeName),
          _kv('Pendapatan', _rp(data.revenue), bold: true),
          _kv('Jumlah transaksi', '${data.count}'),
          _kv('Barang terjual', '${data.items}'),
          _kv('Rata-rata per transaksi', _rp(data.avg)),
          _kv('Pembayaran tunai', _rp(data.cash)),
          _kv('Pembayaran non-tunai', _rp(data.bank)),
          _kv('Pengeluaran', _rp(expenses)),
          pw.Divider(),
          _kv('Estimasi laba bersih', _rp(data.revenue - expenses), bold: true),
          pw.SizedBox(height: 18),
          pw.Text('Produk terlaris', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          if (data.top.isEmpty)
            pw.Text('Belum ada penjualan.')
          else
            pw.TableHelper.fromTextArray(
              headers: ['Produk', 'Qty', 'Omzet'],
              data: [for (final p in data.top) [p.name, '${p.qty}', _rp(p.revenue)]],
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellAlignments: {1: pw.Alignment.centerRight, 2: pw.Alignment.centerRight},
            ),
          pw.SizedBox(height: 24),
          pw.Text('Dicetak ${_date(DateTime.now())} ${_time(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
        ],
      ),
    );
    return _save(doc, 'laporan_penjualan_${_stamp()}');
  }

  /// Rekap absensi untuk bulan [month] (hari pertama bulan).
  static Future<File> attendanceReport({
    required DateTime month,
    required List<Rec> employees,
    required List<Rec> attendance,
    String storeName = 'Vecta POS',
  }) async {
    final prefix = '${month.year}-${_two(month.month)}';
    final inMonth = attendance.where((a) => '${a['date'] ?? ''}'.startsWith(prefix)).toList();

    final rows = <List<String>>[];
    for (final e in employees) {
      var present = 0, leave = 0, minutes = 0;
      for (final a in inMonth.where((a) => a['empId'] == e['id'])) {
        if (a['status'] == 'leave') {
          leave++;
        } else if (a['status'] == 'present') {
          present++;
          final i = DateTime.tryParse('${a['inAt'] ?? ''}');
          final o = DateTime.tryParse('${a['outAt'] ?? ''}');
          if (i != null && o != null) minutes += o.difference(i).inMinutes;
        }
      }
      rows.add(['${e['name'] ?? ''}', '$present', '$leave', '${minutes ~/ 60}j ${minutes % 60}m']);
    }

    final detail = [...inMonth]
      ..sort((a, b) => '${a['date']}${a['empName']}'.compareTo('${b['date']}${b['empName']}'));

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (_) => [
          _header('Rekap Absensi', '${_two(month.month)}/${month.year}', storeName),
          pw.Text('Ringkasan per karyawan', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          if (rows.isEmpty)
            pw.Text('Belum ada karyawan.')
          else
            pw.TableHelper.fromTextArray(
              headers: ['Nama', 'Hadir', 'Izin/Sakit', 'Total jam'],
              data: rows,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellAlignments: {1: pw.Alignment.center, 2: pw.Alignment.center, 3: pw.Alignment.centerRight},
            ),
          pw.SizedBox(height: 18),
          pw.Text('Detail harian', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          if (detail.isEmpty)
            pw.Text('Belum ada data absensi bulan ini.')
          else
            pw.TableHelper.fromTextArray(
              headers: ['Tanggal', 'Nama', 'Status', 'Masuk', 'Pulang'],
              data: [
                for (final a in detail)
                  [
                    '${a['date']}',
                    '${a['empName'] ?? ''}',
                    a['status'] == 'leave' ? 'Izin/Sakit' : 'Hadir',
                    _t(a['inAt']),
                    _t(a['outAt']),
                  ],
              ],
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellStyle: const pw.TextStyle(fontSize: 10),
            ),
        ],
      ),
    );
    return _save(doc, 'rekap_absensi_${month.year}_${_two(month.month)}');
  }

  static String _t(dynamic v) {
    final d = DateTime.tryParse('${v ?? ''}')?.toLocal();
    return d == null ? '-' : _time(d);
  }

  static String _stamp() {
    final n = DateTime.now();
    return '${n.year}${_two(n.month)}${_two(n.day)}_${_two(n.hour)}${_two(n.minute)}';
  }

  static Future<File> _save(pw.Document doc, String name) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$name.pdf');
    await file.writeAsBytes(await doc.save(), flush: true);
    return file;
  }

  /// Buka menu share (pilih WhatsApp untuk mengirim ke nomor/grup).
  static Future<void> share(File file, {String? text}) async {
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path, mimeType: 'application/pdf')], text: text),
    );
  }
}
