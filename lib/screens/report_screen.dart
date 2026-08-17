import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  String selectedTab = 'วันนี้'; 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F1),
      // 🔴 เอา AppBar ออกไปแล้ว เพื่อไม่ให้ซ้อนกับหน้า Dashboard หลัก
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                child: Text("ร้านป้าต้อย • ข้อมูลยอดขาย", style: TextStyle(color: Colors.grey, fontSize: 12)),
              ),
            ),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("ยอดขายทั้งหมด", style: TextStyle(fontWeight: FontWeight.bold)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10)),
                        child: const Text("ยอดรวม", style: TextStyle(fontSize: 10, color: Colors.grey)),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text("0.00", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.red)),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Text("0 บิล", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ),
                  const Divider(height: 24, thickness: 1),
                  const Text("ต้นทุน & กำไร", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        const Text("ต้นทุน", style: TextStyle(color: Colors.grey, fontSize: 13)),
                      ]),
                      const Text("0.00 บาท", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF1D5A5D), shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        const Text("กำไรสุทธิ", style: TextStyle(color: Colors.grey, fontSize: 13)),
                      ]),
                      const Text("0.00 บาท", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),

            const Padding(
              padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
              child: Text("เงิน", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.receipt_long, color: Color(0xFF1D5A5D)),
                    ),
                    title: const Text("ยอดขาย", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: const Text("ยอดสด/โอน • บิลเฉลี่ย • รายชั่วโมง...", style: TextStyle(color: Colors.grey, fontSize: 11)),
                    trailing: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("0.00", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        SizedBox(width: 4),
                        Icon(Icons.print, size: 16, color: Colors.grey),
                        Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                  ),
                  const Divider(height: 1, indent: 60),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.calculate_outlined, color: Color(0xFF1D5A5D)),
                    ),
                    title: const Text("ต้นทุน & กำไร", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: const Text("ต้นทุนรวม กำไรสุทธิ และอัตรา...", style: TextStyle(color: Colors.grey, fontSize: 11)),
                    trailing: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("0.00", style: TextStyle(color: Color(0xFF1D5A5D), fontWeight: FontWeight.bold)),
                        SizedBox(width: 4),
                        Icon(Icons.print, size: 16, color: Colors.grey),
                        Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                  ),
                ],
              ),
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
          child: Text(
            "ประวัติการอัพเดตสต็อก", 
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1D5A5D))
          ),
        ),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('stock_history')
              .orderBy('created_at', descending: true)
              .limit(20) 
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: Text("ยังไม่มีประวัติการอัพเดตสต็อก", style: TextStyle(color: Colors.grey))),
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
                   timeString = "${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
                }

                double newCost = (data['new_cost'] ?? 0).toDouble();

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
                          color: isAdd ? Colors.green.shade50 : Colors.red.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isAdd ? Icons.add_shopping_cart : Icons.remove_shopping_cart,
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
                                Text(data['product_name'] ?? 'ไม่ทราบชื่อ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                Text(timeString, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              data['detail'] ?? '', 
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12)
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F3F1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("คงเหลือ: ${data['new_stock']} ชิ้น", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1D5A5D))),
                                  Text("ทุนเฉลี่ย: ฿${newCost.toStringAsFixed(2)}/ชิ้น", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1D5A5D))),
                                ],
                              ),
                            ),
                          ],
                        ),
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