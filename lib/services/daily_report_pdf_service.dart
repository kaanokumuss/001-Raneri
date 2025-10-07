import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../data/models/daily_report_model.dart';

class DailyReportPDFService {
  static Future<void> generateDailyReport(DailyReportModel report) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.openSansRegular();
    final fontBold = await PdfGoogleFonts.openSansBold();

    final completedTasks =
        report.todayTasks.where((t) => t.status == TaskStatus.completed).length;
    final totalMaterialCost = report.materialsUsed
        .fold(0.0, (sum, material) => sum + material.totalCost);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            // Başlık
            _buildPDFHeader(report, font, fontBold),
            pw.SizedBox(height: 30),

            // Özet Bilgiler
            _buildPDFSummary(
                report, font, fontBold, completedTasks, totalMaterialCost),
            pw.SizedBox(height: 25),

            // Çalışan Durumu
            _buildPDFAttendance(report, font, fontBold),
            pw.SizedBox(height: 25),

            // Bugün Yapılan İşler
            if (report.todayTasks.isNotEmpty) ...[
              _buildPDFTodayTasks(report, font, fontBold),
              pw.SizedBox(height: 25),
            ],

            // Yarın Planı
            if (report.tomorrowPlans.isNotEmpty) ...[
              _buildPDFTomorrowPlans(report, font, fontBold),
              pw.SizedBox(height: 25),
            ],

            // Malzeme Kullanımı
            if (report.materialsUsed.isNotEmpty) ...[
              _buildPDFMaterials(report, font, fontBold),
              pw.SizedBox(height: 25),
            ],

            // Hava Durumu
            _buildPDFWeather(report, font, fontBold),
            pw.SizedBox(height: 25),

            // Güvenlik Olayları
            if (report.safetyIncidents.isNotEmpty) ...[
              _buildPDFSafety(report, font, fontBold),
              pw.SizedBox(height: 25),
            ],

