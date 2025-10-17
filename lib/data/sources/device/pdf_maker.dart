import 'dart:typed_data';

import 'package:pdf/widgets.dart' as pw;
import 'package:qr_code/domain/entities/qr_source.dart';

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
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text('Created: ${item.createdAt}'),
                pw.Text('Source: ${_sourceLabel(item.source)}'),
                if (item.tags.isNotEmpty)
                  pw.Text('Tags: ${item.tags.join(', ')}'),
                pw.SizedBox(height: 8),
              ],
            ),
        ],
      ),
    );
    return pdf.save();
  }

  String _sourceLabel(int sourceIndex) {
    final normalized = sourceIndex.clamp(0, QrSource.values.length - 1);
    final source = QrSource.values[normalized];
    switch (source) {
      case QrSource.generated:
        return 'Generated';
      case QrSource.scanned:
        return 'Scanned';
      case QrSource.unknown:
        return 'Uncategorized';
    }
  }
}
