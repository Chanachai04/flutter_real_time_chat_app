# Flutter Real-Time Chat App

แอปแชทแบบเรียลไทม์ที่พัฒนาด้วย Flutter โดยใช้ Supabase เป็น backend สำหรับระบบสมาชิก ฐานข้อมูล และการอัปเดตข้อความแบบ real-time เหมาะสำหรับใช้เป็นโปรเจ็กต์ตัวอย่างเพื่อเรียนรู้การทำ Mobile Chat Application แบบ full flow ตั้งแต่สมัครสมาชิก เข้าสู่ระบบ เริ่มบทสนทนา ไปจนถึงรับส่งข้อความทันที

## ภาพรวมโปรเจ็กต์

โปรเจ็กต์นี้ถูกออกแบบให้เป็นแอปแชท 1 ต่อ 1 ที่มีโครงสร้างค่อนข้างชัดเจน แยกส่วน UI, state management, models และ services ออกจากกัน ทำให้ต่อยอดฟีเจอร์เพิ่มได้ง่าย เช่น การแจ้งเตือน การแนบรูป หรือการทำ group chat ในอนาคต

## ฟีเจอร์หลัก

- สมัครสมาชิกและเข้าสู่ระบบด้วย Supabase Auth
- ตรวจสอบ session เดิมอัตโนมัติเมื่อเปิดแอป
- แสดงรายการบทสนทนาของผู้ใช้
- ค้นหาผู้ใช้เพื่อเริ่มแชทใหม่
- ส่งและรับข้อความแบบ real-time
- จัดการสถานะด้วย Provider
- รองรับการแสดงผลตาม light/dark mode ของระบบ

## เทคโนโลยีที่ใช้

- Flutter
- Dart
- Supabase
- Provider
- flutter_dotenv
- cached_network_image
- shared_preferences
- intl
- timeago

## โครงสร้างภายในโปรเจ็กต์

โฟลเดอร์สำคัญภายใต้ `lib/`

- `config/` จัดการค่า config ของแอป เช่น การอ่านค่า Supabase จากไฟล์ environment
- `models/` เก็บ model ของข้อมูล เช่น ผู้ใช้ ข้อความ และบทสนทนา
- `providers/` จัดการ state ของ authentication และ chat
- `services/` รวม business logic และการเชื่อมต่อกับ Supabase
- `screens/` รวมหน้าต่าง ๆ ของแอป เช่น splash, login, signup, home, chat, profile

## การทำงานโดยสรุป

1. แอปเริ่มต้นที่หน้า Splash Screen
2. โหลดค่า environment และเชื่อมต่อ Supabase
3. ตรวจสอบว่าผู้ใช้มี session อยู่แล้วหรือไม่
4. หากยังไม่เข้าสู่ระบบ จะพาไปหน้า login/signup
5. เมื่อเข้าสู่ระบบแล้ว ผู้ใช้สามารถดูรายการแชท ค้นหาผู้ใช้ และเริ่มสนทนาได้
6. ข้อความใหม่จะอัปเดตบนหน้าจอแบบ real-time

## การตั้งค่าก่อนเริ่มใช้งาน

### 1. ติดตั้ง dependencies

```bash
flutter pub get
```

### 2. สร้างไฟล์ environment

โปรเจ็กต์นี้ใช้ไฟล์ `.env.local` สำหรับเก็บค่าเชื่อมต่อ Supabase

ตัวอย่าง:

```env
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

### 3. เตรียมฐานข้อมูลบน Supabase

โปรเจ็กต์นี้คาดหวังการมีตารางหลักอย่างน้อยดังนี้

- `profiles`
- `conversations`
- `messages`
- `conversation_participants`

รวมถึงการตั้งค่า authentication และ policy ให้เหมาะสมกับการใช้งานจริง

## วิธีรันโปรเจ็กต์

```bash
flutter run
```

ถ้าต้องการตรวจสอบคุณภาพโค้ดเพิ่มเติม:

```bash
flutter analyze
```

## จุดเด่นของโค้ดชุดนี้

- แยก provider ออกจาก service ชัดเจน ทำให้อ่านและดูแลง่าย
- ใช้ Supabase เป็น backend ครบทั้ง Auth, Database และ Realtime
- โครงสร้างเหมาะกับการนำไปต่อยอดเป็นโปรเจ็กต์จริงหรือใช้ฝึกสถาปัตยกรรมแอป Flutter

## แนวทางการต่อยอด

- เพิ่มการส่งรูปภาพหรือไฟล์แนบ
- เพิ่มสถานะอ่านข้อความแล้ว
- เพิ่มการแจ้งเตือนแบบ push notification
- รองรับ group chat
- เพิ่ม unit test และ widget test

## หมายเหตุ

โปรเจ็กต์นี้เหมาะสำหรับใช้ศึกษาแนวทางการพัฒนาแอปแชทด้วย Flutter ร่วมกับ Supabase หากจะนำไปใช้จริง ควรตรวจสอบเรื่อง validation, security policy, error handling และ performance เพิ่มเติม
