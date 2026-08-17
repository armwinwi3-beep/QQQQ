import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
// 🟢 เพิ่ม 2 ตัวแปรนี้สำหรับจัดการหมวดหมู่
  final TextEditingController _addCategoryController = TextEditingController(text: 'ทั่วไป');
  String selectedCategory = 'ทั้งหมด';
 // 🟢 วางทับฟังก์ชัน build เดิมทั้งหมด
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('products').snapshots(),
      builder: (context, snapshot) {
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFF3F3F1),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        var docs = snapshot.data?.docs ?? [];
        List<Map<String, dynamic>> inventoryItems = docs.map((doc) {
          var data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id; 
          return data;
        }).toList();

        // 🟢 ดึงรายการหมวดหมู่ที่ไม่ซ้ำกันออกมาสร้างเป็นปุ่ม
        Set<String> categoriesSet = {'ทั้งหมด'};
        for (var item in inventoryItems) {
          if (item['category'] != null && item['category'].toString().isNotEmpty) {
            categoriesSet.add(item['category']);
          }
        }
        List<String> categoryList = categoriesSet.toList();

        // 🟢 กรองรายการสินค้าตามหมวดหมู่ที่เลือก
        List<Map<String, dynamic>> filteredItems = inventoryItems.where((item) {
          if (selectedCategory == 'ทั้งหมด') return true;
          return item['category'] == selectedCategory;
        }).toList();

        int totalItems = 0;
        double totalValue = 0.0; 
        int trackingCount = 0;
        int lowStockCount = 0;
        int outOfStockCount = 0;

        for (var item in inventoryItems) {
          if (item['is_tracking'] == true) {
            trackingCount++;
            int stock = item['stock'] ?? 0;
            double cost = (item['cost'] ?? 0).toDouble(); 
            int minStock = item['min_stock'] ?? 0;
            totalItems += stock;
            totalValue += (stock * cost);
            if (stock == 0) outOfStockCount++;
            else if (stock <= minStock) lowStockCount++;
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
              _buildDashboardSummary(inventoryItems.length, trackingCount, lowStockCount, outOfStockCount, totalItems, totalValue),

              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("รายการสินค้า", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1D5A5D), fontSize: 16)),
                    Row(
                      children: [
                        const Icon(Icons.swap_vert, size: 16, color: Colors.grey),
                        Text(" เริ่มต้น", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1),

              // 🟢 แถบปุ่มหมวดหมู่ (เลื่อนซ้ายขวาได้)
              if (categoryList.length > 1)
                Container(
                  color: const Color(0xFFF3F3F1),
                  height: 60,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    itemCount: categoryList.length,
                    itemBuilder: (context, index) {
                      String cat = categoryList[index];
                      bool isSelected = selectedCategory == cat;
                      return GestureDetector(
                        onTap: () => setState(() => selectedCategory = cat),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF1D5A5D) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isSelected ? const Color(0xFF1D5A5D) : Colors.grey.shade300),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            cat,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

              // 🟢 รายการสินค้า (ดีไซน์ใหม่)
              Expanded(
                child: filteredItems.isEmpty
                    ? const Center(child: Text("ไม่มีสินค้าในหมวดหมู่นี้", style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: filteredItems.length,
                        itemBuilder: (context, index) {
                          var item = filteredItems[index];
                          bool isSelected = selectedItemId == item['id'];
                          bool isTracking = item['is_tracking'] == true;
                          int stock = item['stock'] ?? 0;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedItemId = isSelected ? null : item['id'];
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.teal.shade50 : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF1D5A5D) : Colors.transparent,
                                  width: 1.5,
                                ),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 2))],
                              ),
                              child: Row(
                                children: [
                                  // ไอคอนด้านซ้าย
                                  Container(
                                    width: 50, height: 50,
                                    decoration: BoxDecoration(color: const Color(0xFFE0F2F1), borderRadius: BorderRadius.circular(12)),
                                    alignment: Alignment.center,
                                    child: Text(
                                      item['name'].isNotEmpty ? item['name'][0] : "?", 
                                      style: const TextStyle(color: Color(0xFF1D5A5D), fontWeight: FontWeight.bold, fontSize: 20)
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  
                                  // ชื่อและป้ายสถานะ
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item['name'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                                        const SizedBox(height: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: isTracking ? Colors.blue.shade50 : Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            isTracking ? 'พร้อมขาย' : 'ไม่ติดตามสต็อก',
                                            style: TextStyle(color: isTracking ? Colors.blue.shade700 : Colors.grey.shade600, fontSize: 11, fontWeight: FontWeight.bold),
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                  
                                  // ตัวเลขสต็อกด้านขวา
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        isTracking ? '$stock' : '-',
                                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isTracking ? const Color(0xFF1D5A5D) : Colors.grey),
                                      ),
                                      const Text("คงเหลือ", style: TextStyle(color: Colors.grey, fontSize: 11)),
                                    ],
                                  ),
                                  const SizedBox(width: 12),
                                  const Icon(Icons.chevron_right, color: Colors.grey, size: 20)
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
          
          bottomNavigationBar: selectedItemId != null
              ? Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
                  ),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => setState(() => selectedItemId = null),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          child: const Icon(Icons.close, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            var selectedData = inventoryItems.firstWhere((item) => item['id'] == selectedItemId);
                            _showEditStockModal(context, selectedData);
                          },
                          icon: const Icon(Icons.edit_square, color: Colors.white),
                          label: const Text("แก้ไข / เติมสต็อก", style: TextStyle(fontSize: 16, color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1D5A5D),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : null,
        );
      }
    );
  }

  Widget _buildDashboardSummary(int totalProducts, int tracking, int low, int out, int totalItems, double totalValue) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildStatCard("สินค้าทั้งหมด", "$totalProducts", Icons.inventory_2_outlined, Colors.blue)),
              const SizedBox(width: 10),
              Expanded(child: _buildStatCard("ติดตามสต็อก", "$tracking", Icons.check_box_outlined, Colors.teal)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildStatCard("ใกล้หมด", "$low", Icons.warning_amber_rounded, Colors.orange)),
              const SizedBox(width: 10),
              Expanded(child: _buildStatCard("หมดแล้ว", "$out", Icons.remove_shopping_cart, Colors.red)),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: const Color(0xFF1F7A83), borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                const Icon(Icons.widgets, color: Colors.white70, size: 36),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("คงเหลือรวมทั้งร้าน", style: TextStyle(color: Colors.white70, fontSize: 12)),
                      Text("$totalItems ชิ้น", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Container(width: 1, height: 40, color: Colors.white30),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text("มูลค่าสต็อก", style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Text("฿${totalValue.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: iconColor)),
        ],
      ),
    );
  }

