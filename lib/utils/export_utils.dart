// lib/utils/export_utils.dart DOSYASININ İÇERİĞİ
/*
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file_plus/open_file_plus.dart';

// ❗ DİKKAT: Bu import satırını kendi projenizdeki AnalysisViewModel dosyasının yoluna göre düzeltin.
import '../view_model/analysis_view_model.dart';


// Widget'ı resim verisine (Uint8List) çeviren yardımcı fonksiyon
Future<Uint8List> _captureWidget(GlobalKey key) async {
  RenderRepaintBoundary boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
  ui.Image image = await boundary.toImage(pixelRatio: 2.0); // Yüksek çözünürlük için
  ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  return byteData!.buffer.asUint8List();
}


// DIŞA AKTARMA DİYALOĞUNU GÖSTEREN ANA FONKSİYON
void showExportDialog(
    BuildContext context,
    AnalysisViewModel viewModel,
    Map<String, String> categoryNames,
    GlobalKey summaryKey,
    GlobalKey lineChartKey,
    GlobalKey pieChartKey,
    ) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Raporu Dışa Aktar'),
      content: Text(
        'Finansal raporunuz PDF formatında dışa aktarılacaktır. '
            'Dosya İndirilenler klasörüne kaydedilecek.',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('İptal')),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            _exportReportAsPdf(context, viewModel, categoryNames, summaryKey, lineChartKey, pieChartKey);
          },
          child: Text('Dışa Aktar'),
        ),
      ],
    ),
  );
}


// PDF OLUŞTURMA VE KAYDETME İŞLEMİNİ YÖNETEN FONKSİYON
Future<void> _exportReportAsPdf(
    BuildContext context,
    AnalysisViewModel viewModel,
    Map<String, String> categoryNames,
    GlobalKey summaryKey,
    GlobalKey lineChartKey,
    GlobalKey pieChartKey,
    ) async {
  var status = await Permission.storage.status;
  if (!status.isGranted) {
    status = await Permission.storage.request();
  }

  if (!status.isGranted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Dosya kaydetme izni reddedildi!'), backgroundColor: Colors.red),
    );
    return;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Rapor PDF olarak hazırlanıyor...')),
  );

  try {
    final summaryImage = await _captureWidget(summaryKey);
    final lineChartImage = await _captureWidget(lineChartKey);
    final pieChartImage = await _captureWidget(pieChartKey);

    final pdfBytes = await _createPdfReport(viewModel, categoryNames, summaryImage, lineChartImage, pieChartImage);
    final filePath = await _saveFile(pdfBytes, 'pdf');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Rapor başarıyla kaydedildi!'),
        backgroundColor: Colors.green,
        action: SnackBarAction(label: 'AÇ', onPressed: () => OpenFile.open(filePath)),
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Hata: Rapor oluşturulamadı. $e'), backgroundColor: Colors.red),
    );
  }
}


// PDF BELGESİNİ OLUŞTURAN ASIL FONKSİYON
Future<Uint8List> _createPdfReport(
    AnalysisViewModel viewModel,
    Map<String, String> categoryNames,
    Uint8List summaryImage,
    Uint8List lineChartImage,
    Uint8List pieChartImage,
    ) async {
  final pdf = pw.Document();
  final moneyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      header: (context) => pw.Container(
        alignment: pw.Alignment.center,
        margin: const pw.EdgeInsets.only(bottom: 20.0),
        child: pw.Text(
          'Aylık Finansal Rapor - ${DateFormat.yMMMM('tr_TR').format(DateTime.now())}',
          style: pw.Theme.of(context).header3,
        ),
      ),
      build: (context) => [
        pw.Header(level: 1, text: 'Genel Bakış'),
        pw.Image(pw.MemoryImage(summaryImage), fit: pw.BoxFit.contain),
        pw.SizedBox(height: 20),

        pw.Header(level: 1, text: 'Son 6 Aylık Gelir/Gider Trendi'),
        pw.Image(pw.MemoryImage(lineChartImage), fit: pw.BoxFit.contain),
        pw.SizedBox(height: 20),

        pw.Header(level: 1, text: 'Bu Ayki Harcama Dağılımı'),
        pw.Image(pw.MemoryImage(pieChartImage), fit: pw.BoxFit.contain),
        pw.SizedBox(height: 20),

        pw.Header(level: 1, text: 'Kategori Bazlı Gider Detayları'),
        _buildPdfExpenseTable(viewModel, categoryNames, moneyFormat),
      ],
    ),
  );

  return pdf.save();
}


pw.Widget _buildPdfExpenseTable(AnalysisViewModel viewModel, Map<String, String> categoryNames, NumberFormat moneyFormat) {
  final sortedExpenses = viewModel.expenseSummary.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  if (sortedExpenses.isEmpty) {
    return pw.Text('Bu ay için gider verisi bulunmamaktadır.');
  }

  final headers = ['Kategori', 'Tutar', 'Oran (%)'];
  final data = sortedExpenses.map((item) {
    final categoryName = categoryNames[item.key] ?? item.key;
    final amount = moneyFormat.format(item.value);
    final percentage = viewModel.totalExpense > 0
        ? ((item.value / viewModel.totalExpense) * 100).toStringAsFixed(1)
        : '0.0';
    return [categoryName, amount, '%$percentage'];
  }).toList();

  return pw.Table.fromTextArray(
    headers: headers,
    data: data,
    border: pw.TableBorder.all(color: PdfColors.grey),
    headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
    headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey),
    cellAlignment: pw.Alignment.centerLeft,
    cellAlignments: { 1: pw.Alignment.centerRight, 2: pw.Alignment.centerRight },
  );
}

Future<String> _saveFile(Uint8List content, String extension) async {
  final directory = await getDownloadsDirectory();
  if (directory == null) {
    throw Exception('İndirilenler klasörü bulunamadı.');
  }
  final path = directory.path;
  final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
  final file = File('$path/FinansalRapor_$timestamp.$extension');
  await file.writeAsBytes(content);
  return file.path;
}
*/
