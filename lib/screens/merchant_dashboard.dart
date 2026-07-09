import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';

class MerchantDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Dashboard แม่ค้า")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('status', isNotEqualTo: 'completed')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return Center(child: CircularProgressIndicator());
          var orders = snapshot.data!.docs;

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              var data = orders[index].data() as Map<String, dynamic>;
              var id = orders[index].id;

              return ListTile(
                title: Text(data['food_name']),
                subtitle: Text("สถานะ: ${data['status']}"),
                trailing: ElevatedButton(
                  onPressed: () => Firebaseservice.updateStatus(
                      id, data['status'] == 'pending' ? 'ready' : 'completed'),
                  child: Text(data['status'] == 'pending'
                      ? "ทำเสร็จแล้ว"
                      : "เสร็จสิ้น"),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
