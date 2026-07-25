import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrderHistoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // ดึง UID ของผู้ใช้ปัจจุบัน
    String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text("ประวัติการสั่งซื้อของฉัน"),
      ),
      body: currentUserId == null
          ? Center(child: Text("ไม่พบข้อมูลผู้ใช้งาน"))
          : StreamBuilder<QuerySnapshot>(
              // กรองเฉพาะออเดอร์ที่ user_id ตรงกับผู้ใช้ปัจจุบัน
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .where('user_id', isEqualTo: currentUserId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                      child: Text("เกิดข้อผิดพลาด: ${snapshot.error}"));
                }
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                var orders = snapshot.data!.docs;

                if (orders.isEmpty) {
                  return Center(child: Text("ยังไม่มีประวัติการสั่งซื้อ"));
                }

                return ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    var doc = orders[index];
                    var orderData = doc.data() as Map<String, dynamic>;
                    var orderCode = orderData['order_code'] ?? 'ไม่มีรหัส';

                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: ListTile(
                        title: Text("ออเดอร์: $orderCode",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("สถานะ: ${orderData['status'] ?? 'pending'}"),
                            Text(
                                "ราคารวม: ${orderData['total_price'] ?? 0} บาท"),
                          ],
                        ),
                        trailing: Icon(Icons.info_outline),
                        onTap: () => _showHistoryDetail(context, orderData),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  // ฟังก์ชัน Popup แสดงรายละเอียดออเดอร์
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
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      var item = items[index];
                      return ListTile(
                        title: Text(item['name'] ?? 'ไม่มีชื่อ'),
                        trailing: Text(
                            "price ${item['price'] ?? 0} x ${item['qty'] ?? 0}"),
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
}
