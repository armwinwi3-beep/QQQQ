import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PrintSlipService {
  // ฟังก์ชันสำหรับเรียกปริ้นท์สลิป
  static Future<void> printOrderSlip({
    required String queueNumber,
    required List<Map<String, dynamic>> items,
    required double totalPrice,
    required String orderId,
  }) async {
    final doc = pw.Document();

    // 🔴 โหลดฟอนต์ภาษาไทย (Sarabun) อัตโนมัติจาก Google Fonts (แก้ปัญหาภาษาไทยเป็นสี่เหลี่ยม)
    final thaiFont = await PdfGoogleFonts.sarabunRegular();
    final thaiFontBold = await PdfGoogleFonts.sarabunBold();

    // ลิงก์สำหรับให้ลูกค้าสแกนดูคิว (เปลี่ยนเป็นลิงก์เว็บของคุณ)
    final String trackingUrl = "https://qqqq-eb471.web.app/#/track?id=$orderId";

    // เริ่มวาดหน้าสลิป
    doc.addPage(
      pw.Page(
        // ตั้งค่าหน้ากระดาษเป็นสลิปความร้อนขนาด 80mm (ถ้าเครื่องปริ้นท์เล็กให้ใช้ roll57)
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // 1. หัวสลิป
              pw.Text("ร้านป้าต้อย",
                  style: pw.TextStyle(font: thaiFontBold, fontSize: 24)),
              pw.SizedBox(height: 5),
              pw.Text("คิวของคุณ",
                  style: pw.TextStyle(font: thaiFont, fontSize: 16)),

              // 2. หมายเลขคิวตัวใหญ่ๆ
              pw.Text(queueNumber,
                  style: pw.TextStyle(font: thaiFontBold, fontSize: 45)),
              pw.Divider(
                  thickness: 1, borderStyle: pw.BorderStyle.dashed), // เส้นประ

              // 3. รายการอาหาร (วนลูปแสดงตามที่สั่ง)
              ...items.map((item) {
                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text("${item['name']} x${item['qty']}",
                          style: pw.TextStyle(font: thaiFont, fontSize: 14)),
                      pw.Text("${item['price']} ฿",
                          style: pw.TextStyle(font: thaiFont, fontSize: 14)),
                    ],
                  ),
                );
              }).toList(),

              pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),

              // 4. ยอดรวม
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("ยอดรวมทั้งสิ้น",
                      style: pw.TextStyle(font: thaiFontBold, fontSize: 16)),
                  pw.Text("$totalPrice ฿",
                      style: pw.TextStyle(font: thaiFontBold, fontSize: 16)),
                ],
              ),
              pw.SizedBox(height: 20),

              // 5. QR Code ให้ลูกค้าสแกน (สร้างง่ายๆ ด้วยวิดเจ็ต Barcode ของ pdf เลย)
              pw.BarcodeWidget(
                barcode: pw.Barcode.qrCode(),
                data: trackingUrl,
                width: 100,
                height: 100,
              ),
              pw.SizedBox(height: 10),
              pw.Text("สแกนคิวอาร์โค้ด",
                  style: pw.TextStyle(font: thaiFontBold, fontSize: 14)),
              pw.Text("เพื่อดูสถานะคิวของคุณบนมือถือ",
                  style: pw.TextStyle(font: thaiFont, fontSize: 12)),
              pw.SizedBox(height: 10),
              pw.Text("ขอบคุณที่ใช้บริการค่ะ",
                  style: pw.TextStyle(font: thaiFont, fontSize: 12)),
            ],
          );
        },
      ),
    );

    // คำสั่งนี้จะเด้งหน้าต่าง Preview ของเบราว์เซอร์/มือถือ ให้กดสั่งปริ้นท์ได้เลย
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Receipt_$queueNumber', // ชื่อไฟล์ตอนเซฟ
    );
  }
}
