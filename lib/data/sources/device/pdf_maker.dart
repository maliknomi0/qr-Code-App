import 'dart:typed_data';

import 'package:pdf/widgets.dart' as pw;

import '../../models/qr_item_model.dart';

class PdfMaker {
  Future<Uint8List> createHistoryPdf(List<QrItemModel> items) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(text: 'QR History'),
          for (final item in items)
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  item.data,
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                ),
                pw.Text('Created: ' '${item.createdAt}'),
                pw.SizedBox(height: 8),
              ],
            ),
        ],
      ),
    );
    return pdf.save();
  }
}
