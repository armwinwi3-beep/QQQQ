import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'order_tracker.dart';
import 'order_history_screen.dart';

class MenuScreen extends StatefulWidget {
  @override
  _MenuScreenState createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  // 1. ข้อมูลเมนู
  final List<Map<String, dynamic>> menuItems = [
    {'name': 'ปูอัด', 'price': 50},
    {'name': 'ไก่ป๊อป', 'price': 45},
    {'name': 'ลูกชิ้นหมู', 'price': 55},
    {'name': 'ลูกชิ้นปลา', 'price': 40},
    {'name': 'ลูกชิ้นเนื้อ', 'price': 40},
    {'name': 'ไส้กรอกชีส', 'price': 45},
    {'name': 'ไส้กรอกหนังกรอบ', 'price': 50},
    {'name': 'หมูพันสาหร่าย', 'price': 80},
    {'name': 'หมูทอด', 'price': 60},
    {'name': 'ปลานีโม่', 'price': 25},
  ];

  // 2. เก็บจำนวนที่เลือกไว้ในตะกร้า
  Map<String, int> cart = {};

  // 3. ฟังก์ชันส่ง Order
  void _placeOrder() async {
    double totalPrice = 0;
    List<Map<String, dynamic>> orderList = [];
    String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
    String newOrderCode = await _generateDailyOrderCode();

    cart.forEach((name, qty) {
      if (qty > 0) {
        var item = menuItems.firstWhere((i) => i['name'] == name);
        totalPrice += (item['price'] * qty);
        orderList.add({'name': name, 'qty': qty, 'price': item['price']});
      }
    });

    if (orderList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("กรุณาเลือกอาหารอย่างน้อย 1 รายการ")));
      return;
    }

    DocumentReference docRef =
        await FirebaseFirestore.instance.collection('orders').add({
      'order_code': newOrderCode,
      'user_id': currentUserId,
      'items': orderList,
      'total_price': totalPrice,
      'status': 'pending',
      'created_at': FieldValue.serverTimestamp(),
    });

    // ล้างตะกร้าหลังสั่งเสร็จ
    setState(() {
      cart.clear();
    });

    if (context.mounted) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => OrderTracker(orderId: docRef.id)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1D5A5D),
        title: const Text(
          "เมนูอาหาร",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                MaterialPageRoute(builder: (context) => OrderHistoryScreen()),
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
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView.builder(
            padding:
                const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 20),
            itemCount: menuItems.length,
            itemBuilder: (context, index) {
              var item = menuItems[index];
              String itemName = item['name'];
              int itemPrice = item['price'];
              int qty = cart[itemName] ?? 0;

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
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child:
                          const Icon(Icons.fastfood, color: Color(0xFF1F7A83)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(itemName,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text("$itemPrice บาท",
                              style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF1F7A83),
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        _buildQtyButton(Icons.remove, () {
                          setState(() {
                            if (qty > 0) cart[itemName] = qty - 1;
                          });
                        }),
                        Container(
                          width: 40,
                          alignment: Alignment.center,
                          child: Text("$qty",
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                        _buildQtyButton(Icons.add, () {
                          setState(() {
                            cart[itemName] = qty + 1;
                          });
                        }, isAdd: true),
                      ],
                    )
                  ],
                ),
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: Container(
        width: double.infinity,
        decoration: const BoxDecoration(color: Colors.white, boxShadow: [
          BoxShadow(
              color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))
        ]),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _placeOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1F7A83),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
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
                ),
              ],
            ),
          ),
        ),
      ),
    ); // ปิด Scaffold ที่หายไป
  } // ปิด Widget build ที่หายไป

  // Widget ตัวช่วยสำหรับสร้างปุ่ม + และ -
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
} // ปิดคลาส _MenuScreenState

// ฟังก์ชันสำหรับรันเลขคิวแบบ Transaction (อยู่นอกคลาสตามปกติ)
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
