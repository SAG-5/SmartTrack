import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class FaceRegistrationScreen extends StatefulWidget {
  @override
  _FaceRegistrationScreenState createState() => _FaceRegistrationScreenState();
}

class _FaceRegistrationScreenState extends State<FaceRegistrationScreen> {
  File? _image;
  final ImagePicker _picker = ImagePicker();

  final String endpoint = "https://smarttrack-face.cognitiveservices.azure.com/";
  final String subscriptionKey = "CV9aKo4XrMZ4Yqfn7EBXzly3cwG0ydw8xzAdR5mD8fsB0stuGdXUJQQJ99BDACF24PCXJ3w3AAAKACOG2nVe";

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      await _detectFace(File(pickedFile.path));
    }
  }

  Future<void> _detectFace(File imageFile) async {
    final bytes = await imageFile.readAsBytes();

    final response = await http.post(
      Uri.parse("${endpoint}face/v1.0/detect"),
      headers: {
        "Content-Type": "application/octet-stream",
        "Ocp-Apim-Subscription-Key": subscriptionKey,
      },
      body: bytes,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data.isNotEmpty) {
        print("✅ وجه تم التعرف عليه!");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ وجه تم تسجيله بنجاح')));
      } else {
        print("⚠️ لم يتم العثور على وجه!");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('⚠️ لم يتم العثور على وجه!')));
      }
    } else {
      print("❌ خطأ في الاتصال: ${response.body}");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ خطأ في الاتصال!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('تسجيل الوجه'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _image != null
                ? Image.file(_image!, height: 300)
                : Text("اضغط زر الكاميرا لالتقاط صورة"),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: Icon(Icons.camera_alt),
              label: Text('التقاط صورة للوجه'),
            ),
          ],
        ),
      ),
    );
  }
}
