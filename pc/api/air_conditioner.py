# pc/api/air_conditioner.py

from .connection_base import HomeAutomationSystemConnection
# Bu dosya, connection_base.py dosyasındaki ana sınıfı kullanmak için gereklidir.

# UART Komutlarının Tanımlanması (Sadece Bilgi Amaçlı, Koda Dahil Değil)
# GET Komutları: 0b00000xxx
GET_DESIRED_TEMP_LOW  = 0b00000001
GET_DESIRED_TEMP_HIGH = 0b00000010
GET_AMBIENT_TEMP_LOW  = 0b00000011 # [cite: 675]
GET_AMBIENT_TEMP_HIGH = 0b00000100 # [cite: 675]
GET_FAN_SPEED         = 0b00000101 # [cite: 675]

# SET Komutları: 0b1x t5 t4 t3 t2 t1 t0 (10x veya 11x)
SET_LOW_MASK  = 0b10000000 # Kesirli kısım için
SET_HIGH_MASK = 0b11000000 # Tam kısım için

class AirConditionerSystemConnection(HomeAutomationSystemConnection):
    """
    Board #1 (Klima Sistemi) ile iletişimi yönetir. (R2.3-1)
    """
    def __init__(self, port: str, rate: int):
        super().__init__(port, rate)
        # Sınıf üye verilerini tanımla [cite: 736-738]
        self.desiredTemperature: float = 0.0   # [R2.1.1-1]
        self.ambientTemperature: float = 0.0   # [R2.1.1-4]
        self.fanSpeed: int = 0                 # [R2.1.1-5]

    # --- YARDIMCI FONKSİYONLAR ---

    def _bytes_to_float(self, integral_byte: int, fractional_byte: int) -> float:
        """
        PIC'ten gelen 6-bitlik tam ve kesirli kısımları float değere çevirir.
        Gereksinimler [cite: 675]'e göre, gelen byte'lar 6 bitlik değeri içerir (0-63).
        Keypad örneği: 29.5 -> 29 (tam), 5 (kesirli, 0.1 basamağı)
        """
        integral = integral_byte & 0x3F # Alt 6 biti al (t5..t0)
        fractional = fractional_byte & 0x3F # Alt 6 biti al (t5..t0)
        
        # Sıcaklık değeri (Tam Kısım + Kesirli Kısım / 10)
        return float(integral) + float(fractional) / 10.0

    def _read_and_process(self, command_byte: int) -> int:
        """UART komutunu gönderir ve tek bir byte cevap okur."""
        if self._connection and self._connection.is_open:
            self._connection.write(bytes([command_byte]))
            response = self._connection.read(1)
            if response:
                return response[0]
        return 0

    # --- ANA API FONKSİYONLARI ---

    def update(self) -> None:
        """
        Board #1'den ortam sıcaklığı ve fan hızını günceller. (R2.3-1 - update)
        [cite: 675]
        """
        if not self._connection or not self._connection.is_open:
           
            return

        print("Board 1 verileri güncelleniyor...")

        # 1. Ortam Sıcaklığını (Ambient Temp) Çek
        ambient_frac = self._read_and_process(GET_AMBIENT_TEMP_LOW)
        ambient_int  = self._read_and_process(GET_AMBIENT_TEMP_HIGH)
        
        self.ambientTemperature = self._bytes_to_float(ambient_int, ambient_frac)
            
        # 2. Fan Hızını Çek
        fan_byte = self._read_and_process(GET_FAN_SPEED)
        self.fanSpeed = fan_byte # rps değeri doğrudan byte olarak okunur
        
        # 3. İstenen Sıcaklığı (Desired Temp) Çek (Arayüzde gösterim için)
        desired_frac = self._read_and_process(GET_DESIRED_TEMP_LOW)
        desired_int  = self._read_and_process(GET_DESIRED_TEMP_HIGH)
        
        self.desiredTemperature = self._bytes_to_float(desired_int, desired_frac)


    def setDesiredTemp(self, temp: float) -> bool:
        """
        Board #1'e istenen sıcaklığı gönderir. (R2.3-1 - setDesiredTemp)
        [cite: 675]
        """
        if not self._connection or not self._connection.is_open:
          
            return False

        # 10.0°C < T < 50.0°C kontrolü (R2.1.2-3)
        if not (10.0 <= temp <= 50.0):
            print(f"Hata: Sıcaklık {temp}°C, geçerli aralık (10.0-50.0) dışında.")
            return False

        # Sıcaklık değerini integral (tam) ve fractional (kesirli) kısımlara ayırma
        integral = int(temp)
        fractional = int(round((temp - integral) * 10)) # 1 ondalık basamağı

        # Komut Hazırlığı (6-bitlik veri + 10/11 komut biti)
        # Integral Komutu (High Byte): 11xxxxxx | 6 bitlik integral kısmı
        integral_cmd_byte = SET_HIGH_MASK | (integral & 0x3F) 

        # Fractional Komutu (Low Byte): 10xxxxxx | 6 bitlik fractional kısmı
        fractional_cmd_byte = SET_LOW_MASK | (fractional & 0x3F)

        # UART Üzerinden Gönderme
        self._connection.write(bytes([fractional_cmd_byte]))
        self._connection.write(bytes([integral_cmd_byte]))
        
        self.desiredTemperature = temp
        print(f"Hedef sıcaklık {temp}°C olarak ayarlandı. UART komutları gönderildi.")
        return True

    # --- GET METOTLARI (Verileri Yerel Üyeden Döndürür) ---
    
    def getAmbientTemp(self) -> float:
        """Ortam sıcaklığını döndürür."""
        return self.ambientTemperature
    
    def getFanSpeed(self) -> int:
        """Fan hızını döndürür."""
        return self.fanSpeed

    def getDesiredTemp(self) -> float:
        """İstenen sıcaklığı döndürür."""
        return self.desiredTemperature