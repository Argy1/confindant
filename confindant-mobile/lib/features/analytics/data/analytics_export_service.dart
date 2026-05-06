import 'dart:convert';
import 'dart:typed_data';

import 'package:confindant/features/analytics/models/advanced_analytics_models.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class AnalyticsExportService {
  Future<ExportResult> export(ExportRequest request) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final nameBase = 'confindant_analytics_$timestamp';

    if (request.format == ExportFormat.csv) {
      final csv = _buildCsv(request);
      final bytes = Uint8List.fromList(utf8.encode(csv));
      final path = await FileSaver.instance.saveFile(
        name: nameBase,
        bytes: bytes,
        fileExtension: 'csv',
        mimeType: MimeType.csv,
      );
      return ExportResult(
        fileName: '$nameBase.csv',
        success: true,
        message: 'CSV exported to: $path',
      );
    }

    final pdfBytes = await _buildPdf(request);
    final path = await FileSaver.instance.saveFile(
      name: nameBase,
      bytes: pdfBytes,
      fileExtension: 'pdf',
      mimeType: MimeType.pdf,
    );
    return ExportResult(
      fileName: '$nameBase.pdf',
      success: true,
      message: 'PDF exported to: $path',
    );
  }

  String _buildCsv(ExportRequest request) {
    final data = request.data;
    final buffer = StringBuffer();
    buffer.writeln('Confindant Analytics Report');
    buffer.writeln('Generated At,${DateTime.now().toIso8601String()}');
    buffer.writeln('Period,${request.period.name}');
    buffer.writeln('Filter From,${request.filter.fromDateLabel}');
    buffer.writeln('Filter To,${request.filter.toDateLabel}');
    buffer.writeln('Wallet,${request.filter.wallet}');
    buffer.writeln('Category,${request.filter.category}');
    buffer.writeln();

    buffer.writeln('Summary');
    buffer.writeln('Metric,Amount');
    buffer.writeln('Total Income,${data.summary.totalIncome.toStringAsFixed(2)}');
    buffer.writeln('Total Expense,${data.summary.totalExpense.toStringAsFixed(2)}');
    buffer.writeln('Net Saving,${data.summary.netSaving.toStringAsFixed(2)}');
    buffer.writeln();

    buffer.writeln('Category Breakdown');
    buffer.writeln('Category,Amount');
    for (final item in data.categoryBreakdown) {
      buffer.writeln('${_csv(item.label)},${item.amount.toStringAsFixed(2)}');
    }
    buffer.writeln();

    buffer.writeln('Trend');
    buffer.writeln('Label,Amount');
    for (final point in data.trendPoints) {
      buffer.writeln('${_csv(point.label)},${point.amount.toStringAsFixed(2)}');
    }
    buffer.writeln();

    buffer.writeln('Budget Progress');
    buffer.writeln('Category,Used,Limit,Progress (%)');
    for (final budget in data.budgetProgress) {
      buffer.writeln(
        '${_csv(budget.category)},${budget.used.toStringAsFixed(2)},${budget.limit.toStringAsFixed(2)},${(budget.progress * 100).toStringAsFixed(1)}',
      );
    }
    buffer.writeln();
    buffer.writeln('Insight,${_csv(data.insightText)}');
    return buffer.toString();
  }

  Future<Uint8List> _buildPdf(ExportRequest request) async {
    final data = request.data;
    final doc = pw.Document();
    final logoBytes = (await rootBundle.load('assets/images/app_logo.png'))
        .buffer
        .asUint8List();
    final logo = pw.MemoryImage(logoBytes);

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.all(24),
          theme: pw.ThemeData.withFont(
            base: pw.Font.helvetica(),
            bold: pw.Font.helveticaBold(),
          ),
        ),
        build: (context) => [
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              borderRadius: pw.BorderRadius.circular(12),
              color: PdfColor.fromHex('#EAF2FF'),
            ),
            child: pw.Row(
              children: [
                pw.ClipRRect(
                  horizontalRadius: 8,
                  verticalRadius: 8,
                  child: pw.Image(logo, width: 48, height: 48, fit: pw.BoxFit.cover),
                ),
                pw.SizedBox(width: 12),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Confindant',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#0A2472'),
                      ),
                    ),
                    pw.Text(
                      'Analytics Report',
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: PdfColor.fromHex('#364153'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 14),
          pw.Text(
            'Generated: ${DateTime.now().toIso8601String()}',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.Text('Period: ${request.period.name}', style: const pw.TextStyle(fontSize: 10)),
          pw.Text(
            'Filter: ${request.filter.fromDateLabel} - ${request.filter.toDateLabel} | ${request.filter.wallet} | ${request.filter.category}',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 14),
          _sectionTitle('Summary'),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#0A2472'),
            ),
            cellAlignment: pw.Alignment.centerLeft,
            headers: ['Metric', 'Amount'],
            data: [
              ['Total Income', _money(data.summary.totalIncome)],
              ['Total Expense', _money(data.summary.totalExpense)],
              ['Net Saving', _money(data.summary.netSaving)],
            ],
          ),
          pw.SizedBox(height: 12),
          _sectionTitle('Category Breakdown'),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#0A2472'),
            ),
            headers: ['Category', 'Amount'],
            data: data.categoryBreakdown
                .map((e) => [e.label, _money(e.amount)])
                .toList(),
          ),
          pw.SizedBox(height: 12),
          _sectionTitle('Trend'),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#0A2472'),
            ),
            headers: ['Label', 'Amount'],
            data: data.trendPoints.map((e) => [e.label, _money(e.amount)]).toList(),
          ),
          pw.SizedBox(height: 12),
          _sectionTitle('Budget Progress'),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#0A2472'),
            ),
            headers: ['Category', 'Used', 'Limit', 'Progress'],
            data: data.budgetProgress
                .map(
                  (e) => [
                    e.category,
                    _money(e.used),
                    _money(e.limit),
                    '${(e.progress * 100).toStringAsFixed(1)}%',
                  ],
                )
                .toList(),
          ),
          pw.SizedBox(height: 12),
          _sectionTitle('Insight'),
          pw.Text(data.insightText.isEmpty ? '-' : data.insightText),
        ],
      ),
    );

    return doc.save();
  }

  pw.Widget _sectionTitle(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          fontSize: 13,
          color: PdfColor.fromHex('#0A2472'),
        ),
      ),
    );
  }

  String _money(double value) {
    final raw = value.toStringAsFixed(0);
    final chars = raw.split('').reversed.toList();
    final chunks = <String>[];
    for (var i = 0; i < chars.length; i++) {
      if (i > 0 && i % 3 == 0) {
        chunks.add('.');
      }
      chunks.add(chars[i]);
    }
    return 'Rp ${chunks.reversed.join()}';
  }

  String _csv(String input) {
    final escaped = input.replaceAll('"', '""');
    return '"$escaped"';
  }
}
