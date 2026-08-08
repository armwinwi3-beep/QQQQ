import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ดึงไฟล์หน้าย่อยเข้ามาใช้งาน
import 'report_screen.dart';
import 'inventory_screen.dart';
import 'merchant_dashboard.dart';

// 🟢 1. Import ไฟล์หน้าเมนูเข้ามา
import 'menu_screen.dart';

class MainDashboardScreen extends StatefulWidget {
  const MainDashboardScreen({super.key});

  @override
  _MainDashboardScreenState createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen> {
  int _selectedIndex = 0;

  // 🟢 2. อัปเดตรายชื่อหน้าจอที่จะสลับไปมา
  final List<Widget> _pages = [
    const ReportScreen(),
    InventoryScreen(),
    MerchantDashboard(),

    // 🔴 แก้ไขบรรทัดนี้: เติม isMerchant: true เข้าไปในวงเล็บครับ!
    const MenuScreen(isMerchant: true),

    const Center(child: Text('หน้าตั้งค่า')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1D5A5D),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          tooltip: 'ออกจากระบบ',
          onPressed: () async {
            await FirebaseAuth.instance.signOut();
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
        // 🟢 3. อัปเดตปุ่มเมนูด้านล่าง
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'รายงาน'),
          BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined), label: 'คลัง'),
          BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long), label: 'ออเดอร์เข้า'),
          BottomNavigationBarItem(
              icon: Icon(Icons.point_of_sale),
              label:
                  'หน้าร้าน'), // 🟢 เปลี่ยนไอคอนและชื่อให้เหมาะกับการเป็นเครื่อง POS
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'ตั้งค่า'),
        ],
      ),
    );
  }
}
