import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 🟢 1. Import Firestore

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String? selectedItemId;

  final TextEditingController _addNameController = TextEditingController();
  final TextEditingController _addPriceController = TextEditingController();
  final TextEditingController _addCostController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // 🟢 2. เอา StreamBuilder ครอบหน้าจอไว้ เพื่อดึงข้อมูลจาก Firebase แบบ Real-time
    return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('products').snapshots(),
        builder: (context, snapshot) {
          // ระหว่างรอโหลดข้อมูล
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: Color(0xFFF3F3F1),
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // แปลงข้อมูลจาก Firebase ให้ใช้งานง่าย
          var docs = snapshot.data?.docs ?? [];
          List<Map<String, dynamic>> inventoryItems = docs.map((doc) {
            var data = doc.data() as Map<String, dynamic>;
            data['id'] =
                doc.id; // ดึงรหัสเอกสาร (Doc ID) มาเก็บไว้ใช้ตอนแก้ข้อมูล
            return data;
          }).toList();

          // 🟢 3. คำนวณสรุปยอด Dashboard จากข้อมูลใน Database จริง
          int totalItems = 0;
          int totalValue = 0;
          int trackingCount = 0;
          int lowStockCount = 0;
          int outOfStockCount = 0;

          for (var item in inventoryItems) {
            if (item['is_tracking'] == true) {
              trackingCount++;
              int stock = item['stock'] ?? 0;
              int cost = item['cost'] ?? 0;
              int minStock = item['min_stock'] ?? 0;

              totalItems += stock;
              totalValue += (stock * cost);

              if (stock == 0) {
                outOfStockCount++;
              } else if (stock <= minStock) {
                lowStockCount++;
              }
            }
          }

          return Scaffold(
            backgroundColor: const Color(0xFFF3F3F1),
            floatingActionButton: selectedItemId == null
                ? FloatingActionButton(
                    onPressed: () => _showAddProductModal(context),
                    backgroundColor: const Color(0xFF1D5A5D),
                    child: const Icon(Icons.add_box, color: Colors.white),
                  )
                : null,
            body: Column(
              children: [
                // Dashboard
                _buildDashboardSummary(inventoryItems.length, trackingCount,
                    lowStockCount, outOfStockCount, totalItems, totalValue),

                // แถบเมนู
                Container(
                  color: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("รายการสินค้า",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1D5A5D))),
                      Row(
                        children: [
                          const Icon(Icons.swap_vert,
                              size: 16, color: Colors.grey),
                          Text(" เริ่มต้น",
                              style: TextStyle(color: Colors.grey.shade600)),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, thickness: 1),

                // รายการสินค้า
                Expanded(
                  child: inventoryItems.isEmpty
                      ? const Center(
                          child: Text("ยังไม่มีสินค้าในคลัง",
                              style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: inventoryItems.length,
                          itemBuilder: (context, index) {
                            var item = inventoryItems[index];
                            bool isSelected = selectedItemId == item['id'];

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedItemId =
                                      isSelected ? null : item['id'];
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.teal.shade50
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF1D5A5D)
                                        : Colors.transparent,
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.grey.withOpacity(0.1),
                                        blurRadius: 5,
                                        spreadRadius: 1)
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 45,
                                      height: 45,
                                      decoration: BoxDecoration(
                                          color: const Color(0xFFE0F2F1),
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      alignment: Alignment.center,
                                      child: Text(
                                          item['name'].isNotEmpty
                                              ? item['name'][0]
                                              : "?",
                                          style: const TextStyle(
                                              color: Color(0xFF1D5A5D),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18)),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(item['name'],
                                              style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              item['is_tracking']
                                                  ? 'พร้อมขาย'
                                                  : 'ไม่ติดตาม',
                                              style: TextStyle(
                                                  color: Colors.blue.shade700,
                                                  fontSize: 11),
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          item['is_tracking']
                                              ? '${item['stock']}'
                                              : '-',
                                          style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1D5A5D)),
                                        ),
                                        const Text("คงเหลือ",
                                            style: TextStyle(
                                                color: Colors.grey,
                                                fontSize: 11)),
                                      ],
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.chevron_right,
                                        color: Colors.grey)
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),

            // แถบเมนูด้านล่าง (แก้ไขสต็อก)
            bottomNavigationBar: selectedItemId != null
                ? Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            offset: Offset(0, -2))
                      ],
                    ),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: () => setState(() => selectedItemId = null),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                                color: Colors.red, shape: BoxShape.circle),
                            child: const Icon(Icons.close, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              var selectedData = inventoryItems.firstWhere(
                                  (item) => item['id'] == selectedItemId);
                              _showEditStockModal(context, selectedData);
                            },
                            icon: const Icon(Icons.edit_square,
                                color: Colors.white),
                            label: const Text("แก้ไข / เติมสต็อก",
                                style: TextStyle(
                                    fontSize: 16, color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1D5A5D),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : null,
          );
        });
  }

  // Dashboard (แก้ให้รับค่าที่คำนวณมา)
  Widget _buildDashboardSummary(int totalProducts, int tracking, int low,
      int out, int totalItems, int totalValue) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                  child: _buildStatCard("สินค้าทั้งหมด", "$totalProducts",
                      Icons.inventory_2_outlined, Colors.blue)),
              const SizedBox(width: 10),
              Expanded(
                  child: _buildStatCard("ติดตามสต็อก", "$tracking",
                      Icons.check_box_outlined, Colors.teal)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: _buildStatCard("ใกล้หมด", "$low",
                      Icons.warning_amber_rounded, Colors.orange)),
              const SizedBox(width: 10),
              Expanded(
                  child: _buildStatCard("หมดแล้ว", "$out",
                      Icons.remove_shopping_cart, Colors.red)),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: const Color(0xFF1F7A83),
                borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                const Icon(Icons.widgets, color: Colors.white70, size: 36),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("คงเหลือรวมทั้งร้าน",
                          style:
                              TextStyle(color: Colors.white70, fontSize: 12)),
                      Text("$totalItems ชิ้น",
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Container(width: 1, height: 40, color: Colors.white30),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text("มูลค่าสต็อก",
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Text("฿$totalValue",
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold, color: iconColor)),
        ],
      ),
    );
  }

  // 🟢 4. ฟังก์ชันเพิ่มสินค้า (บันทึกลง Database จริง!)
  void _showAddProductModal(BuildContext context) {
    _addNameController.clear();
    _addPriceController.clear();
    _addCostController.clear();

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return Container(
            decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("เพิ่มสินค้า",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1D5A5D))),
                      IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12)),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("?",
                                style: TextStyle(
                                    fontSize: 28,
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold)),
                            SizedBox(height: 4),
                            Text("เลือกรูป",
                                style:
                                    TextStyle(fontSize: 12, color: Colors.grey))
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          children: [
                            _buildAddField("ชื่อสินค้า *", "เช่น กาแฟเย็น",
                                _addNameController),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                    child: _buildAddField(
                                        "ราคาขาย *", "0", _addPriceController,
                                        isNumber: true)),
                                const SizedBox(width: 10),
                                Expanded(
                                    child: _buildAddField(
                                        "ต้นทุน", "0", _addCostController,
                                        isNumber: true)),
                              ],
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_addNameController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("กรุณากรอกชื่อสินค้า!"),
                                  backgroundColor: Colors.red));
                          return;
                        }

                        // 🟢 ยิงข้อมูลลง Firebase ตรงนี้!
                        await FirebaseFirestore.instance
                            .collection('products')
                            .add({
                          'name': _addNameController.text.trim(),
                          'price': int.tryParse(_addPriceController.text) ?? 0,
                          'cost': int.tryParse(_addCostController.text) ?? 0,
                          'stock': 0,
                          'min_stock': 0,
                          'is_tracking': false,
                          'created_at': FieldValue.serverTimestamp(),
                        });

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("เพิ่มสินค้าสำเร็จ!"),
                                  backgroundColor: Colors.green));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1D5A5D),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.save_outlined, color: Colors.white),
                          SizedBox(width: 8),
                          Text("บันทึก",
                              style:
                                  TextStyle(fontSize: 16, color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        });
  }

  Widget _buildAddField(
      String label, String hint, TextEditingController controller,
      {bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            hintText: hint,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF1F7A83))),
          ),
        ),
      ],
    );
  }

  void _showEditStockModal(BuildContext context, Map<String, dynamic> item) {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return EditStockModalWidget(
            item: item,
            onSave: (updatedItem) async {
              // 🟢 5. อัปเดตข้อมูลขึ้น Firebase
              String docId = updatedItem['id'];
              updatedItem.remove('id'); // ลบ ID ออกก่อนโยนขึ้น Database

              await FirebaseFirestore.instance
                  .collection('products')
                  .doc(docId)
                  .update(updatedItem);

              setState(() {
                selectedItemId = null; // ปิดสถานะการเลือก
              });
            },
          );
        });
  }
}

