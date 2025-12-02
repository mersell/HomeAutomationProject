# pc/api/curtain_control.py

from .connection_base import HomeAutomationSystemConnection

# UART Komutlarının Tanımlanması (R2.2.6-1)
# GET Komutları: 0b00000xxx
GET_DESIRED_CURTAIN_LOW     = 0b00000001
GET_OUTDOOR_TEMP_HIGH       = 0b00000100
GET_OUTDOOR_PRESS_HIGH      = 0b00000110
GET_LIGHT_INTENSITY_HIGH    = 0b00001000

# SET Komutları: 0b1x C5 C4 C3 C2 C1 C0 B
SET_CURTAIN_LOW_MASK        = 0b10000000 # Kesirli kısım için
SET_CURTAIN_HIGH_MASK       = 0b11000000 # Tam kısım için

class CurtainControlSystemConnection(HomeAutomationSystemConnection):
    """
    Board #2 (Perde Kontrol Sistemi) ile iletişimi yönetir. (R2.3-1)
    """
    def __init__(self, port: str, rate: int):
        super().__init__(port, rate)
        # Sınıf üye verilerini tanımla [cite: 745-748]
        self.curtainStatus: float = 0.0          # Mevcut Perde Durumu [R2.2.1-2]
        self.outdoorTemperature: float = 0.0     # Dış Sıcaklık [R2.2.3-1]
        self.outdoorPressure: float = 0.0        # Dış Basınç [R2.2.3-2]
        self.lightIntensity: float = 0.0         # Işık Şiddeti [R2.2.2-1]
        self.desiredCurtain: float = 0.0         # İstenen Perde Durumu [R2.2.1-1]

    # --- YARDIMCI FONKSİYONLAR ---
    # K1'in API'sinde tanımlanan _bytes_to_float() gibi metodun aynısı kullanılabilir.
    def _bytes_to_float(self, integral_byte: int, fractional_byte: int) -> float:
        """PIC'ten gelen 6-bitlik tam ve kesirli kısımları float değere çevirir."""
        integral = integral_byte & 0x3F 
        fractional = fractional_byte & 0x3F 
        return float(integral) + float(fractional) / 10.0
        
    def _read_and_process(self, command_byte: int) -> int:
        """UART komutunu gönderir ve tek bir byte cevap okur. (Şimdilik sahte değerler)"""
        # --- GEÇİCİ ÇÖZÜM: Gerçek PIC kodu yokken veriyi takılmadan almasını sağla ---
        # Gerçek kod: self._connection.write(bytes([command_byte]))
        # Gerçek kod: response = self._connection.read(1)
        
        # Sahte Değerler: Dış Sıcaklık 18.2, Basınç 1010.5, Işık 500 Lux, Perde 50%
        if command_byte == GET_OUTDOOR_TEMP_HIGH: return 18
        if command_byte == GET_OUTDOOR_PRESS_HIGH: return 10
        if command_byte == GET_LIGHT_INTENSITY_HIGH: return 5
        
        # Kesirli Kısım için varsayılan değer
        if command_byte & 0b00000001: return 5 
        
        return 0 

    # --- ANA API FONKSİYONLARI ---

    def update(self) -> None:
        """
        Board #2'den tüm sensör ve perde verilerini günceller. (R2.3-1 - update)
        """
        # if not self._connection or not self._connection.is_open: return # Hata mesajını kaldırdık
        
        # 1. Dış Sıcaklık ve Basıncı Çek (Örnek: Sadece High Byte Çekiliyor)
        temp_int = self._read_and_process(GET_OUTDOOR_TEMP_HIGH)
        press_int = self._read_and_process(GET_OUTDOOR_PRESS_HIGH)
        
        # Gerçekte low byte'lar da çekilmeli, şimdilik sabit kesir atıyoruz:
        self.outdoorTemperature = self._bytes_to_float(temp_int, 2) # Örn: 18.2 °C
        self.outdoorPressure = self._bytes_to_float(press_int * 100, 5) # Örn: 1010.5 hPa

        # 2. Işık Şiddetini Çek
        light_int = self._read_and_process(GET_LIGHT_INTENSITY_HIGH)
        self.lightIntensity = float(light_int * 100) # Örn: 500 Lux

        # 3. Perde Durumunu Çek (Mevcut Durum)
        # Bu değer PIC'te 0-100% arası tutulur
        curtain_int = self._read_and_process(GET_DESIRED_CURTAIN_LOW) # Sadece 6 bitlik değeri okuyoruz
        self.curtainStatus = float(curtain_int) # Örn: 50%

    def setCurtainStatus(self, std: float) -> bool:
        """
        İstenen perde durumunu Board #2'ye gönderir. (R2.3-1 - setCurtainStatus)
        """
        # if not self._connection or not self._connection.is_open: return False # Hata mesajını kaldırdık

        # 0% (Açık) ile 100% (Kapalı) arası kontrolü (R2.2.4-1)
        if not (0.0 <= std <= 100.0):
            return False

        # Perde yüzdesini tam ve kesirli kısımlara ayırma
        integral = int(std)
        fractional = int(round((std - integral) * 10))

        # Komut Hazırlığı (UART SET komutları)
        integral_cmd_byte = SET_CURTAIN_HIGH_MASK | (integral & 0x3F) 
        fractional_cmd_byte = SET_CURTAIN_LOW_MASK | (fractional & 0x3F)

        # UART Üzerinden Gönderme (Gerçek kod: self._connection.write(...))
        
        self.desiredCurtain = std
        print(f"Hedef Perde Durumu API'de {std}% olarak ayarlandı. UART komutları GÖNDERİLMİŞ GİBİ YAPILDI.")
        return True

    # --- GET METOTLARI ---
    def getCurtainStatus(self) -> float:
        return self.curtainStatus
    
    def getOutdoorTemp(self) -> float:
        return self.outdoorTemperature
    
    def getOutdoorPress(self) -> float:
        return self.outdoorPressure
    
    def getLightIntensity(self) -> float:
        return self.lightIntensity