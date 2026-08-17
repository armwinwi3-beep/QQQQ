import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import 'dart:async';

class MerchantDashboard extends StatelessWidget {
  const MerchantDashboard({super.key});

  void _showOrderDetails(BuildContext context, DocumentSnapshot doc) {
    var data = doc.data() as Map<String, dynamic>;
    var items =
        (data['items'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    double total = (data['total_price'] ?? 0).toDouble();
    String orderCode =
        data['order_code'] ?? doc.id; // ดึงรหัสออเดอร์มาใช้ตอนบันทึกประวัติ
    String status = data['status'] ?? 'pending';
    String docId = doc.id; // 🟢 เพิ่มบรรทัดนี้เข้าไป

    showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: Colors.white,
            child: Container(
              width: 500,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- 1. ส่วนหัว (Header) ---
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2F1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.receipt_long,
                            color: Color(0xFF1D5A5D)),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text("รายละเอียดออเดอร์",
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1D5A5D))),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () => Navigator.pop(context),
                      )
                    ],
                  ),
                  const SizedBox(height: 20),

                  // --- 2. รายการอาหาร (Items List) ---
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: items.map((item) {
                        String name = item['name'] ?? 'ไม่มีชื่อ';
                        int qty = item['qty'] ?? 0;
                        double price = (item['price'] ?? 0).toDouble();

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(name,
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500)),
                              ),
                              Text("$qty  x  ฿${price.toStringAsFixed(0)}",
                                  style:
                                      TextStyle(color: Colors.grey.shade600)),
                              const SizedBox(width: 16),
                              SizedBox(
                                width: 70,
                                child: Text(
                                    "฿${(price * qty).toStringAsFixed(0)}",
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- 3. สรุปยอดรวม (Total Price) ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("ราคารวมทั้งสิ้น",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      Text("฿${total.toStringAsFixed(2)}",
                          style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.red)),
                    ],
                  ),
                  const Divider(height: 32),

                  // --- 4. ปุ่มจัดการออเดอร์ (Actions) ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("ปิด",
                            style: TextStyle(color: Colors.grey)),
                      ),
                      const SizedBox(width: 8),
                      // 🟢 1. ปุ่มยกเลิกออเดอร์ (ให้โชว์เฉพาะตอนที่ออเดอร์ยังไม่เสร็จสิ้นหรือยังไม่ถูกยกเลิก)
                      if (status != 'completed' && status != 'cancelled')
                        OutlinedButton.icon(
                          onPressed: () async {
                            // อัปเดตสถานะใน Firebase เป็น 'cancelled'
                            await FirebaseFirestore.instance
                                .collection('orders')
                                .doc(doc.id)
                                .update({'status': 'cancelled'});
                            if (context.mounted) Navigator.pop(context);
                          },
                          icon: const Icon(Icons.cancel,
                              color: Colors.red, size: 18),
                          label: const Text("ยกเลิกออเดอร์",
                              style: TextStyle(color: Colors.red)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),

                      const SizedBox(width: 8),
                      // ถ้าสถานะเป็น 'pending' (รอดำเนินการ) ให้โชว์ปุ่ม "รับออเดอร์/กำลังทำ"
                      if (status == 'pending')
                        ElevatedButton.icon(
                          onPressed: () async {
                            // อัปเดตสถานะเป็น 'cooking'
                            await FirebaseFirestore.instance
                                .collection('orders')
                                .doc(docId)
                                .update({'status': 'cooking'});
                            if (context.mounted) Navigator.pop(context);
                          },
                          icon: const Icon(Icons.soup_kitchen,
                              color: Colors.white),
                          label: const Text("เริ่มทำอาหาร",
                              style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange),
                        )

                      // ถ้าสถานะเป็น 'cooking' (กำลังทำอยู่) ให้โชว์ปุ่ม "เสร็จสิ้น"
                      else if (status == 'cooking')
                        ElevatedButton.icon(
                          onPressed: () async {
                            // อัปเดตสถานะเป็น 'completed'
                            await FirebaseFirestore.instance
                                .collection('orders')
                                .doc(docId)
                                .update({'status': 'completed'});
                            if (context.mounted) Navigator.pop(context);
                          },
                          icon: const Icon(Icons.check_circle,
                              color: Colors.white),
                          label: const Text("ทำรายการเสร็จสิ้น",
                              style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1D5A5D)),
                        ),
                    ],
                  )
                ],
              ),
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, authSnapshot) {
          if (authSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          User? user = authSnapshot.data;
          if (user == null) {
            return const Center(child: Text("กรุณาเข้าสู่ระบบใหม่"));
          }

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('orders')
                .where('merchant_id', isEqualTo: user.uid)
                // 🟢 เปลี่ยนมาใช้ whereIn เพื่อให้โชว์ทั้ง 2 สถานะเลย
                .where('status', whereIn: ['pending', 'cooking'])
                .orderBy('created_at', descending: false)
                .snapshots(),
            builder: (context, snapshot) {
              // 1. ดักจับ Error (กรณีรอสร้าง Index)
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SelectableText(
                      "เกิดข้อผิดพลาด ให้คลิกลิงก์สีฟ้าใน Debug Console ด้านล่างเพื่อสร้าง Index\n\n${snapshot.error}",
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              // 2. เช็คสถานะกำลังโหลด
              if (snapshot.connectionState == ConnectionState.waiting ||
                  !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              var orders = snapshot.data!.docs;

              // 3. ถ้าไม่มีออเดอร์เลย
              if (orders.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox, size: 80, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text("ยังไม่มีออเดอร์ใหม่",
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 16)),
                    ],
                  ),
                );
              }

              // 4. ถ้ามีออเดอร์ แสดงผลเป็น ListView
              return ListView.builder(
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  var doc = orders[index];
                  var data = doc.data() as Map<String, dynamic>;
                  Timestamp? createdAt = data['created_at'] as Timestamp?;
                  String orderCode = data['order_code'] ?? doc.id;

// 🟢 1. ต้องดึงและเช็กเงื่อนไขตรงนี้ ก่อนจะสั่ง return Card
                  String status = data['status'] ?? 'pending';
                  String statusText = 'รอดำเนินการ';
                  Color statusColor = Colors.orange;
                  if (status == 'cooking') {
                    statusText = 'กำลังทำอาหาร';
                    statusColor = Colors.blue;
                  } else if (status == 'completed') {
                    statusText = 'เสร็จสิ้น';
                    statusColor = Colors.green;
                  } else if (status == 'cancelled') {
                    statusText = 'ยกเลิกแล้ว';
                    statusColor = Colors.red;
                  }
                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF1F7A83),
                        child: Text("${index + 1}",
                            style: const TextStyle(color: Colors.white)),
                      ),
                      title: Text("ออเดอร์: $orderCode",
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 🟢 2. เปลี่ยนมาใช้ตัวแปร dynamic (เอาคำว่า const ออกด้วยนะครับ เพราะสีและข้อความต้องเปลี่ยนตามตัวแปร)
                          Text(
                            "สถานะ: $statusText",
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          TimeElapsedWidget(createdAt: createdAt),
                        ],
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => _showOrderDetails(context, doc),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class TimeElapsedWidget extends StatefulWidget {
  final Timestamp? createdAt;

  const TimeElapsedWidget({super.key, required this.createdAt});

  @override
  State<TimeElapsedWidget> createState() => _TimeElapsedWidgetState();
}

class _TimeElapsedWidgetState extends State<TimeElapsedWidget> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.createdAt == null) {
      return const Text("กำลังรับข้อมูลเวลา...",
          style: TextStyle(color: Colors.grey, fontSize: 12));
    }

    DateTime orderTime = widget.createdAt!.toDate();
    Duration diff = DateTime.now().difference(orderTime);

    int minutes = diff.inMinutes;
    int seconds = diff.inSeconds % 60;

    Color textColor = minutes >= 15
        ? Colors.red
        : (minutes >= 5 ? Colors.orange : Colors.green);

    return Text(
      "รอมาแล้ว: $minutes นาที $seconds วินาที",
      style: TextStyle(
          color: textColor, fontWeight: FontWeight.bold, fontSize: 13),
    );
  }
}
