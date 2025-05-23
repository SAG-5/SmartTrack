# SmartTrack - نظام التدريب الذكي 🎓📍

تطبيق ذكي شامل لإدارة التدريب الميداني، يتيح للمتدربين تسجيل الحضور ببصمة الوجه والموقع الجغرافي، وتسليم المهام الأسبوعية إلكترونيًا، مع نظام تواصل مباشر مع المشرفين، ولوحة تحكم متقدمة لتقييم الأداء واستعراض التقارير.  
هذا المشروع قُدِّم ضمن متطلبات التخرج من الكلية التقنية، ويجري تطويره ليكون منتجًا فعليًا يمكن تطبيقه واعتماده في الكليات والجامعات السعودية.

---

## 🎯 الفئة المستهدفة

- طلاب وخريجو الكليات التقنية أثناء فترة التدريب الميداني  
- مشرفو التدريب في الكليات وجهات التدريب

---

## ⚙️ المزايا الأساسية

- **توثيق حضور آمن:** باستخدام بصمة الوجه والموقع الجغرافي  
- **تسليم المهام إلكترونيًا:** مع إمكانية التقييم وإعادة الفتح  
- **نظام رسائل فوري:** بين المتدرب والمشرف، وبين المشرف وجهة التدريب  
- **تقارير شاملة:** أسبوعية، شهرية، ونهائية بصيغة PDF  
- **تنبيهات فورية:** عند التأخير أو وصول المهام  
- **لوحة تحكم للمشرف:** لمتابعة الأداء والتقييم والتقارير

---

## 🛠️ التقنيات المستخدمة

- Flutter + Dart  
- Firebase (Auth, Firestore, Storage, Cloud Messaging)  
- Face++ API  
- Google Maps & Geolocation  
- GitHub Actions (نشر اختياري)

---

# SmartTrack – The Intelligent Training System 🎓📍

A comprehensive smart application for managing field training. It allows trainees to log attendance using facial recognition and geolocation, submit weekly tasks electronically, communicate directly with supervisors, and includes a dashboard for performance tracking and smart reporting.  
Originally developed as a graduation project, SmartTrack is now being enhanced to be offered as a real solution for colleges and universities in Saudi Arabia.

---

## 🎯 Target Audience

- Technical college students and graduates in field training  
- Supervisors at colleges and training institutions

---

## ⚙️ Key Features

- **Secure Attendance:** Face recognition + Geolocation verification  
- **Weekly Tasks:** Electronic submission with grading & feedback  
- **Instant Messaging:** Between trainee and supervisor, or supervisor and training provider  
- **Reports:** Auto-generated weekly, monthly, and final PDF reports  
- **Notifications:** For delays or task updates  
- **Supervisor Dashboard:** To evaluate and monitor trainee performance

---

## 📱 صور من التطبيق | Screenshots

> كل صورة تمثل ميزة مهمة في التطبيق، موضّحة بالعربي والإنجليزي 👇

---

### 🧾 اختيار نوع الحساب | Role Selection  
يختار المستخدم هل هو "خريج" أم "مشرف"  
**User selects their role: Graduate or Supervisor**  
![Role Selection](screenshots/role_selection_screen.jpg)

---

### 🔐 تسجيل دخول الخريج | Login Screen  
واجهة دخول المتدرب عبر البريد الإلكتروني وكلمة المرور  
**Login screen for trainees using email and password**  
![Login](screenshots/login_screen.jpg)

---

### 🕘 تسجيل الحضور | Attendance  
واجهة الضغط على زر الحضور والتحقق من الوجه والموقع  
**Attendance screen verifying face and geolocation**  
![Attendance](screenshots/attendance_screen.jpg)

---

### 🎭 تسجيل بصمة الوجه | Face Registration  
أول مرة يتم فيها تسجيل وجه المتدرب لربطه بالحضور  
**First-time face registration for attendance validation**  
![Face Registration](screenshots/face_registration_screen.jpg)

---

### 🗺️ تحديد موقع جهة التدريب | Training Location  
خريطة لتحديد موقع التدريب الفعلي لأول مرة  
**Map interface to set training location**  
![Training Location](screenshots/training_location_screen.jpg)

---

### 📅 سجل الحضور | Attendance Log  
يعرض الأيام التي تم تسجيل الحضور فيها  
**Shows attendance days and timestamps**  
![Attendance Log](screenshots/attendance_log_screen.jpg)

---

### 📋 المهام الأسبوعية | Weekly Tasks  
شاشة المهام المرسلة أسبوعيًا من جهة التدريب  
**Weekly tasks assigned and submitted**  
![Weekly Tasks](screenshots/weekly_task_screen.jpg)

---

### 💬 اختيار المحادثة | Select Chat  
المتدرب يختار المحادثة بين مشرف التدريب أو الجهة  
**Trainee selects chat with supervisor or training group**  
![Chat Selection](screenshots/chat_with_supervisor_screen.jpg)

---

### ⚙️ الإعدادات | Settings  
ضبط الحساب والمعلومات والتقارير وبيانات جهة التدريب  
**App settings, final reports, and training organization info**  
![Settings](screenshots/settings_screen.jpg)

---

### 👨‍💼 تسجيل دخول المشرف | Supervisor Login  
المشرف يدخل للنظام باستخدام البريد وكلمة المرور  
**Supervisor login using email and password**  
![Admin Login](screenshots/admin_login_screen.png)

---

### 🧑‍💼 المتدربين التابعين للمشرف | Trainees under Supervisor  
قائمة جميع المتدربين المرتبطين بالمشرف  
**All trainees assigned to the supervisor**  
![Manage Trainees](screenshots/admin_manage_trainees_screen.png)

---

### 💬 تبويب محادثات المشرف | Supervisor Messages Tab  
عرض محادثات المشرف الفردية  
**Tab showing all one-on-one supervisor messages**  
![Messages Tab](screenshots/admin_messages_tab.png)

---

### 🏢 جهات تدريب المتدربين | Training Organizations  
إدارة وربط المتدربين بجهاتهم التدريبية  
**Training organization assignment and overview**  
![Training Orgs](screenshots/admin_training_orgs_screen.png)

---

### 🕘 سجل حضور المشرف | Supervisor Attendance Log  
سجل الحضور العام للمتدربين  
**Global attendance log monitored by the supervisor**  
![Admin Attendance](screenshots/attendance_admin_screen.png)
