import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  // 🟢 2. อัปเดตรายชื่อหน้าจอที่จะสลับไปมา
  final List<Widget> _pages = [
    const ReportScreen(),
    const InventoryScreen(), // (แอบแนะนำ: เติม const ข้างหน้าแบบนี้ จะช่วยแก้ขีดเส้นใต้สีน้ำเงินได้ด้วยครับ)
    const MerchantDashboard(),
    const MenuScreen(), // 🔴 แก้บรรทัดนี้: ลบ isMerchant: true ออกให้เหลือแค่วงเล็บเปล่าๆ ครับ
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
        // 🟢 เปลี่ยน Title เป็น FutureBuilder เพื่อดึงข้อมูลร้าน
        title: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection(
                  'merchants') // ⚠️ อย่าลืมแก้ตรงนี้เป็นชื่อตารางเก็บข้อมูลร้านของคุณ (เช่น 'users')
              .doc(FirebaseAuth.instance.currentUser?.uid)
              .get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2));
            }

            if (snapshot.hasData && snapshot.data!.exists) {
              var data = snapshot.data!.data() as Map<String, dynamic>;
              // ⚠️ อย่าลืมแก้ 'store_name' ให้ตรงกับชื่อฟิลด์ใน Firebase ของคุณ
              String storeName = data['store_name'] ?? 'ไม่มีชื่อร้าน';

              return Column(
                children: [
                  Text(
                    storeName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'B.T.Ad.App',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              );
            }

            return const Text(
              "ไม่พบข้อมูลร้าน",
              style: TextStyle(color: Colors.white),
            );
          },
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
