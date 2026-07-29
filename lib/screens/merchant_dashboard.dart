import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import 'dart:async';

class MerchantDashboard extends StatelessWidget {
  const MerchantDashboard({super.key});

  @override
  void _showOrderDetails(BuildContext context, DocumentSnapshot doc) {
    var data = doc.data() as Map<String, dynamic>;
    var items =
        (data['items'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    var total = data['total_price'] ?? 0;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("รายละเอียดออเดอร์"),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...items.map((item) => ListTile(
                      title: Text(item['name'] ?? 'ไม่มีชื่อ'),
                      trailing: Text("price ${item['price'] ?? 0}"
                          " x ${item['qty'] ?? 0}"),
                    )),
                const Divider(),
                Text("ราคารวม: $total บาท",
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("ปิด", style: TextStyle(color: Colors.grey))),

            // 🟢 เพิ่มปุ่ม "ยกเลิก" สีแดง สำหรับแม่ค้า
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade400),
              onPressed: () {
                // โชว์ Popup ถามเพื่อความชัวร์ก่อนแม่ค้าจะกดยกเลิก
                showDialog(
                  context: context,
                  builder: (BuildContext confirmContext) {
                    return AlertDialog(
                      title: const Text("ยกเลิกออเดอร์ลูกค้า"),
                      content: const Text("ต้องการยกเลิกออเดอร์นี้ใช่หรือไม่?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(confirmContext),
                          child: const Text("ปิด"),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red),
                          onPressed: () async {
                            // 1. อัปเดตสถานะใน Firestore เป็น cancelled
                            await FirebaseFirestore.instance
                                .collection('orders')
                                .doc(doc.id)
                                .update({'status': 'cancelled'});

                            // 2. ปิด Popup ยืนยัน และ Popup รายละเอียด
                            if (context.mounted) {
                              Navigator.pop(confirmContext);
                              Navigator.pop(context);
                            }
                          },
                          child: const Text("ยืนยันยกเลิก",
                              style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    );
                  },
                );
              },
              child: const Text("ยกเลิกออเดอร์",
                  style: TextStyle(color: Colors.white)),
            ),

            // ปุ่มทำรายการเสร็จสิ้น (สีเขียว)
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () async {
                // 1. อัปเดตสถานะใน Firestore
                await FirebaseFirestore.instance
                    .collection('orders')
                    .doc(doc.id)
                    .update({
                  'status': 'completed',
                });
                // 2. ปิด Popup
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text("ทำรายการเสร็จสิ้น",
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override // เพิ่ม @override เพื่อความถูกต้องตามหลักของ StatelessWidget
  Widget build(BuildContext context) {
    return Scaffold(
      // เอา AppBar ออกตามที่เราเคยทำหน้า Modern UI ไปแล้ว เพื่อไม่ให้หัวแอปซ้อนกัน
      // appBar: AppBar(
      //   title: Text("Dashboard แม่ค้า"),
      // ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('status', isEqualTo: 'pending')
            .orderBy('created_at', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var orders = snapshot.data!.docs;

          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text("ยังไม่มีออเดอร์ใหม่",
                      style:
                          TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              var doc = orders[index];
              var data = doc.data() as Map<String, dynamic>;
              Timestamp? createdAt = data['created_at'] as Timestamp?;
              String orderCode = data['order_code'] ?? doc.id;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF1F7A83),
                    child: Text("${index + 1}",
                        style: const TextStyle(color: Colors.white)),
                  ),
                  title: Text("ออเดอร์: $orderCode",
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("สถานะ: รอดำเนินการ",
                          style: TextStyle(color: Colors.orange)),
                      // เรียกใช้ Widget จับเวลาที่เราสร้างไว้!
                      TimeElapsedWidget(createdAt: createdAt),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showOrderDetails(context, doc),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class TimeElapsedWidget extends StatefulWidget {
  final Timestamp? createdAt;

  const TimeElapsedWidget({super.key, required this.createdAt});

  @override
  _TimeElapsedWidgetState createState() => _TimeElapsedWidgetState();
}

class _TimeElapsedWidgetState extends State<TimeElapsedWidget> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // สั่งให้รีเฟรชหน้าจอตัวเองทุกๆ 1 วินาที
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // ยกเลิกการนับเวลาเมื่อปิดหน้าจอ (ป้องกันแอปค้าง)
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.createdAt == null) {
      return const Text("กำลังรับข้อมูลเวลา...",
          style: TextStyle(color: Colors.grey, fontSize: 12));
    }

    // คำนวณความต่างของเวลาปัจจุบัน กับเวลาที่สั่ง
    DateTime orderTime = widget.createdAt!.toDate();
    Duration diff = DateTime.now().difference(orderTime);

    int minutes = diff.inMinutes;
    int seconds = diff.inSeconds % 60; // เอาเศษวินาทีที่เหลือจากการหาร 60

    // ลูกเล่นเสริม: เปลี่ยนสีตัวหนังสือตามความนาน (แดงถ้านานกว่า 15 นาที)
    Color textColor = minutes >= 15
        ? Colors.red
        : (minutes >= 5 ? Colors.orange : Colors.green);

    return Text(
      "รอมาแล้ว: $minutes นาที $seconds วินาที",
      style: TextStyle(
          color: textColor, fontWeight: FontWeight.bold, fontSize: 13),
    );
  }
}
