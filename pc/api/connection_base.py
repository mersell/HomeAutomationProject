# pc/api/connection_base.py
import serial 

class HomeAutomationSystemConnection:
    """
    Tüm bağlantılar için temel sınıf. Seri port ayarlarını yönetir. (R2.3-1, R2.3-2)
    """
    def __init__(self, port: str, rate: int):
        self.comPort = port          # COM port numarası (Örn: 'COM1') [cite: 729]
        self.baudRate = rate         # Baud hızı (Örn: 9600) [cite: 729]
        self._connection = None      # pyserial bağlantı nesnesi

    def setComPort(self, port: str) -> None:
        """İletişim portunu ayarlar. (R2.3-1 - setComPort) [cite: 732, 758]"""
        self.comPort = port

    def setBaudRate(self, rate: int) -> None:
        """Baud hızını ayarlar. (R2.3-1 - setBaudRate) [cite: 734, 758]"""
        self.baudRate = rate

# pc/api/connection_base.py dosyasındaki open() metodunun yeni HATA BLOĞU
    def open(self) -> bool:
        """UART portuna bağlantı başlatır. (R2.3-1 - open) [cite: 730, 758]"""
        try:
            # Bağlantı 8N1 formatında kurulur (PICSimLab gereksinimi) [cite: 310]
            self._connection = serial.Serial(
                self.comPort, 
                self.baudRate, 
                timeout=0.5 # Okuma için zaman aşımı (saniye)
            )
            print(f"[{self.comPort}] portunda bağlantı BAŞARILI.")
            return True
        except serial.SerialException as e:
            print(f"[{self.comPort}] portunda bağlantı HATASI: {e}")
            self._connection = None
            return False
    def close(self) -> bool:
        """Bağlantıyı kapatır. (R2.3-1 - close) [cite: 730, 758]"""
        if self._connection and self._connection.is_open:
            self._connection.close()
            print(f"[{self.comPort}] bağlantısı kapatıldı.")
            return True
        return False

    def update(self):
        """Alt sınıflar tarafından override edilmeli. Tüm verileri günceller. (R2.3-1 - update) [cite: 731, 758]"""
        raise NotImplementedError("update() metodu alt sınıfta implemente edilmelidir.")