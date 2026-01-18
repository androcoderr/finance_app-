// lib/view_model/export_view_model.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/category_service.dart';
import 'analysis_view_model.dart';

enum ExportState { initial, loading, success, error }

class ExportViewModel with ChangeNotifier {
  ExportState _state = ExportState.initial;
  ExportState get state => _state;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void _setState(ExportState newState) {
    _state = newState;
    notifyListeners();
  }

  Future<void> generateAndExportReport(BuildContext context) async {
    _setState(ExportState.loading);
    _errorMessage = null;

    try {
      // 1. Gerekli AnalysisViewModel'i context'ten oku
      final analysisViewModel = Provider.of<AnalysisViewModel>(
        context,
        listen: false,
      );

      // 2. Verileri tazelemek için yükleme yap
      await analysisViewModel.loadAnalysisData();

      // 3. Veri kontrolü
      if (analysisViewModel.errorMessage != null) {
        throw Exception(
          "Veri yüklenirken hata oluştu: ${analysisViewModel.errorMessage}",
        );
      }
      // Veri yetersiz uyarısını kaldırdık (Kullanıcı talebi: boş da olsa rapor çıksın)
      /*
      if (analysisViewModel.totalExpense == 0 &&
          analysisViewModel.totalIncome == 0) {
        throw Exception("Rapor oluşturmak için yeterli veri bulunamadı.");
      }
      */

      // 4. Kategori isimlerini yükle
      final categories = await CategoryService.getCategories();
      final categoryNames = {for (var cat in categories) cat.id: cat.name};

      // 5. PDF'i oluştur
      final pdfBytes = await _createPdf(analysisViewModel, categoryNames);

      // 6. Dosyayı geçici dizine kaydet ve paylaş
      final filePath = await _saveFile(pdfBytes);
      
      // share_plus kullanarak dosyayı dışa aktar (Save to Files, WhatsApp, Mail vb.)
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'Finansal Rapor',
        text: 'Ekteki finansal raporunuzu inceleyebilirsiniz.',
      );

      _setState(ExportState.success);
    } catch (e) {
      _errorMessage = e.toString();
      _setState(ExportState.error);
    }
  }

  Future<Uint8List> _createPdf(
    AnalysisViewModel viewModel,
    Map<String, String> categoryNames,
  ) async {
    final pdf = pw.Document();
    final moneyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

    // PDF başlığını AnalysisViewModel'deki filtreye göre belirle
    String reportTitle;
    switch (viewModel.currentFilter) {
      case DateFilter.thisMonth:
        reportTitle =
            'Finansal Rapor - ${DateFormat.yMMMM('tr_TR').format(DateTime.now())}';
        break;
      case DateFilter.lastMonth:
        reportTitle =
            'Finansal Rapor - Gecen Ay (${DateFormat.yMMMM('tr_TR').format(DateTime.now().subtract(const Duration(days: 30)))})';
        break;
      case DateFilter.last3Months:
        reportTitle = 'Finansal Rapor - Son 3 Ay';
        break;
    }

    // Türkçe karakter sorunu olmaması için standart font kullanımı
    // Not: Özel bir .ttf fontu projenize eklenirse daha iyi Türkçe karakter desteği sağlanır.
    // Şimdilik standart font ile devam ediyoruz.

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (context) => pw.Container(
          alignment: pw.Alignment.center,
          margin: const pw.EdgeInsets.only(bottom: 20.0),
          child: pw.Text(
            reportTitle,
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
        ),
        build: (context) => [
          pw.Header(
            level: 1,
            text: 'Genel Bakis (${viewModel.currentFilter.name})',
          ),
          _buildSummaryTable(viewModel, moneyFormat),
          pw.SizedBox(height: 30),
          pw.Header(level: 1, text: 'Son 6 Aylik Gelir/Gider Trendi'),
          _buildMonthlyTrendTable(viewModel, moneyFormat),
          pw.SizedBox(height: 30),
          pw.Header(
            level: 1,
            text:
                'Kategori Bazli Gider Detaylari (${viewModel.currentFilter.name})',
          ),
          _buildPdfExpenseTable(viewModel, categoryNames, moneyFormat),
        ],
      ),
    );
    return pdf.save();
  }

  pw.Widget _buildSummaryTable(
    AnalysisViewModel viewModel,
    NumberFormat format,
  ) {
    return pw.TableHelper.fromTextArray(
      cellPadding: const pw.EdgeInsets.all(8),
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey),
      headers: ['Kalem', 'Tutar'],
      data: [
        ['Toplam Gelir', format.format(viewModel.totalIncome)],
        ['Toplam Gider', format.format(viewModel.totalExpense)],
        ['Net Bakiye', format.format(viewModel.netBalance)],
      ],
    );
  }

  pw.Widget _buildMonthlyTrendTable(
    AnalysisViewModel viewModel,
    NumberFormat moneyFormat,
  ) {
    final monthlyData = viewModel.getMonthlyTrendData();
    if (monthlyData.isEmpty) {
      return pw.Text('Yeterli aylik veri bulunmamaktadir.');
    }
    final headers = ['Ay', 'Gelir', 'Gider', 'Net'];
    final data = monthlyData.map((item) {
      final date = DateTime(DateTime.now().year, item['month']!.toInt());
      return [
        DateFormat('MMMM yyyy', 'tr_TR').format(date),
        moneyFormat.format(item['income']),
        moneyFormat.format(item['expense']),
        moneyFormat.format(item['income']! - item['expense']!),
      ];
    }).toList();
    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      border: pw.TableBorder.all(),
    );
  }

  pw.Widget _buildPdfExpenseTable(
    AnalysisViewModel viewModel,
    Map<String, String> categoryNames,
    NumberFormat moneyFormat,
  ) {
    final sortedExpenses = viewModel.expenseSummary.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (sortedExpenses.isEmpty) {
      return pw.Text('Bu ay icin gider verisi bulunmamaktadir.');
    }
    final headers = ['Kategori', 'Tutar', 'Oran (%)'];
    final data = sortedExpenses.map((item) {
      return [
        categoryNames[item.key] ?? item.key, // Kategori ismini bul
        moneyFormat.format(item.value),
        viewModel.totalExpense > 0
            ? '%${((item.value / viewModel.totalExpense) * 100).toStringAsFixed(1)}'
            : '%0.0',
      ];
    }).toList();
    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      border: pw.TableBorder.all(),
    );
  }

  Future<String> _saveFile(Uint8List content) async {
    // getTemporaryDirectory kullanıyoruz, bu sayede Android/iOS dosya izinleriyle uğraşmayız.
    // share_plus buradan dosyayı okuyup paylaşabilir.
    final directory = await getTemporaryDirectory();
    final path = directory.path;
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('$path/FinansalRapor_$timestamp.pdf');
    await file.writeAsBytes(content);
    return file.path;
  }
}
