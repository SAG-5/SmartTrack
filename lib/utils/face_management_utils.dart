import 'package:http/http.dart' as http;
import 'dart:convert';

// دالة لحذف جميع الوجوه من FaceSet في Face++
Future<void> deleteAllFacesFromFaceSet() async {
  final url = Uri.parse("https://api-us.faceplusplus.com/facepp/v3/faceset/removeface");

  final response = await http.post(url, body: {
    'api_key': 'NjSd8tJ6FKySDK4GQ9-KBsiPau9qscJf',  // استبدال بمفتاح API الخاص بك
    'api_secret': 'Fs7-P3VMqVbzCNVlXHHxYwg_4ysCUvOM',  // استبدال بمفتاح API الخاص بك
    'outer_id': 'smarttrack_faceset',  // اسم الـ FaceSet
    'face_tokens': 'RemoveAllFaceTokens',  // تعيين القيمة لحذف جميع الوجوه
  });

  final data = json.decode(response.body);

  if (response.statusCode == 200 && data['face_removed'] != null) {
    print('✅ تم حذف ${data['face_removed']} وجه من FaceSet');
  } else {
    print('❌ فشل الحذف: ${data['error_message']}');
  }
}
