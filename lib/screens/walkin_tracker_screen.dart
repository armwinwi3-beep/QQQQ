import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 🟢 1. Import Auth เข้ามา

class WalkinTrackerScreen extends StatefulWidget {
  final String orderId;

  const WalkinTrackerScreen({super.key, required this.orderId});

  @override
  State<WalkinTrackerScreen> createState() => _WalkinTrackerScreenState();
}

class _WalkinTrackerScreenState extends State<WalkinTrackerScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _createTemporaryUser(); // 🟢 2. เรียกใช้ฟังก์ชันสร้าง User ชั่วคราวตอนเปิดหน้า
  }

  Future<void> _createTemporaryUser() async {
    try {
      // เช็คว่าในเครื่องที่สแกนมี User ล็อกอินอยู่หรือเปล่า
      if (FirebaseAuth.instance.currentUser == null) {
        // 🟢 3. ถ้าไม่มี ให้สร้าง User ชั่วคราว (Anonymous) ขึ้นมาเลย!
        await FirebaseAuth.instance.signInAnonymously();
        debugPrint("สร้าง User ชั่วคราวสำเร็จ!");
      }
    } catch (e) {
      debugPrint("Error signing in anonymously: $e");
    } finally {
      // ไม่ว่าจะสำเร็จหรือพัง ก็ให้ปิดตัวโหลดแล้วโชว์หน้าจอต่อ
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🟢 4. ระหว่างแอบสร้าง User ชั่วคราว ให้ขึ้นวงกลมหมุนๆ โหลดรอแปปนึง
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF3F3F1),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F1),
      appBar: AppBar(
        title:
            const Text('ติดตามสถานะคิว', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1D5A5D),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      // โค้ดดึงข้อมูล Firestore เหมือนเดิมเป๊ะ
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .doc(widget.orderId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("ไม่พบข้อมูลออเดอร์นี้"));
          }

          var orderData = snapshot.data!.data() as Map<String, dynamic>;
          String status = orderData['status'] ?? 'pending';
          String orderCode = orderData['order_code'] ?? '-';
          Timestamp? createdAt = orderData['created_at'];

          if (status != 'pending' || createdAt == null) {
            return _buildStatusUI(orderCode, status, 0);
          }

          return FutureBuilder<AggregateQuerySnapshot>(
            future: FirebaseFirestore.instance
                .collection('orders')
                .where('status', isEqualTo: 'pending')
                .where('created_at', isLessThan: createdAt)
                .count()
                .get(),
            builder: (context, countSnapshot) {
              int queuesAhead = countSnapshot.data?.count ?? 0;
              return _buildStatusUI(orderCode, status, queuesAhead);
            },
          );
        },
      ),
    );
  }

  // วิดเจ็ตสำหรับวาดหน้าจอแสดงคิว
  Widget _buildStatusUI(String orderCode, String status, int queuesAhead) {
    String statusText;
    Color statusColor;

    if (status == 'pending') {
      statusText = "กำลังรอคิว\n(รออีก $queuesAhead คิว)";
      statusColor = Colors.orange;
    } else if (status == 'cooking') {
      statusText = "กำลังเตรียมอาหาร!";
      statusColor = Colors.blue;
    } else {
      statusText = "เสร็จเรียบร้อย\nรับอาหารได้เลย!";
      statusColor = Colors.green;
    }

    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 2)
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("หมายเลขคิวของคุณ",
                style: TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 10),
            Text(
              orderCode,
              style: const TextStyle(
                  fontSize: 45,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1D5A5D)),
            ),
            const SizedBox(height: 30),
            Icon(
              status == 'pending'
                  ? Icons.access_time_filled
                  : (status == 'cooking'
                      ? Icons.soup_kitchen
                      : Icons.check_circle),
              size: 80,
              color: statusColor,
            ),
            const SizedBox(height: 20),
            Text(
              statusText,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: statusColor),
            ),
          ],
        ),
      ),
    );
  }
}
