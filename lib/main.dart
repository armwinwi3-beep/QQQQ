import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'screens/merchant_dashboard.dart';
import 'screens/role_selection_screen.dart';
import 'services/firebase_service.dart';
import 'screens/role_check_screen.dart';
import 'package:qqqq/screens/walkin_tracker_screen.dart'; // 🟢 ดึงไฟล์หน้ารอคิวเข้ามา

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 🟢 เปลี่ยนมาเรียกใช้คลาส MyApp() เป็นโครงสร้างหลักของแอป
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // ปิดป้ายแจ้งเตือน Debug มุมขวาบน
      title: 'ร้านป้าต้อย',

      // 🟢 หน้าแรกของแอป (อิงตามโค้ดเดิมของคุณที่ใช้ RoleCheckScreen)
      home: RoleCheckScreen(),

      // 🟢 เพิ่มระบบดักจับ URL จาก QR Code ตรงนี้
      onGenerateRoute: (settings) {
        // เช็คว่าลิงก์ที่ลูกค้าสแกนเข้ามามีคำว่า /track ไหม
        if (settings.name != null && settings.name!.startsWith('/track')) {
          // แกะเอา id ของออเดอร์ออกมาจากลิงก์
          final Uri uri = Uri.parse(settings.name!);
          final String? orderId = uri.queryParameters['id'];

          if (orderId != null) {
            // ถ้ามี ID ให้เปิดหน้า WalkinTrackerScreen
            return MaterialPageRoute(
              builder: (context) => WalkinTrackerScreen(orderId: orderId),
            );
          }
        }
        return null; // ถ้ารูทอื่น หรือลิงก์ไม่ถูกต้องก็ปล่อยผ่านไปทำงานตามปกติ
      },
    );
  }
}
