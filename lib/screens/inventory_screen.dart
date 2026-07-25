import 'package:flutter/material.dart';
// ดึงไฟล์หน้าย่อยเข้ามาใช้งาน
import 'report_screen.dart';
import 'inventory_screen.dart';
import 'package:flutter/material.dart';

class InventoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          // กล่อง 4 อันด้านบน
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildStockBox(
                        'สินค้าทั้งหมด', '1', Icons.inventory_2_outlined),
                    const SizedBox(width: 16),
                    _buildStockBox(
                        'ติดตามสต็อก', '0', Icons.check_box_outlined),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildStockBox('ใกล้หมด', '0', Icons.warning_amber_rounded,
                        textColor: Colors.orange),
                    const SizedBox(width: 16),
                    _buildStockBox('หมดแล้ว', '0', Icons.remove_shopping_cart,
                        textColor: Colors.red),
                  ],
                ),
                const SizedBox(height: 16),
                // กล่องสีเขียวใหญ่
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      color: const Color(0xFF1F7A83),
                      borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            color: Colors.white24, shape: BoxShape.circle),
                        child: const Icon(Icons.widgets, color: Colors.white),
                      ),
                      const SizedBox(width: 16),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('คงเหลือรวมทั้งร้าน',
                              style: TextStyle(color: Colors.white70)),
                          Text('0 ชิ้น',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold)),
                        ],
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
          // แถบ Tab
          const TabBar(
            labelColor: Color(0xFF1F7A83),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFF1F7A83),
            tabs: [
              Tab(text: 'รายการสินค้า'),
              Tab(text: 'การเคลื่อนไหว'),
            ],
          ),
          // เนื้อหาใน Tab
          Expanded(
            child: TabBarView(
              children: [
                // หน้า 1: รายการสินค้า
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        leading: CircleAvatar(
                            backgroundColor: Colors.blue[50],
                            child: const Text('ล',
                                style: TextStyle(color: Colors.teal))),
                        title: const Text('ลูกชิ้น',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('ไม่ติดตามสต็อก',
                                style: TextStyle(color: Colors.grey)),
                            const Icon(Icons.chevron_right, color: Colors.grey),
                          ],
                        ),
                        // พอกดไอเท็ม จะเด้ง Bottom Sheet หน้าเติมสต็อกขึ้นมา
                        onTap: () => _showAddStockModal(context),
                      ),
                    )
                  ],
                ),
                // หน้า 2: การเคลื่อนไหว
                const Center(
                    child: Text('ยังไม่มีสินค้าที่ติดตามสต็อก',
                        style: TextStyle(color: Colors.grey))),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStockBox(String title, String count, IconData icon,
      {Color textColor = Colors.black}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.teal, size: 20),
                const SizedBox(width: 8),
                Text(title,
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),
            Text(count,
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor)),
          ],
        ),
      ),
    );
  }

  // ฟังก์ชันแสดง Popup เติมสต็อก (เหมือนรูปที่ 5)
  void _showAddStockModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20), topRight: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
              top: 20,
              left: 20,
              right: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: CircleAvatar(
                    backgroundColor: Colors.blue[50],
                    child:
                        const Text('ล', style: TextStyle(color: Colors.teal))),
                title: const Text('ลูกชิ้น',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                subtitle:
                    const Text('ยังไม่ติดตามสต็อก — เติมครั้งแรกเพื่อเริ่ม...'),
                trailing: IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(height: 16),
              // สามารถเพิ่ม TextField สำหรับกรอกจำนวน และปุ่ม "เติมสต็อก" สีฟ้าตรงนี้ได้เลย
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add_box),
                  label:
                      const Text('เติมสต็อก', style: TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1F7A83),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10))),
                ),
              )
            ],
          ),
        );
      },
    );
  }
}