// ==========================================
// 🟢 วิดเจ็ตหน้าต่าง "แก้ไขสต็อก" (ลอกของเดิมมาใส่ได้เลย)
// ==========================================
// ==========================================
// 🟢 วิดเจ็ตหน้าต่าง "แก้ไขสต็อก" (อัปเดตแก้ราคาขายได้)
// ==========================================
// 🟢 วิดเจ็ตหน้าต่าง "แก้ไขสต็อก" (แก้ UI ให้จัดเรียงสวยงามเป๊ะๆ)
// ==========================================
class EditStockModalWidget extends StatefulWidget {
  final Map<String, dynamic> item;
  final Function(Map<String, dynamic>) onSave;

  const EditStockModalWidget(
      {super.key, required this.item, required this.onSave});

  @override
  State<EditStockModalWidget> createState() => _EditStockModalWidgetState();
}

class _EditStockModalWidgetState extends State<EditStockModalWidget> {
  bool isAddingStock = true;
  String reduceReason = 'lost';

  final TextEditingController amountController = TextEditingController();
  final TextEditingController costController = TextEditingController();
  final TextEditingController minStockController = TextEditingController();
  final TextEditingController damageCostController = TextEditingController();
  final TextEditingController priceController = TextEditingController();

  // 🟢 เพิ่ม Controller สำหรับโชว์ต้นทุนเดิมด้านบนให้หน้าตาเหมือนช่องราคาขาย
  final TextEditingController currentCostController = TextEditingController();