// 🟢 วางทับฟังก์ชัน _showAddProductModal เดิม
  void _showAddProductModal(BuildContext context) {
    _addNameController.clear();
    _addPriceController.clear();
    _addCostController.clear();
    _addCategoryController.text = 'ทั่วไป'; // ค่าเริ่มต้น

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("เพิ่มสินค้า", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1D5A5D))),
                    IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 90, height: 90,
                      decoration: BoxDecoration(color: Colors.grey.shade50, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("?", style: TextStyle(fontSize: 28, color: Colors.blue, fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text("เลือกรูป", style: TextStyle(fontSize: 12, color: Colors.grey))
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        children: [
                          _buildAddField("ชื่อสินค้า *", "เช่น กาแฟเย็น", _addNameController),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(child: _buildAddField("ราคาขาย *", "0", _addPriceController, isNumber: true)),
                              const SizedBox(width: 10),
                              Expanded(child: _buildAddField("ต้นทุน", "0", _addCostController, isNumber: true)),
                            ],
                          )
                        ],
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 16),
                
                // 🟢 เปลี่ยนหมวดหมู่เป็นช่องพิมพ์ เพื่อให้ตั้งชื่อหมวดหมู่เองได้เลย
                _buildAddField("หมวดหมู่", "เช่น เครื่องดื่ม, ของทอด", _addCategoryController),
                
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_addNameController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("กรุณากรอกชื่อสินค้า!"), backgroundColor: Colors.red));
                        return;
                      }

                      await FirebaseFirestore.instance.collection('products').add({
                        'name': _addNameController.text.trim(),
                        'price': double.tryParse(_addPriceController.text) ?? 0.0,
                        'cost': double.tryParse(_addCostController.text) ?? 0.0,
                        'category': _addCategoryController.text.trim().isEmpty ? 'ทั่วไป' : _addCategoryController.text.trim(), // บันทึกหมวดหมู่
                        'stock': 0,
                        'min_stock': 0,
                        'is_tracking': false,
                        'created_at': FieldValue.serverTimestamp(),
                      });

                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("เพิ่มสินค้าสำเร็จ!"), backgroundColor: Colors.green));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1D5A5D),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.save_outlined, color: Colors.white),
                        SizedBox(width: 8),
                        Text("บันทึก", style: TextStyle(fontSize: 16, color: Colors.white)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildAddField(String label, String hint, TextEditingController controller, {bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text, 
          decoration: InputDecoration(
            hintText: hint,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF1F7A83))),
          ),
        ),
      ],
    );
  }

  Widget _buildAddMenuBtn(IconData icon, String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF1D5A5D)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () {},
      ),
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
              String docId = updatedItem['id'];
              updatedItem.remove('id'); 
              await FirebaseFirestore.instance.collection('products').doc(docId).update(updatedItem);

              setState(() {
                selectedItemId = null; 
              });
            },
          );
        });
  }
}

