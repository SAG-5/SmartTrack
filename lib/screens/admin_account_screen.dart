import 'package:flutter/material.dart';

class AdminAccountScreen extends StatefulWidget {
  @override
  _AdminAccountScreenState createState() => _AdminAccountScreenState();
}

class _AdminAccountScreenState extends State<AdminAccountScreen> {
  TextEditingController _nameController = TextEditingController(text: "المهندس سعيد الغامدي");
  TextEditingController _emailController = TextEditingController(text: "admin@email.com");
  TextEditingController _phoneController = TextEditingController(text: "0502292630");
  TextEditingController _passwordController = TextEditingController();

  bool _isEditing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("إدارة الحساب"),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close : Icons.edit),
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
              });
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField("الاسم الكامل", _nameController, enabled: _isEditing),
            _buildTextField("البريد الإلكتروني", _emailController, enabled: false),
            _buildTextField("رقم الجوال", _phoneController, enabled: _isEditing),
            _buildTextField("كلمة المرور الجديدة", _passwordController, obscureText: true, enabled: _isEditing),
            SizedBox(height: 20),
            if (_isEditing)
              ElevatedButton.icon(
                icon: Icon(Icons.save),
                label: Text("حفظ التعديلات",selectionColor: Colors.white,),
                onPressed: () {
                  setState(() {
                    _isEditing = false;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text("تم حفظ التعديلات بنجاح"),
                  ));
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool enabled = true, bool obscureText = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        enabled: enabled,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
      ),
    );
  }
}
