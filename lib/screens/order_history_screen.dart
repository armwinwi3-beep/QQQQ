import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderHistoryScreen extends StatelessWidget {
  @override
  void _showHistoryDetail(BuildContext context, Map<String, dynamic> data) {
    var items =
        (data['items'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    var total = data['total_price'] ?? 0;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("รายละเอียดรายการ"),
          content: Container(
            width: double.maxFinite, // ให้กล่องกว้างเต็มพื้นที่เท่าที่ได้
            child: Column(
              mainAxisSize: MainAxisSize.min, // ให้กล่องยืดหดตามเนื้อหา
              children: [
                // ลิสต์รายการอาหาร
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      var item = items[index];
                      return ListTile(
                        title: Text(item['name'] ?? 'ไม่มีชื่อ'),
                        trailing: Text("x${item['qty'] ?? 0}"),
                      );
                    },
                  ),
                ),
                Divider(),
                Text("ราคาทั้งหมด: $total บาท",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("ปิด"),
            ),
          ],
        );
      },
    );
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("ประวัติการสั่งซื้อ")),
      body: StreamBuilder<QuerySnapshot>(
        // ดึงข้อมูลเรียงตามเวลาล่าสุด (ต้องทำ Index ถ้า Query ซับซ้อน)
        stream: FirebaseFirestore.instance
            .collection('orders')
            // .where('user_id', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
            .orderBy('created_at', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return Center(child: CircularProgressIndicator());

          var orders = snapshot.data!.docs;

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              var data = orders[index].data() as Map<String, dynamic>;
              var orderData = orders[index].data() as Map<String, dynamic>;
              String status = data['status'] ?? 'pending';

              return Card(
                child: ListTile(
                  title: Text(
                      "ออเดอร์วันที่: ${orderData['created_at']?.toDate().toString().substring(0, 16) ?? 'ไม่ระบุ'}"),
                  subtitle: Text("สถานะ: ${orderData['status'] ?? 'pending'}"),
                  trailing:
                      Icon(Icons.info_outline), // เพิ่มไอคอนให้รู้ว่ากดได้
                  onTap: () {
                    // เพิ่มส่วนนี้: เรียกฟังก์ชัน popup
                    _showHistoryDetail(context, orderData);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ฟังก์ชันช่วยแสดงไอคอนสถานะให้สวยๆ
  Widget _getStatusIcon(String status) {
    switch (status) {
      case 'completed':
        return Icon(Icons.check_circle, color: Colors.blue);
      case 'ready':
        return Icon(Icons.restaurant, color: Colors.green);
      default:
        return Icon(Icons.access_time, color: Colors.orange);
    }
  }
}