  @override
  void initState() {
    super.initState();
    costController.text = widget.item['cost'].toString();
    minStockController.text = widget.item['min_stock'].toString();
    priceController.text = widget.item['price'].toString();
    currentCostController.text = widget.item['cost'].toString();

    amountController.addListener(_calculateDamage);
    costController.addListener(_calculateDamage);
  }

  @override
  void dispose() {
    amountController.dispose();
    costController.dispose();
    minStockController.dispose();
    damageCostController.dispose();
    priceController.dispose();
    currentCostController.dispose();
    super.dispose();
  }

  void _calculateDamage() {
    if (!isAddingStock) {
      if (reduceReason == 'typo') {
        damageCostController.text = '0';
      } else {
        int amt = int.tryParse(amountController.text) ?? 0;
        int cost = int.tryParse(costController.text) ?? 0;
        damageCostController.text = (amt * cost).toString();
      }
      setState(() {});
    } else {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    int currentStock = widget.item['stock'] ?? 0;
    int amountInput = int.tryParse(amountController.text) ?? 0;
    int costInput = int.tryParse(costController.text) ?? 0;
    int totalAddValue = amountInput * costInput;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFE0F2F1),
                  child: Text(widget.item['name'][0],
                      style: const TextStyle(
                          color: Color(0xFF1D5A5D),
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.item['name'],
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1D5A5D))),
                      Text(
                          "คงเหลือ $currentStock ชิ้น · เติมสต็อกล่าสุด $currentStock",
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () => Navigator.pop(context)),
              ],
            ),
            const Divider(),
            const SizedBox(height: 10),

            // 🟢 ปรับ UI แถวแรกให้เป็นช่อง Input ทั้งคู่ และจัดให้อยู่ชิดขอบบน
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildInput("ราคาขาย", priceController, "0")),
                const SizedBox(width: 10),
                Expanded(
                    // 🟢 ล็อกช่องต้นทุนไว้ไม่ให้แก้ (ให้แก้ที่ช่องตอนเติมสต็อกแทน)
                    child: _buildInput("ต้นทุน", currentCostController, "0",
                        enabled: false)),
              ],
            ),

            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        isAddingStock = true;
                        amountController.clear();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isAddingStock
                            ? const Color(0xFF1F7A83)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_box_outlined,
                              color:
                                  isAddingStock ? Colors.white : Colors.grey),
                          const SizedBox(width: 8),
                          Text("เติมสต็อก",
                              style: TextStyle(
                                  color: isAddingStock
                                      ? Colors.white
                                      : Colors.grey,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        isAddingStock = false;
                        amountController.clear();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color:
                            !isAddingStock ? Colors.red : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined,
                              color:
                                  !isAddingStock ? Colors.white : Colors.grey),
                          const SizedBox(width: 8),
                          Text("ลดสต็อก",
                              style: TextStyle(
                                  color: !isAddingStock
                                      ? Colors.white
                                      : Colors.grey,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (isAddingStock) ...[
              // 🟢 เพิ่ม crossAxisAlignment: CrossAxisAlignment.start ไม่ให้กล่องขยับขึ้นลงตามคำอธิบายใต้ช่อง
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                      child: _buildInput(
                          "จำนวนสินค้าพร้อมขาย", amountController, "เช่น 5",
                          hintBottom:
                              "เว้นว่างไว้ได้ ถ้าจะแก้แค่จำนวนขั้นต่ำ")),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _buildInput(
                          "ต้นทุนซื้อเข้าต่อชิ้น (บาท)", costController, "0")),
                ],
              ),
              const SizedBox(height: 10),
              _buildInput(
                  "จำนวนขั้นต่ำ (แจ้งเตือนใกล้หมด)", minStockController, "0"),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("มูลค่าจะบันทึกเป็นรายจ่ายวันนี้",
                        style: TextStyle(color: Colors.grey)),
                    Text("$totalAddValue",
                        style: const TextStyle(
                            color: Colors.red,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ] else ...[
              // 🟢 เพิ่ม crossAxisAlignment: CrossAxisAlignment.start ตรงนี้ด้วย
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                      child: _buildInput("จำนวนที่ลด *", amountController, "0",
                          hintBottom: "ลดได้ไม่เกิน $currentStock ชิ้น")),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildInput(
                      "ค่าความเสียหาย (บาท) *",
                      damageCostController,
                      "0",
                      hintBottom: reduceReason == 'typo'
                          ? "ไม่มีค่าความเสียหาย"
                          : "คิดจากต้นทุน ${widget.item['cost']} ต่อชิ้น แก้ไขได้",
                      enabled: reduceReason != 'typo',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildInput(
                  "จำนวนขั้นต่ำ (แจ้งเตือนใกล้หมด)", minStockController, "0"),
              const SizedBox(height: 20),
              const Text("เหตุผล *",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _buildReasonBtn("ของหาย", 'lost')),
                  Expanded(child: _buildReasonBtn("ของเสีย", 'spoiled')),
                  Expanded(child: _buildReasonBtn("กรอกผิด", 'typo')),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                reduceReason == 'typo'
                    ? "แก้ตัวเลขให้ถูก ไม่บันทึกเป็นรายจ่าย"
                    : "ค่าความเสียหายจะบันทึกเป็นรายจ่ายของวันนี้",
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
            const SizedBox(height: 20),
            Center(
              child: TextButton(
                onPressed: () {
                  Map<String, dynamic> updatedItem = Map.from(widget.item);
                  updatedItem['is_tracking'] = false;
                  widget.onSave(updatedItem);
                  Navigator.pop(context);
                },
                child: const Text("หยุดติดตามสต็อกสินค้านี้",
                    style: TextStyle(color: Colors.grey)),
              ),
            ),
            // ... (โค้ดปุ่มหยุดติดตามสต็อกด้านบน เก็บไว้เหมือนเดิม) ...

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Map<String, dynamic> updatedItem = Map.from(widget.item);
                  int amt = int.tryParse(amountController.text) ?? 0;
                  int currentCost = widget.item['cost'] ?? 0;
                  int inputCost = int.tryParse(costController.text) ?? 0;

                  if (isAddingStock) {
                    int newStock = currentStock + amt;
                    updatedItem['stock'] = newStock;

                    // 🟢 คำนวณต้นทุนถัวเฉลี่ย (Weighted Average Cost)
                    if (newStock > 0 && amt > 0) {
                      double totalOldValue =
                          (currentStock * currentCost).toDouble();
                      double totalNewValue = (amt * inputCost).toDouble();
                      double avgCost =
                          (totalOldValue + totalNewValue) / newStock;

                      // ปัดเศษให้เป็นจำนวนเต็มเพื่อเก็บลง Database
                      // (เช่น 7.5 บาท จะปัดเป็น 8 บาท)
                      updatedItem['cost'] = avgCost.round();
                    } else {
                      // ถ้าไม่ได้เติมจำนวน ให้คงต้นทุนเดิมไว้
                      updatedItem['cost'] = currentCost;
                    }
                  } else {
                    // โหมดลดสต็อก
                    int newStock = currentStock - amt;
                    updatedItem['stock'] = newStock < 0 ? 0 : newStock;

                    // ลดสต็อก (ของหาย/ของเสีย) ต้นทุนต่อชิ้นต้องเท่าเดิมเสมอ
                    updatedItem['cost'] = currentCost;
                  }

                  updatedItem['min_stock'] =
                      int.tryParse(minStockController.text) ??
                          widget.item['min_stock'];
                  updatedItem['price'] = int.tryParse(priceController.text) ??
                      widget.item['price'];

                  updatedItem['is_tracking'] = true;

                  widget.onSave(updatedItem);
                  Navigator.pop(context);
                },
                icon: Icon(
                    isAddingStock ? Icons.add_box : Icons.inventory_2_outlined,
                    color: Colors.white),
                label: Text(isAddingStock ? "เติมสต็อก" : "ลดสต็อก",
                    style: const TextStyle(fontSize: 16, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isAddingStock
                      ? const Color(0xFF1F7A83)
                      : Colors.teal.shade400,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(
      String label, TextEditingController controller, String hint,
      {String? hintBottom, bool enabled = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          enabled: enabled,
          decoration: InputDecoration(
            hintText: hint,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            filled: !enabled,
            fillColor: enabled ? Colors.transparent : Colors.grey.shade100,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300)),
            disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade200)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF1F7A83))),
          ),
        ),
        if (hintBottom != null) ...[
          const SizedBox(height: 4),
          Text(hintBottom,
              style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ]
      ],
    );
  }

  Widget _buildReasonBtn(String text, String val) {
    bool isSel = reduceReason == val;
    return GestureDetector(
      onTap: () {
        setState(() {
          reduceReason = val;
        });
        _calculateDamage();
      },
      child: Container(
        margin: const EdgeInsets.only(right: 5),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSel ? const Color(0xFF1F7A83) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: Text(text,
            style: TextStyle(
                color: isSel ? Colors.white : Colors.grey.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 13)),
      ),
    );
  }
}
