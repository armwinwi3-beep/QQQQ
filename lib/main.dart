import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 🟢 1. เพิ่มตัวนี้เพื่อฟังสถานะล็อกอิน
import 'firebase_options.dart';
import 'screens/auth_screen.dart'; // 🟢 2. เพิ่มหน้า Login
import 'screens/role_check_screen.dart';
import 'package:qqqq/screens/walkin_tracker_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ร้านป้าต้อย',

      // 🟢 3. ใช้ StreamBuilder เช็คสถานะการล็อกอินตลอดเวลา
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // กำลังโหลดสถานะ
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: Color(0xFFF3F3F1),
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // ถ้ายังไม่ล็อกอิน ให้แสดงหน้าเข้าสู่ระบบ (AuthScreen)
          if (!snapshot.hasData) {
            return const AuthScreen();
          }

          // ถ้าล็อกอินแล้ว ให้ส่งไปเช็คสิทธิ์ (RoleCheckScreen) เพื่อพาไปหน้าแอดมิน/แม่ค้า/ลูกค้าทันที
          return const RoleCheckScreen();
        },
      ),

      // ระบบดักจับ URL จาก QR Code
      onGenerateRoute: (settings) {
        if (settings.name != null && settings.name!.startsWith('/track')) {
          final Uri uri = Uri.parse(settings.name!);
          final String? orderId = uri.queryParameters['id'];

          if (orderId != null) {
            return MaterialPageRoute(
              builder: (context) => WalkinTrackerScreen(orderId: orderId),
            );
          }
        }
        return null;
      },
    );
  }
}