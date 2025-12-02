# pc/app/main_app.py

import sys
import os

# K1'in API sınıflarını import etmek için yol ayarı
# Bu kısım, 'pc/app' içinden 'pc/api' klasöründeki kodları görmemizi sağlar.
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

# K1 tarafından yazılan API sınıflarını içe aktar
from api.air_conditioner import AirConditionerSystemConnection

# --- GLOBAL AYARLAR (R2.4-1) ---
# Sanal portunuzu (com0com/tty0tty'nin PC tarafı) ve hızı buraya yazın.
COM_PORT = 'COM3'  # ÖRNEK DEĞERİ KENDİ VİRTÜEL PORTUNUZLA DEĞİŞTİRİN
BAUD_RATE = 9600

# K1'in API nesnelerini oluşturma
ac_system = AirConditionerSystemConnection(COM_PORT, BAUD_RATE)
# CurtainControlSystemConnection sınıfı K1 tarafından henüz yazılmadı.

def display_main_menu():
    """Ana Menüyü gösterir. (R2.4-1)"""
    print("\n" + "="*40)
    print("           ANA MENÜ (HOME AUTOMATION)")
    print("="*40)
    print("1. Klima Kontrol Sistemi")
    print("2. Perde Kontrol Sistemi")
    print("3. Bağlantıyı Kapat ve Çıkış")
    print("="*40)
    
"""def display_ac_menu():

    print("\n" + "-"*40)
    print("         KLİMA KONTROL SİSTEMİ")
    print("-" * 40)

    # K1'in API'sinden güncel verileri çekme (UART GET komutlarını gönderir)
    ac_system.update() 

    # Güncel verileri ekrana yazdır (R2.4-1)
    print(f"Ev Ortam Sıcaklığı: {ac_system.getAmbientTemp():.1f} °C")
    print(f"Ev Hedef Sıcaklığı: {ac_system.getDesiredTemp():.1f} °C")
    print(f"Fan Hızı: {ac_system.getFanSpeed()} rps")
    print("-" * 40)
    print(f"Bağlantı Portu: {COM_PORT} | Baud: {BAUD_RATE}")
    print("-" * 40)
    print("1. İstenen Hedef Sıcaklığı Gir")
    print("2. Geri Dön")
    print("-" * 40)"""
def display_ac_menu():
    """Klima Kontrol Menüsünü gösterir ve güncel verileri görüntüler. (R2.4-1, Şekil 18)"""
    print("\n" + "-"*40)
    print("         KLİMA KONTROL SİSTEMİ")
    print("-" * 40)

    # K1'in API'sinden güncel verileri çekme (UART GET komutlarını dener)
    ac_system.update() 

    # Güncel verileri ekrana yazdır (R2.4-1)
    # Bu satırların, önceki kodunuzda eksik veya yanlış girintili olması muhtemeldir.
    print(f"Ev Ortam Sıcaklığı: {ac_system.getAmbientTemp():.1f} °C") 
    print(f"Ev Hedef Sıcaklığı: {ac_system.getDesiredTemp():.1f} °C") 
    print(f"Fan Hızı: {ac_system.getFanSpeed()} rps")
    print("-" * 40)
    print(f"Bağlantı Portu: {COM_PORT} | Baud: {BAUD_RATE}")
    print("-" * 40)
  
def handle_ac_input():
    """Klima menüsünden kullanıcı girdisini alır ve K1'in API'sine yollar."""
    try:
        temp = float(input("Enter Desired Temp (10.0-50.0): "))
        
        # K1'in API metodunu kullan (Bu metot UART SET komutlarını gönderir)
        if ac_system.setDesiredTemp(temp):
            print(f"-> Başarılı: Hedef sıcaklık {temp}°C olarak ayarlandı.")
        else:
            print("-> Hata: Sıcaklık ayarı başarısız (Aralık dışı veya bağlantı hatası).")
    except ValueError:
        print("-> Hata: Lütfen geçerli bir sayı (örn: 25.5) giriniz.")

def run_application():
    """Ana uygulama döngüsünü yönetir."""
    # K1'in open() metodu ile bağlantıyı açmayı dene (R2.3-1)
    if not ac_system.open(): 
        print("\nFATAL HATA: Seri Port Bağlantısı Başlatılamadı. Uygulama Kapatılıyor.")
        return

    while True:
        display_main_menu()
        choice = input("Seçiminiz (1-3): ")

        if choice == '1':
            while True:
                display_ac_menu()
                sub_choice = input("Seçiminiz (1-2): ")
                if sub_choice == '1':
                    handle_ac_input()
                elif sub_choice == '2':
                    break # Ana Menüye dön
        
        elif choice == '2':
            print("Perde Kontrol Menüsü (Board #2) API tarafından henüz desteklenmiyor.")
            # İleride K1'in Curtain API'si ve K2'nin mantığı buraya gelecek.

        elif choice == '3':
            ac_system.close() # K1'in close() metodu
            print("Uygulama Kapatılıyor...")
            break
        else:
            print("Geçersiz seçim. Tekrar deneyin.")

if __name__ == "__main__":
    run_application()