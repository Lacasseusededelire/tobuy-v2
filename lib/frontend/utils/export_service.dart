import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tobuy/models/shopping_list.dart';

class ExportService {
  Future<void> exportToPdf(ShoppingList list) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Liste: ${list.name}', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 16),
            pw.Text('Articles:', style: pw.TextStyle(fontSize: 18)),
            ...list.items.map((item) => pw.Text(
                  '- ${item.name}: ${item.quantity} (Total: ${item.totalItemPrice} FCFA)${item.isChecked ? " [Acheté]" : ""}',
                )),
            pw.SizedBox(height: 16),
            pw.Text('Total: ${list.totalPrice} FCFA', style: pw.TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/list_${list.id}.pdf');
    await file.writeAsBytes(await pdf.save());
    await Share.shareXFiles([XFile(file.path)], text: 'Liste ${list.name}');
  }
}

final exportServiceProvider = Provider<ExportService>((ref) => ExportService());