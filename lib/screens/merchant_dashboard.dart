import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';

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
                      trailing: Text("price${item['price '] ?? 0}" +
                          " x${item['qty'] ?? 0}"),
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
      appBar: AppBar(title: Text("Dashboard แม่ค้า")),
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
              return Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text("${index + 1}")), // เลขคิว
                  title: Text(
                      "ออเดอร์: ${doc.id.substring(0, 5)}"), // โชว์แค่ 5 ตัวแรก
                  subtitle: Text("สถานะ: รอดำเนินการ"),
                  trailing: Icon(Icons.arrow_forward_ios),
                  onTap: () =>
                      _showOrderDetails(context, doc), // คลิกแล้วเด้ง Popup
                ),
              );
            },
          );
        },
      ),
    );
  }
}
