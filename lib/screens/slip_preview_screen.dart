import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import 'package:qqqq/services/print_slip_service.dart';

class SlipPreviewScreen extends StatelessWidget {
  final String queueNumber;
  final List<Map<String, dynamic>> items;
  final double totalPrice;
  final String orderId;

  const SlipPreviewScreen({
    super.key,
    required this.queueNumber,
    required this.items,
    required this.totalPrice,
    required this.orderId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1D5A5D),
        foregroundColor: Colors.white,
        title: Text(
          'พรีวิวใบเสร็จ $queueNumber',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: PdfPreview(
        pdfFileName: 'Receipt_$queueNumber.pdf',
        initialPageFormat: PdfPageFormat.roll80,
        canChangePageFormat: false,
        canChangeOrientation: false,
        allowPrinting: true,
        allowSharing: true,
        build: (format) {
          return PrintSlipService.generatePdf(
            queueNumber: queueNumber,
            items: items,
            totalPrice: totalPrice,
            orderId: orderId,
          );
        },
      ),
    );
  }
}
