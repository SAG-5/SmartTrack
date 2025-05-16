import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ✅ متابعة حالة المستخدم (معرفة ما إذا كان مسجل دخول أم لا)
  Stream<User?> get userChanges => _auth.authStateChanges();

  // ✅ تسجيل الدخول باستخدام البريد الإلكتروني وكلمة المرور
  Future<User?> login(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return userCredential.user;
    } catch (e) {
      print("❌ خطأ في تسجيل الدخول: ${e.toString()}");
      return null;
    }
  }

  // ✅ إنشاء حساب جديد
  Future<User?> register(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      return userCredential.user;
    } catch (e) {
      print("❌ خطأ في إنشاء الحساب: ${e.toString()}");
      return null;
    }
  }

  // ✅ تسجيل خروج المستخدم
  Future<void> logout() async {
    await _auth.signOut();
  }

  // ✅ استرجاع بيانات المستخدم الحالي
  User? getCurrentUser() {
    return _auth.currentUser;
  }
}
