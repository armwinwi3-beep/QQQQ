import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderTracker extends StatelessWidget {
  final String orderId; // รับค่า ID ของออเดอร์ที่สั่งไป

  OrderTracker({required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("ติดตามสถานะอาหาร")),
      body: StreamBuilder<DocumentSnapshot>(
        // ฟังข้อมูลแค่ Document เดียว (ออเดอร์เดียว)
        stream: FirebaseFirestore.instance
            .collection('orders')
            .doc(orderId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return Center(child: CircularProgressIndicator());

          var data = snapshot.data!.data() as Map<String, dynamic>;
          String status = data['status']; // 'pending', 'ready', 'completed'

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_getIcon(status), size: 100, color: _getColor(status)),
                SizedBox(height: 20),
                Text("สถานะ: $status",
                    style:
                        TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Text("ออเดอร์ ID: $orderId"),
              ],
            ),
          );
        },
      ),
    );
  }

  // Helper function เพื่อเปลี่ยนสีตามสถานะ
  Color _getColor(String status) {
    switch (status) {
      case 'ready':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  // Helper function เพื่อเปลี่ยนไอคอน
  IconData _getIcon(String status) {
    switch (status) {
      case 'ready':
        return Icons.check_circle;
      case 'completed':
        return Icons.done_all;
      default:
        return Icons.access_time;
    }
  }
}
