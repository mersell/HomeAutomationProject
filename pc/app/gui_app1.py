# pc/app/gui_app1.py - Akıllı Ev Otomasyon Sistemi (Multi-Page GUI)
# ===========================================================================
# Written and implemented by Şevval Ayça Çerence (Student ID: 152120211128).
# ===========================================================================
from tkinter import messagebox, Canvas
import tkinter as tk
from PIL import Image, ImageTk
import sys
import os

import ttkbootstrap as ttk
from ttkbootstrap.constants import *

# Add project root directory to sys.path to allow safe importing of API modules
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..')))

# API classes used for UART-based communication with the boards
from pc.api.air_conditioner import AirConditionerSystemConnection
from pc.api.curtain_control import CurtainControlSystemConnection

# =============================================================================
# GLOBAL CONFIGURATION PARAMETERS
# =============================================================================

COM_PORT_AC = 'COM8'
COM_PORT_CURTAIN = 'COM5'
BAUD_RATE = 9600

TEMP_MIN = 16.0
TEMP_MAX = 30.0

UPDATE_INTERVAL = 500

THEME_NAME = "superhero"


BG_PATH = os.path.join(os.path.dirname(__file__), "assets", "bg_house.png")
BG_OVERLAY_COLOR = (11, 26, 42)  
BG_OVERLAY_ALPHA = 0.85  

# Font
FONT_BASLIK = ("Segoe UI", 22, "bold")
FONT_ALT_BASLIK = ("Segoe UI", 12)
FONT_DEGER = ("Segoe UI", 13)
FONT_ETIKET = ("Segoe UI", 11)
FONT_KUCUK = ("Segoe UI", 10)


# =============================================================================
# ARKA PLAN FRAME (Canvas + Resim)
# =============================================================================
class ArkaplanFrame(tk.Frame):
    """Arka planda resim gösteren özel frame."""
    
    def __init__(self, parent):
        super().__init__(parent)
        
        self.bg_original = None
        self.bg_tk = None
        self._last_size = (0, 0)
        
       
        self.canvas = Canvas(self, highlightthickness=0, bd=0, bg="#0b1a2a")
        self.canvas.pack(fill="both", expand=True)
        
        
        self._load_image()
        
        
        self.bind("<Configure>", self._on_resize)
    
    def _load_image(self):
        """Arka plan resmini yükler."""
        try:
            if os.path.exists(BG_PATH):
                img = Image.open(BG_PATH).convert("RGBA")
                
                overlay = Image.new("RGBA", img.size, 
                                   (*BG_OVERLAY_COLOR, int(255 * BG_OVERLAY_ALPHA)))
                img = Image.alpha_composite(img, overlay)
                self.bg_original = img
                print(f"[Arka Plan] Resim yüklendi: {BG_PATH}")
            else:
                print(f"[Arka Plan] Resim bulunamadı: {BG_PATH}")
        except Exception as e:
            print(f"[Arka Plan] Yükleme hatası: {e}")
    
    def _on_resize(self, event=None):
        """Pencere boyutu değiştiğinde arka planı günceller."""
        w = self.winfo_width()
        h = self.winfo_height()
        
        if w < 50 or h < 50:
            return
        
        
        if (w, h) == self._last_size:
            return
        self._last_size = (w, h)
        
        if self.bg_original is None:
            return
        
        try:
            
            iw, ih = self.bg_original.size
            scale = max(w / iw, h / ih)
            nw, nh = int(iw * scale), int(ih * scale)
            
            resized = self.bg_original.resize((nw, nh), Image.LANCZOS)
            
            
            x1 = (nw - w) // 2
            y1 = (nh - h) // 2
            cropped = resized.crop((x1, y1, x1 + w, y1 + h))
            
            self.bg_tk = ImageTk.PhotoImage(cropped)
            self.canvas.delete("bg")
            self.canvas.create_image(0, 0, image=self.bg_tk, anchor="nw", tags="bg")
        except Exception as e:
            print(f"[Arka Plan] Resize hatası: {e}")


# =============================================================================
# MAIN APPLICATION CLASS
# =============================================================================

