import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart'; 
import '../services/auth_service.dart';
import 'admin_dashboard_screen.dart'; // 🟢 เพิ่ม import หน้า Admin
import 'main_dashboard_screen.dart'; // 🟢 เพิ่ม import หน้า Dashboard แม่ค้า
import 'store_selection_screen.dart';
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final AuthService _auth = AuthService();
  final _usernameController = TextEditingController(); // 🟢 ใช้เป็น Username แทน
  final _passwordController = TextEditingController();
  bool isLogin = true;

  // 🟢 ฟังก์ชันล็อคอินด้วย Username (แยกระบบแอดมิน)
  Future<void> _loginWithUsername() async {
    String username = _usernameController.text.trim().toLowerCase();
    String password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("กรุณากรอก Username และรหัสผ่าน")));
      return;
    }

    try {
      // 1. เช็คว่าเป็นแอดมินหรือแม่ค้าทั่วไป
      String loginEmail = "";
      if (username == 'admin') {
        loginEmail = "admin@btadapp.com"; 
      } else {
        loginEmail = "$username@btadapp.com"; 
      }

      // 2. ให้ Firebase ล็อคอิน และเก็บผลลัพธ์ไว้
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: loginEmail, 
        password: password
      );
      
      // 3. ดึงข้อมูลสิทธิ์ (Role) ให้เสร็จเรียบร้อยก่อน
      String role = 'customer'; 
      if (username == 'admin') {
        role = 'admin';
      } else {
        // นำ uid ที่เพิ่งล็อกอินสำเร็จมาค้นหาใน Firestore ทันที
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid) 
            .get();
        
        if (userDoc.exists) {
          var data = userDoc.data() as Map<String, dynamic>;
          role = data['role'] ?? 'customer';
        }
      }

      // 4. แยกว่าจะพาไปหน้าไหน 
      if (context.mounted) {
        if (role == 'admin') {
          // ไปหน้าแอดมิน (สร้างร้านค้า)
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AdminDashboardScreen()));
        } else if (role == 'merchant') {
          // ไปหน้า Dashboard ของแม่ค้า
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainDashboardScreen()));
        } else {
          // 🟢 เพิ่มบล็อกนี้ สำหรับพาลูกค้าไปหน้าเลือกร้านค้า
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const StoreSelectionScreen()));
        }
      }

    } on FirebaseAuthException catch (e) {
      String message = "เข้าสู่ระบบไม่สำเร็จ";
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        message = "Username หรือรหัสผ่านไม่ถูกต้อง";
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
    } catch (e) {
      // 🟢 เพิ่มตัวนี้ เพื่อดักจับปัญหาเวลา Firebase มีปัญหา จะได้รู้ว่าเกิดจากอะไร
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("เกิดข้อผิดพลาด: $e"), backgroundColor: Colors.orange));
    }
  }
  
  // 🟢 ฟังก์ชันสำหรับเข้าสู่ระบบด้วย Google (ลูกค้าทั่วไป)
  Future<void> _signInWithGoogle() async {
    try {
      GoogleAuthProvider googleProvider = GoogleAuthProvider();
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithPopup(googleProvider);

      User? user = userCredential.user;
      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (!userDoc.exists) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
            'email': user.email,
            'role': 'customer', 
            'created_at': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      debugPrint("Google Login Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("เกิดข้อผิดพลาดในการล็อกอินด้วย Google")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F1),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(32.0),
            margin: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 20,
                  offset: Offset(0, 10),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. โลโก้
                const Icon(
                  Icons.storefront_rounded,
                  size: 80,
                  color: Color(0xFF1F7A83),
                ),
                const SizedBox(height: 16),

                // 2. หัวข้อ
                Text(
                  isLogin ? 'เข้าสู่ระบบ' : 'สมัครสมาชิก',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 32),

                // 3. ช่องกรอก Username (แก้จาก Email)
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'ชื่อผู้ใช้ (Username)',
                    prefixIcon: const Icon(Icons.person_outline, color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF1F7A83), width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 16),

                // 4. ช่องกรอก Password
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'รหัสผ่าน (Password)',
                    prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF1F7A83), width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 24),

                // 5. ปุ่มหลัก (เข้าสู่ระบบ / สมัครสมาชิก)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (isLogin) {
                        // 🟢 ถ้าเป็นโหมดล็อกอิน เรียกใช้ฟังก์ชันที่เช็คแอดมิน
                        await _loginWithUsername();
                      } else {
                        // 🟢 ถ้าเป็นโหมดสมัครสมาชิก (ลูกค้าทั่วไป) ให้แปลงเป็นอีเมลจำลอง
                        String fakeEmail = "${_usernameController.text.trim().toLowerCase()}@btadapp.com";
                        var user = await _auth.signUp(fakeEmail, _passwordController.text, 'customer');

                        if (user == null && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("เกิดข้อผิดพลาดในการสมัครสมาชิก")));
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1F7A83),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      isLogin ? "เข้าสู่ระบบ" : "สมัครสมาชิก",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // 6. ปุ่มสลับโหมด Login / Register
                TextButton(
                  onPressed: () => setState(() => isLogin = !isLogin),
                  child: Text(
                    isLogin
                        ? "ยังไม่มีบัญชี? สมัครเลย"
                        : "มีบัญชีแล้ว? เข้าสู่ระบบ",
                    style: const TextStyle(
                        color: Color(0xFF1F7A83), fontWeight: FontWeight.bold),
                  ),
                ),

                // 7. เส้นคั่น "หรือ"
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text("หรือ", style: TextStyle(color: Colors.grey)),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                ),

                // 8. ปุ่ม Google Login
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _signInWithGoogle,
                    icon: const Icon(Icons.g_mobiledata, size: 32, color: Colors.red),
                    label: const Text(
                      'เข้าสู่ระบบด้วย Google',
                      style: TextStyle(color: Colors.black87, fontSize: 15),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 9. ปุ่ม Guest
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      var user = await _auth.signInGuest();
                      if (user == null && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("เกิดข้อผิดพลาดในการเข้าสู่ระบบ Guest")));
                      }
                    },
                    icon: const Icon(Icons.person_outline, color: Colors.black54),
                    label: const Text(
                      'เข้าใช้งานโดยไม่สมัครสมาชิก (Guest)',
                      style: TextStyle(color: Colors.black87),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}