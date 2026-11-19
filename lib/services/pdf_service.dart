import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'database_service.dart';

class PdfService {
  /// Genera y abre el diálogo de descarga/impresión del historial
  static Future<void> generateAndDownloadPdf({
    required String loteName,
    required String crop,
  }) async {
    final pdf = pw.Document();

    // 1. Leemos el historial guardado en Hive
    final historyBox = DatabaseService.history;
    final historyList = historyBox.values.toList();

    // 2. Diseñamos la estructura visual del PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Encabezado del reporte
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'ESSENZA - Reporte de Historial',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green800,
                    ),
                  ),
                  pw.Text(
                    DateTime.now().toString().split(' ')[0],
                    style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            // Detalles del Lote y Cultivo
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.green50,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Lote: $loteName', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('Cultivo: $crop', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            pw.Text(
              'Registros de Actividades:',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),

            // Tabla con los registros cargados de Hive
            if (historyList.isEmpty)
              pw.Text('No hay registros detallados guardados en la base de datos Hive.')
            else
              pw.TableHelper.fromTextArray(
                headers: ['Fecha', 'Actividad', 'Detalle / Observación'],
                data: historyList.map((item) {
                  final map = item is Map ? item : {};
                  return [
                    map['date'] ?? 'N/A',
                    map['activity'] ?? 'General',
                    map['detail'] ?? map['description'] ?? 'Sin detalle',
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.green700),
                rowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
                cellAlignment: pw.Alignment.centerLeft,
                cellPadding: const pw.EdgeInsets.all(6),
              ),
          ];
        },
      ),
    );

    // 3. Permite guardar/descargar el archivo PDF directamente en el navegador o dispositivo sin internet
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Reporte_Essenza_$loteName.pdf',
    );
  }
}