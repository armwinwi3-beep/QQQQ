import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'role_check_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final AuthService _auth = AuthService();
  final _usernameController =
      TextEditingController(); // 🟢 ใช้เป็น Username แทน
  final _passwordController = TextEditingController();
  bool _isLoading = false; // 🟢 เพิ่มตัวแปรสำหรับคุมสถานะกำลังโหลด
  bool isLogin = true;

  // 🟢 ฟังก์ชันล็อคอินด้วย Username (แยกระบบแอดมิน + เคลียร์เซสชันป้องกันค้าง)
  Future<void> _loginWithUsername() async {
    String username = _usernameController.text.trim().toLowerCase();
    String password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("กรุณากรอก Username และรหัสผ่าน")));
      }
      return;
    }

    setState(() {
      _isLoading = true; // เริ่มหมุน
    });

    try {
      String loginEmail =
          (username == 'admin') ? "admin@btadapp.com" : "$username@btadapp.com";

      // สั่งล็อกอินตรงๆ ทันที ไม่เรียก signOut() ซ้ำซ้อนเพื่อกันค้าง
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: loginEmail, password: password);
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const RoleCheckScreen()),
          (Route<dynamic> route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      // <--- บรรทัดที่ 45 ในรูปของคุณคือตรงนี้ครับ
      String message = "เข้าสู่ระบบไม่สำเร็จ";
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("เกิดข้อผิดพลาด: $e"),
            backgroundColor: Colors.orange));
      }
    } finally {
      // บล็อกนี้บังคับทำงานเสมอ ปุ่มจะหายค้างทันทีไม่ว่าจะสำเร็จหรือพัง
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
          const SnackBar(
              content: Text("เกิดข้อผิดพลาดในการล็อกอินด้วย Google")),
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
                    prefixIcon:
                        const Icon(Icons.person_outline, color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Color(0xFF1F7A83), width: 2),
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
                    prefixIcon:
                        const Icon(Icons.lock_outline, color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Color(0xFF1F7A83), width: 2),
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
                    // 🟢 ถ้ากำลังโหลดอยู่ ให้กดซ้ำไม่ได้ (ป้องกันปุ่มเบิิล)
                    onPressed: _isLoading
                        ? null
                        : () async {
                            if (isLogin) {
                              await _loginWithUsername();
                            } else {
                              // โหมดสมัครสมาชิกเดิมของคุณ
                              String fakeEmail =
                                  "${_usernameController.text.trim().toLowerCase()}@btadapp.com";
                              var user = await _auth.signUp(fakeEmail,
                                  _passwordController.text, 'customer');

                              if (user == null && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            "เกิดข้อผิดพลาดในการสมัครสมาชิก")));
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
                    // 🟢 ถ้ากำลังโหลดอยู่ ให้โชว์วงกลมหมุนๆ แทนตัวหนังสือ
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
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
                        child:
                            Text("หรือ", style: TextStyle(color: Colors.grey)),
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
                    icon: const Icon(Icons.g_mobiledata,
                        size: 32, color: Colors.red),
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
                            const SnackBar(
                                content: Text(
                                    "เกิดข้อผิดพลาดในการเข้าสู่ระบบ Guest")));
                      }
                    },
                    icon:
                        const Icon(Icons.person_outline, color: Colors.black54),
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
