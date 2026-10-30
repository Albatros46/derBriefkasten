# Evrak Kutusu

Gelen posta evraklarını telefonla tarayıp cihazda saklayan, kategorize eden,
cevap gerektirenler için hatırlatma kuran ve PDF olarak e-posta/yazdırma yapan
Flutter uygulaması (Android + iOS, Türkçe/Almanca arayüz).

## Özellikler
- **E-posta ile giriş** (Firebase Auth): kayıt, giriş, şifre sıfırlama.
- **Tarama**: otomatik kenar algılama ve kırpma, çok sayfalı (Android: ML Kit, iOS: VisionKit). Galeriden de eklenebilir.
- **Cihazda saklama**: sayfalar uygulamanın belgeler klasöründe, kayıtlar SQLite'ta; kullanıcıya göre ayrı.
- **Otomatik kategori**: cihaz üzerinde OCR (internetsiz) + anahtar kelimeler
  (Finanzamt, Banka, Sigorta, Krankenkasse, Resmi daire, Jobcenter, Kira, Fatura, Okul, Diğer).
  Başlık ("Betreff"), gönderen ve son tarih ("bis zum …", "innerhalb von 14 Tagen") önerilir.
- **Arama**: başlık, gönderen, not ve tanınan metinde.
- **Hatırlatmalar**: cevap gereken evraklar için yerel bildirim; son tarihi geçenler kırmızı.
- **PDF**: e-posta uygulamasıyla ek olarak gönderme, yazdırma (AirPrint / Android yazdırma), paylaşma/dosyalara kaydetme.

## Kurulum

### 1. Firebase (bir kerelik, zorunlu)
1. https://console.firebase.google.com adresinde yeni proje oluşturun.
2. **Authentication → Sign-in method → Email/Password** seçeneğini etkinleştirin.
3. Bilgisayarda CLI'ları kurun ve projeyi bağlayın:
   ```
   npm install -g firebase-tools
   firebase login
   dart pub global activate flutterfire_cli
   cd E:\Projeler\flutter_proje\evrak_kutusu
   flutterfire configure --platforms=android,ios
   ```
   Bu komut `lib/firebase_options.dart` dosyasını kendi projenizin ayarlarıyla yeniden yazar.
   Bu adım yapılmadan uygulama açılışta "Firebase yapılandırılmamış" uyarısı gösterir.

### 2. Android
```
flutter run
```
(minSdk 24; kamera ve bildirim izinleri uygulama içinden istenir.)

### 3. iOS (Mac + Xcode gerekir)
- Minimum iOS 15.5 (ML Kit gereksinimi).
- `flutter run` ilk çalıştırmada CocoaPods bağımlılıklarını kurar. Bir `ios/Podfile` oluşursa
  en üstteki satırı `platform :ios, '15.5'` yapın.
- Xcode'da Signing & Capabilities altında kendi Apple ekibinizi seçin.

## Testler
```
flutter test
```
