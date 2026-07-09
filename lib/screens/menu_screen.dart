import 'package:flutter/material.dart';
import 'order_tracker.dart';
import 'order_history_screen.dart'; // <--- 1. อย่าลืม Import ไฟล์ History เข้ามาด้วย
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MenuScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("เมนูอาหาร"),
        actions: [
          // <--- 2. ส่วนนี้คือจุดที่จะวางปุ่ม
          IconButton(
            icon: Icon(Icons.history), // ไอคอนรูปนาฬิกาย้อนหลัง
            onPressed: () {
              // 3. สั่งให้กดแล้วไปหน้า History
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => OrderHistoryScreen()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            // โค้ดสั่งอาหารของคุณเหมือนเดิม...
            DocumentReference docRef =
                await FirebaseFirestore.instance.collection('orders').add({
              'food_name': 'ข้าวมันไก่',
              'status': 'pending',
              'created_at': FieldValue.serverTimestamp(),
              'user_id': FirebaseAuth.instance.currentUser!.uid,
            });
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => OrderTracker(orderId: docRef.id)));
          },
          child: Text("สั่งข้าวมันไก่"),
        ),
      ),
    );
  }
}
