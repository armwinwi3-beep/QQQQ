import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Firebaseservice {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ฟังก์ชันสั่งอาหาร
  // ใน services/firebase_service.dart
  static Future<void> createOrder(String foodName) async {
    String uid =
        FirebaseAuth.instance.currentUser!.uid; // ดึง UID มาจากระบบ Auth

    await FirebaseFirestore.instance.collection('orders').add({
      'food_name': foodName,
      'status': 'pending',
      'created_at': FieldValue.serverTimestamp(),
      'user_id': uid, // <--- บันทึก UID ลงใน Database ด้วย
    });
  }

  // ฟังก์ชันอัปเดตสถานะ (จากแม่ค้า)
  static Future<void> updateStatus(String id, String newStatus) async {
    await _db.collection('orders').doc(id).update({'status': newStatus});
  }
}
