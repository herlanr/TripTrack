import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../models/trip.dart';
import '../models/vehicle.dart';
import '../utils/format.dart';

/// Handles exporting Fahrtenbuch trip logs into .csv or real PDF files.
/// Works cross-platform (Chrome/Web, Android, iOS) using in-memory XFile data.
class ExportService {
  /// Generates the requested file format and opens the native Share / Download dialog.
  static Future<void> exportTrips({
    required List<Trip> trips,
    required String format, // 'csv' or 'pdf'
    Vehicle? vehicleFilter,
  }) async {
    final filteredTrips = vehicleFilter != null
        ? trips.where((t) => t.vehicleId == vehicleFilter.id).toList()
        : trips;

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    Uint8List bytes;
    String filename;
    String mimeType;

    if (format == 'pdf') {
      bytes = await _generatePdf(filteredTrips);
      filename = 'fahrtenbuch_$timestamp.pdf';
      mimeType = 'application/pdf';
    } else {
      final csvContent = _generateCsv(filteredTrips);
      bytes = Uint8List.fromList(utf8.encode(csvContent));
      filename = 'fahrtenbuch_$timestamp.csv';
      mimeType = 'text/csv';
    }

    final xFile = XFile.fromData(
      bytes,
      name: filename,
      mimeType: mimeType,
    );

    await SharePlus.instance.share(
      ShareParams(
        files: [xFile],
        subject: 'Fahrtenbuch Export ($format)',
      ),
    );
  }

  /// Generates a real formatted PDF document with styled tables.
  static Future<Uint8List> _generatePdf(List<Trip> trips) async {
    final pdf = pw.Document();

    final tableHeaders = [
      '#',
      'Fahrer',
      'Startzeit',
      'Endzeit',
      'Startort',
      'Zielort',
      'Strecke',
      'Dauer',
    ];

    final tableData = <List<String>>[];
    for (int i = 0; i < trips.length; i++) {
      final t = trips[i];
      tableData.add([
        '${i + 1}',
        t.driverName,
        formatDateTime(t.startTime),
        t.endTime != null ? formatDateTime(t.endTime!) : '—',
        t.startLocationText ?? '—',
        t.endLocationText ?? '—',
        formatKm(t.distanceKm),
        formatDuration(t.duration),
      ]);
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'TripTrack - Fahrtenbuch Export',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green800,
                  ),
                ),
                pw.Text(
                  'Erstellt: ${formatDateTime(DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: tableHeaders,
            data: tableData,
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.green700,
            ),
            rowDecoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
            ),
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.all(6),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static String _generateCsv(List<Trip> trips) {
    final List<List<dynamic>> rows = [
      [
        'ID',
        'Fahrer',
        'Startzeit',
        'Endzeit',
        'Startort',
        'Zielort',
        'Start KM',
        'Strecke (KM)',
        'Dauer (min)',
        'GPS Punkte'
      ]
    ];

    for (final t in trips) {
      rows.add([
        t.id,
        t.driverName,
        formatDateTime(t.startTime),
        t.endTime != null ? formatDateTime(t.endTime!) : '—',
        t.startLocationText ?? '—',
        t.endLocationText ?? '—',
        formatKmValue(t.startKm),
        formatKmValue(t.distanceKm),
        t.duration.inMinutes,
        t.routePoints.length,
      ]);
    }

    return rows
        .map((row) => row.map((field) => '"$field"').join(','))
        .join('\n');
  }
}
