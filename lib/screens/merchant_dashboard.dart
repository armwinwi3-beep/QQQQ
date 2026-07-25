import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import 'dart:async';

class MerchantDashboard extends StatelessWidget {
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
          title: Text("รายละเอียดออเดอร์"),
          content: Container(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...items.map((item) => ListTile(
                      title: Text(item['name'] ?? 'ไม่มีชื่อ'),
                      trailing: Text("price ${item['price'] ?? 0}" +
                          " x ${item['qty'] ?? 0}"),
                    )),
                Divider(),
                Text("ราคารวม: $total บาท",
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context), child: Text("ปิด")),
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
                Navigator.pop(context);
              },
              child: Text("ทำรายการเสร็จสิ้น",
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Dashboard แม่ค้า"),
        actions: [
          // เพิ่มปุ่ม Logout ตรงนี้ครับ
          IconButton(
            icon: Icon(Icons.logout),
            tooltip: 'ออกจากระบบ',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              // พอคำสั่งนี้ทำงานปุ๊บ ระบบจะดีดกลับไปหน้า Login อัตโนมัติ
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('status', isEqualTo: 'pending')
            .orderBy('created_at', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return Center(child: CircularProgressIndicator());

          var orders = snapshot.data!.docs;

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              var doc = orders[index];
              var data = doc.data() as Map<String, dynamic>;
              Timestamp? createdAt = data['created_at'] as Timestamp?;
              String orderCode = data['order_code'] ?? doc.id;
              return Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text("${index + 1}")),
                  title: Text("ออเดอร์: $orderCode"),

                  // เปลี่ยน subtitle จาก Text ธรรมดา เป็น Column เพื่อให้ใส่ได้ 2 บรรทัด
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("สถานะ: รอดำเนินการ"),

                      // เรียกใช้ Widget จับเวลาที่เราสร้างไว้!
                      TimeElapsedWidget(createdAt: createdAt),
                    ],
                  ),

                  trailing: Icon(Icons.arrow_forward_ios),
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

  const TimeElapsedWidget({Key? key, required this.createdAt})
      : super(key: key);

  @override
  _TimeElapsedWidgetState createState() => _TimeElapsedWidgetState();
}

class _TimeElapsedWidgetState extends State<TimeElapsedWidget> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // สั่งให้รีเฟรชหน้าจอตัวเองทุกๆ 1 วินาที
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
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
      return Text("กำลังรับข้อมูลเวลา...",
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
