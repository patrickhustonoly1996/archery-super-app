import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../db/database.dart';

/// Service for exporting scorecards to PDF format.
/// Follows World Archery official scorecard layout.
class ScorecardExportService {
  ScorecardExportService._();

  /// Generate a PDF scorecard for a session.
  static Future<Uint8List> generatePdf({
    required Session session,
    required RoundType roundType,
    required List<End> ends,
    required List<List<Arrow>> endArrows,
    required String archerName,
    String? archerDob,
    String? division,
    String? bowClass,
    String? eventName,
    String? location,
    Uint8List? archerSignature,
    Uint8List? witnessSignature,
    Uint8List? plotImage,
  }) async {
    final pdf = pw.Document();

    // Load fonts
    final pixelFont = await _loadFont('assets/fonts/VT323-Regular.ttf');
    final bodyFont = await _loadFont('assets/fonts/ShareTechMono-Regular.ttf');

    final date = session.completedAt ?? session.startedAt;
    final dateStr = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(
                pixelFont: pixelFont,
                bodyFont: bodyFont,
                roundName: roundType.name,
                eventName: eventName,
                date: dateStr,
                location: location ?? session.location,
              ),
              pw.SizedBox(height: 12),

              // Archer info
              _buildArcherInfo(
                bodyFont: bodyFont,
                archerName: archerName,
                dob: archerDob,
                division: division,
                bowClass: bowClass,
              ),
              pw.SizedBox(height: 16),

              // Scorecard table
              _buildScorecardTable(
                bodyFont: bodyFont,
                ends: ends,
                endArrows: endArrows,
                arrowsPerEnd: roundType.arrowsPerEnd,
                totalEnds: roundType.totalEnds,
                maxScore: roundType.maxScore,
                totalScore: session.totalScore,
                totalXs: session.totalXs,
              ),
              pw.SizedBox(height: 20),

              // Plot image (if provided)
              if (plotImage != null) ...[
                pw.Text(
                  'Arrow Plot',
                  style: pw.TextStyle(font: pixelFont, fontSize: 12),
                ),
                pw.SizedBox(height: 8),
                pw.Center(
                  child: pw.Image(
                    pw.MemoryImage(plotImage),
                    width: 200,
                    height: 200,
                  ),
                ),
                pw.SizedBox(height: 20),
              ],

              pw.Spacer(),

              // Signatures
              _buildSignatures(
                bodyFont: bodyFont,
                archerSignature: archerSignature,
                witnessSignature: witnessSignature,
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static Future<pw.Font> _loadFont(String path) async {
    try {
      final fontData = await rootBundle.load(path);
      return pw.Font.ttf(fontData);
    } catch (_) {
      // Fallback to built-in font
      return pw.Font.helvetica();
    }
  }

  static pw.Widget _buildHeader({
    required pw.Font pixelFont,
    required pw.Font bodyFont,
    required String roundName,
    String? eventName,
    required String date,
    String? location,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey700),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                roundName.toUpperCase(),
                style: pw.TextStyle(font: pixelFont, fontSize: 18),
              ),
              if (eventName != null)
                pw.Text(
                  eventName,
                  style: pw.TextStyle(font: bodyFont, fontSize: 10),
                ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                date,
                style: pw.TextStyle(font: bodyFont, fontSize: 12),
              ),
              if (location != null)
                pw.Text(
                  location,
                  style: pw.TextStyle(font: bodyFont, fontSize: 10, color: PdfColors.grey600),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildArcherInfo({
    required pw.Font bodyFont,
    required String archerName,
    String? dob,
    String? division,
    String? bowClass,
  }) {
    return pw.Row(
      children: [
        _infoBox('Archer', archerName, bodyFont, flex: 3),
        pw.SizedBox(width: 8),
        if (dob != null) ...[
          _infoBox('DOB', dob, bodyFont),
          pw.SizedBox(width: 8),
        ],
        if (division != null) ...[
          _infoBox('Division', division, bodyFont),
          pw.SizedBox(width: 8),
        ],
        if (bowClass != null)
          _infoBox('Class', bowClass, bodyFont),
      ],
    );
  }

  static pw.Widget _infoBox(String label, String value, pw.Font font, {int flex = 1}) {
    return pw.Expanded(
      flex: flex,
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey400),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label,
              style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey600),
            ),
            pw.Text(
              value,
              style: pw.TextStyle(font: font, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildScorecardTable({
    required pw.Font bodyFont,
    required List<End> ends,
    required List<List<Arrow>> endArrows,
    required int arrowsPerEnd,
    required int totalEnds,
    required int maxScore,
    required int totalScore,
    required int totalXs,
  }) {
    final rows = <pw.TableRow>[];

    // Header row
    rows.add(pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
      children: [
        _tableCell('End', bodyFont, isHeader: true),
        ...List.generate(arrowsPerEnd, (i) =>
            _tableCell('${i + 1}', bodyFont, isHeader: true)),
        _tableCell('E/T', bodyFont, isHeader: true),
        _tableCell('R/T', bodyFont, isHeader: true),
        _tableCell('10+X', bodyFont, isHeader: true),
        _tableCell('X', bodyFont, isHeader: true),
      ],
    ));

    // End rows
    int runningTotal = 0;
    int cumulative10s = 0;
    int cumulativeXs = 0;

    for (int i = 0; i < totalEnds; i++) {
      final hasEnd = i < ends.length;
      final end = hasEnd ? ends[i] : null;
      final arrows = hasEnd && i < endArrows.length ? endArrows[i] : <Arrow>[];

      if (hasEnd) {
        runningTotal += end!.endScore;
        cumulativeXs += end.endXs;
        cumulative10s += arrows.where((a) => a.score == 10).length;
      }

      rows.add(pw.TableRow(
        children: [
          _tableCell('${i + 1}', bodyFont),
          ...List.generate(arrowsPerEnd, (j) {
            if (j < arrows.length) {
              final arrow = arrows[j];
              return _tableCell(
                arrow.isX ? 'X' : arrow.score.toString(),
                bodyFont,
                highlight: arrow.score == 10 || arrow.isX,
              );
            }
            return _tableCell('-', bodyFont, muted: true);
          }),
          _tableCell(hasEnd ? end!.endScore.toString() : '', bodyFont),
          _tableCell(hasEnd ? runningTotal.toString() : '', bodyFont, highlight: true),
          _tableCell(hasEnd && cumulative10s > 0 ? cumulative10s.toString() : '', bodyFont),
          _tableCell(hasEnd && cumulativeXs > 0 ? cumulativeXs.toString() : '', bodyFont),
        ],
      ));
    }

    // Total row
    rows.add(pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
      children: [
        _tableCell('TOTAL', bodyFont, isHeader: true, colSpan: arrowsPerEnd + 1),
        ...List.generate(arrowsPerEnd, (_) => pw.SizedBox.shrink()),
        _tableCell('', bodyFont), // E/T
        _tableCell(totalScore.toString(), bodyFont, isHeader: true, highlight: true),
        _tableCell(cumulative10s.toString(), bodyFont, isHeader: true),
        _tableCell(totalXs.toString(), bodyFont, isHeader: true),
      ],
    ));

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      columnWidths: {
        0: const pw.FixedColumnWidth(30),
        ...Map.fromEntries(
          List.generate(arrowsPerEnd, (i) => MapEntry(i + 1, const pw.FixedColumnWidth(25))),
        ),
        arrowsPerEnd + 1: const pw.FixedColumnWidth(35),
        arrowsPerEnd + 2: const pw.FixedColumnWidth(40),
        arrowsPerEnd + 3: const pw.FixedColumnWidth(35),
        arrowsPerEnd + 4: const pw.FixedColumnWidth(30),
      },
      children: rows,
    );
  }

  static pw.Widget _tableCell(
    String text,
    pw.Font font, {
    bool isHeader = false,
    bool highlight = false,
    bool muted = false,
    int colSpan = 1,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: pw.Center(
        child: pw.Text(
          text,
          style: pw.TextStyle(
            font: font,
            fontSize: isHeader ? 9 : 10,
            fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: muted
                ? PdfColors.grey500
                : (highlight ? PdfColors.amber800 : PdfColors.black),
          ),
        ),
      ),
    );
  }

  static pw.Widget _buildSignatures({
    required pw.Font bodyFont,
    Uint8List? archerSignature,
    Uint8List? witnessSignature,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
      children: [
        _signatureBox('Archer Signature', archerSignature, bodyFont),
        pw.SizedBox(width: 40),
        _signatureBox('Witness Signature', witnessSignature, bodyFont),
      ],
    );
  }

  static pw.Widget _signatureBox(String label, Uint8List? signature, pw.Font font) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: 180,
          height: 60,
          decoration: pw.BoxDecoration(
            border: pw.Border(
              bottom: const pw.BorderSide(color: PdfColors.grey600),
            ),
          ),
          child: signature != null
              ? pw.Center(child: pw.Image(pw.MemoryImage(signature), height: 50))
              : pw.SizedBox.shrink(),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          label,
          style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey600),
        ),
      ],
    );
  }

  /// Share or print the PDF
  static Future<void> sharePdf(Uint8List pdfBytes, String filename) async {
    await Printing.sharePdf(bytes: pdfBytes, filename: filename);
  }

  /// Print the PDF directly
  static Future<void> printPdf(Uint8List pdfBytes) async {
    await Printing.layoutPdf(onLayout: (_) async => pdfBytes);
  }
}