class AkilliEvApp:
    """Ana controller sınıfı."""
    
    def __init__(self):
        
        self.root = tk.Tk()
        self.root.title("Akıllı Ev Otomasyon Sistemi")
        self.root.geometry("950x680")
        self.root.minsize(850, 600)
        self.root.configure(bg="#0b1a2a")
        
       
        self.style = ttk.Style(THEME_NAME)
        
        self.bg_frame = ArkaplanFrame(self.root)
        self.bg_frame.place(x=0, y=0, relwidth=1, relheight=1)
        
        self.container = ttk.Frame(self.root)
        self.container.place(x=0, y=0, relwidth=1, relheight=1)
        self.container.grid_rowconfigure(0, weight=1)
        self.container.grid_columnconfigure(0, weight=1)
        
        
        self.klima_api = None
        self.perde_api = None
        self.klima_bagli = False
        self.perde_bagli = False
        
        self._baglantilari_kur()
        
        if not self.klima_bagli and not self.perde_bagli:
            messagebox.showerror(
                "Bağlantı Hatası",
                "Hiçbir kart ile bağlantı kurulamadı.\n\n"
                f"Board #1 (Klima): {COM_PORT_AC}\n"
                f"Board #2 (Perde): {COM_PORT_CURTAIN}\n\n"
                "COM port ayarlarını kontrol edin."
            )
            self.root.destroy()
            return
        
        self._update_job = None
        
        # Create and register all application page frames
        self.frames = {}
        for FrameClass in (AnaMenuFrame, KlimaFrame, PerdeFrame):
            frame = FrameClass(self.container, self)
            self.frames[FrameClass.__name__] = frame
            frame.grid(row=0, column=0, sticky="nsew")
        
        self.sayfa_goster("AnaMenuFrame")
        self.root.protocol("WM_DELETE_WINDOW", self.kapat)
    
    def _baglantilari_kur(self):
        """API bağlantılarını açar."""
        if COM_PORT_AC:
            try:
                self.klima_api = AirConditionerSystemConnection(COM_PORT_AC, BAUD_RATE)
                if self.klima_api.open():
                    self.klima_bagli = True
                    print(f"[Klima] {COM_PORT_AC} bağlantısı başarılı")
                else:
                    self.klima_api = None
                    print(f"[Klima] {COM_PORT_AC} açılamadı")
            except Exception as e:
                self.klima_api = None
                print(f"[Klima] Bağlantı hatası: {e}")
        
        if COM_PORT_CURTAIN:
            try:
                self.perde_api = CurtainControlSystemConnection(COM_PORT_CURTAIN, BAUD_RATE)
                if self.perde_api.open():
                    self.perde_bagli = True
                    print(f"[Perde] {COM_PORT_CURTAIN} bağlantısı başarılı")
                else:
                    self.perde_api = None
                    print(f"[Perde] {COM_PORT_CURTAIN} açılamadı")
            except Exception as e:
                self.perde_api = None
                print(f"[Perde] Bağlantı hatası: {e}")
    
    def sayfa_goster(self, sayfa_adi: str):
        """Belirtilen sayfayı gösterir."""
        if self._update_job:
            self.root.after_cancel(self._update_job)
            self._update_job = None
        
        frame = self.frames.get(sayfa_adi)
        if frame:
            frame.tkraise()
            if hasattr(frame, "aktif_ol"):
                frame.aktif_ol()
    
    def guncelleme_planla(self, callback, aralik=UPDATE_INTERVAL):
        self._update_job = self.root.after(aralik, callback)
    
    def kapat(self):
        if self._update_job:
            self.root.after_cancel(self._update_job)
        
        try:
            if self.klima_api:
                self.klima_api.close()
        except:
            pass
        
        try:
            if self.perde_api:
                self.perde_api.close()
        except:
            pass
        
        self.root.destroy()
    
    def calistir(self):
        self.root.mainloop()


# =============================================================================
# MAIN MENU FRAME
# =============================================================================

