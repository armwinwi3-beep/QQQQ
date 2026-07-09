import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderHistoryScreen extends StatelessWidget {
  @override
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
              String status = data['status'] ?? 'pending';

              return Card(
                margin: EdgeInsets.all(10),
                child: ListTile(
                  title: Text(data['food_name'] ?? 'ไม่มีชื่อเมนู'),
                  subtitle: Text("สถานะ: $status"),
                  trailing: _getStatusIcon(status),
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
