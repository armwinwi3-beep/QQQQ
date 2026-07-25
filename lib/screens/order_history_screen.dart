import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'order_tracker.dart';

class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ดึง UID ของผู้ใช้ปัจจุบัน
    String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F1), // สีพื้นหลังธีม Modern
      appBar: AppBar(
        backgroundColor: const Color(0xFF1D5A5D),
        title: const Text(
          "ประวัติการสั่งซื้อของฉัน",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: currentUserId == null
          ? const Center(child: Text("ไม่พบข้อมูลผู้ใช้งาน"))
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                    maxWidth: 600), // บังคับความกว้างบนเว็บ
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('orders')
                      .where('user_id', isEqualTo: currentUserId)
                      // 🔴 ปิด orderBy ไว้ชั่วคราว เพื่อป้องกัน Error เรื่อง Index
                      .orderBy('created_at', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                          child: Text("เกิดข้อผิดพลาด: ${snapshot.error}"));
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFF1F7A83)));
                    }

                    var orders = snapshot.data!.docs;

                    if (orders.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long,
                                size: 80, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text("ยังไม่มีประวัติการสั่งซื้อ",
                                style: TextStyle(
                                    color: Colors.grey.shade500, fontSize: 16)),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: orders.length,
                      itemBuilder: (context, index) {
                        var doc = orders[index];
                        var orderData = doc.data() as Map<String, dynamic>;
                        String docId = doc.id;
                        String orderCode =
                            orderData['order_code'] ?? 'ไม่มีรหัส';
                        String status = orderData['status'] ?? 'pending';
                        double totalPrice =
                            (orderData['total_price'] ?? 0).toDouble();

                        // แปลงเวลา
                        Timestamp? createdAt =
                            orderData['created_at'] as Timestamp?;
                        String dateString = "ไม่ระบุเวลา";
                        if (createdAt != null) {
                          DateTime date = createdAt.toDate();
                          dateString =
                              "${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} น.";
                        }

                        // สีสถานะ
                        Color statusBgColor;
                        Color statusTextColor;
                        String statusText;

                        switch (status.toLowerCase()) {
                          case 'completed':
                            statusBgColor = Colors.green.shade50;
                            statusTextColor = Colors.green.shade700;
                            statusText = 'เสร็จสิ้น';
                            break;
                          case 'cooking':
                            statusBgColor = Colors.blue.shade50;
                            statusTextColor = Colors.blue.shade700;
                            statusText = 'กำลังเตรียม';
                            break;
                          case 'cancelled':
                            statusBgColor = Colors.red.shade50;
                            statusTextColor = Colors.red.shade700;
                            statusText = 'ยกเลิก';
                            break;
                          case 'pending':
                          default:
                            statusBgColor = Colors.orange.shade50;
                            statusTextColor = Colors.orange.shade700;
                            statusText = 'รอดำเนินการ';
                            break;
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              // 🔴 พอกดการ์ด จะเรียก Popup แบบโค้ดเก่าของคุณเลย

                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "ออเดอร์: $orderCode",
                                          style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1D5A5D)),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: statusBgColor,
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            statusText,
                                            style: TextStyle(
                                                color: statusTextColor,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    const Divider(color: Colors.black12),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.access_time,
                                                size: 16, color: Colors.grey),
                                            const SizedBox(width: 4),
                                            Text(dateString,
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color:
                                                        Colors.grey.shade600)),
                                          ],
                                        ),
                                        Text(
                                          "$totalPrice บาท",
                                          style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
    );
  }

  // 🔴 ฟังก์ชัน Popup แสดงรายละเอียด (อัปเกรดให้สวยขึ้น)
  void _showHistoryDetail(
      BuildContext context, Map<String, dynamic> data, String docId) {
    var items =
        (data['items'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    var total = data['total_price'] ?? 0;
    var orderCode = data['order_code'] ?? 'ไม่มีรหัส';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text("รายการอาหาร ($orderCode)",
              style: const TextStyle(
                  color: Color(0xFF1D5A5D), fontWeight: FontWeight.bold)),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      var item = items[index];
                      int price = item['price'] ?? 0;
                      int qty = item['qty'] ?? 0;

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(item['name'] ?? 'ไม่มีชื่อ',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        trailing: Text(
                          "$price x $qty  =  ${price * qty} ฿",
                          style: TextStyle(color: Colors.grey.shade800),
                        ),
                      );
                    },
                  ),
                ),
                const Divider(thickness: 1),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("ราคารวมทั้งหมด:",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(
                        "$total บาท",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Color(0xFF1F7A83)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("ปิด", style: TextStyle(color: Colors.grey)),
            ),
            // ปุ่มติดตามสถานะ (Track Order)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context); // ปิด Popup ก่อน
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => OrderTracker(orderId: docId)),
                );
              },
              icon:
                  const Icon(Icons.location_on, color: Colors.white, size: 18),
              label: const Text("ติดตามสถานะ",
                  style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1F7A83),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        );
      },
    );
  }
}
