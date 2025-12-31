# pc/app/test_air_conditioner_api.py

# ===========================================================================
# Written and implemented by Şevval Ayça Çerence (Student ID: 152120211128).
# ===========================================================================

import time
import sys, os

## Configure Python path to access pc/api modules from pc/app

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from api.air_conditioner import AirConditionerSystemConnection

# === UART PORT SETTINGS ===
# Virtual serial port mapping using VSPE:
# PC side (Python application) -> COM7
# PICSimLab IO UART module     -> COM8

PORT = "COM8"
BAUD = 9600


def main():
    api = AirConditionerSystemConnection(PORT, BAUD)

    if not api.open():
        print(f"{PORT} açılamadı, çıkıyorum.")
        return

    print(f"{PORT} bağlantı açık, Board #1 (Klima) ile konuşma başlıyor...\n")

    # -------------------------------------------------
    # GET TEST
    # -------------------------------------------------
    for i in range(3):
        api.update()

        print(f"[READ {i+1}]")
        print(f"  Ambient Temp   : {api.getAmbientTemp():.1f} °C")
        print(f"  Desired Temp   : {api.getDesiredTemp():.1f} °C")
        print(f"  Fan Speed      : {api.getFanSpeed()} rps")
        print()

        time.sleep(1.0)

    # -------------------------------------------------
    # SET + GET TEST
    # -------------------------------------------------
    test_values = [22.0, 25.5, 30.0, 18.5]

    for temp in test_values:
        print(f"Hedef sıcaklık {temp:.1f} °C gönderiliyor...")
        ok = api.setDesiredTemp(temp)
        print(f"  setDesiredTemp sonucu: {ok}")

        time.sleep(0.5)

        api.update()
        print(f"  -> Board'dan gelen Desired: {api.getDesiredTemp():.1f} °C")
        print(f"  -> Ambient Temp           : {api.getAmbientTemp():.1f} °C")
        print(f"  -> Fan Speed              : {api.getFanSpeed()} rps")
        print()

    # -------------------------------------------------
    # Close active communication connections
    # -------------------------------------------------
    api.close()
    print(f"[{PORT}] bağlantısı kapatıldı.")
    print("Klima UART test tamamlandı.")


if __name__ == "__main__":
    main()