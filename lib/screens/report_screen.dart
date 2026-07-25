import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({Key? key}) : super(key: key);

  @override
  _ReportScreenState createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  // ตัวเก็บสถานะแท็บที่เลือก (0 = วันนี้, 1 = 7 วัน, 2 = 30 วัน, 3 = กำหนดเอง)
  int _selectedTabIndex = 0;

  // ฟังก์ชันคำนวณหาวันที่เริ่มต้นตามแท็บที่กดเลือก
  DateTime _getStartDate() {
    DateTime now = DateTime.now();
    DateTime todayMidnight = DateTime(now.year, now.month, now.day);

    switch (_selectedTabIndex) {
      case 0: // วันนี้
        return todayMidnight;
      case 1: // 7 วันย้อนหลัง
        return todayMidnight.subtract(const Duration(days: 7));
      case 2: // 30 วันย้อนหลัง
        return todayMidnight.subtract(const Duration(days: 30));
      case 3: // กำหนดเอง (ในที่นี้ดึงย้อนหลังไป 1 ปี หรือทั้งหมด)
      default:
        return DateTime(2020);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // แถบเลือกช่วงเวลา (กดเปลี่ยนสถานะได้จริง)
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: [
                  _buildTabButton('วันนี้', 0),
                  _buildTabButton('7 วัน', 1),
                  _buildTabButton('30 วัน', 2),
                  _buildTabButton('กำหนดเอง', 3),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('ร้านป้าต้อย • ข้อมูลยอดขาย',
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),

            // 🔴 ดึงข้อมูลจาก Firebase มาคำนวณแสดงผลแบบ Real-time
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .where('status',
                      isEqualTo:
                          'completed') // กรองเฉพาะออเดอร์ที่เสร็จสิ้นแล้ว
                  .where('created_at',
                      isGreaterThanOrEqualTo:
                          _getStartDate()) // กรองตามช่วงเวลา
                  .snapshots(),
              builder: (context, snapshot) {
                // ค่าเริ่มต้นเป็น 0 ระหว่างรอโหลด
                double totalSales = 0;
                int totalBills = 0;

                if (snapshot.hasData) {
                  var docs = snapshot.data!.docs;
                  totalBills = docs.length;
                  for (var doc in docs) {
                    var data = doc.data() as Map<String, dynamic>;
                    totalSales += (data['total_price'] ?? 0).toDouble();
                  }
                }

                // คำนวณต้นทุนและกำไร (จำลองสัดส่วนต้นทุน 40% กำไร 60%)
                double totalCost = totalSales * 0.4;
                double totalProfit = totalSales - totalCost;

                return Column(
                  children: [
                    // กล่องยอดขายรวม
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('ยอดขายทั้งหมด',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(10)),
                                child: const Text('ยอดรวม',
                                    style: TextStyle(fontSize: 12)),
                              )
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                totalSales.toStringAsFixed(2),
                                style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold),
                              ),
                              Text('$totalBills บิล',
                                  style: const TextStyle(color: Colors.grey)),
                            ],
                          ),
                          const Divider(height: 30),
                          const Text('ต้นทุน & กำไร',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: totalSales > 0 ? 0.4 : 0,
                            backgroundColor: Colors.grey[300],
                            color: Colors.orange,
                          ),
                          const SizedBox(height: 16),
                          _buildCostProfitRow('ต้นทุน',
                              totalCost.toStringAsFixed(2), Colors.orange),
                          const SizedBox(height: 8),
                          _buildCostProfitRow(
                              'กำไรสุทธิ',
                              totalProfit.toStringAsFixed(2),
                              const Color(0xFF1F7A83)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                    const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('เงิน',
                            style: TextStyle(fontWeight: FontWeight.bold))),
                    const SizedBox(height: 8),

                    // เมนูย่อยแสดงผลยอดเงิน
                    Container(
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        children: [
                          _buildMenuCard(
                              Icons.money,
                              'ยอดขาย',
                              'ยอดสด/โอน • บิลเฉลี่ย • รายชั่วโม...',
                              totalSales.toStringAsFixed(2),
                              isRed: true),
                          const Divider(height: 1),
                          _buildMenuCard(
                              Icons.calculate_outlined,
                              'ต้นทุน & กำไร',
                              'ต้นทุนรวม กำไรสุทธิ และอัตรา...',
                              totalProfit.toStringAsFixed(2)),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Widget ปุ่มแท็บที่กดเปลี่ยนสถานะได้
  Widget _buildTabButton(String title, int index) {
    bool isActive = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF1F7A83) : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Center(
            child: Text(title,
                style: TextStyle(
                    color: isActive ? Colors.white : Colors.black54,
                    fontWeight:
                        isActive ? FontWeight.bold : FontWeight.normal)),
          ),
        ),
      ),
    );
  }

  Widget _buildCostProfitRow(String title, String amount, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            CircleAvatar(radius: 4, backgroundColor: color),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        Row(
          children: [
            Text(amount, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            const Text('บาท', style: TextStyle(color: Colors.grey)),
          ],
        )
      ],
    );
  }

  Widget _buildMenuCard(
      IconData icon, String title, String subtitle, String amount,
      {bool isRed = false}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: Colors.blueGrey[50], borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: const Color(0xFF1F7A83)),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle,
          style: const TextStyle(fontSize: 12, color: Colors.grey)),
      trailing: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(amount,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isRed ? Colors.red : const Color(0xFF1F7A83))),
          const SizedBox(width: 8),
          const Icon(Icons.receipt_long, size: 16, color: Colors.grey),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
      onTap: () {},
    );
  }
}
