# HomeAutomationProject

## Proje Hakkında
HomeAutomationProject, bir ev otomasyon sisteminin geliştirilmesini hedefler. Sistem; PC uygulaması, API, iki farklı mikrodenetleyici kartı (Board1 ve Board2), sensörler ve kullanıcı arayüzünü kapsar.  

Bu README, **gelecekte yapılacak işler ve görev dağılımı** üzerine hazırlanmıştır. Kodlar henüz yazılmamıştır; bu yapı, ekip üyelerinin çalışmalarını düzenlemesi ve hocanın proje ilerleyişini takip etmesi için rehber niteliğindedir.

---

## Görev Dağılımı ve Sorumluluklar

| Kişi | Rol | Sorumluluklar / Yapılacak İşler | Dosya / Klasör |
|------|-----|-------------------------------|----------------|
| K1 | PC API + Board1 UART + Entegrasyon | - Board1 ile iletişim için API sınıfları oluşturulacak.<br>- `setDesiredTemp`, `update` gibi temel fonksiyonlar yazılacak.<br>- Entegrasyon testleri yapılacak. | `pc/api/` |
| K2 | PC Uygulama + Board2 UART + GitHub/Belgeleme | - Konsol veya GUI uygulama menüsü geliştirilecek.<br>- Kullanıcıdan veri alma ve API’ye gönderme kodları yazılacak.<br>- Repo düzeni, branch ve commit standartları oluşturulacak.<br>- Rapor ve dokümantasyon birleştirilecek. | `pc/app/` |
| K3 | Board1 – Sıcaklık ve Fan Kontrol + Pin Mapping | - LM35 ile sıcaklık okuma modülü yazılacak.<br>- Fan ve heater kontrol algoritmaları oluşturulacak.<br>- Fan hız ölçümü ve common data hafıza adresleri düzenlenecek.<br>- Pin mapping tablosu oluşturulacak. | `board1/tempfan/` |
| K4 | Board1 – Keypad & 7-Segment + UART desteği | - Keypad giriş akışı tamamlanacak (A ile başlat, * ile ondalık, # ile bitir).<br>- 7-segment display ile sıcaklık ve fan bilgisi gösterilecek.<br>- Board1 UART testleri yapılacak. | `board1/keypad_display/` |
| K5 | Board2 – Perde, Sensörler, BMP180, LCD + UART desteği | - Step motor ile perde kontrol algoritması yazılacak.<br>- LDR ve potansiyometre sensörleri okuma ve hedef değer hesaplama.<br>- BMP180 ile dış sıcaklık ve basınç ölçümü, LCD’de gösterim.<br>- Board2 UART testleri yapılacak. | `board2/curtain/`, `board2/sensors_lcd/` |

---

## Klasör Yapısı (Gelecekteki Kod ve Dosyalar)

HomeAutomationProject/
│
├─ pc/
│ ├─ api/ # K1: API sınıfları ve Board1 UART
│ └─ app/ # K2: Konsol/GUI uygulama
│
├─ board1/
│ ├─ tempfan/ # K3: Sıcaklık ve fan kontrol
│ └─ keypad_display/ # K4: Keypad ve 7-segment
│
├─ board2/
│ ├─ curtain/ # K5: Step motor ve perde kontrol
│ └─ sensors_lcd/ # K5: LDR, Pot, BMP180, LCD
│
├─ docs/ # Rapor, UML, Pin Mapping, Hafıza Haritası
└─ README.md



> Her klasör ve dosya, ileride ilgili kişinin kodlarını ve testlerini içerecek.

---

## Yapılacak İşler ve Zaman Planı (Geleceğe Dönük)

| Hafta | Görevler |
|-------|----------|
| 1 | - Kurulum ve temel testler (PICSimLab, COM portlar, placeholder dosyalar)<br>- Pin mapping ve common data taslakları<br>- Basit test kodları (LED, 7-segment, LCD, step motor) |
| 2 | - Board1 ve Board2 modülleri geliştirilecek (UART hariç)<br>- K1: API iskeleti oluşturacak<br>- K2: PC uygulama menü iskeleti oluşturacak<br>- K3/K4/K5: Sensör ve cihaz modüllerini tamamlayacak |
| 3 | - UART entegrasyonu ve testleri<br>- API ile Board1/Board2 iletişimi sağlanacak<br>- PC uygulama üzerinden kullanıcı etkileşimi test edilecek |
| 4 | - Entegrasyon testleri ve hata düzeltme<br>- Dokümantasyon ve rapor tamamlanacak<br>- Sunum ve demo hazırlanacak |

---

## GitHub Branch ve Commit Standartları

- **Branch isimleri:** `k1-api`, `k2-app`, `k3-board1`, `k4-keypad`, `k5-board2`  
- **Commit mesajları:** Örnek: `K1: API iskeleti oluşturuldu`  
- Bu standartlar, ekip üyelerinin çalışmalarını ve değişiklikleri kolay takip etmelerini sağlar.

---

## Notlar

docs/ klasöründe her modüle ait dokümantasyon ilerleyen haftalarda oluşturulacak.

## Git Kullanımı – Temel İş Akışı

Bu proje için temel Git komutları ve iş akışı aşağıdaki gibidir. Her ekip üyesi kendi branch’inde çalışmalı, main branch’e direkt müdahale edilmemelidir.

1. Repo’yu klonlamak (ilk defa indirirken):  
git clone https://github.com/mersell/HomeAutomationProject.git

2. Branch’e geçmek / kendi modülünde çalışmak:  
git checkout k1-api   # K1 için örnek

3. Yeni kod ekleme / değişiklik yapma:  
- Dosyaları ekle veya düzenle.  
- Değişiklikleri stage et:  
git add .

4. Commit mesajı ile kaydetmek:  
git commit -m "K1: API fonksiyon iskeleti eklendi"

5. GitHub’a göndermek (push):  
git push origin k1-api

6. Başka birisinin yaptığı değişiklikleri almak (pull):  
git pull origin k1-api

Not: Kod tamamlandığında ve test edildiğinde branch’ler main ile birleştirilebilir (merge). Her zaman önce güncel branch’ten pull yaparak başlayın.






