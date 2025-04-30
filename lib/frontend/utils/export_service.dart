import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:tobuy/models/shopping_list.dart';
import 'package:tobuy/models/shopping_item.dart';

class ExportService {
  Future<File> exportToPdf(ShoppingList list) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Liste d\'achats: ${list.name}',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 20),
            pw.Text('Articles:', style: const pw.TextStyle(fontSize: 18)),
            pw.SizedBox(height: 10),
            ...list.items.map(
              (item) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 8),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      item.name,
                      style: const pw.TextStyle(fontSize: 14),
                    ),
                    pw.Text(
                      'Qté: ${item.quantity} | Prix: ${item.totalPrice} FCFA',
                      style: const pw.TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'Total: ${list.totalPrice} FCFA',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/${list.name.replaceAll(' ', '_')}.pdf');
    await file.writeAsBytes(await pdf.save());
    print('PDF exporté: ${file.path}');
    return file;
  }
}