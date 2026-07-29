import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'menu_screen.dart';
import 'merchant_dashboard.dart';
import 'auth_screen.dart';
import 'main_dashboard_screen.dart';

class RoleCheckScreen extends StatelessWidget {
  const RoleCheckScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        // 1. เช็คว่า ล็อกอินหรือยัง?
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        User? user = authSnapshot.data;

        // ถ้ายังไม่ล็อกอิน ให้ไปหน้า AuthScreen
        if (user == null) {
          return AuthScreen();
        }

        // 2. ถ้าล็อกอินแล้ว ให้ดึงข้อมูล Role จาก Firestore
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                  body: Center(child: CircularProgressIndicator()));
            }

            // ถ้าเจอข้อมูลใน Collection 'users'
            if (userSnapshot.hasData && userSnapshot.data!.exists) {
              String role = userSnapshot.data!['role'];

              if (role == 'merchant') {
                return MainDashboardScreen(); // แม่ค้า ไป Dashboard
              } else {
                return MenuScreen(); // ลูกค้าทั่วไป ไปหน้าเมนู
              }
            }

            // ถ้าไม่เจอข้อมูล (แปลว่าเป็น Guest) ให้ไปหน้าเมนู
            return MenuScreen();
          },
        );
      },
    );
  }
}
