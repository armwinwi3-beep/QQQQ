import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'auth_screen.dart';
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final TextEditingController _storeNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  // 🟢 ฟังก์ชันสร้าง User ให้แม่ค้า (ด้วย Username)
  Future<void> _createMerchantUser() async {
    if (_storeNameController.text.isEmpty || _usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("กรุณากรอกข้อมูลให้ครบถ้วน"), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. แปลง Username ให้กลายเป็น Email จำลอง เพื่อหลอก Firebase
      String username = _usernameController.text.trim().toLowerCase();
      String fakeEmail = "$username@btadapp.com"; // เติมโดเมนจำลองด้านหลัง
      String password = _passwordController.text.trim();

      // 2. สร้าง User ใน Firebase Auth 
      // (ใช้เทคนิค FirebaseApp ตัวที่สอง เพื่อไม่ให้แอดมินโดนเด้งออกจากระบบเมื่อสร้าง User ใหม่เสร็จ)
      FirebaseApp app = await Firebase.initializeApp(name: 'Secondary', options: Firebase.app().options);
      UserCredential userCredential = await FirebaseAuth.instanceFor(app: app).createUserWithEmailAndPassword(
        email: fakeEmail,
        password: password,
      );

      // 3. บันทึกข้อมูลร้านค้าลง Firestore (เอาไว้ดึงไปแสดงหน้าร้าน)
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'store_name': _storeNameController.text.trim(),
        'username': username,
        'role': 'merchant', // กำหนดสิทธิ์ให้เป็นแม่ค้า
        'created_at': FieldValue.serverTimestamp(),
      });

      // ลบ App ตัวที่สองทิ้งเมื่อใช้งานเสร็จ
      await app.delete();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("สร้างบัญชีร้านค้าสำเร็จ!"), backgroundColor: Colors.green));
        _storeNameController.clear();
        _usernameController.clear();
        _passwordController.clear();
      }
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        String message = "เกิดข้อผิดพลาด";
        if (e.code == 'email-already-in-use') message = "Username นี้มีคนใช้แล้ว กรุณาเปลี่ยนใหม่";
        else if (e.code == 'weak-password') message = "รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร";
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1D5A5D),
        title: const Text("ระบบจัดการแอดมิน", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        // 🟢 เพิ่มปุ่ม Logout ตรงนี้
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'ออกจากระบบ',
            onPressed: () async {
              // 1. สั่งให้ Firebase ออกจากระบบ
              await FirebaseAuth.instance.signOut();
              
              // 2. เด้งกลับไปหน้าเข้าสู่ระบบ
              if (context.mounted) {
                Navigator.pushReplacement(
                  context, 
                  MaterialPageRoute(builder: (context) => const AuthScreen())
                );
              }
            },
          )
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.storefront, size: 60, color: Color(0xFF1D5A5D)),
                const SizedBox(height: 16),
                const Text("เพิ่มบัญชีร้านค้าใหม่", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1D5A5D))),
                const SizedBox(height: 32),
                
                // ฟิลด์กรอกข้อมูล
                _buildTextField("ชื่อร้านค้า", Icons.store, _storeNameController),
                const SizedBox(height: 16),
                _buildTextField("Username (ใช้ตอนล็อกอิน)", Icons.person, _usernameController),
                const SizedBox(height: 16),
                _buildTextField("รหัสผ่าน", Icons.lock, _passwordController, isPassword: true),
                
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _createMerchantUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1D5A5D),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading 
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text("สร้างบัญชี", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String hint, IconData icon, TextEditingController controller, {bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.grey),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1D5A5D))),
      ),
    );
  }
}