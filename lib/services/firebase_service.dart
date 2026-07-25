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

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sign Up (เพิ่มการบันทึก Role)
  Future<User?> signUp(String email, String password, String role) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);

      // เมื่อสมัครเสร็จ ให้บันทึก Role ลงใน Firestore Collection 'users'
      await _firestore.collection('users').doc(result.user!.uid).set({
        'email': email,
        'role': role, // 'user' หรือ 'merchant'
        'created_at': FieldValue.serverTimestamp(),
      });

      return result.user;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  // Sign In (ล็อกอินปกติ)
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return result.user;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  // Guest Login (ล็อกอินแบบไม่ระบุตัวตน)
  Future<User?> signInGuest() async {
    try {
      UserCredential result = await _auth.signInAnonymously();
      return result.user;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
