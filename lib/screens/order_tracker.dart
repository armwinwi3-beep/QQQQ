import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderTracker extends StatelessWidget {
  final String orderId; // รับ ID ของออเดอร์มาจากหน้าเมนู

  const OrderTracker({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F1), // สีพื้นหลัง
      appBar: AppBar(
        backgroundColor: const Color(0xFF1D5A5D), // สีเขียวเข้ม
        title: const Text(
          'ติดตามสถานะอาหาร',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(
            color: Colors.white), // เปลี่ยนสีลูกศรย้อนกลับเป็นสีขาว
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(maxWidth: 500), // บังคับความกว้างบนเว็บ
          child: StreamBuilder<DocumentSnapshot>(
            // 🔴 ดึงข้อมูลออเดอร์นี้จาก Firebase แบบ Real-time
            stream: FirebaseFirestore.instance
                .collection('orders')
                .doc(orderId)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(
                    child: Text("เกิดข้อผิดพลาดในการโหลดข้อมูล"));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF1F7A83)));
              }
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const Center(child: Text("ไม่พบข้อมูลออเดอร์"));
              }

              // ดึงข้อมูลออกมาใช้งาน
              var data = snapshot.data!.data() as Map<String, dynamic>;
              String status = data['status'] ?? 'pending';
              String orderCode = data['order_code'] ?? 'ไม่มีรหัส';

              // ตัวแปรสำหรับปรับเปลี่ยน UI ตามสถานะ
              Color statusColor;
              IconData statusIcon;
              String statusText;
              double progress; // ความคืบหน้าของแถบ (0.0 ถึง 1.0)

              // เช็คสถานะเพื่อเปลี่ยนสีและข้อความ
              switch (status.toLowerCase()) {
                case 'cooking':
                  statusColor = Colors.blue;
                  statusIcon = Icons.soup_kitchen;
                  statusText = 'กำลังเตรียมอาหาร';
                  progress = 0.6;
                  break;
                case 'completed':
                  statusColor = Colors.green;
                  statusIcon = Icons.check_circle;
                  statusText = 'เสร็จเรียบร้อยแล้ว!';
                  progress = 1.0;
                  break;
                case 'cancelled':
                  statusColor = Colors.red;
                  statusIcon = Icons.cancel;
                  statusText = 'ออเดอร์ถูกยกเลิก';
                  progress = 0.0;
                  break;
                case 'pending':
                default:
                  statusColor = Colors.orange;
                  statusIcon = Icons.access_time_filled;
                  statusText = 'รอดำเนินการ';
                  progress = 0.3;
                  break;
              }

              return Padding(
                padding: const EdgeInsets.all(24.0),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 15,
                        offset: Offset(0, 8),
                      )
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("หมายเลขคิวของคุณ",
                          style: TextStyle(
                              fontSize: 16, color: Colors.grey.shade600)),
                      const SizedBox(height: 8),
                      // โชว์รหัสคิวตัวใหญ่ๆ
                      Text(
                        orderCode,
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F7A83),
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // ไอคอนสถานะ (มีพื้นหลังวงกลมสีจางๆ)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(statusIcon, size: 80, color: statusColor),
                      ),
                      const SizedBox(height: 24),

                      // ข้อความสถานะภาษาไทย
                      Text(
                        statusText,
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: statusColor),
                      ),
                      const SizedBox(height: 40),

                      // แถบ Progress Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 12,
                          backgroundColor: Colors.grey.shade200,
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "สถานะในระบบ: $status",
                        style: TextStyle(
                            color: Colors.grey.shade400, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