class AnaMenuFrame(ttk.Frame):
    """Ana Menü Ekranı."""
    
    def __init__(self, parent, controller):
        super().__init__(parent)
        self.controller = controller
        
        self.grid_rowconfigure(0, weight=1)
        self.grid_rowconfigure(1, weight=3)
        self.grid_rowconfigure(2, weight=1)
        self.grid_columnconfigure(0, weight=1)
        
        self._arayuz_olustur()
    
    def _arayuz_olustur(self):
        
        baslik_frame = ttk.Frame(self)
        baslik_frame.grid(row=0, column=0, sticky="s", pady=(40, 20))
        
        ttk.Label(
            baslik_frame,
            text="🏠 Akıllı Ev Otomasyon Sistemi",
            font=FONT_BASLIK,
            foreground="white"
        ).pack()
        
        ttk.Label(
            baslik_frame,
            text="Ana Menü",
            font=FONT_ALT_BASLIK,
            foreground="#8899aa"
        ).pack(pady=(10, 0))
        
        
        kartlar = ttk.Frame(self)
        kartlar.grid(row=1, column=0, sticky="n", pady=20)
        
        
        klima_kart = ttk.Labelframe(kartlar, text="❄️ Klima Kontrol", padding=20, bootstyle="info")
        klima_kart.grid(row=0, column=0, padx=20, pady=10, sticky="nsew")
        
        self.lbl_ortam = ttk.Label(klima_kart, text="Ortam Sıcaklığı: N/A", font=FONT_ETIKET)
        self.lbl_ortam.pack(anchor="w", pady=4)
        
        self.lbl_hedef = ttk.Label(klima_kart, text="Hedef Sıcaklık: N/A", font=FONT_ETIKET)
        self.lbl_hedef.pack(anchor="w", pady=4)
        
        self.lbl_fan = ttk.Label(klima_kart, text="Fan Hızı: N/A", font=FONT_ETIKET)
        self.lbl_fan.pack(anchor="w", pady=4)
        
        ttk.Separator(klima_kart, orient="horizontal").pack(fill="x", pady=15)
        
        ttk.Button(
            klima_kart, text="Ayarla",
            command=lambda: self.controller.sayfa_goster("KlimaFrame"),
            bootstyle="info-outline", width=18
        ).pack()
        
        
        perde_kart = ttk.Labelframe(kartlar, text="🪟 Perde Kontrol", padding=20, bootstyle="success")
        perde_kart.grid(row=0, column=1, padx=20, pady=10, sticky="nsew")
        
        self.lbl_isik = ttk.Label(perde_kart, text="Işık Şiddeti: N/A", font=FONT_ETIKET)
        self.lbl_isik.pack(anchor="w", pady=4)
        
        self.lbl_perde_hedef = ttk.Label(perde_kart, text="Hedef Perde: N/A", font=FONT_ETIKET)
        self.lbl_perde_hedef.pack(anchor="w", pady=4)
        
        self.lbl_perde_mevcut = ttk.Label(perde_kart, text="Mevcut Perde: N/A", font=FONT_ETIKET)
        self.lbl_perde_mevcut.pack(anchor="w", pady=4)
        
        ttk.Separator(perde_kart, orient="horizontal").pack(fill="x", pady=15)
        
        ttk.Button(
            perde_kart, text="Ayarla",
            command=lambda: self.controller.sayfa_goster("PerdeFrame"),
            bootstyle="success-outline", width=18
        ).pack()
        
        # ===== EXIT =====
        cikis = ttk.Frame(self)
        cikis.grid(row=2, column=0, sticky="n", pady=30)
        
        ttk.Button(cikis, text="🚪 Çıkış", command=self.controller.kapat,
                   bootstyle="danger-outline", width=15).pack()
    
    def aktif_ol(self):
        self._verileri_guncelle()
    
    def _verileri_guncelle(self):
        # air conditioner
        api = self.controller.klima_api
        if api and self.controller.klima_bagli:
            try:
                api.update()
                self.lbl_ortam.config(text=f"Ortam Sıcaklığı: {api.getAmbientTemp():.1f} °C")
                self.lbl_hedef.config(text=f"Hedef Sıcaklık: {api.getDesiredTemp():.1f} °C")
                self.lbl_fan.config(text=f"Fan Hızı: {api.getFanSpeed()} rps")
            except:
                self._klima_na()
        else:
            self._klima_na()
        
        # Curtain
        api = self.controller.perde_api
        if api and self.controller.perde_bagli:
            try:
                api.update()
                self.lbl_isik.config(text=f"Işık Şiddeti: {api.getLightIntensity():.0f} Lux")
                self.lbl_perde_hedef.config(text=f"Hedef Perde: {api.getDesiredCurtain():.1f}%")
                self.lbl_perde_mevcut.config(text=f"Mevcut Perde: {api.getCurtainStatus():.1f}%")
            except:
                self._perde_na()
        else:
            self._perde_na()
        
        self.controller.guncelleme_planla(self._verileri_guncelle)
    
    def _klima_na(self):
        self.lbl_ortam.config(text="Ortam Sıcaklığı: N/A")
        self.lbl_hedef.config(text="Hedef Sıcaklık: N/A")
        self.lbl_fan.config(text="Fan Hızı: N/A")
    
    def _perde_na(self):
        self.lbl_isik.config(text="Işık Şiddeti: N/A")
        self.lbl_perde_hedef.config(text="Hedef Perde: N/A")
        self.lbl_perde_mevcut.config(text="Mevcut Perde: N/A")


