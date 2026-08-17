import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PrintSlipService {
  /// สร้าง PDF ของสลิป แล้วคืนค่าเป็น bytes
  static Future<Uint8List> generatePdf({
    required String queueNumber,
    required List<Map<String, dynamic>> items,
    required double totalPrice,
    required String orderId,
  }) async {
    final doc = pw.Document();

    final fontRegular = await rootBundle.load('assets/fonts/Kanit-Regular.ttf');
    final fontBold = await rootBundle.load('assets/fonts/Kanit-Bold.ttf');

    final thaiFont = pw.Font.ttf(fontRegular);
    final thaiFontBold = pw.Font.ttf(fontBold);
    final trackingUrl = 'https://qqqq-eb471.web.app/#/track?id=$orderId';

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 10,
        ),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                'ร้านป้าต้อย',
                style: pw.TextStyle(font: thaiFontBold, fontSize: 24),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                'คิวของคุณ',
                style: pw.TextStyle(font: thaiFont, fontSize: 16),
              ),
              pw.Text(
                queueNumber,
                style: pw.TextStyle(
                    font: thaiFontBold, fontSize: 45, lineSpacing: 1.2),
              ),
              pw.Divider(
                thickness: 1,
                borderStyle: pw.BorderStyle.dashed,
              ),

              // 3. รายการอาหาร (แสดงชื่อพร้อมจำนวนฝั่งซ้าย และราคารวมของรายการนั้นฝั่งขวา)
              ...items.map((item) {
                double itemTotal = (item['price'] ?? 0) * (item['qty'] ?? 1);
                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        "${item['name']} x${item['qty']}",
                        style: pw.TextStyle(font: thaiFont, fontSize: 12),
                      ),
                      pw.Text(
                        "${itemTotal.toStringAsFixed(0)} ฿",
                        style: pw.TextStyle(font: thaiFont, fontSize: 12),
                      ),
                    ],
                  ),
                );
              }).toList(),

              pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),

              // 4. ยอดรวมทั้งสิ้น
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    "ยอดรวมทั้งสิ้น",
                    style: pw.TextStyle(
                      font: thaiFontBold,
                      fontSize: 14, // 🟢 ปรับลดขนาดลงเล็กน้อยเช่นกัน
                    ),
                  ),
                  pw.Text(
                    "$totalPrice ฿",
                    style: pw.TextStyle(
                      font: thaiFontBold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.BarcodeWidget(
                barcode: pw.Barcode.qrCode(),
                data: trackingUrl,
                width: 100,
                height: 100,
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'สแกนคิวอาร์โค้ด',
                style: pw.TextStyle(font: thaiFontBold, fontSize: 14),
                textAlign: pw.TextAlign.center,
              ),
              pw.Text(
                'เพื่อดูสถานะคิวของคุณบนมือถือ',
                style: pw.TextStyle(font: thaiFont, fontSize: 12),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'ขอบคุณที่ใช้บริการค่ะ',
                style: pw.TextStyle(font: thaiFont, fontSize: 12),
                textAlign: pw.TextAlign.center,
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  /// ใช้ได้กับจุดอื่นที่ต้องการเปิดระบบพิมพ์โดยตรง
  static Future<void> printOrderSlip({
    required String queueNumber,
    required List<Map<String, dynamic>> items,
    required double totalPrice,
    required String orderId,
  }) async {
    await Printing.layoutPdf(
      name: 'Receipt_$queueNumber.pdf',
      onLayout: (PdfPageFormat format) {
        return generatePdf(
          queueNumber: queueNumber,
          items: items,
          totalPrice: totalPrice,
          orderId: orderId,
        );
      },
    );
  }
}
