# pc/app/gui_app.py - Final Sürümü (Sıcaklık ve Perde için Manuel Giriş Destekli)

from tkinter import messagebox
import sys
import os

# YENİ: ttkbootstrap (ttk) import edilir
import ttkbootstrap as ttk
from ttkbootstrap.constants import *
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..')))

# K1 tarafından yazılan API sınıflarını içe aktar
from pc.api.air_conditioner import AirConditionerSystemConnection
from pc.api.curtain_control import CurtainControlSystemConnection 

# --- GLOBAL AYARLAR ---
COM_PORT = 'COM17'  # Lütfen burayı kendi sanal portunuzun PC tarafına ayarlayın!
BAUD_RATE = 9600
UPDATE_INTERVAL = 2000 # MS cinsinden (2 saniye)

class HomeAutomationGUI:
    def __init__(self):
        self.master = ttk.Window(themename="superhero") 
        master = self.master 
        
        master.title("ESOGU Home Automation System")
        master.geometry("650x650")
        
        self.ac_system = AirConditionerSystemConnection(COM_PORT, BAUD_RATE)
        self.curtain_system = CurtainControlSystemConnection(COM_PORT, BAUD_RATE)
        
        if not self.ac_system.open():
            messagebox.showerror("Hata", "Seri Port Bağlantısı Başlatılamadı!")
            master.destroy()
            return
        
        self.create_widgets()
        self.master.after(UPDATE_INTERVAL, self.auto_update_data)
        master.protocol("WM_DELETE_WINDOW", self.on_closing) 


    def create_widgets(self):
        """GUI bileşenlerini (Label, Buton, Slider, Entry) oluşturur."""
        
        # --- 1. KLİMA KONTROL ÇERÇEVESİ (BOARD #1) ---
        ac_frame = ttk.Labelframe(self.master, text="Klima Kontrol (Board #1)", padding=20, bootstyle="info")
        ac_frame.pack(padx=10, pady=10, fill="x")

        # 1.1 Veri Etiketleri
        self.ambient_temp_label = self.add_label(ac_frame, "Ortam Sıcaklığı: N/A")
        self.desired_temp_label = self.add_label(ac_frame, "Hedef Sıcaklık: N/A")
        self.fan_speed_label = self.add_label(ac_frame, "Fan Hızı: N/A")

        # 1.2 Sıcaklık Ayar Girişi (SLIDER + MANUEL GİRİŞ)
        
        # Slider ve Buton Grubu
        slider_frame = ttk.Frame(ac_frame)
        slider_frame.pack(pady=10)

        ttk.Label(slider_frame, text="Slider Ayarı (°C):").pack(side="left", padx=5)
        self.slider_value_label = ttk.Label(slider_frame, text="25.0", width=4)
        self.slider_value_label.pack(side="left", padx=5)
        
        self.temp_slider = ttk.Scale(slider_frame, 
                                     from_=10.0, to=50.0, 
                                     orient="horizontal",
                                     command=self.update_slider_label, 
                                     length=200, 
                                     bootstyle="info")
        self.temp_slider.set(25.0) 
        self.temp_slider.pack(side="left", padx=10)
        
        set_slider_button = ttk.Button(slider_frame, text="SLIDER İLE AYARLA", command=self.set_desired_temp_slider, bootstyle="success")
        set_slider_button.pack(side="left", padx=5)

        # Manuel Giriş Grubu
        manual_temp_frame = ttk.Frame(ac_frame)
        manual_temp_frame.pack(pady=10)
        
        ttk.Label(manual_temp_frame, text="Veya Manuel Giriş (°C):").pack(side="left", padx=5)
        self.manual_temp_entry = ttk.Entry(manual_temp_frame, width=10)
        self.manual_temp_entry.pack(side="left", padx=5)
        
        set_manual_temp_button = ttk.Button(manual_temp_frame, text="MANUEL AYARLA", command=self.set_desired_temp_manual, bootstyle="primary")
        set_manual_temp_button.pack(side="left", padx=5)

        
        # --- 2. PERDE & DIŞ ORTAM KONTROL ÇERÇEVESİ (BOARD #2) ---
        curtain_frame = ttk.Labelframe(self.master, text="Perde & Dış Ortam (Board #2)", padding=20, bootstyle="primary")
        curtain_frame.pack(padx=10, pady=10, fill="x")

        # 2.1 Veri Etiketleri
        self.outdoor_temp_label = self.add_label(curtain_frame, "Dış Sıcaklık: N/A")
        self.outdoor_press_label = self.add_label(curtain_frame, "Dış Basınç: N/A")
        self.light_intensity_label = self.add_label(curtain_frame, "Işık Şiddeti: N/A")
        self.curtain_status_label = self.add_label(curtain_frame, "Perde Durumu: N/A")

        # 2.2 Perde Ayar Kontrolü (3 BUTON + MANUEL GİRİŞ)
        
        # Sabit Butonlar
        btn_frame = ttk.Frame(curtain_frame)
        btn_frame.pack(pady=10)

        ttk.Button(btn_frame, text="AÇ (0%)", command=lambda: self.set_desired_curtain_api(0.0), bootstyle="success").pack(side="left", padx=5)
        ttk.Button(btn_frame, text="KAPAT (100%)", command=lambda: self.set_desired_curtain_api(100.0), bootstyle="danger").pack(side="left", padx=5)
        ttk.Button(btn_frame, text="YARIM (50%)", command=lambda: self.set_desired_curtain_api(50.0), bootstyle="secondary").pack(side="left", padx=5)

        # Manuel Giriş Grubu
        manual_curtain_frame = ttk.Frame(curtain_frame)
        manual_curtain_frame.pack(pady=10)
        
        ttk.Label(manual_curtain_frame, text="Veya Manuel Giriş (%):").pack(side="left", padx=5)
        self.manual_curtain_entry = ttk.Entry(manual_curtain_frame, width=10)
        self.manual_curtain_entry.pack(side="left", padx=5)
        
        set_manual_curtain_button = ttk.Button(manual_curtain_frame, text="MANUEL AYARLA", command=self.set_desired_curtain_manual, bootstyle="primary")
        set_manual_curtain_button.pack(side="left", padx=5)


    def add_label(self, frame, text):
        """Kolayca Label eklemek için yardımcı fonksiyon."""
        label = ttk.Label(frame, text=text, anchor="w", font=("Helvetica", 12))
        label.pack(fill="x", pady=5)
        return label
    
    def update_slider_label(self, value):
        """Slider kaydırıldıkça yanındaki Label'ı günceller."""
        self.slider_value_label.config(text=f"{float(value):.1f}")


    def auto_update_data(self):
        """K1'in update() metodunu çağırır ve GUI'yi günceller."""
        self.ac_system.update()
        self.curtain_system.update() 
        
        # Board #1 verilerini GUI'ye yansıtma
        self.ambient_temp_label.config(text=f"Ortam Sıcaklığı: {self.ac_system.getAmbientTemp():.1f} °C")
        self.desired_temp_label.config(text=f"Hedef Sıcaklık: {self.ac_system.getDesiredTemp():.1f} °C")
        self.fan_speed_label.config(text=f"Fan Hızı: {self.ac_system.getFanSpeed()} rps")

        # Board #2 verilerini GUI'ye yansıtma
        self.outdoor_temp_label.config(text=f"Dış Sıcaklık: {self.curtain_system.getOutdoorTemp():.1f} °C")
        self.outdoor_press_label.config(text=f"Dış Basınç: {self.curtain_system.getOutdoorPress():.1f} hPa")
        self.light_intensity_label.config(text=f"Işık Şiddeti: {self.curtain_system.getLightIntensity():.1f} Lux")
        self.curtain_status_label.config(text=f"Perde Durumu: {self.curtain_system.getCurtainStatus():.1f} %")
        
        self.master.after(UPDATE_INTERVAL, self.auto_update_data)

    # --- SICAKLIK AYAR METOTLARI (Slider ve Manuel) ---

    def set_desired_temp_slider(self):
        """Sıcaklığı SLIDER'dan alır ve API'ye yollar."""
        desired_temp = float(self.temp_slider.get())
        desired_temp = round(desired_temp, 1) 
        self._send_temp_to_api(desired_temp)

    def set_desired_temp_manual(self):
        """Sıcaklığı MANUEL GİRİŞ kutusundan alır ve API'ye yollar."""
        try:
            desired_temp = float(self.manual_temp_entry.get())
            self._send_temp_to_api(desired_temp)
        except ValueError:
            messagebox.showerror("Hata", "Lütfen Manuel Giriş için geçerli bir sayı giriniz.")

    def _send_temp_to_api(self, desired_temp: float):
        """Ortak API'ye gönderme mantığı."""
        if self.ac_system.setDesiredTemp(desired_temp):
            messagebox.showinfo("Başarılı", f"Hedef sıcaklık {desired_temp}°C olarak ayarlandı.")
        else:
            messagebox.showerror("Hata", f"Sıcaklık {desired_temp}°C, geçerli aralık (10.0-50.0) dışında.")
            
    # --- PERDE AYAR METOTLARI (Buton ve Manuel) ---
    
    def set_desired_curtain_api(self, percentage: float):
        """BUTONLARDAN gelen sabit perde değerini API'ye yollar."""
        self._send_curtain_to_api(percentage)

    def set_desired_curtain_manual(self):
        """PERDEYİ MANUEL GİRİŞ kutusundan alır ve API'ye yollar."""
        try:
            desired_curtain = float(self.manual_curtain_entry.get())
            self._send_curtain_to_api(desired_curtain)
        except ValueError:
            messagebox.showerror("Hata", "Lütfen Manuel Giriş için geçerli bir sayı giriniz.")

    def _send_curtain_to_api(self, percentage: float):
        """Ortak API'ye gönderme mantığı."""
        if self.curtain_system.setCurtainStatus(percentage):
            messagebox.showinfo("Başarılı", f"Hedef perde durumu %{percentage:.1f} olarak ayarlandı.")
        else:
            messagebox.showerror("Hata", f"Perde durumu %{percentage:.1f}, geçerli aralık (0-100) dışında.")
            
    def on_closing(self):
        """Pencere kapatıldığında her iki bağlantıyı da kapatır."""
        self.ac_system.close()
        self.curtain_system.close() 
        self.master.destroy()

# --- Uygulamayı Başlatma ---
if __name__ == "__main__":
    app = HomeAutomationGUI()
    app.master.mainloop()