# =============================================================================
# AIR CONDITIONER FRAME
# =============================================================================
class KlimaFrame(ttk.Frame):
    """Klima Kontrol Ekranı."""
    
    def __init__(self, parent, controller):
        super().__init__(parent)
        self.controller = controller
        
        self.grid_rowconfigure(1, weight=1)
        self.grid_columnconfigure(0, weight=1)
        
        self._arayuz_olustur()
    
    def _arayuz_olustur(self):
        
        ust = ttk.Frame(self)
        ust.grid(row=0, column=0, sticky="ew", padx=20, pady=15)
        
        ttk.Button(ust, text="◀ Geri",
                   command=lambda: self.controller.sayfa_goster("AnaMenuFrame"),
                   bootstyle="secondary-outline", width=12).pack(side="left")
        
        ttk.Label(ust, text="❄️ Klima Kontrol", font=FONT_BASLIK,
                  foreground="white").pack(side="left", padx=25)
        
       
        icerik = ttk.Frame(self)
        icerik.grid(row=1, column=0, sticky="n", padx=40, pady=10)
        
        # Sensor measurement data

        veri = ttk.Labelframe(icerik, text="📊 Sensör Verileri", padding=20, bootstyle="info")
        veri.pack(fill="x", pady=12)
        
        self.lbl_ortam = ttk.Label(veri, text="Ortam Sıcaklığı: N/A", font=FONT_DEGER)
        self.lbl_ortam.pack(anchor="w", pady=6)
        
        self.lbl_hedef = ttk.Label(veri, text="Hedef Sıcaklık: N/A", font=FONT_DEGER)
        self.lbl_hedef.pack(anchor="w", pady=6)
        
        self.lbl_fan = ttk.Label(veri, text="Fan Hızı: N/A", font=FONT_DEGER)
        self.lbl_fan.pack(anchor="w", pady=6)
        
        # Serial communication connection information

        bag = ttk.Labelframe(icerik, text="📡 Bağlantı Bilgileri", padding=15, bootstyle="secondary")
        bag.pack(fill="x", pady=12)
        
        bag_row = ttk.Frame(bag)
        bag_row.pack()
        ttk.Label(bag_row, text=f"Port: {COM_PORT_AC}", font=FONT_ETIKET).pack(side="left", padx=20)
        ttk.Label(bag_row, text=f"Hız: {BAUD_RATE}", font=FONT_ETIKET).pack(side="left", padx=20)
        
        # Desired temperature setting

        ayar = ttk.Labelframe(icerik, text="🌡️ Hedef Sıcaklık Ayarı", padding=20, bootstyle="primary")
        ayar.pack(fill="x", pady=12)
        
        giris = ttk.Frame(ayar)
        giris.pack(pady=10)
        
        ttk.Label(giris, text=f"Sıcaklık ({TEMP_MIN:.0f}-{TEMP_MAX:.0f} °C):", font=FONT_ETIKET).pack(side="left", padx=5)
        
        self.sicaklik_entry = ttk.Entry(giris, width=10, font=FONT_ETIKET)
        self.sicaklik_entry.pack(side="left", padx=10)
        
        self.uygula_btn = ttk.Button(giris, text="Uygula", command=self._sicaklik_uygula,
                                     bootstyle="success", width=12)
        self.uygula_btn.pack(side="left", padx=10)
        
        if not self.controller.klima_bagli:
            self.uygula_btn.config(state="disabled")
            ttk.Label(ayar, text="⚠️ Klima kartı bağlı değil", font=FONT_KUCUK, bootstyle="warning").pack()
    
    def aktif_ol(self):
        self._verileri_guncelle()
    
    def _verileri_guncelle(self):
        api = self.controller.klima_api
        if api and self.controller.klima_bagli:
            try:
                api.update()
                self.lbl_ortam.config(text=f"Ortam Sıcaklığı: {api.getAmbientTemp():.1f} °C")
                self.lbl_hedef.config(text=f"Hedef Sıcaklık: {api.getDesiredTemp():.1f} °C")
                self.lbl_fan.config(text=f"Fan Hızı: {api.getFanSpeed()} rps")
            except:
                self._na()
        else:
            self._na()
        self.controller.guncelleme_planla(self._verileri_guncelle)
    
    def _na(self):
        self.lbl_ortam.config(text="Ortam Sıcaklığı: N/A")
        self.lbl_hedef.config(text="Hedef Sıcaklık: N/A")
        self.lbl_fan.config(text="Fan Hızı: N/A")
    
    def _sicaklik_uygula(self):
        deger = self.sicaklik_entry.get().strip()
        if not deger:
            messagebox.showerror("Hata", "Lütfen bir sıcaklık değeri giriniz.")
            return
        try:
            sicaklik = float(deger)
        except:
            messagebox.showerror("Hata", "Geçersiz değer! Sayısal bir değer giriniz.")
            return
        if sicaklik < TEMP_MIN or sicaklik > TEMP_MAX:
            messagebox.showerror("Hata", f"Sıcaklık {TEMP_MIN:.0f}-{TEMP_MAX:.0f}°C arasında olmalı.")
            return
        
        api = self.controller.klima_api
        if api and api.setDesiredTemp(round(sicaklik, 1)):
            messagebox.showinfo("Başarılı", f"Hedef sıcaklık {sicaklik:.1f}°C ayarlandı.")
            self.sicaklik_entry.delete(0, 'end')
        else:
            messagebox.showerror("Hata", "Sıcaklık ayarlanamadı.")


