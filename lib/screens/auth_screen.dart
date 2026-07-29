import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final AuthService _auth = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool isLogin = true;
  String selectedRole = 'user'; // ค่าเริ่มต้นตอนสมัครคือเป็นลูกค้า

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F1), // สีพื้นหลัง
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

                // 2. หัวข้อ (เปลี่ยนอัตโนมัติตามสถานะ isLogin)
                Text(
                  isLogin ? 'เข้าสู่ระบบ' : 'สมัครสมาชิก',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 32),

                // 3. ช่องกรอก Email
                TextField(
                  controller: _emailController, // เชื่อมกับ Controller เดิม
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'อีเมล (Email)',
                    prefixIcon:
                        const Icon(Icons.email_outlined, color: Colors.grey),
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
                  controller: _passwordController, // เชื่อมกับ Controller เดิม
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

                // 5. ตัวเลือก Role (โชว์เฉพาะตอนสมัครสมาชิก !isLogin)
                if (!isLogin) ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Radio(
                        value: 'user',
                        groupValue: selectedRole,
                        activeColor: const Color(0xFF1F7A83), // สีเขียวธีมหลัก
                        onChanged: (val) =>
                            setState(() => selectedRole = val.toString()),
                      ),
                      const Text("ลูกค้า", style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 20),
                      Radio(
                        value: 'merchant',
                        groupValue: selectedRole,
                        activeColor: const Color(0xFF1F7A83),
                        onChanged: (val) =>
                            setState(() => selectedRole = val.toString()),
                      ),
                      const Text("แม่ค้า", style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ],

                const SizedBox(height: 24),

                // 6. ปุ่มหลัก (เข้าสู่ระบบ / สมัครสมาชิก)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      // ดึงฟังก์ชันมาจากโค้ดเก่า
                      var user = isLogin
                          ? await _auth.signIn(
                              _emailController.text, _passwordController.text)
                          : await _auth.signUp(_emailController.text,
                              _passwordController.text, selectedRole);

                      if (user == null) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      "เกิดข้อผิดพลาดในการล็อกอิน/สมัครสมาชิก")));
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

                // 7. ปุ่มสลับโหมด Login / Register
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

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Divider(),
                ),

                // 8. ปุ่ม Guest
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      var user = await _auth.signInGuest();
                      if (user == null) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      "เกิดข้อผิดพลาดในการเข้าสู่ระบบ Guest")));
                        }
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
