# pc/app/main_app.py
# ===========================================================================
# Written and implemented by Şevval Ayça Çerence (Student ID: 152120211128).
# ===========================================================================

import sys
import os
import time

# Adjust Python path to allow importing API classes

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

# Import project-specific API classes
from api.air_conditioner import AirConditionerSystemConnection
from api.curtain_control import CurtainControlSystemConnection

# --- GLOBAL SETTINGS ---
COM_PORT = 'COM5' 
BAUD_RATE = 9600

# Create API communication objects
ac_system = AirConditionerSystemConnection(COM_PORT, BAUD_RATE)
curtain_system = CurtainControlSystemConnection(COM_PORT, BAUD_RATE)

def display_main_menu():
    """Ana Menüyü gösterir. [cite: 771]"""
    print("\n" + "="*40)
    print("           ANA MENÜ (HOME AUTOMATION)")
    print("="*40)
    print("1. Klima Kontrol Sistemi")
    print("2. Perde Kontrol Sistemi")
    print("3. Bağlantıyı Kapat ve Çıkış")
    print("="*40)

def display_ac_menu():
    """Klima Kontrol Menüsünü ve verilerini gösterir. [cite: 779]"""
    print("\n" + "-"*40)
    print("         KLİMA KONTROL SİSTEMİ")
    print("-" * 40)
    
    # Retrieve current data from Board #1
    ac_system.update() 

    print(f"Ev Ortam Sıcaklığı: {ac_system.getAmbientTemp():.1f} °C") 
    print(f"Ev Hedef Sıcaklığı: {ac_system.getDesiredTemp():.1f} °C") 
    print(f"Fan Hızı: {ac_system.getFanSpeed()} rps")
    print("-" * 40)
    print(f"Bağlantı Portu: {COM_PORT} | Baud: {BAUD_RATE}")
    print("-" * 40)
    print("1. İstenen Hedef Sıcaklığı Gir")
    print("2. Geri Dön")
    print("-" * 40)

def display_curtain_menu():
    """Perde Kontrol Menüsünü ve sensör verilerini gösterir. [cite: 788]"""
    print("\n" + "-"*40)
    print("         PERDE KONTROL SİSTEMİ")
    print("-" * 40)
    
    ## Retrieve current data from Board #2 via UART module (5UART2.asm)
    curtain_system.update()

    print(f"Dış Sıcaklık: {curtain_system.getOutdoorTemp():.1f} °C") 
    print(f"Dış Basınç: {curtain_system.getOutdoorPress():.1f} hPa") 
    print(f"Perde Durumu: %{curtain_system.getCurtainStatus():.1f}") 
    print(f"Işık Şiddeti: {curtain_system.getLightIntensity():.1f} Lux") 
    print("-" * 40)
    print(f"Bağlantı Portu: {COM_PORT} | Baud: {BAUD_RATE}")
    print("-" * 40)
    print("1. İstenen Perde Durumunu Gir (%)")
    print("2. Geri Dön")
    print("-" * 40)

def handle_ac_input():
    """Klima hedef sıcaklığını ayarlar."""
    try:
        temp = float(input("Enter Desired Temp (10.0-50.0): "))
        if ac_system.setDesiredTemp(temp):
            print(f"-> Başarılı: Hedef sıcaklık {temp}°C olarak ayarlandı.")
        else:
            print("-> Hata: Değer aralık dışı (10-50) veya bağlantı hatası.")
    except ValueError:
        print("-> Hata: Geçerli bir sayı giriniz.")

def handle_curtain_input():
    """Perde açıklık yüzdesini ayarlar."""
    try:
        percent = float(input("Enter Desired Curtain (% 0-100): "))
        if curtain_system.setCurtainStatus(percent):
            print(f"-> Başarılı: Perde %{percent} hedefine ayarlanıyor...")
        else:
            print("-> Hata: Geçersiz yüzde veya bağlantı hatası.")
    except ValueError:
        print("-> Hata: Geçerli bir sayı giriniz.")

def run_application():
    """Ana uygulama döngüsü."""
    # Attempt to open the UART communication port
    if not ac_system.open(): 
        print(f"\nFATAL HATA: {COM_PORT} portu açılamadı!")
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
                    break 
        
        elif choice == '2':
            while True:
                display_curtain_menu()
                sub_choice = input("Seçiminiz (1-2): ")
                if sub_choice == '1':
                    handle_curtain_input()
                elif sub_choice == '2':
                    break 

        elif choice == '3':
            ac_system.close()
            print("Bağlantı kapatıldı. Çıkış yapılıyor...")
            break
        else:
            print("Geçersiz seçim!")

if __name__ == "__main__":
    run_application()
