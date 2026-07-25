import 'package:flutter/material.dart';
// ดึงไฟล์หน้าย่อยเข้ามาใช้งาน
import 'report_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'inventory_screen.dart';

// 🟢 เพิ่มบรรทัดนี้เข้าไป
import 'merchant_dashboard.dart';

class MainDashboardScreen extends StatefulWidget {
  @override
  _MainDashboardScreenState createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen> {
  int _selectedIndex = 0;

  // รายชื่อหน้าจอที่จะสลับไปมา
  final List<Widget> _pages = [
    ReportScreen(),
    InventoryScreen(),
    MerchantDashboard(), // รอใส่หน้าขายของ
    Center(child: Text('หน้ารายจ่าย')),
    Center(child: Text('หน้าตั้งค่า')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F1), // สีพื้นหลังอิงจากรูป
      appBar: AppBar(
        backgroundColor: const Color(0xFF1D5A5D), // สีเขียวเข้ม
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white, size: 20),
          tooltip: 'ออกจากระบบ',
          onPressed: () async {
            await FirebaseAuth.instance.signOut();
            // พอคำสั่งนี้ทำงานปุ๊บ ระบบจะดีดกลับไปหน้า Login อัตโนมัติ
          },
        ),
        title: const Column(
          children: [
            Text('ป้าต้อย',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            Text('B.T.Ad.App',
                style: TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),

        centerTitle: true,
        elevation: 0,
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF1F7A83),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white54,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'รายงาน'),
          BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined), label: 'คลัง'),
          BottomNavigationBarItem(
              icon: Icon(Icons.store_outlined), label: 'ขายของ'),
          BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined),
              label: 'รายจ่าย'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'ตั้งค่า'),
        ],
      ),
    );
  }
}
