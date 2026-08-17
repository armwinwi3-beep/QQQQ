import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'menu_screen.dart';
import 'auth_screen.dart';
import 'order_history_screen.dart';

class StoreSelectionScreen extends StatelessWidget {
  const StoreSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1D5A5D),
        title: const Text(
          "เลือกร้านอาหาร",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          // 🟢 แทรกปุ่มประวัติการสั่งซื้อตรงนี้
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            tooltip: 'ประวัติการสั่งซื้อ',
            onPressed: () {
              // อย่าลืม import 'order_history_screen.dart'; ไว้ด้านบนไฟล์ด้วยนะครับ
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const OrderHistoryScreen()),
              );
            },
          ),
          // ปุ่ม Logout เดิมของคุณ
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        // 🟢 1. ดึงรายชื่อ User ที่เป็น 'merchant' (ร้านค้า) ทั้งหมดมาแสดง
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'merchant')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("ยังไม่มีร้านค้าเปิดให้บริการในขณะนี้",
                  style: TextStyle(color: Colors.grey, fontSize: 16)),
            );
          }

          var stores = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: stores.length,
            itemBuilder: (context, index) {
              var store = stores[index];

              // 🟢 1. แปลงข้อมูลเป็น Map ก่อน เพื่อป้องกัน Error กรณีไม่มีฟิลด์
              var data = store.data() as Map<String, dynamic>;

              String storeId = store.id;

              // 🟢 2. ดึงค่าผ่านตัวแปร map ปลอดภัยหายห่วง
              String storeName = data['store_name'] ?? 'ไม่ระบุชื่อร้าน';

              return _buildStoreCard(context, storeId, storeName);
            },
          );
        },
      ),
    );
  }

  // 🟢 วิดเจ็ตสร้างการ์ดร้านค้า + ดึงจำนวนคิว
  Widget _buildStoreCard(
      BuildContext context, String storeId, String storeName) {
    return StreamBuilder<QuerySnapshot>(
      // 🟢 2. ดึงจำนวนออเดอร์ของร้านนี้ ที่สถานะยัง 'pending'
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('merchant_id', isEqualTo: storeId) // ค้นหาเฉพาะคิวของร้านนี้
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        int queueCount = snapshot.hasData ? snapshot.data!.docs.length : 0;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              // 🟢 พอกดเลือกร้าน ให้ส่ง ID และชื่อร้านไปที่หน้า MenuScreen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MenuScreen(
                    isMerchant: false,
                    merchantId: storeId, // ส่ง ID ร้านไป
                    storeName: storeName, // ส่งชื่อร้านไป
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2F1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.storefront,
                        size: 32, color: Color(0xFF1D5A5D)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(storeName,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.people_alt_outlined,
                                size: 16, color: Colors.orange),
                            const SizedBox(width: 4),
                            Text("รออยู่ $queueCount คิว",
                                style: const TextStyle(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios,
                      color: Colors.grey, size: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
