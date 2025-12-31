# pc/app/test_curtain_api.py

# ===========================================================================
# Written and implemented by Şevval Ayça Çerence (Student ID: 152120211128).
# ===========================================================================

import time
import sys, os

## Configure Python path to access pc/api modules from pc/app

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from api.curtain_control import CurtainControlSystemConnection

# Configure the COM port used for UART communication
PORT = "COM5"   
BAUD = 9600

def main():
    api = CurtainControlSystemConnection(PORT, BAUD)

    if not api.open():
        print(f"{PORT} açılamadı, çıkıyorum.")
        return

    print(f"{PORT} bağlantı açık, Board#2 ile konuşmayı deniyorum...\n")

    # Perform three consecutive read operations
    for i in range(3):
        api.update()
        print(f"[READ {i+1}]")
        print(f"  Desired Curtain : {api.getDesiredCurtain():.1f} %")
        print(f"  Current Curtain : {api.getCurtainStatus():.1f} %")
        print(f"  Outdoor Temp    : {api.getOutdoorTemp():.1f} °C")
        print(f"  Outdoor Press   : {api.getOutdoorPress():.1f}")
        print(f"  Light Intensity : {api.getLightIntensity():.1f}")
        print()
        time.sleep(1.0)

    # Send multiple target curtain values

    for target in [0.0, 30.0, 60.0, 90.0]:
        print(f"Perdeyi %{target:.1f} hedefine gönderiyorum...")
        ok = api.setCurtainStatus(target)
        print(f"  setCurtainStatus sonucu: {ok}")

        # Read updated values after calling update()
        time.sleep(0.5)
        api.update()
        print(f"  -> Board'dan gelen Current: {api.getCurtainStatus():.1f} %, Desired: {api.getDesiredCurtain():.1f} %")
        print()

    api.close()
    print(f"[{PORT}] bağlantısı kapatıldı.")
    print("Test bitti.")

if __name__ == "__main__":
    main()