import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import 'dart:async';

class MerchantDashboard extends StatelessWidget {
  const MerchantDashboard({super.key});

  @override
void _showOrderDetails(BuildContext context, DocumentSnapshot doc) {
    var data = doc.data() as Map<String, dynamic>;
    var items = (data['items'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    double total = (data['total_price'] ?? 0).toDouble();
    String orderCode = data['order_code'] ?? doc.id; // ดึงรหัสออเดอร์มาใช้ตอนบันทึกประวัติ

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                      child: const Icon(Icons.receipt_long, color: Color(0xFF1D5A5D)),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        "รายละเอียดออเดอร์", 
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1D5A5D))
                      ),
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
                              child: Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                            ),
                            Text("$qty  x  ฿${price.toStringAsFixed(0)}", style: TextStyle(color: Colors.grey.shade600)),
                            const SizedBox(width: 16),
                            SizedBox(
                              width: 70,
                              child: Text(
                                "฿${(price * qty).toStringAsFixed(0)}", 
                                textAlign: TextAlign.right, 
                                style: const TextStyle(fontWeight: FontWeight.bold)
                              ),
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
                    const Text("ราคารวมทั้งสิ้น", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text("฿${total.toStringAsFixed(2)}", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red)),
                  ],
                ),
                const Divider(height: 32),
                
                // --- 4. ปุ่มจัดการออเดอร์ (Actions) ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("ปิด", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    
                    // 🟢 ปุ่มยกเลิก (เพิ่มระบบคืนสต็อก)
                    OutlinedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext confirmContext) {
                            return AlertDialog(
                              title: const Text("ยกเลิกออเดอร์ลูกค้า"),
                              content: const Text("ต้องการยกเลิกออเดอร์และคืนสต็อกสินค้าใช่หรือไม่?"),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(confirmContext),
                                  child: const Text("ปิด"),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                  onPressed: () async {
                                    // 1. อัปเดตสถานะใน Firestore เป็น cancelled
                                    await FirebaseFirestore.instance
                                        .collection('orders')
                                        .doc(doc.id)
                                        .update({'status': 'cancelled'});

                                    // 🟢 2. วนลูปคืนสต็อกสินค้า
                                    for (var item in items) {
                                      String? productId = item['product_id'];
                                      int qty = item['qty'] ?? 0;
                                      
                                      if (productId != null && qty > 0) {
                                        var productDoc = await FirebaseFirestore.instance.collection('products').doc(productId).get();
                                        if (productDoc.exists) {
                                          var productData = productDoc.data() as Map<String, dynamic>;
                                          bool isTracking = productData['is_tracking'] ?? false;
                                          
                                          if (isTracking) {
                                            int currentStock = productData['stock'] ?? 0;
                                            int newStock = currentStock + qty;
                                            double currentCost = (productData['cost'] ?? 0).toDouble();

                                            // อัปเดตสต็อกกลับเข้าคลัง
                                            await FirebaseFirestore.instance.collection('products').doc(productId).update({
                                              'stock': newStock,
                                            });

                                            // บันทึกประวัติการคืนสต็อก
                                            await FirebaseFirestore.instance.collection('stock_history').add({
                                              'product_name': productData['name'],
                                              'action': 'add',
                                              'amount': qty,
                                              'old_stock': currentStock,
                                              'new_stock': newStock,
                                              'old_cost': currentCost,
                                              'new_cost': currentCost, 
                                              'detail': 'คืนสต็อก (ยกเลิกออเดอร์: $orderCode)',
                                              'created_at': FieldValue.serverTimestamp(),
                                            });
                                          }
                                        }
                                      }
                                    }

                                    // 3. ปิด Popup ยืนยัน และ Popup รายละเอียด
                                    if (context.mounted) {
                                      Navigator.pop(confirmContext);
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("ยกเลิกออเดอร์และคืนสต็อกสำเร็จ"), backgroundColor: Colors.orange)
                                      );
                                    }
                                  },
                                  child: const Text("ยืนยันยกเลิก", style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      icon: const Icon(Icons.cancel_outlined, color: Colors.red, size: 18),
                      label: const Text("ยกเลิกออเดอร์", style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    
                    // ปุ่มทำรายการเสร็จสิ้น
                    ElevatedButton.icon(
                      onPressed: () async {
                        await FirebaseFirestore.instance
                            .collection('orders')
                            .doc(doc.id)
                            .update({'status': 'completed'});
                        
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      },
                      icon: const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                      label: const Text("ทำรายการเสร็จสิ้น", style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1D5A5D),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      }
    );
  }
  @override // เพิ่ม @override เพื่อความถูกต้องตามหลักของ StatelessWidget
  Widget build(BuildContext context) {
    return Scaffold(
      // เอา AppBar ออกตามที่เราเคยทำหน้า Modern UI ไปแล้ว เพื่อไม่ให้หัวแอปซ้อนกัน
      // appBar: AppBar(
      //   title: Text("Dashboard แม่ค้า"),
      // ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            // 🟢 เพิ่มบรรทัดนี้ เพื่อให้ดึงมาเฉพาะออเดอร์ที่เป็นของร้านตัวเองเท่านั้น
            .where('merchant_id', isEqualTo: FirebaseAuth.instance.currentUser!.uid) 
            .where('status', isEqualTo: 'pending')
            .orderBy('created_at', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          // ... โค้ดเดิม ...
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var orders = snapshot.data!.docs;

          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text("ยังไม่มีออเดอร์ใหม่",
                      style:
                          TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              var doc = orders[index];
              var data = doc.data() as Map<String, dynamic>;
              Timestamp? createdAt = data['created_at'] as Timestamp?;
              String orderCode = data['order_code'] ?? doc.id;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                      const Text("สถานะ: รอดำเนินการ",
                          style: TextStyle(color: Colors.orange)),
                      // เรียกใช้ Widget จับเวลาที่เราสร้างไว้!
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
      ),
    );
  }
}

class TimeElapsedWidget extends StatefulWidget {
  final Timestamp? createdAt;

  const TimeElapsedWidget({super.key, required this.createdAt});

  @override
  _TimeElapsedWidgetState createState() => _TimeElapsedWidgetState();
}

class _TimeElapsedWidgetState extends State<TimeElapsedWidget> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // สั่งให้รีเฟรชหน้าจอตัวเองทุกๆ 1 วินาที
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // ยกเลิกการนับเวลาเมื่อปิดหน้าจอ (ป้องกันแอปค้าง)
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.createdAt == null) {
      return const Text("กำลังรับข้อมูลเวลา...",
          style: TextStyle(color: Colors.grey, fontSize: 12));
    }

    // คำนวณความต่างของเวลาปัจจุบัน กับเวลาที่สั่ง
    DateTime orderTime = widget.createdAt!.toDate();
    Duration diff = DateTime.now().difference(orderTime);

    int minutes = diff.inMinutes;
    int seconds = diff.inSeconds % 60; // เอาเศษวินาทีที่เหลือจากการหาร 60

    // ลูกเล่นเสริม: เปลี่ยนสีตัวหนังสือตามความนาน (แดงถ้านานกว่า 15 นาที)
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
