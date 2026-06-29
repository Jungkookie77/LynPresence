import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'attendance_service.dart';
import 'leave_service.dart';

class PdfService {
  static Future<void> generateAndPrintReport(
    int totalEmployees,
    int presentEmployees,
    int pendingRequests, {
    List<AttendanceRecord>? attendanceRecords,
    List<LeaveRequest>? leaveRequests,
  }) async {
    final pdf = pw.Document();
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    final fileDate = DateFormat('yyyyMMdd').format(DateTime.now());

    final records = attendanceRecords ?? [];
    final leaves = leaveRequests ?? [];

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(dateStr),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          _buildStatsSection(totalEmployees, presentEmployees, pendingRequests),
          pw.SizedBox(height: 24),
          if (records.isNotEmpty) ...[
            _buildSectionTitle('Pointages Récents'),
            pw.SizedBox(height: 8),
            _buildAttendanceTable(records),
            pw.SizedBox(height: 24),
          ],
          if (leaves.isNotEmpty) ...[
            _buildSectionTitle('Demandes de Congé'),
            pw.SizedBox(height: 8),
            _buildLeaveTable(leaves),
          ],
          pw.SizedBox(height: 24),
          pw.Text(
            'Ce rapport certifie l\'état des présences à l\'instant T pour l\'application RUThere — IAI Cameroun.',
            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600, fontStyle: pw.FontStyle.italic),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'rapport_presence_$fileDate.pdf',
    );
  }

  static pw.Widget _buildHeader(String dateStr) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('RUThere — Rapport Global de Présence',
                    style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.deepPurple700)),
                pw.Text('IAI Cameroun', style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('Généré le', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                pw.Text(dateStr, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              ],
            ),
          ],
        ),
        pw.Divider(color: PdfColors.deepPurple200, thickness: 1.5),
        pw.SizedBox(height: 4),
      ],
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text('RUThere © IAI Cameroun', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey500)),
        pw.Text('Page ${context.pageNumber} / ${context.pagesCount}',
            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey500)),
      ],
    );
  }

  static pw.Widget _buildStatsSection(int total, int present, int pending) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.deepPurple50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.deepPurple200),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildStatBox('Employés Total', '$total', PdfColors.deepPurple700),
          _buildStatBox('Présents Aujourd\'hui', '$present', PdfColors.green700),
          _buildStatBox('Congés en Attente', '$pending', PdfColors.orange700),
          _buildStatBox('Taux de Présence', total > 0 ? '${((present / total) * 100).toStringAsFixed(0)}%' : '—', PdfColors.blue700),
        ],
      ),
    );
  }

  static pw.Widget _buildStatBox(String label, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(value, style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: color)),
        pw.SizedBox(height: 4),
        pw.Text(label, style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
      ],
    );
  }

  static pw.Widget _buildSectionTitle(String title) {
    return pw.Text(title,
        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.deepPurple800));
  }

  static pw.Widget _buildAttendanceTable(List<AttendanceRecord> records) {
    final displayed = records.take(20).toList();
    return pw.TableHelper.fromTextArray(
      headers: ['Employé', 'Type', 'Date', 'Heure', 'Localisation'],
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.deepPurple700),
      cellStyle: const pw.TextStyle(fontSize: 9),
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.center,
        2: pw.Alignment.center,
        3: pw.Alignment.center,
        4: pw.Alignment.center,
      },
      data: displayed.map((r) {
        final typeLabel = r.type == 'IN' ? '▶ Entrée' : '◀ Sortie';
        final hasGeo = r.latitude != null && r.longitude != null;
        return [
          r.userName ?? 'Inconnu',
          typeLabel,
          DateFormat('dd/MM/yyyy').format(r.timestamp),
          DateFormat('HH:mm').format(r.timestamp),
          hasGeo ? '${r.latitude!.toStringAsFixed(4)}, ${r.longitude!.toStringAsFixed(4)}' : '—',
        ];
      }).toList(),
      oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
    );
  }

  static pw.Widget _buildLeaveTable(List<LeaveRequest> leaves) {
    return pw.TableHelper.fromTextArray(
      headers: ['Type', 'Du', 'Au', 'Statut', 'Motif'],
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.deepPurple700),
      cellStyle: const pw.TextStyle(fontSize: 9),
      data: leaves.map((l) {
        return [
          l.type,
          DateFormat('dd/MM/yyyy').format(l.startDate),
          DateFormat('dd/MM/yyyy').format(l.endDate),
          l.status,
          l.reason ?? '—',
        ];
      }).toList(),
      oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
    );
  }
}