            // Genel Notlar
            if (report.generalNotes.isNotEmpty) ...[
              _buildPDFNotes(report, font, fontBold),
            ],
          ];
        },
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 20),
            child: pw.Text(
              'Sayfa ${context.pageNumber}/${context.pagesCount} - Raneri Energy',
              style: pw.TextStyle(
                  font: font, fontSize: 10, color: PdfColors.grey600),
            ),
          );
        },
      ),
    );

    await _savePDF(
      pdf,
      'Gunluk_Rapor_${DateFormat('yyyy_MM_dd', 'tr').format(report.date)}',
    );
  }

  static pw.Widget _buildPDFHeader(
      DailyReportModel report, pw.Font font, pw.Font fontBold) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: PdfColors.blue200, width: 2),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'GÜNLÜK RAPOR',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 28,
                      color: PdfColors.blue800,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    DateFormat('dd MMMM yyyy - EEEE', 'tr').format(report.date),
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 18,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'RANERI ENERGY',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 16,
                      color: PdfColors.blue800,
                    ),
                  ),
                  pw.Text(
                    'Construction & Consultancy',
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 12,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 15),
          pw.Container(
            width: double.infinity,
            height: 1,
            color: PdfColors.blue200,
          ),
          pw.SizedBox(height: 15),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Proje: ${report.projectName}',
                      style: pw.TextStyle(font: fontBold, fontSize: 14),
                    ),
                    pw.Text(
                      'Raporlayan: ${report.reportedBy}',
                      style: pw.TextStyle(
                          font: font, fontSize: 12, color: PdfColors.grey700),
                    ),
                  ],
                ),
              ),
              pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFFE8F5E8),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Text(
                  'İlerleme: ${report.overallProgress.toStringAsFixed(1)}%',
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 12,
                    color: const PdfColor.fromInt(0xFF2E7D32),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPDFSummary(
    DailyReportModel report,
    pw.Font font,
    pw.Font fontBold,
    int completedTasks,
    double totalMaterialCost,
  ) {
    return pw.Container(
      child: pw.Column(
        children: [
          pw.Text(
            'GÜNLÜK ÖZET',
            style: pw.TextStyle(
                font: fontBold, fontSize: 16, color: PdfColors.grey800),
          ),
          pw.SizedBox(height: 15),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildPDFStatBox('Toplam İş',
                    report.todayTasks.length.toString(), PdfColors.blue),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: _buildPDFStatBox(
                    'Tamamlanan', completedTasks.toString(), PdfColors.green),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: _buildPDFStatBox(
                    'Çalışan',
                    report.attendanceSummary.presentWorkers.toString(),
                    const PdfColor.fromInt(0xFF00796B)),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: _buildPDFStatBox(
                    'Malzeme',
                    '₺${totalMaterialCost.toStringAsFixed(0)}',
                    PdfColors.orange),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPDFStatBox(
      String title, String value, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromRYB(
            color.red * 0.1, color.green * 0.1, color.blue * 0.1),
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: color, width: 0.5),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 18,
              color: color,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            title,
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPDFAttendance(
      DailyReportModel report, pw.Font font, pw.Font fontBold) {
    final attendance = report.attendanceSummary;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'ÇALIŞAN DURUMU',
          style: pw.TextStyle(
              font: fontBold, fontSize: 16, color: PdfColors.grey800),
        ),
        pw.SizedBox(height: 15),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _buildPDFTableCell('Toplam Çalışan', fontBold),
                _buildPDFTableCell('Gelen', fontBold),
                _buildPDFTableCell('Gelmeyen', fontBold),
                _buildPDFTableCell('Devam Oranı', fontBold),
              ],
            ),
            pw.TableRow(
              children: [
                _buildPDFTableCell(attendance.totalWorkers.toString(), font),
                _buildPDFTableCell(attendance.presentWorkers.toString(), font),
                _buildPDFTableCell(attendance.absentWorkers.toString(), font),
                _buildPDFTableCell(
                    '${attendance.attendancePercentage.toStringAsFixed(1)}%',
                    font),
              ],
            ),
          ],
        ),
        if (attendance.presentWorkerNames.isNotEmpty) ...[
          pw.SizedBox(height: 15),
          pw.Text(
            'Gelen Çalışanlar:',
            style: pw.TextStyle(font: fontBold, fontSize: 12),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            attendance.presentWorkerNames.join(', '),
            style: pw.TextStyle(
                font: font, fontSize: 11, color: PdfColors.grey700),
          ),
        ],
        if (attendance.absentWorkerNames.isNotEmpty) ...[
          pw.SizedBox(height: 10),
          pw.Text(
            'Gelmeyen Çalışanlar:',
            style: pw.TextStyle(font: fontBold, fontSize: 12),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            attendance.absentWorkerNames.join(', '),
            style: pw.TextStyle(
                font: font, fontSize: 11, color: PdfColors.grey700),
          ),
        ],
      ],
    );
  }

  static pw.Widget _buildPDFTodayTasks(
      DailyReportModel report, pw.Font font, pw.Font fontBold) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'BUGÜN YAPILAN İŞLER',
          style: pw.TextStyle(
              font: fontBold, fontSize: 16, color: PdfColors.grey800),
        ),
        pw.SizedBox(height: 15),
        pw.Table.fromTextArray(
          context: null,
          headerStyle: pw.TextStyle(
              font: fontBold, fontSize: 11, color: PdfColors.white),
          cellStyle: pw.TextStyle(font: font, fontSize: 10),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
          oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
          cellAlignments: {
            0: pw.Alignment.centerLeft,
            1: pw.Alignment.centerLeft,
            2: pw.Alignment.center,
            3: pw.Alignment.center,
            4: pw.Alignment.center,
            5: pw.Alignment.centerLeft,
          },
          headers: [
            'İş Başlığı',
            'Açıklama',
            'Durum',
            'İlerleme',
            'Çalışan',
            'Notlar'
          ],
          data: report.todayTasks.map((task) {
            return [
              task.title,
              task.description.length > 50
                  ? '${task.description.substring(0, 50)}...'
                  : task.description,
              _getTaskStatusTextForPDF(task.status),
              '${task.completionPercentage.toStringAsFixed(0)}%',
              '${task.assignedWorkers} kişi',
              task.notes ?? '-',
            ];
          }).toList(),
        ),
      ],
    );
  }

  static pw.Widget _buildPDFTomorrowPlans(
      DailyReportModel report, pw.Font font, pw.Font fontBold) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'YARIN PLANI',
          style: pw.TextStyle(
              font: fontBold, fontSize: 16, color: PdfColors.grey800),
        ),
        pw.SizedBox(height: 15),
        pw.Table.fromTextArray(
          context: null,
          headerStyle: pw.TextStyle(
              font: fontBold, fontSize: 11, color: PdfColors.white),
          cellStyle: pw.TextStyle(font: font, fontSize: 10),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.green800),
          oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
          cellAlignments: {
            0: pw.Alignment.centerLeft,
            1: pw.Alignment.centerLeft,
            2: pw.Alignment.center,
            3: pw.Alignment.center,
            4: pw.Alignment.centerLeft,
          },
          headers: ['İş Başlığı', 'Açıklama', 'Öncelik', 'Çalışan', 'Notlar'],
          data: report.tomorrowPlans.map((task) {
            return [
              task.title,
              task.description.length > 50
                  ? '${task.description.substring(0, 50)}...'
                  : task.description,
              _getPriorityTextForPDF(task.priority),
              '${task.assignedWorkers} kişi',
              task.notes ?? '-',
            ];
          }).toList(),
        ),
      ],
    );
  }

  static pw.Widget _buildPDFMaterials(
      DailyReportModel report, pw.Font font, pw.Font fontBold) {
    final totalCost = report.materialsUsed
        .fold(0.0, (sum, material) => sum + material.totalCost);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'MALZEME KULLANIMI',
              style: pw.TextStyle(
                  font: fontBold, fontSize: 16, color: PdfColors.grey800),
            ),
            pw.Container(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: pw.BoxDecoration(
                color: const PdfColor.fromInt(0xFFFFF3E0),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Text(
                'Toplam: ₺${totalCost.toStringAsFixed(2)}',
                style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 12,
                    color: const PdfColor.fromInt(0xFFE65100)),
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 15),
        pw.Table.fromTextArray(
          context: null,
          headerStyle: pw.TextStyle(
              font: fontBold, fontSize: 11, color: PdfColors.white),
          cellStyle: pw.TextStyle(font: font, fontSize: 10),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.orange800),
          oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
          cellAlignments: {
            0: pw.Alignment.centerLeft,
            1: pw.Alignment.center,
            2: pw.Alignment.center,
            3: pw.Alignment.centerRight,
            4: pw.Alignment.centerLeft,
            5: pw.Alignment.centerLeft,
          },
          headers: [
            'Malzeme',
            'Miktar',
            'Birim',
            'Toplam Maliyet',
            'Tedarikçi',
            'Not'
          ],
          data: report.materialsUsed.map((material) {
            return [
              material.materialName,
              material.quantity.toString(),
              material.unit,
              '₺${material.totalCost.toStringAsFixed(2)}',
              material.supplier,
              material.notes.isEmpty ? '-' : material.notes,
            ];
          }).toList(),
        ),
      ],
    );
  }

  static pw.Widget _buildPDFWeather(
      DailyReportModel report, pw.Font font, pw.Font fontBold) {
    final weather = report.weatherInfo;

    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.blue200),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'HAVA DURUMU',
            style: pw.TextStyle(
                font: fontBold, fontSize: 16, color: PdfColors.grey800),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Text(
                  '${_getWeatherTextForPDF(weather.condition)} - ${weather.temperature.toStringAsFixed(0)}°C',
                  style: pw.TextStyle(font: font, fontSize: 14),
                ),
              ),
              if (weather.affectedWork)
                pw.Container(
                  padding:
                      const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: pw.BoxDecoration(
                    color: const PdfColor.fromInt(0xFFFFF3E0),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(
                    'İş Etkilendi',
                    style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 10,
                        color: const PdfColor.fromInt(0xFFE65100)),
                  ),
                ),
            ],
          ),
          if (weather.description.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pw.Text(
              weather.description,
              style: pw.TextStyle(
                  font: font, fontSize: 12, color: PdfColors.grey700),
            ),
          ],
          if (weather.affectedWork &&
              weather.workImpact?.isNotEmpty == true) ...[
            pw.SizedBox(height: 8),
            pw.Text(
              'İş Etkisi: ${weather.workImpact!}',
              style: pw.TextStyle(
                  font: font,
                  fontSize: 12,
                  color: const PdfColor.fromInt(0xFFE65100)),
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _buildPDFSafety(
      DailyReportModel report, pw.Font font, pw.Font fontBold) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'GÜVENLİK OLAYLARI',
          style: pw.TextStyle(
              font: fontBold, fontSize: 16, color: PdfColors.grey800),
        ),
        pw.SizedBox(height: 15),
        pw.Table.fromTextArray(
          context: null,
          headerStyle: pw.TextStyle(
              font: fontBold, fontSize: 11, color: PdfColors.white),
          cellStyle: pw.TextStyle(font: font, fontSize: 10),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.red800),
          oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
          headers: [
            'Olay',
            'Ciddiyet',
            'Saat',
            'İlgili Kişi',
            'Aksiyon',
            'Durum'
          ],
          data: report.safetyIncidents.map((incident) {
            return [
              incident.title,
              _getSeverityTextForPDF(incident.severity),
              DateFormat('HH:mm').format(incident.time),
              incident.involvedPersonnel,
              incident.actionTaken.length > 30
                  ? '${incident.actionTaken.substring(0, 30)}...'
                  : incident.actionTaken,
              incident.resolved ? 'Çözüldü' : 'Beklemede',
            ];
          }).toList(),
        ),
      ],
    );
  }

  static pw.Widget _buildPDFNotes(
      DailyReportModel report, pw.Font font, pw.Font fontBold) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'GENEL NOTLAR',
            style: pw.TextStyle(
                font: fontBold, fontSize: 16, color: PdfColors.grey800),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            report.generalNotes,
            style: pw.TextStyle(
                font: font, fontSize: 12, color: PdfColors.grey700),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPDFTableCell(String text, pw.Font font) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(font: font, fontSize: 11),
      ),
    );
  }

  static String _getTaskStatusTextForPDF(TaskStatus status) {
    switch (status) {
      case TaskStatus.notStarted:
        return 'Başlanmadı';
      case TaskStatus.inProgress:
        return 'Devam Ediyor';
      case TaskStatus.completed:
        return 'Tamamlandı';
      case TaskStatus.delayed:
        return 'Gecikti';
      case TaskStatus.cancelled:
        return 'İptal';
    }
  }

  static String _getPriorityTextForPDF(String priority) {
    switch (priority) {
      case 'high':
        return 'Yüksek';
      case 'medium':
        return 'Orta';
      case 'low':
        return 'Düşük';
      default:
        return 'Orta';
    }
  }

  static String _getWeatherTextForPDF(WeatherCondition condition) {
    switch (condition) {
      case WeatherCondition.sunny:
        return 'Güneşli';
      case WeatherCondition.rainy:
        return 'Yağmurlu';
      case WeatherCondition.cloudy:
        return 'Bulutlu';
      case WeatherCondition.stormy:
        return 'Fırtınalı';
      case WeatherCondition.snowy:
        return 'Karlı';
    }
  }

  static String _getSeverityTextForPDF(SafetyLevel level) {
    switch (level) {
      case SafetyLevel.low:
        return 'Düşük';
      case SafetyLevel.medium:
        return 'Orta';
      case SafetyLevel.high:
        return 'Yüksek';
      case SafetyLevel.critical:
        return 'Kritik';
    }
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
