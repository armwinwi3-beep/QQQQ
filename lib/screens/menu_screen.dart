import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'order_tracker.dart';
import 'order_history_screen.dart';
import 'slip_preview_screen.dart';

class MenuScreen extends StatefulWidget {
  final bool isMerchant;
  final String? merchantId;
  final String? storeName;

  const MenuScreen(
      {super.key, this.isMerchant = false, this.merchantId, this.storeName});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  Map<String, int> cart = {};

  void _increment(String id, bool isTracking, int maxStock) {
    int currentQty = cart[id] ?? 0;

    // 🟢 ถ้าเปิดติดตามสต็อก และของจะเกินสต็อก ถึงจะแจ้งเตือน
    if (isTracking && currentQty >= maxStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("สินค้าในสต็อกมีไม่พอ!"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    setState(() {
      cart[id] = currentQty + 1;
    });
  }

  void _decrement(String id) {
    int currentQty = cart[id] ?? 0;
    if (currentQty > 0) {
      setState(() {
        cart[id] = currentQty - 1;
        if (cart[id] == 0) {
          cart.remove(id);
        }
      });
    }
  }

  void _placeOrder(List<QueryDocumentSnapshot> products) async {
    double totalPrice = 0;
    List<Map<String, dynamic>> orderList = [];
    String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

    String newOrderCode = await _generateDailyOrderCode();

    for (var doc in products) {
      if (cart.containsKey(doc.id)) {
        var data = doc.data() as Map<String, dynamic>;
        int qty = cart[doc.id]!;
        double price = (data['price'] ?? 0).toDouble();

        totalPrice += (price * qty);
        orderList.add({
          'product_id': doc.id,
          'name': data['name'],
          'qty': qty,
          'price': price
        });
      }
    }

    if (orderList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("กรุณาเลือกอาหารอย่างน้อย 1 รายการ")));
      return;
    }

    String customerName = "ลูกค้าทั่วไป";
    String orderType = "online";

    if (widget.isMerchant) {
      customerName = "Walk-in (หน้าร้าน)";
      orderType = "walk-in";
    }

    // 🟢 1. บันทึกออเดอร์ลงระบบ
    // 1. บันทึกออเดอร์ลงระบบ
    DocumentReference docRef =
        await FirebaseFirestore.instance.collection('orders').add({
      'order_code': newOrderCode,
      'user_id': currentUserId,
      'merchant_id': widget.merchantId ?? currentUserId,

      // 🟢 เพิ่มบรรทัดนี้ เพื่อเซฟชื่อร้านลงไปในออเดอร์ด้วย!
      'merchant_name': widget.storeName ?? 'ร้านค้าทั่วไป',

      'customer_name': customerName,
      'order_type': orderType,
      'items': orderList,
      'total_price': totalPrice,
      'status': 'pending',
      'created_at': FieldValue.serverTimestamp(),
    });

    // 2. ตัดสต็อกคลังสินค้า และ บันทึกประวัติ
    // 2. ตัดสต็อกคลังสินค้า และ บันทึกประวัติการขาย
    for (var doc in products) {
      if (cart.containsKey(doc.id)) {
        var data = doc.data() as Map<String, dynamic>;
        bool isTracking =
            data['is_tracking'] ?? false; // 🟢 ดึงสถานะติดตามสต็อก

        int currentStock = data['stock'] ?? 0;
        int orderQty = cart[doc.id]!;
        int newStock = currentStock;
        double currentCost = (data['cost'] ?? 0).toDouble();

        // 🟢 2.1 อัปเดตคลัง (ตัดสต็อกเฉพาะเมนูที่เปิดติดตามเท่านั้น)
        if (isTracking) {
          newStock = currentStock - orderQty;
          if (newStock < 0) newStock = 0; // ไม่ให้ติดลบ

          await FirebaseFirestore.instance
              .collection('products')
              .doc(doc.id)
              .update({'stock': newStock});
        }

        // 🟢 2.2 บันทึกประวัติการขาย (บันทึกเสมอทุกเมนู เพื่อเก็บรายงานยอดขายปกติ)
        await FirebaseFirestore.instance.collection('stock_history').add({
          'product_name': data['name'],
          'action': 'reduce',
          'amount': orderQty,
          'old_stock': currentStock,
          // 🟢 ถ้าไม่ติดตามสต็อก ให้โชว์สต็อกเดิม ไม่ต้องหักลบ
          'new_stock': isTracking ? newStock : currentStock,
          'old_cost': currentCost,
          'new_cost': currentCost,
          'detail': 'ขายผ่านระบบ (ออเดอร์: $newOrderCode)',
          'created_at': FieldValue.serverTimestamp(),
        });
      }
    }

    setState(() {
      cart.clear();
    });

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OrderTracker(
            orderId: docRef.id,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🟢 หา ID ของร้านค้าที่จะดึงข้อมูล (ถ้ารับค่ามาให้ใช้ค่านั้น ถ้าไม่มีใช้ UID คนที่ล็อกอินอยู่)
    String targetMerchantId =
        widget.merchantId ?? FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F1),
      appBar: widget.isMerchant
          ? null
          : AppBar(
              backgroundColor: const Color(0xFF1D5A5D),
              title: const Text(
                "เมนูอาหาร",
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              centerTitle: true,
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.history, color: Colors.white),
                  tooltip: 'ประวัติการสั่งซื้อ',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const OrderHistoryScreen()),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white),
                  tooltip: 'ออกจากระบบ',
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                  },
                ),
              ],
            ),
      body: StreamBuilder<QuerySnapshot>(
          // 🟢 เพิ่มตัวกรอง .where เพื่อให้เมนูตรงกับคลังของร้านนั้นเป๊ะๆ
          stream: FirebaseFirestore.instance
              .collection('products')
              .where('merchant_id', isEqualTo: targetMerchantId)
              .snapshots(),
          builder: (context, snapshot) {
            // ดักจับ Error เผื่อต้องสร้าง Index
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SelectableText(
                    "กรุณากดลิงก์ใน Debug Console เพื่อสร้าง Index\n\n${snapshot.error}",
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                  child: Text("ยังไม่มีเมนูอาหารในระบบ",
                      style: TextStyle(color: Colors.grey)));
            }

            var products = snapshot.data!.docs;
            double totalPrice = 0;
            int totalItems = 0;

            for (var doc in products) {
              var data = doc.data() as Map<String, dynamic>;
              String docId = doc.id;
              double price = (data['price'] ?? 0).toDouble();

              if (cart.containsKey(docId)) {
                int qty = cart[docId]!;
                totalPrice += (price * qty);
                totalItems += qty;
              }
            }

            return Column(
              children: [
                if (widget.isMerchant)
                  Container(
                    width: double.infinity,
                    color: const Color(0xFF1D5A5D),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    alignment: Alignment.center,
                    child: const Text("เมนูอาหาร",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ),
                Expanded(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          var doc = products[index];
                          var data = doc.data() as Map<String, dynamic>;
                          String docId = doc.id;
                          String name = data['name'] ?? 'ไม่ระบุชื่อ';
                          double price = (data['price'] ?? 0).toDouble();

                          // 🟢 สถานะติดตามสต็อก (ยึดตามที่บันทึกในฐานข้อมูล)
                          bool isTracking = data['is_tracking'] ?? false;
                          int stock = data['stock'] ?? 0;

                          int qty = cart[docId] ?? 0;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
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
                            child: Row(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                      color: Colors.teal.shade50,
                                      borderRadius: BorderRadius.circular(12)),
                                  child: const Icon(Icons.fastfood,
                                      color: Color(0xFF1F7A83)),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(name,
                                          style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Text(
                                              "${price.toStringAsFixed(0)} บาท",
                                              style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Color(0xFF1F7A83),
                                                  fontWeight: FontWeight.bold)),

                                          // 🟢 ถ้าติดตามสต็อก ถึงจะโชว์ว่าเหลือเท่าไหร่
                                          if (isTracking) ...[
                                            const SizedBox(width: 8),
                                            Text("(เหลือ $stock)",
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color: stock > 0
                                                        ? Colors.grey
                                                        : Colors.red)),
                                          ]
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    _buildQtyButton(
                                        Icons.remove, () => _decrement(docId)),
                                    Container(
                                      width: 40,
                                      alignment: Alignment.center,
                                      child: Text(
                                        "$qty",
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    _buildQtyButton(
                                        Icons.add,
                                        () => _increment(
                                            docId, isTracking, stock),
                                        isAdd: true),
                                  ],
                                )
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                if (totalItems > 0)
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black12,
                              blurRadius: 10,
                              offset: Offset(0, -2))
                        ]),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 600),
                              child: Row(
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text("$totalItems รายการ",
                                          style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12)),
                                      Text("฿${totalPrice.toStringAsFixed(2)}",
                                          style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1D5A5D))),
                                    ],
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () => _placeOrder(products),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF1F7A83),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.shopping_cart_checkout,
                                              color: Colors.white),
                                          SizedBox(width: 8),
                                          Text(
                                            "สั่งอาหารที่เลือกทั้งหมด",
                                            style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          }),
    );
  }

  Widget _buildQtyButton(IconData icon, VoidCallback onTap,
      {bool isAdd = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isAdd ? const Color(0xFF1F7A83) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child:
            Icon(icon, size: 20, color: isAdd ? Colors.white : Colors.black87),
      ),
    );
  }
}

Future<String> _generateDailyOrderCode() async {
  DateTime now = DateTime.now();
  String todayDate = "${now.year}-${now.month}-${now.day}";

  DocumentReference counterRef =
      FirebaseFirestore.instance.collection('system').doc('order_counter');

  return await FirebaseFirestore.instance.runTransaction((transaction) async {
    DocumentSnapshot snapshot = await transaction.get(counterRef);

    int currentNumber = 1;

    if (snapshot.exists) {
      var data = snapshot.data() as Map<String, dynamic>;
      String? lastDate = data['date'];
      int? lastNumber = data['number'];

      if (lastDate == todayDate) {
        currentNumber = (lastNumber ?? 0) + 1;
      }
    }

    transaction.set(counterRef, {
      'date': todayDate,
      'number': currentNumber,
    });

    String formattedNumber = currentNumber.toString().padLeft(3, '0');
    return "TOY$formattedNumber";
  });
}
