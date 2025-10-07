import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../data/models/expense_model.dart';
import '../data/models/attendance_model.dart';

class PDFService {
  static Future<void> generateMonthlyExpenseReport(
    List<ExpenseModel> expenses,
    int year,
    int month,
  ) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.openSansRegular();
    final fontBold = await PdfGoogleFonts.openSansBold();

    // Kategoriye göre grupla
    final Map<String, List<ExpenseModel>> groupedExpenses = {};
    final Map<String, double> categoryTotals = {};

    for (var expense in expenses) {
      if (!groupedExpenses.containsKey(expense.category)) {
        groupedExpenses[expense.category] = [];
        categoryTotals[expense.category] = 0;
      }
      groupedExpenses[expense.category]!.add(expense);
      categoryTotals[expense.category] =
          categoryTotals[expense.category]! + expense.amount;
    }

    final totalAmount = expenses.fold(
      0.0,
      (sum, expense) => sum + expense.amount,
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            // Başlık
            pw.Container(
              padding: const pw.EdgeInsets.only(bottom: 20),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'HARCAMA RAPORU',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 24,
                      color: PdfColors.blue800,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    '${DateFormat('MMMM yyyy', 'tr').format(DateTime(year, month))}',
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 16,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.Text(
                    'Rapor Tarihi: ${DateFormat('dd/MM/yyyy HH:mm', 'tr').format(DateTime.now())}',
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 12,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
            ),

            // Özet bilgileri
            pw.Container(
              padding: const pw.EdgeInsets.all(15),
              margin: const pw.EdgeInsets.only(bottom: 20),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: PdfColors.blue200),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Column(
                    children: [
                      pw.Text(
                        'TOPLAM HARCAMA',
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 12,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        expenses.length.toString(),
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 18,
                          color: PdfColors.blue800,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Text(
                        'TOPLAM TUTAR',
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 12,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        '₺${NumberFormat('#,##0.00', 'tr').format(totalAmount)}',
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 18,
                          color: PdfColors.green700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Kategoriye göre özet
            pw.Text(
              'KATEGORİ ÖZETİ',
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 16,
                color: PdfColors.grey800,
              ),
            ),
            pw.SizedBox(height: 10),

            pw.Table.fromTextArray(
              context: context,
              headerStyle: pw.TextStyle(
                font: fontBold,
                fontSize: 12,
                color: PdfColors.white,
              ),
              cellStyle: pw.TextStyle(font: font, fontSize: 11),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blue800,
              ),
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.center,
                2: pw.Alignment.centerRight,
                3: pw.Alignment.centerRight,
              },
              headers: ['Kategori', 'Adet', 'Tutar', 'Oran'],
              data: categoryTotals.entries.map((entry) {
                final count = groupedExpenses[entry.key]!.length;
                final percentage =
                    (entry.value / totalAmount * 100).toStringAsFixed(1);
                return [
                  entry.key,
                  count.toString(),
                  '₺${NumberFormat('#,##0.00', 'tr').format(entry.value)}',
                  '%$percentage',
                ];
              }).toList(),
            ),

            pw.SizedBox(height: 30),

            // Detaylar
            pw.Text(
              'HARCAMA DETAYLARI',
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 16,
                color: PdfColors.grey800,
              ),
            ),
            pw.SizedBox(height: 10),

            // Kategoriye göre harcamalar
            ...groupedExpenses.entries.map((entry) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    margin: const pw.EdgeInsets.only(top: 15, bottom: 10),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey200,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          entry.key.toUpperCase(),
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 12,
                            color: PdfColors.grey800,
                          ),
                        ),
                        pw.Text(
                          '₺${NumberFormat('#,##0.00', 'tr').format(categoryTotals[entry.key]!)}',
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 12,
                            color: PdfColors.green700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.Table.fromTextArray(
                    context: context,
                    headerStyle: pw.TextStyle(
                      font: fontBold,
                      fontSize: 10,
                      color: PdfColors.white,
                    ),
                    cellStyle: pw.TextStyle(font: font, fontSize: 10),
                    headerDecoration: const pw.BoxDecoration(
                      color: PdfColors.grey600,
                    ),
                    cellAlignments: {
                      0: pw.Alignment.centerLeft,
                      1: pw.Alignment.center,
                      2: pw.Alignment.centerRight,
                      3: pw.Alignment.centerLeft,
                    },
                    headers: ['Açıklama', 'Tarih', 'Tutar', 'Not'],
                    data: entry.value.map((expense) {
                      return [
                        expense.description,
                        DateFormat('dd/MM/yyyy', 'tr').format(expense.date),
                        '₺${NumberFormat('#,##0.00', 'tr').format(expense.amount)}',
                        expense.notes ?? '-',
                      ];
                    }).toList(),
                  ),
                ],
              );
            }),
          ];
        },
      ),
    );

    // PDF'i kaydet ve aç
    await _savePDF(
      pdf,
      'Harcama_Raporu_${DateFormat('yyyy_MM', 'tr').format(DateTime(year, month))}',
    );
  }

  static Future<void> generateAttendanceReport(
    MonthlyAttendanceSummary summary,
  ) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.openSansRegular();
    final fontBold = await PdfGoogleFonts.openSansBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            // Başlık
            pw.Container(
              padding: const pw.EdgeInsets.only(bottom: 20),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'PUANTAJ RAPORU',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 24,
                      color: PdfColors.blue800,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    summary.personnelName,
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 18,
                      color: PdfColors.grey800,
                    ),
                  ),
                  pw.Text(
                    '${DateFormat('MMMM yyyy', 'tr').format(DateTime(summary.year, summary.month))}',
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 16,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.Text(
                    'Rapor Tarihi: ${DateFormat('dd/MM/yyyy HH:mm', 'tr').format(DateTime.now())}',
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 12,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
            ),

            // Özet bilgileri
            pw.Container(
              padding: const pw.EdgeInsets.all(15),
              margin: const pw.EdgeInsets.only(bottom: 20),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: PdfColors.blue200),
              ),
              child: pw.Column(
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                    children: [
                      pw.Column(
                        children: [
                          pw.Text(
                            'TOPLAM GÜN',
                            style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 12,
                              color: PdfColors.grey700,
                            ),
                          ),
                          pw.SizedBox(height: 5),
                          pw.Text(
                            summary.totalWorkDays.toString(),
                            style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 18,
                              color: PdfColors.blue800,
                            ),
                          ),
                        ],
                      ),
                      pw.Column(
                        children: [
                          pw.Text(
                            'GELİŞ',
                            style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 12,
                              color: PdfColors.grey700,
                            ),
                          ),
                          pw.SizedBox(height: 5),
                          pw.Text(
                            summary.presentDays.toString(),
                            style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 18,
                              color: PdfColors.green700,
                            ),
                          ),
                        ],
                      ),
                      pw.Column(
                        children: [
                          pw.Text(
                            'DEVAMSIZLIK',
                            style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 12,
                              color: PdfColors.grey700,
                            ),
                          ),
                          pw.SizedBox(height: 5),
                          pw.Text(
                            (summary.totalWorkDays - summary.presentDays)
                                .toString(),
                            style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 18,
                              color: PdfColors.red700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 15),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                    children: [
                      pw.Column(
                        children: [
                          pw.Text(
                            'TOPLAM SAAT',
                            style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 12,
                              color: PdfColors.grey700,
                            ),
                          ),
                          pw.SizedBox(height: 5),
                          pw.Text(
                            summary.totalWorkHours.toStringAsFixed(1),
                            style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 18,
                              color: PdfColors.orange700,
                            ),
                          ),
                        ],
                      ),
                      pw.Column(
                        children: [
                          pw.Text(
                            'ORTALAMA SAAT',
                            style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 12,
                              color: PdfColors.grey700,
                            ),
                          ),
                          pw.SizedBox(height: 5),
                          pw.Text(
                            summary.averageWorkHours.toStringAsFixed(1),
                            style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 18,
                              color: PdfColors.purple700,
                            ),
                          ),
                        ],
                      ),
                      pw.Column(
                        children: [
                          pw.Text(
                            'DEVAM ORANI',
                            style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 12,
                              color: PdfColors.grey700,
                            ),
                          ),
                          pw.SizedBox(height: 5),
                          pw.Text(
                            '${summary.attendanceRate.toStringAsFixed(1)}%',
                            style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 18,
                              color: PdfColors.teal700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Günlük detaylar
            pw.Text(
              'GÜNLÜK DETAYLAR',
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 16,
                color: PdfColors.grey800,
              ),
            ),
            pw.SizedBox(height: 10),

            pw.Table.fromTextArray(
              context: context,
              headerStyle: pw.TextStyle(
                font: fontBold,
                fontSize: 12,
                color: PdfColors.white,
              ),
              cellStyle: pw.TextStyle(font: font, fontSize: 11),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blue800,
              ),
              oddRowDecoration: const pw.BoxDecoration(
                color: PdfColors.grey100,
              ),
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.center,
                2: pw.Alignment.center,
                3: pw.Alignment.centerLeft,
              },
              headers: ['Tarih', 'Durum', 'Mesai Saati', 'Not'],
              data: summary.attendances.map((attendance) {
                return [
                  DateFormat('dd/MM/yyyy - EEEE', 'tr').format(attendance.date),
                  attendance.isPresent ? 'GELDİ' : 'GELMEDİ',
                  attendance.isPresent ? '${attendance.workHours} saat' : '-',
                  attendance.notes ?? '-',
                ];
              }).toList(),
            ),
          ];
        },
      ),
    );

    await _savePDF(
      pdf,
      'Puantaj_${summary.personnelName.replaceAll(' ', '_')}_${DateFormat('yyyy_MM', 'tr').format(DateTime(summary.year, summary.month))}',
    );
  }

  static Future<void> _savePDF(pw.Document pdf, String fileName) async {
    try {
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/$fileName.pdf');
      await file.writeAsBytes(await pdf.save());

      // PDF'i varsayılan uygulamayla aç
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );

      // Aynı zamanda dosyayı paylaşılabilir konuma kaydet
      final documentsDir = await getApplicationDocumentsDirectory();
      final savedFile = File('${documentsDir.path}/$fileName.pdf');
      await savedFile.writeAsBytes(await pdf.save());

      print('PDF saved to: ${savedFile.path}');
    } catch (e) {
      throw Exception('PDF kaydedilemedi: $e');
    }
  }
}