# =============================================================================
# CURTAIN FRAME
# =============================================================================
class PerdeFrame(ttk.Frame):
    """Perde & Dış Ortam Kontrol. SLIDER YOK."""
    
    def __init__(self, parent, controller):
        super().__init__(parent)
        self.controller = controller
        
        self.grid_rowconfigure(1, weight=1)
        self.grid_columnconfigure(0, weight=1)
        
        self._arayuz_olustur()
    
    def _arayuz_olustur(self):
      
        ust = ttk.Frame(self)
        ust.grid(row=0, column=0, sticky="ew", padx=20, pady=15)
        
        ttk.Button(ust, text="◀ Geri",
                   command=lambda: self.controller.sayfa_goster("AnaMenuFrame"),
                   bootstyle="secondary-outline", width=12).pack(side="left")
        
        ttk.Label(ust, text="🪟 Perde & Dış Ortam", font=FONT_BASLIK,
                  foreground="white").pack(side="left", padx=25)
        
        
        icerik = ttk.Frame(self)
        icerik.grid(row=1, column=0, sticky="n", padx=40, pady=10)
        
        
        dis = ttk.Labelframe(icerik, text="🌤️ Dış Ortam Verileri", padding=15, bootstyle="info")
        dis.pack(fill="x", pady=10)
        
        dis_row = ttk.Frame(dis)
        dis_row.pack()
        
        self.lbl_dis_sicaklik = ttk.Label(dis_row, text="Dış Sıcaklık: N/A", font=FONT_DEGER)
        self.lbl_dis_sicaklik.pack(side="left", padx=15)
        
        self.lbl_dis_basinc = ttk.Label(dis_row, text="Dış Basınç: N/A", font=FONT_DEGER)
        self.lbl_dis_basinc.pack(side="left", padx=15)
        
        self.lbl_isik = ttk.Label(dis_row, text="Işık Şiddeti: N/A", font=FONT_DEGER)
        self.lbl_isik.pack(side="left", padx=15)
        
        # Curtain status
        perde = ttk.Labelframe(icerik, text="🪟 Perde Durumu", padding=15, bootstyle="success")
        perde.pack(fill="x", pady=10)
        
        perde_row = ttk.Frame(perde)
        perde_row.pack()
        
        self.lbl_perde_hedef = ttk.Label(perde_row, text="Hedef: N/A", font=FONT_DEGER)
        self.lbl_perde_hedef.pack(side="left", padx=25)
        
        self.lbl_perde_mevcut = ttk.Label(perde_row, text="Mevcut: N/A", font=FONT_DEGER)
        self.lbl_perde_mevcut.pack(side="left", padx=25)
        
        
        bag = ttk.Labelframe(icerik, text="📡 Bağlantı Bilgileri", padding=15, bootstyle="secondary")
        bag.pack(fill="x", pady=10)
        
        bag_row = ttk.Frame(bag)
        bag_row.pack()
        ttk.Label(bag_row, text=f"Port: {COM_PORT_CURTAIN}", font=FONT_ETIKET).pack(side="left", padx=20)
        ttk.Label(bag_row, text=f"Hız: {BAUD_RATE}", font=FONT_ETIKET).pack(side="left", padx=20)
        
        # Curtaın setting
        ayar = ttk.Labelframe(icerik, text="🎚️ Hedef Perde Ayarı", padding=20, bootstyle="primary")
        ayar.pack(fill="x", pady=10)
        
        giris = ttk.Frame(ayar)
        giris.pack(pady=10)
        
        ttk.Label(giris, text="Perde Açıklığı (0-100 %):", font=FONT_ETIKET).pack(side="left", padx=5)
        
        self.perde_entry = ttk.Entry(giris, width=10, font=FONT_ETIKET)
        self.perde_entry.pack(side="left", padx=10)
        
        self.uygula_btn = ttk.Button(giris, text="Uygula", command=self._perde_uygula,
                                     bootstyle="success", width=12)
        self.uygula_btn.pack(side="left", padx=10)
        
        if not self.controller.perde_bagli:
            self.uygula_btn.config(state="disabled")
            ttk.Label(ayar, text="⚠️ Perde kartı bağlı değil", font=FONT_KUCUK, bootstyle="warning").pack()
    
    def aktif_ol(self):
        self._verileri_guncelle()
    
    def _verileri_guncelle(self):
        api = self.controller.perde_api
        if api and self.controller.perde_bagli:
            try:
                api.update()
                self.lbl_dis_sicaklik.config(text=f"Dış Sıcaklık: {api.getOutdoorTemp():.1f} °C")
                self.lbl_dis_basinc.config(text=f"Dış Basınç: {api.getOutdoorPress():.1f} hPa")
                self.lbl_isik.config(text=f"Işık Şiddeti: {api.getLightIntensity():.0f} Lux")
                self.lbl_perde_hedef.config(text=f"Hedef: {api.getDesiredCurtain():.1f}%")
                self.lbl_perde_mevcut.config(text=f"Mevcut: {api.getCurtainStatus():.1f}%")
            except:
                self._na()
        else:
            self._na()
        self.controller.guncelleme_planla(self._verileri_guncelle)
    
    def _na(self):
        self.lbl_dis_sicaklik.config(text="Dış Sıcaklık: N/A")
        self.lbl_dis_basinc.config(text="Dış Basınç: N/A")
        self.lbl_isik.config(text="Işık Şiddeti: N/A")
        self.lbl_perde_hedef.config(text="Hedef: N/A")
        self.lbl_perde_mevcut.config(text="Mevcut: N/A")
    
    def _perde_uygula(self):
        deger = self.perde_entry.get().strip()
        if not deger:
            messagebox.showerror("Hata", "Lütfen bir yüzde değeri giriniz.")
            return
        try:
            yuzde = float(deger)
        except:
            messagebox.showerror("Hata", "Geçersiz değer! 0-100 arası sayı giriniz.")
            return
        if yuzde < 0 or yuzde > 100:
            messagebox.showerror("Hata", "Yüzde 0-100 arasında olmalı.")
            return
        
        api = self.controller.perde_api
        if api and api.setCurtainStatus(round(yuzde, 1)):
            messagebox.showinfo("Başarılı", f"Hedef perde %{yuzde:.1f} ayarlandı.")
            self.perde_entry.delete(0, 'end')
        else:
            messagebox.showerror("Hata", "Perde ayarlanamadı.")

# =============================================================================
# APPLICATION STARTUP
# =============================================================================

if __name__ == "__main__":
    print("=" * 60)
    print("Akıllı Ev Otomasyon Sistemi - GUI")
    print(f"Board #1 (Klima): {COM_PORT_AC}")
    print(f"Board #2 (Perde): {COM_PORT_CURTAIN}")
    print(f"Arka plan: {BG_PATH}")
    print("=" * 60)
    
    app = AkilliEvApp()
    app.calistir()
