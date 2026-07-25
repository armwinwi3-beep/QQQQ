import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'order_tracker.dart';
import 'order_history_screen.dart';

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
    String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
    String newOrderCode = await _generateDailyOrderCode();
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
      'order_code': newOrderCode,
      'user_id': currentUserId,
      'items': orderList,
      'total_price': totalPrice,
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
      appBar: AppBar(
        title: Text("เมนูอาหาร"),
        actions: [
          // เพิ่มปุ่ม Logout ตรงนี้ครับ
          IconButton(
            icon: Icon(Icons.history),
            tooltip: 'ประวัติการสั่งซื้อ',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => OrderHistoryScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.logout),
            tooltip: 'ออกจากระบบ',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              // พอคำสั่งนี้ทำงานปุ๊บ ระบบจะดีดกลับไปหน้า Login อัตโนมัติ
            },
          ),
        ],
      ),
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

// ฟังก์ชันสำหรับรันเลขคิวแบบ Transaction
Future<String> _generateDailyOrderCode() async {
  // สร้างตัวแปรวันที่ของวันนี้ (เช่น 2026-7-25)
  DateTime now = DateTime.now();
  String todayDate = "${now.year}-${now.month}-${now.day}";

  // ชี้ไปยัง Document ที่ใช้เก็บตัวนับ (ตั้งชื่อว่า order_counter)
  DocumentReference counterRef =
      FirebaseFirestore.instance.collection('system').doc('order_counter');

  return await FirebaseFirestore.instance.runTransaction((transaction) async {
    DocumentSnapshot snapshot = await transaction.get(counterRef);

    int currentNumber = 1; // เริ่มต้นที่ 1

    if (snapshot.exists) {
      var data = snapshot.data() as Map<String, dynamic>;
      String? lastDate = data['date'];
      int? lastNumber = data['number'];

      // เช็คว่า วันที่ที่บันทึกล่าสุด คือ "วันนี้" หรือไม่?
      if (lastDate == todayDate) {
        // ถ้าเป็นวันเดียวกัน ให้บวกเลขเพิ่มไปอีก 1
        currentNumber = (lastNumber ?? 0) + 1;
      } else {
        // ถ้าเป็นวันใหม่ (เที่ยงคืนผ่านไปแล้ว) เลขจะถูก Reset กลับเป็น 1 อัตโนมัติ
      }
    }

    // อัปเดตข้อมูลวันที่และเลขล่าสุดกลับเข้า Firebase
    transaction.set(counterRef, {
      'date': todayDate,
      'number': currentNumber,
    });

    // นำเลขมาจัดรูปแบบ ใส่ TOY และเติมเลข 0 ด้านหน้าให้ครบ 3 หลัก (001 - 999)
    String formattedNumber = currentNumber.toString().padLeft(3, '0');
    return "TOY$formattedNumber";
  });
}
