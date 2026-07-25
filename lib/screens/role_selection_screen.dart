import 'package:flutter/material.dart';
import 'menu_screen.dart'; // import หน้าจอลูกค้า
import 'merchant_dashboard.dart'; // import หน้าจอแม่ค้า
import 'order_history_screen.dart';
import 'main_dashboard_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("เลือกโหมดทดสอบ")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (context) => MenuScreen())),
              child: Text("ไปหน้าลูกค้า (สั่งอาหาร)",
                  style: TextStyle(fontSize: 20)),
              style: ElevatedButton.styleFrom(padding: EdgeInsets.all(20)),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => MainDashboardScreen())),
              child: Text("ไปหน้าแม่ค้า (ดูออเดอร์)",
                  style: TextStyle(fontSize: 20)),
              style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.all(20), backgroundColor: Colors.orange),
            ),
            SizedBox(height: 40), // เว้นระยะห่างจากปุ่มบทบาท

            // ปุ่มประวัติการสั่งซื้อที่เพิ่มเข้ามา
            OutlinedButton.icon(
                // ใช้ OutlinedButton เพื่อให้ดูเป็นปุ่มรอง (Secondary)
                icon: Icon(Icons.history),
                label: Text("ประวัติการสั่งซื้อของฉัน"),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => OrderHistoryScreen()),
                  );
                })
          ],
        ),
      ),
    );
  }
}
