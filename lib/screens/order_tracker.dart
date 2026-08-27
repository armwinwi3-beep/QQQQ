import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:audioplayers/audioplayers.dart'; // 🟢 อย่าลืม Import audioplayers
import 'slip_preview_screen.dart';

class OrderTracker extends StatefulWidget {
  final String orderId; // รับ ID ของออเดอร์มาจากหน้าเมนู

  const OrderTracker({super.key, required this.orderId});

  @override
  State<OrderTracker> createState() => _OrderTrackerState();
}

class _OrderTrackerState extends State<OrderTracker> {
  String? _lastStatus; // เก็บสถานะก่อนหน้าเพื่อเอาไว้เทียบ
  final AudioPlayer _audioPlayer = AudioPlayer(); // ตัวเล่นเสียง

  @override
  void initState() {
    super.initState();
    _listenToOrderStatus(); // 🟢 เรียกใช้ฟังก์ชันดักจับสถานะตอนเปิดหน้าจอ
  }

  // ฟังก์ชันสำหรับดักจับการเปลี่ยนแปลงของ Firestore
  void _listenToOrderStatus() {
    FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.orderId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        var data = snapshot.data() as Map<String, dynamic>;
        String newStatus = data['status'] ?? 'pending';

        // 🟢 ถ้าสถานะเปลี่ยนไปจากเดิม (และไม่ใช่ตอนเปิดหน้าจอครั้งแรก) ให้แจ้งเตือน
        if (_lastStatus != null && _lastStatus != newStatus) {
          _showNotificationPopup(newStatus);
        }
        _lastStatus = newStatus; // อัปเดตสถานะล่าสุดเก็บไว้
      }
    });
  }

  // ฟังก์ชันแสดง Popup และเล่นเสียง
  void _showNotificationPopup(String status) async {
    String title = "";
    String message = "";
    IconData icon = Icons.info;
    Color color = Colors.blue;
    String audioFileName = ""; // 🟢 สร้างตัวแปรเก็บชื่อไฟล์เสียง

    // 1. เช็กสถานะเพื่อกำหนดข้อความ หน้าตา Popup และไฟล์เสียง
    if (status == 'cooking') {
      title = "ร้านกำลังทำอาหาร!";
      message = "ออเดอร์ของคุณกำลังถูกเตรียม โปรดรอสักครู่";
      icon = Icons.soup_kitchen;
      color = Colors.orange;
      audioFileName = "sounds/namo.mp3"; // 🎵 เสียงเมื่อเริ่มทำอาหาร
    } else if (status == 'completed') {
      title = "อาหารเสร็จแล้ว!";
      message = "ออเดอร์ของคุณพร้อมแล้ว มารับได้เลยครับ";
      icon = Icons.check_circle;
      color = Colors.green;
      audioFileName = "sounds/malaew.mp3"; // 🎵 เสียงเมื่อทำอาหารเสร็จ
    } else if (status == 'cancelled') {
      title = "ออเดอร์ถูกยกเลิก";
      message = "ขออภัย ออเดอร์ของคุณถูกยกเลิกระบบ";
      icon = Icons.cancel;
      color = Colors.red;
    } else {
      return; // ถ้าเป็นสถานะอื่นให้ข้ามไป
    }

    // 2. สั่งเล่นเสียง
    if (audioFileName.isNotEmpty) {
      await _audioPlayer.play(AssetSource(audioFileName));
    }

    if (!mounted) return;

    // 3. แสดง Popup หน้าจอ
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 10),
            Text(title,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 16)),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: color),
            onPressed: () {
              _audioPlayer
                  .stop(); // 🟢 สั่งให้หยุดเสียงทันทีถ้าลูกค้ากดปุ่มตกลง
              Navigator.pop(context);
            },
            child: const Text("ตกลง", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose(); // คืนหน่วยความจำตัวเล่นเสียง
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F1), // สีพื้นหลัง
      appBar: AppBar(
        backgroundColor: const Color(0xFF1D5A5D), // สีเขียวเข้ม
        title: const Text(
          'ติดตามสถานะอาหาร',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(
            color: Colors.white), // เปลี่ยนสีลูกศรย้อนกลับเป็นสีขาว
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(maxWidth: 500), // บังคับความกว้างบนเว็บ
          child: StreamBuilder<DocumentSnapshot>(
            // 🔴 ดึงข้อมูลออเดอร์นี้จาก Firebase แบบ Real-time
            stream: FirebaseFirestore.instance
                .collection('orders')
                .doc(widget.orderId) // 🟢 เปลี่ยนเป็น widget.orderId
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(
                    child: Text("เกิดข้อผิดพลาดในการโหลดข้อมูล"));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF1F7A83)));
              }
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const Center(child: Text("ไม่พบข้อมูลออเดอร์"));
              }

              // ดึงข้อมูลออกมาใช้งาน
              var data = snapshot.data!.data() as Map<String, dynamic>;
              String status = data['status'] ?? 'pending';
              String orderCode = data['order_code'] ?? 'ไม่มีรหัส';

              // ตัวแปรสำหรับปรับเปลี่ยน UI ตามสถานะ
              Color statusColor;
              IconData statusIcon;
              String statusText;
              double progress; // ความคืบหน้าของแถบ (0.0 ถึง 1.0)

              // เช็คสถานะเพื่อเปลี่ยนสีและข้อความ
              switch (status.toLowerCase()) {
                case 'cooking':
                  statusColor = Colors.blue;
                  statusIcon = Icons.soup_kitchen;
                  statusText = 'กำลังเตรียมอาหาร';
                  progress = 0.6;
                  break;
                case 'completed':
                  statusColor = Colors.green;
                  statusIcon = Icons.check_circle;
                  statusText = 'เสร็จเรียบร้อยแล้ว!';
                  progress = 1.0;
                  break;
                case 'cancelled':
                  statusColor = Colors.red;
                  statusIcon = Icons.cancel;
                  statusText = 'ออเดอร์ถูกยกเลิก';
                  progress = 0.0;
                  break;
                case 'pending':
                default:
                  statusColor = Colors.orange;
                  statusIcon = Icons.access_time_filled;
                  statusText = 'รอดำเนินการ';
                  progress = 0.3;
                  break;
              }

              return Padding(
                padding: const EdgeInsets.all(24.0),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 15,
                        offset: Offset(0, 8),
                      )
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("หมายเลขคิวของคุณ",
                          style: TextStyle(
                              fontSize: 16, color: Colors.grey.shade600)),
                      const SizedBox(height: 8),
                      // โชว์รหัสคิวตัวใหญ่ๆ
                      Text(
                        orderCode,
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F7A83),
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // ไอคอนสถานะ (มีพื้นหลังวงกลมสีจางๆ)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(statusIcon, size: 80, color: statusColor),
                      ),
                      const SizedBox(height: 24),

                      // ข้อความสถานะภาษาไทย
                      Text(
                        statusText,
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: statusColor),
                      ),
                      const SizedBox(height: 40),

                      // แถบ Progress Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 12,
                          backgroundColor: Colors.grey.shade200,
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(height: 28),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            final itemsRaw = data['items'];

                            final List<Map<String, dynamic>> items =
                                itemsRaw is List
                                    ? itemsRaw
                                        .map(
                                          (item) => Map<String, dynamic>.from(
                                              item as Map),
                                        )
                                        .toList()
                                    : [];

                            final double totalPrice =
                                (data['total_price'] ?? 0).toDouble();

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SlipPreviewScreen(
                                  queueNumber: orderCode,
                                  items: items,
                                  totalPrice: totalPrice,
                                  orderId: widget
                                      .orderId, // 🟢 เปลี่ยนเป็น widget.orderId
                                ),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.receipt_long,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'ดูสลิป / พรีวิวใบเสร็จ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1D5A5D),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                      Text(
                        "สถานะในระบบ: $status",
                        style: TextStyle(
                            color: Colors.grey.shade400, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
