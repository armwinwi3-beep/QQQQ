import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart'; // ไฟล์ที่สร้างจากขั้นตอนที่ 2
import 'screens/merchant_dashboard.dart';
import 'screens/role_selection_screen.dart';
import 'services/firebase_service.dart';
import 'screens/role_check_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Login ทันทีที่เปิดแอป

  runApp(MaterialApp(home: RoleCheckScreen()));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              // ทดสอบเขียนข้อมูลลง Database
              await FirebaseFirestore.instance
                  .collection('test_collection')
                  .add({
                'message': 'Hello Firebase!',
                'timestamp': FieldValue.serverTimestamp(),
              });
              print("Data Sent!");
            },
            child: Text('Test Firebase Connection'),
          ),
        ),
      ),
    );
  }
}
