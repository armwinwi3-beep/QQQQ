import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthScreen extends StatefulWidget {
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
      appBar: AppBar(title: Text(isLogin ? "เข้าสู่ระบบ" : "สมัครสมาชิก")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
                controller: _emailController,
                decoration: InputDecoration(labelText: "Email")),
            TextField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: "Password"),
                obscureText: true),

            // ซ่อนตัวเลือก Role ถ้าเป็นการ Login
            if (!isLogin) ...[
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Radio(
                      value: 'user',
                      groupValue: selectedRole,
                      onChanged: (val) =>
                          setState(() => selectedRole = val.toString())),
                  Text("ลูกค้า"),
                  Radio(
                      value: 'merchant',
                      groupValue: selectedRole,
                      onChanged: (val) =>
                          setState(() => selectedRole = val.toString())),
                  Text("แม่ค้า"),
                ],
              ),
            ],

            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                var user = isLogin
                    ? await _auth.signIn(
                        _emailController.text, _passwordController.text)
                    : await _auth.signUp(
                        _emailController.text,
                        _passwordController.text,
                        selectedRole); // ส่ง Role ไปด้วย

                if (user == null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text("เกิดข้อผิดพลาดในการล็อกอิน/สมัครสมาชิก")));
                }
              },
              child: Text(isLogin ? "เข้าสู่ระบบ" : "สมัครสมาชิก"),
            ),
            TextButton(
              onPressed: () => setState(() => isLogin = !isLogin),
              child: Text(isLogin
                  ? "ยังไม่มีบัญชี? สมัครเลย"
                  : "มีบัญชีแล้ว? เข้าสู่ระบบ"),
            ),

            Divider(),

            // ปุ่ม Guest
            OutlinedButton.icon(
              icon: Icon(Icons.person_outline),
              label: Text("เข้าใช้งานโดยไม่สมัครสมาชิก (Guest)"),
              onPressed: () async {
                var user = await _auth.signInGuest();
                if (user == null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text("เกิดข้อผิดพลาดในการเข้าสู่ระบบ Guest")));
                }
              },
            )
          ],
        ),
      ),
    );
  }
}
