import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'order_tracker.dart';

class MenuScreen extends StatefulWidget {
  // เปลี่ยนเป็น StatefulWidget
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

  // 3. ฟังก์ชัน Popup เลือกจำนวน
  void _showQuantityDialog(BuildContext context, Map<String, dynamic> item) {
    int tempQty = cart[item['name']] ?? 0;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text("เลือกจำนวน: ${item['name']}"),
              content: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                      icon: Icon(Icons.remove),
                      onPressed: () => setDialogState(() {
                            if (tempQty > 0) tempQty--;
                          })),
                  Text("$tempQty", style: TextStyle(fontSize: 20)),
                  IconButton(
                      icon: Icon(Icons.add),
                      onPressed: () => setDialogState(() => tempQty++)),
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("ยกเลิก")),
                ElevatedButton(
                  onPressed: () {
                    setState(
                        () => cart[item['name']] = tempQty); // อัปเดตตะกร้าหลัก
                    Navigator.pop(context);
                  },
                  child: Text("ตกลง"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 4. ฟังก์ชันส่ง Order
  void _placeOrder() async {
    double totalPrice = 0;
    List<Map<String, dynamic>> orderList = [];

    cart.forEach((name, qty) {
      if (qty > 0) {
        var item = menuItems.firstWhere((i) => i['name'] == name);
        totalPrice += (item['price'] * qty);
        orderList.add({'name': name, 'qty': qty, 'price': item['price']});
      }
    });

    if (orderList.isEmpty) return;

    DocumentReference docRef =
        await FirebaseFirestore.instance.collection('orders').add({
      'items': orderList,
      'total_price': totalPrice,
      'user_id': FirebaseAuth.instance.currentUser?.uid,
      'status': 'pending',
      'created_at': FieldValue.serverTimestamp(),
    });

    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => OrderTracker(orderId: docRef.id)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("เมนูอาหาร")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                var item = menuItems[index];
                return ListTile(
                  title: Text(item['name']),
                  subtitle: Text("${item['price']} บาท"),
                  trailing: Text("เลือก: ${cart[item['name']] ?? 0}"),
                  onTap: () => _showQuantityDialog(context, item),
                );
              },
            ),
          ),
          ElevatedButton(
            onPressed: _placeOrder,
            child: Text("สั่งอาหารที่เลือกทั้งหมด"),
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }
}
