import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  String selectedTab = 'วันนี้';

  // 🟢 แสดงรายละเอียด ยอดขาย (เพิ่มปุ่มลบบิลและคืนสต็อกแบบปลอดภัย)
  void _showSalesDetails(BuildContext context,
      List<QueryDocumentSnapshot> orders, double totalSales, int totalBills) {
    double avgPerBill = totalBills > 0 ? (totalSales / totalBills) : 0.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("รายละเอียด ยอดขาย",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1D5A5D))),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F3F1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text("ยอดขายรวม",
                          style: TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text("฿${totalSales.toStringAsFixed(2)}",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.red)),
                    ],
                  ),
                  Column(
                    children: [
                      const Text("จำนวนบิล",
                          style: TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text("$totalBills",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Color(0xFF1D5A5D))),
                    ],
                  ),
                  Column(
                    children: [
                      const Text("เฉลี่ย/บิล",
                          style: TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text("฿${avgPerBill.toStringAsFixed(2)}",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text("รายการบิลทั้งหมด",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            Expanded(
              child: orders.isEmpty
                  ? const Center(
                      child: Text("ไม่มีรายการบิล",
                          style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: orders.length,
                      itemBuilder: (context, index) {
                        var doc = orders[index];
                        var data = doc.data() as Map<String, dynamic>;
                        String orderCode = data['order_code'] ?? doc.id;
                        double price = (data['total_price'] ?? 0).toDouble();

                        String timeString = "";
                        if (data['created_at'] != null) {
                          DateTime dt =
                              (data['created_at'] as Timestamp).toDate();
                          timeString =
                              "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} น.";
                        }

                        var items = (data['items'] as List<dynamic>?)
                                ?.cast<Map<String, dynamic>>() ??
                            [];

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          elevation: 0,
                          color: Colors.grey.shade50,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFFE0F2F1),
                              child: Text("${index + 1}",
                                  style: const TextStyle(
                                      color: Color(0xFF1D5A5D),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12)),
                            ),
                            title: Text("ออเดอร์: $orderCode",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: Text(
                              items
                                  .map((e) => "${e['name']} x${e['qty']}")
                                  .join(", "),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text("฿${price.toStringAsFixed(2)}",
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red)),
                                    Text(timeString,
                                        style: const TextStyle(
                                            fontSize: 10, color: Colors.grey)),
                                  ],
                                ),
                                const SizedBox(width: 8),
                                // 🟢 ปุ่มลบเพื่อยกเลิกยอดขายและคืนสต็อก (เวอร์ชันป้องกัน Error)
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.red),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text("ยกเลิกบิลนี้?"),
                                        content: const Text(
                                            "ยอดขายและกำไรของบิลนี้จะถูกหักออก และระบบจะคืนจำนวนสินค้ากลับเข้าคลังอัตโนมัติ ต้องการดำเนินการต่อหรือไม่?"),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: const Text("ปิด",
                                                style: TextStyle(
                                                    color: Colors.grey)),
                                          ),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red),
                                            onPressed: () async {
                                              try {
                                                // 1. อัปเดตสถานะเป็น cancelled
                                                await FirebaseFirestore.instance
                                                    .collection('orders')
                                                    .doc(doc.id)
                                                    .update({
                                                  'status': 'cancelled'
                                                });

                                                // 2. ดึงข้อมูลแบบปลอดภัย ป้องกัน Error จากบิลเก่า
                                                List<dynamic> rawItems =
                                                    data['items'] ?? [];
                                                for (var item in rawItems) {
                                                  if (item is Map) {
                                                    String productId =
                                                        item['product_id']
                                                                ?.toString() ??
                                                            '';
                                                    int qty = int.tryParse(item[
                                                                    'qty']
                                                                ?.toString() ??
                                                            '0') ??
                                                        0;

                                                    if (productId.isNotEmpty &&
                                                        qty > 0) {
                                                      var productRef =
                                                          FirebaseFirestore
                                                              .instance
                                                              .collection(
                                                                  'products')
                                                              .doc(productId);
                                                      var pDoc =
                                                          await productRef
                                                              .get();

                                                      if (pDoc.exists) {
                                                        var pData = pDoc.data()
                                                            as Map<String,
                                                                dynamic>;
                                                        bool isTracking = pData[
                                                                'is_tracking'] ??
                                                            false;

                                                        if (isTracking) {
                                                          int currentStock =
                                                              pData['stock'] ??
                                                                  0;
                                                          int newStock =
                                                              currentStock +
                                                                  qty;
                                                          double cost =
                                                              (pData['cost'] ??
                                                                      0)
                                                                  .toDouble();

                                                          await productRef
                                                              .update({
                                                            'stock': newStock
                                                          });

                                                          await FirebaseFirestore
                                                              .instance
                                                              .collection(
                                                                  'stock_history')
                                                              .add({
                                                            'product_name': item[
                                                                    'name'] ??
                                                                'ไม่ทราบชื่อ',
                                                            'action': 'add',
                                                            'amount': qty,
                                                            'old_stock':
                                                                currentStock,
                                                            'new_stock':
                                                                newStock,
                                                            'old_cost': cost,
                                                            'new_cost': cost,
                                                            'detail':
                                                                'คืนสต็อก (ยกเลิกบิล: $orderCode)',
                                                            'created_at': FieldValue
                                                                .serverTimestamp(),
                                                          });
                                                        }
                                                      }
                                                    }
                                                  }
                                                }

                                                if (context.mounted) {
                                                  Navigator.pop(context);
                                                  Navigator.pop(context);
                                                }
                                              } catch (e) {
                                                // แจ้งเตือนถ้าเกิด Error โดยไม่ทำให้แอปค้าง
                                                if (context.mounted) {
                                                  Navigator.pop(context);
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                        content: Text(
                                                            "เกิดข้อผิดพลาด: $e"),
                                                        backgroundColor:
                                                            Colors.red),
                                                  );
                                                }
                                              }
                                            },
                                            child: const Text("ยกเลิกบิล",
                                                style: TextStyle(
                                                    color: Colors.white)),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // 🟢 แสดงรายละเอียด ต้นทุน & กำไร
  void _showProfitDetails(BuildContext context, double totalSales,
      double totalCost, double totalProfit) {
    double profitMargin =
        totalSales > 0 ? ((totalProfit / totalSales) * 100) : 0.0;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("รายละเอียด ต้นทุน & กำไร",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1D5A5D))),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
            const Divider(height: 20),
            _buildProfitRow(
                "ยอดขายรวม", "฿${totalSales.toStringAsFixed(2)}", Colors.black),
            const SizedBox(height: 12),
            _buildProfitRow("ต้นทุนสินค้าทั้งหมด",
                "฿${totalCost.toStringAsFixed(2)}", Colors.orange),
            const SizedBox(height: 12),
            _buildProfitRow("กำไรสุทธิ", "฿${totalProfit.toStringAsFixed(2)}",
                const Color(0xFF1D5A5D),
                isBold: true),
            const SizedBox(height: 12),
            _buildProfitRow("อัตรากำไร (Margin)",
                "${profitMargin.toStringAsFixed(1)}%", Colors.green,
                isBold: true),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildProfitRow(String label, String value, Color valueColor,
      {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 14,
                color: isBold ? Colors.black : Colors.grey.shade700,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(value,
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold, color: valueColor)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F1),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- แถบเมนูเวลา ---
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Row(
                  children: [
                    _buildTimeTab('วันนี้'),
                    _buildTimeTab('7 วัน'),
                    _buildTimeTab('30 วัน'),
                    _buildTimeTab('กำหนดเอง'),
                  ],
                ),
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: Text("ข้อมูลยอดขาย",
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
              ),
            ),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .where('merchant_id',
                      isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                  .where('status', isEqualTo: 'completed')
                  .snapshots(),
              builder: (context, snapshot) {
                double totalSales = 0.0;
                double totalCost = 0.0;
                int totalBills = 0;
                List<QueryDocumentSnapshot> orders = [];

                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  orders = snapshot.data!.docs;
                  totalBills = orders.length;

                  for (var doc in orders) {
                    var data = doc.data() as Map<String, dynamic>;
                    totalSales += (data['total_price'] ?? 0).toDouble();

                    var items = (data['items'] as List<dynamic>?)
                            ?.cast<Map<String, dynamic>>() ??
                        [];
                    for (var item in items) {
                      double itemCost = (item['cost'] ?? 0).toDouble();
                      int qty = item['qty'] ?? 1;
                      totalCost += (itemCost * qty);
                    }
                  }
                }

                double totalProfit = totalSales - totalCost;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- กล่องสรุปยอดขายด้านบน ---
                    Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("ยอดขายทั้งหมด",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(10)),
                                child: const Text("ยอดรวม",
                                    style: TextStyle(
                                        fontSize: 10, color: Colors.grey)),
                              )
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(totalSales.toStringAsFixed(2),
                              style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red)),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text("$totalBills บิล",
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 12)),
                          ),
                          const Divider(height: 24, thickness: 1),
                          const Text("ต้นทุน & กำไร",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(children: [
                                Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                        color: Colors.orange,
                                        shape: BoxShape.circle)),
                                const SizedBox(width: 8),
                                const Text("ต้นทุน",
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 13)),
                              ]),
                              Text("${totalCost.toStringAsFixed(2)} บาท",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(children: [
                                Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                        color: Color(0xFF1D5A5D),
                                        shape: BoxShape.circle)),
                                const SizedBox(width: 8),
                                const Text("กำไรสุทธิ",
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 13)),
                              ]),
                              Text("${totalProfit.toStringAsFixed(2)} บาท",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13)),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // --- รายละเอียดหมวดหมู่เงิน ---
                    const Padding(
                      padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
                      child: Text("เงิน",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            ListTile(
                              onTap: () => _showSalesDetails(
                                  context, orders, totalSales, totalBills),
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8)),
                                child: const Icon(Icons.receipt_long,
                                    color: Color(0xFF1D5A5D)),
                              ),
                              title: const Text("ยอดขาย",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14)),
                              subtitle: const Text(
                                  "ยอดสด/โอน • บิลเฉลี่ย • รายชั่วโมง...",
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 11)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(totalSales.toStringAsFixed(2),
                                      style: const TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.print,
                                      size: 16, color: Colors.grey),
                                  const Icon(Icons.chevron_right,
                                      color: Colors.grey),
                                ],
                              ),
                            ),
                            const Divider(height: 1, indent: 60),
                            ListTile(
                              onTap: () => _showProfitDetails(
                                  context, totalSales, totalCost, totalProfit),
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8)),
                                child: const Icon(Icons.calculate_outlined,
                                    color: Color(0xFF1D5A5D)),
                              ),
                              title: const Text("ต้นทุน & กำไร",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14)),
                              subtitle: const Text(
                                  "ต้นทุนรวม กำไรสุทธิ และอัตรา...",
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 11)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(totalProfit.toStringAsFixed(2),
                                      style: const TextStyle(
                                          color: Color(0xFF1D5A5D),
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.print,
                                      size: 16, color: Colors.grey),
                                  const Icon(Icons.chevron_right,
                                      color: Colors.grey),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  ],
                );
              },
            ),

            const SizedBox(height: 16),
            _buildStockHistorySection(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeTab(String title) {
    bool isSelected = selectedTab == title;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => selectedTab = title),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1D5A5D) : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey.shade600,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStockHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text("ประวัติการอัพเดตสต็อก",
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1D5A5D))),
        ),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('stock_history')
              .orderBy('created_at', descending: true)
              .limit(20)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator()));
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                    child: Text("ยังไม่มีประวัติการอัพเดตสต็อก",
                        style: TextStyle(color: Colors.grey))),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                var doc = snapshot.data!.docs[index];
                var data = doc.data() as Map<String, dynamic>;

                bool isAdd = data['action'] == 'add';

                String timeString = "";
                if (data['created_at'] != null) {
                  DateTime dt = (data['created_at'] as Timestamp).toDate();
                  timeString =
                      "${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
                }

                double newCost = (data['new_cost'] ?? 0).toDouble();

                return Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color:
                              isAdd ? Colors.green.shade50 : Colors.red.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isAdd
                              ? Icons.add_shopping_cart
                              : Icons.remove_shopping_cart,
                          color: isAdd ? Colors.green : Colors.red,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(data['product_name'] ?? 'ไม่ทราบชื่อ',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15)),
                                Text(timeString,
                                    style: const TextStyle(
                                        color: Colors.grey, fontSize: 11)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(data['detail'] ?? '',
                                style: TextStyle(
                                    color: Colors.grey.shade600, fontSize: 12)),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F3F1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("คงเหลือ: ${data['new_stock']} ชิ้น",
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: Color(0xFF1D5A5D))),
                                  Text(
                                      "ทุนเฉลี่ย: ฿${newCost.toStringAsFixed(2)}/ชิ้น",
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: Color(0xFF1D5A5D))),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // 🟢 ปุ่มลบประวัติการทำรายการ
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.red, size: 22),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              title: const Text("ยืนยันการลบประวัติ?"),
                              content: const Text(
                                  "การลบประวัตินี้จะลบแค่ข้อความแสดงผลเท่านั้น จะไม่ส่งผลต่อสต็อกจริง คุณต้องการลบใช่หรือไม่?"),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text("ยกเลิก",
                                      style: TextStyle(color: Colors.grey)),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red),
                                  onPressed: () async {
                                    await FirebaseFirestore.instance
                                        .collection('stock_history')
                                        .doc(doc.id)
                                        .delete();
                                    if (context.mounted) Navigator.pop(context);
                                  },
                                  child: const Text("ลบข้อมูล",
                                      style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