// ==========================================
// 🟢 วิดเจ็ตหน้าต่าง "แก้ไขสต็อก" 
// ==========================================
class EditStockModalWidget extends StatefulWidget {
  final Map<String, dynamic> item;
  final Function(Map<String, dynamic>) onSave;

  const EditStockModalWidget({super.key, required this.item, required this.onSave});

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
  final TextEditingController currentCostController = TextEditingController(); 

  @override
  void initState() {
    super.initState();
    
    // ตั้งค่าเริ่มต้น
    minStockController.text = (widget.item['min_stock'] ?? 0).toString();
    
    // ราคาขาย แสดงเป็นค่าดั้งเดิม
    priceController.text = (widget.item['price'] ?? 0).toString(); 
    
    // 🟢 ต้นทุนตรงที่กรอกไม่ได้ (แถวบนสุด) ให้แสดงผลเป็นทศนิยม 2 ตำแหน่ง
    currentCostController.text = (widget.item['cost'] ?? 0).toDouble().toStringAsFixed(2); 

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
        damageCostController.text = '0.00';
      } else {
        int amt = int.tryParse(amountController.text) ?? 0;
        // 🟢 เวลาคำนวณความเสียหายตอนลดสต็อก ให้ใช้ต้นทุนเฉลี่ยที่มีอยู่ปัจจุบันมาคูณ
        double itemCost = (widget.item['cost'] ?? 0).toDouble();
        damageCostController.text = (amt * itemCost).toStringAsFixed(2); 
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
    double costInput = double.tryParse(costController.text) ?? 0.0;
    double totalAddValue = amountInput * costInput;
    double currentCostDouble = (widget.item['cost'] ?? 0).toDouble();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24, right: 24, top: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- ส่วนหัว ---
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFE0F2F1),
                  child: Text(widget.item['name'][0], style: const TextStyle(color: Color(0xFF1D5A5D), fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.item['name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1D5A5D))),
                      Text("คงเหลือ $currentStock ชิ้น", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const Divider(height: 24),
            
            // --- 1. กรอบข้อมูลราคาและต้นทุนปัจจุบัน ---
            if (isAddingStock) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start, 
                  children: [
                    Expanded(child: _buildInput("ราคาขายปัจจุบัน", priceController, "0")),
                    const SizedBox(width: 12),
                    Expanded(child: _buildInput("ต้นทุนเฉลี่ย", currentCostController, "0.00", enabled: false)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // --- ปุ่มสลับโหมด (เติมสต็อก / ลดสต็อก) ---
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
                        color: isAddingStock ? const Color(0xFF1F7A83) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_box_outlined, color: isAddingStock ? Colors.white : Colors.grey),
                          const SizedBox(width: 8),
                          Text("เติมสต็อก", style: TextStyle(color: isAddingStock ? Colors.white : Colors.grey.shade700, fontWeight: FontWeight.bold)),
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
                        color: !isAddingStock ? Colors.red.shade400 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined, color: !isAddingStock ? Colors.white : Colors.grey),
                          const SizedBox(width: 8),
                          Text("ลดสต็อก", style: TextStyle(color: !isAddingStock ? Colors.white : Colors.grey.shade700, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // --- 2. กรอบฟิลด์กรอกข้อมูล (แยกสัดส่วนชัดเจน) ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isAddingStock ? Colors.teal.shade50.withOpacity(0.3) : Colors.red.shade50.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isAddingStock ? Colors.teal.shade100 : Colors.red.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isAddingStock) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildInput("จำนวนที่ต้องการเติม (+)", amountController, "เช่น 5", hintBottom: "จำนวนที่เพิ่มเข้าคลัง", isNumberOnly: true)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildInput("ต้นทุนซื้อเข้าต่อชิ้น (บาท)", costController, "0")),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInput("จำนวนขั้นต่ำ (แจ้งเตือนใกล้หมด)", minStockController, "0", isNumberOnly: true),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("มูลค่าจะบันทึกเป็นรายจ่ายวันนี้", style: TextStyle(color: Colors.grey, fontSize: 13)),
                          Text("฿${totalAddValue.toStringAsFixed(2)}", style: const TextStyle(color: Colors.red, fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ] else ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildInput("จำนวนที่ลด (-)", amountController, "0", hintBottom: "ลดได้ไม่เกิน $currentStock ชิ้น", isNumberOnly: true)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildInput(
                            "ค่าความเสียหาย (บาท)",
                            damageCostController,
                            "0",
                            hintBottom: reduceReason == 'typo' ? "ไม่มีค่าความเสียหาย" : "คิดจากต้นทุน ${currentCostDouble.toStringAsFixed(2)}",
                            enabled: reduceReason != 'typo',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInput("จำนวนขั้นต่ำ (แจ้งเตือนใกล้หมด)", minStockController, "0", isNumberOnly: true),
                    const SizedBox(height: 16),
                    const Text("เหตุผลการลดสต็อก *", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _buildReasonBtn("ของหาย", 'lost')),
                        const SizedBox(width: 8),
                        Expanded(child: _buildReasonBtn("ของเสีย", 'spoiled')),
                        const SizedBox(width: 8),
                        Expanded(child: _buildReasonBtn("กรอกผิด", 'typo')),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // --- ปุ่มบันทึกหลัก ---
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  Map<String, dynamic> updatedItem = Map.from(widget.item);
                  int amt = int.tryParse(amountController.text) ?? 0;
                  
                  double currentCost = (widget.item['cost'] ?? 0).toDouble();
                  double inputCost = double.tryParse(costController.text) ?? 0.0;

                  int newStock = 0;
                  double newCost = 0.0;
                  String detailLog = '';

                  if (isAddingStock) {
                    newStock = currentStock + amt;
                    updatedItem['stock'] = newStock;
                    
                    if (newStock > 0 && amt > 0) {
                      double totalOldValue = currentStock * currentCost;
                      double totalNewValue = amt * inputCost;
                      double avgCost = (totalOldValue + totalNewValue) / newStock;
                      
                      newCost = double.parse(avgCost.toStringAsFixed(2)); 
                      updatedItem['cost'] = newCost; 
                      
                      detailLog = 'เดิม $currentStock ชิ้น (ทุน ${currentCost.toStringAsFixed(2)} บ.) + เติม $amt ชิ้น (ทุน ${inputCost.toStringAsFixed(2)} บ.)';
                    } else {
                      newCost = currentCost;
                      updatedItem['cost'] = newCost;
                      detailLog = 'อัพเดตสต็อกโดยไม่มีต้นทุนเพิ่ม';
                    }
                    
                    updatedItem['price'] = double.tryParse(priceController.text) ?? (widget.item['price'] ?? 0).toDouble(); 
                    
                  } else {
                    newStock = currentStock - amt;
                    newStock = newStock < 0 ? 0 : newStock;
                    newCost = currentCost;
                    updatedItem['stock'] = newStock;
                    updatedItem['cost'] = newCost; 

                    String reasonText = reduceReason == 'typo' ? 'กรอกผิด' : (reduceReason == 'spoiled' ? 'ของเสีย' : 'ของหาย');
                    detailLog = 'ลด $amt ชิ้น (เหตุผล: $reasonText)';
                  }

                  updatedItem['min_stock'] = int.tryParse(minStockController.text) ?? widget.item['min_stock'];
                  updatedItem['is_tracking'] = true; 

                  widget.onSave(updatedItem);

                  await FirebaseFirestore.instance.collection('stock_history').add({
                    'product_name': widget.item['name'],
                    'action': isAddingStock ? 'add' : 'reduce',
                    'amount': amt,
                    'old_stock': currentStock,
                    'new_stock': newStock,
                    'old_cost': currentCost,
                    'new_cost': newCost,
                    'detail': detailLog,
                    'created_at': FieldValue.serverTimestamp(),
                  });

                  if (context.mounted) Navigator.pop(context);
                },
                icon: Icon(isAddingStock ? Icons.add_box : Icons.inventory_2_outlined, color: Colors.white),
                label: Text(isAddingStock ? "บันทึกการเติมสต็อก" : "บันทึกการลดสต็อก", style: const TextStyle(fontSize: 16, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isAddingStock ? const Color(0xFF1F7A83) : Colors.red.shade400,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () {
                  Map<String, dynamic> updatedItem = Map.from(widget.item);
                  updatedItem['is_tracking'] = false; 
                  widget.onSave(updatedItem);
                  Navigator.pop(context);
                },
                child: const Text("หยุดติดตามสต็อกสินค้านี้", style: TextStyle(color: Colors.grey)),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController controller, String hint, {String? hintBottom, bool enabled = true, bool isNumberOnly = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: isNumberOnly ? TextInputType.number : const TextInputType.numberWithOptions(decimal: true), 
          enabled: enabled,
          decoration: InputDecoration(
            hintText: hint,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            filled: !enabled,
            fillColor: enabled ? Colors.transparent : Colors.grey.shade100,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
            disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF1F7A83))),
          ),
        ),
        if (hintBottom != null) ...[
          const SizedBox(height: 4),
          Text(hintBottom, style: const TextStyle(fontSize: 10, color: Colors.grey)),
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
        child: Text(text, style: TextStyle(color: isSel ? Colors.white : Colors.grey.shade700, fontWeight: FontWeight.bold, fontSize: 13)),
      ),
    );
  }
}