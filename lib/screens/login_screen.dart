import 'package:flutter/material.dart';
import 'register_screen.dart';
import 'reset_password_screen.dart';
import 'home_screen.dart';
import 'role_selection_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback toggleTheme;

  const LoginScreen({Key? key, required this.toggleTheme}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isObscure = true;
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      final email = emailController.text.trim();
      final password = passwordController.text.trim();

      if (email.isEmpty || password.isEmpty) {
        _showMessage("⚠️ الرجاء إدخال البريد وكلمة المرور");
        return;
      }

      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      final user = userCredential.user;
      if (user == null) throw FirebaseAuthException(code: 'user-not-found');

      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = doc.data();
      if (data == null) throw FirebaseAuthException(code: 'no-user-data');

      if (data['role'] != 'trainee') {
        throw FirebaseAuthException(code: 'unauthorized-role');
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen(toggleTheme: widget.toggleTheme)),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'invalid-email':
          message = "البريد الإلكتروني غير صحيح";
          break;
        case 'user-not-found':
          message = "لا يوجد حساب مرتبط بهذا البريد";
          break;
        case 'wrong-password':
          message = "كلمة المرور غير صحيحة";
          break;
        case 'user-disabled':
          message = "تم تعطيل هذا الحساب من قبل الإدارة";
          break;
        case 'unauthorized-role':
          message = "❌ هذا الحساب ليس متدرب ولا يمكنه الدخول هنا";
          break;
        case 'no-user-data':
          message = "لم يتم العثور على بيانات الحساب";
          break;
        default:
          message = "❌ حدث خطأ غير متوقع. حاول مرة أخرى";
      }
      _showMessage(message);
    } catch (e) {
      _showMessage("❌ ${e.toString()}");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            _buildBackground(),
            _buildLoginForm(),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RoleSelectionScreen(toggleTheme: widget.toggleTheme),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 60),
          const Icon(Icons.lock_outline, size: 90, color: Colors.white),
          const SizedBox(height: 20),
          const Text("تسجيل الدخول", style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 40),
          _buildTextField(emailController, "البريد الإلكتروني", Icons.email, false),
          const SizedBox(height: 20),
          _buildTextField(passwordController, "كلمة المرور", Icons.lock, true),
          const SizedBox(height: 30),
          _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  onPressed: _login,
                  child: const Text("دخول", style: TextStyle(color: Color(0xFF0D47A1), fontSize: 18, fontWeight: FontWeight.bold)),
                ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => ResetPasswordScreen()));
            },
            child: const Text("هل نسيت كلمة المرور؟", style: TextStyle(color: Colors.white70)),
          ),
          const Divider(color: Colors.white70, thickness: 1, height: 40),
          TextButton(
            onPressed: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => RegisterScreen(toggleTheme: widget.toggleTheme)));
            },
            child: const Text("ليس لديك حساب؟ إنشاء حساب جديد", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, bool isPassword) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? _isObscure : false,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.2),
        prefixIcon: Icon(icon, color: Colors.white),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(_isObscure ? Icons.visibility : Icons.visibility_off, color: Colors.white),
                onPressed: () => setState(() => _isObscure = !_isObscure),
              )
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
      ),
    );
  }
}
