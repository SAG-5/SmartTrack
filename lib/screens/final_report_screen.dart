import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;

class FinalReportScreen extends StatelessWidget {
  const FinalReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('بحث التدريب')),
      body: PdfPreview(
        build: (format) => _generatePdf(),
      ),
    );
  }

  Future<Uint8List> _generatePdf() async {
    final pdf = pw.Document();

    final regularFont = pw.Font.ttf(
      await rootBundle.load('assets/fonts/NotoNaskhArabic-Regular.ttf'),
    );
    final mediumFont = pw.Font.ttf(
      await rootBundle.load('assets/fonts/NotoNaskhArabic-Medium.ttf'),
    );

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("User not logged in");

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final data = doc.data() ?? {};

    final name = data['fullName'] ?? 'غير معروف';
    final academicNumber = data['academicNumber'] ?? 'غير متوفر';
    final trainingOrg = data['trainingOrganization'] ?? 'غير محددة';
    final phone = data['phone'] ?? 'غير متوفر';
    final skills = data['finalSkills'] ?? 'لم يتم التحديد بعد.';
    final challenges = data['finalChallenges'] ?? 'لم يتم التحديد بعد.';
    final supervisor = data['supervisorName'] ?? 'غير معروف';

    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: regularFont, bold: mediumFont),
        textDirection: pw.TextDirection.rtl,
        build: (context) => [
          pw.Header(level: 0, child: pw.Text('بحث التدريب النهائي', style: pw.TextStyle(fontSize: 22))),

          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('معلومات المتدرب:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text('الاسم الكامل: $name'),
                pw.Text('الرقم التدريبي: $academicNumber'),
                pw.Text('جهة التدريب: $trainingOrg'),
                pw.Text('رقم الجوال: $phone'),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          pw.Text('فهرس المحتوى:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Bullet(text: '. المقدمة'),
          pw.Bullet(text: '. ملخص الحضور'),
          pw.Bullet(text: '. المهام والتقييمات'),
          pw.Bullet(text: '. المهارات المكتسبة'),
          pw.Bullet(text: '. التحديات والمعوقات'),

          pw.SizedBox(height: 20),

          pw.Text('١. المقدمة', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Paragraph(text: 'هذا التقرير يمثّل خلاصة تجربة التدريب الميداني، حيث تم قضاء فترة تدريبية عملية ضمن جهة التدريب، بهدف اكتساب المهارات وتطبيق المفاهيم النظرية عمليًا.'),

          pw.SizedBox(height: 12),
          pw.Text('٢. ملخص الحضور', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Paragraph(text: 'تم الالتزام بعدد أيام الحضور المطلوبة. عدد أيام الحضور: ____، عدد أيام الغياب: ____، عدد أيام التأخير: ____. (يتم استبدالها لاحقًا بالقيم الحقيقية).'),

          pw.SizedBox(height: 12),
          pw.Text('٣. المهام والتقييمات', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Paragraph(text: 'خلال فترة التدريب، تم تسليم المهام بشكل أسبوعي حسب الخطة المعتمدة، وتم تقييمها من قبل المشرف. متوسط التقييم: ____ من 10. (تُستبدل لاحقًا بالقيم الحقيقية).'),

          pw.SizedBox(height: 12),
          pw.Text('٤. المهارات المكتسبة', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Paragraph(text: skills),

          pw.SizedBox(height: 12),
          pw.Text('٥. التحديات والمعوقات', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Paragraph(text: challenges),

          pw.SizedBox(height: 30),
          pw.Text('تم إعداد هذا التقرير بواسطة المتدرب: $name', style: pw.TextStyle(fontSize: 14)),
        ],
      ),
    );

    return pdf.save();
  }
}
