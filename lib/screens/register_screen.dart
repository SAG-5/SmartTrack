import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'home_screen.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  final VoidCallback toggleTheme;

  const RegisterScreen({Key? key, required this.toggleTheme}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController academicNumberController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController majorController = TextEditingController();

  bool _isObscure = true;
  bool _isConfirmObscure = true;
  bool _isAgreed = false;
  bool _isLoading = false;

  bool _isValidEmail(String email) {
    return RegExp(r"^[^\s@]+@[^\s@]+\.[^\s@]+$").hasMatch(email);
  }

  bool _isValidPhone(String phone) {
    return RegExp(r"^05\d{8}$").hasMatch(phone);
  }

  bool _isValidAcademicNumber(String number) {
    return RegExp(r"^\d+$").hasMatch(number);
  }

  void _validateAndRegister() async {
    final email = emailController.text.trim();
    final phone = phoneController.text.trim();
    final academicNumber = academicNumberController.text.trim();

    if (nameController.text.isEmpty ||
        email.isEmpty ||
        academicNumber.isEmpty ||
        phone.isEmpty ||
        majorController.text.isEmpty) {
      _showError("⚠️ الرجاء تعبئة جميع الحقول!");
      return;
    }

    if (!_isValidEmail(email)) {
      _showError("❌ البريد الإلكتروني غير صحيح!");
      return;
    }

    if (!_isValidPhone(phone)) {
      _showError("❌ رقم الجوال يجب أن يبدأ بـ 05 ويتكون من 10 أرقام!");
      return;
    }

    if (!_isValidAcademicNumber(academicNumber)) {
      _showError("❌ الرقم التدريبي يجب أن يحتوي على أرقام فقط!");
      return;
    }

    if (passwordController.text.length <1 ) {
      _showError("⚠️ كلمة المرور يجب أن تكون 8 أحرف على الأقل!");
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      _showError("⚠️ كلمتا المرور غير متطابقتين!");
      return;
    }

    if (!_isAgreed) {
      _showError("⚠️ يجب الموافقة على الشروط والأحكام!");
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: passwordController.text.trim(),
      );

      await userCredential.user!.updateDisplayName(nameController.text.trim());

      await FirebaseFirestore.instance.collection("users").doc(userCredential.user!.uid).set({
        "uid": userCredential.user!.uid,
        "fullName": nameController.text.trim(),
        "email": email,
        "academicNumber": academicNumber,
        "phone": phone,
        "major": majorController.text.trim(),
        "role": "trainee",
        "faceIdRegistered": false,
        "createdAt": Timestamp.now(),
        "canEditTrainingOrg": true,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("✅ تم إنشاء الحساب بنجاح!")));
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen(toggleTheme: widget.toggleTheme)));
    } catch (e) {
      _showError("❌ ${e.toString()}");
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void _showError(String message) {
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
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 60),
                    const Icon(Icons.person_add, size: 80, color: Colors.white),
                    const SizedBox(height: 10),
                    const Text("إنشاء حساب خريج", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 30),
                    _buildTextField(nameController, "الاسم الكامل", Icons.person),
                    const SizedBox(height: 15),
                    _buildTextField(emailController, "البريد الإلكتروني", Icons.email),
                    const SizedBox(height: 15),
                    _buildTextField(academicNumberController, "الرقم التدريبي", Icons.confirmation_number),
                    const SizedBox(height: 15),
                    _buildTextField(phoneController, "رقم الجوال", Icons.phone),
                    const SizedBox(height: 15),
                    _buildTextField(majorController, "التخصص", Icons.school),
                    const SizedBox(height: 15),
                    _buildTextField(passwordController, "كلمة المرور", Icons.lock, isPassword: true),
                    const SizedBox(height: 15),
                    _buildTextField(confirmPasswordController, "تأكيد كلمة المرور", Icons.lock, isConfirmPassword: true),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Checkbox(
                          value: _isAgreed,
                          onChanged: (value) => setState(() => _isAgreed = value!),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              const Text("أوافق على ", style: TextStyle(color: Colors.white)),
                              GestureDetector(
                                onTap: _showTermsDialog,
                                child: const Text("الشروط والأحكام", style: TextStyle(color: Colors.yellow, decoration: TextDecoration.underline)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : ElevatedButton(
                            onPressed: _validateAndRegister,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              minimumSize: Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            ),
                            child: const Text("إنشاء الحساب", style: TextStyle(color: Color(0xFF1565C0), fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                    const SizedBox(height: 15),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginScreen(toggleTheme: widget.toggleTheme)));
                      },
                      child: const Text("لديك حساب؟ تسجيل الدخول", style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon,
      {bool isPassword = false, bool isConfirmPassword = false}) {
    return TextField(
      controller: controller,
      keyboardType: (hint.contains("رقم") || hint.contains("التدريبي")) ? TextInputType.number : TextInputType.text,
      obscureText: isPassword ? _isObscure : isConfirmPassword ? _isConfirmObscure : false,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.2),
        prefixIcon: Icon(icon, color: Colors.white),
        suffixIcon: isPassword || isConfirmPassword
            ? IconButton(
                icon: Icon((isPassword ? _isObscure : _isConfirmObscure) ? Icons.visibility : Icons.visibility_off, color: Colors.white),
                onPressed: () {
                  setState(() {
                    if (isPassword) {
                      _isObscure = !_isObscure;
                    } else {
                      _isConfirmObscure = !_isConfirmObscure;
                    }
                  });
                },
              )
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
      ),
    );
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("الشروط والأحكام"),
        content: const SingleChildScrollView(
          child: Text(
            "1. استخدام التطبيق يقتصر على أغراض التدريب فقط.\n"
            "2. يجب تقديم معلومات دقيقة أثناء التسجيل.\n"
            "3. يُمنع مشاركة الحساب مع الآخرين.\n"
            "4. قد يتم إيقاف الحساب في حال مخالفة السياسات.\n"
            "5. يتم جمع بيانات الوجه والموقع لأغراض الحضور فقط.\n\n"
            "باستخدامك للتطبيق فإنك توافق على هذه الشروط.",
            textDirection: TextDirection.rtl,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("موافق")),
        ],
      ),
    );
  }
}