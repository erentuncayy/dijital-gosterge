# Mimari

## Bileşenler

| Bileşen | Dosya | Görevi |
|---|---|---|
| Duvar kağıdı | `wallpaper/index.html` | Canvas ile çizilen gösterge arayüzü |
| Ayarlar | `wallpaper/project.json` | Wallpaper Engine kullanıcı ayarları |
| Telemetri | `telemetri/PC-Telemetri.ps1` | Sistem verisini toplayıp yerel JSON sunar |
| Başlatıcılar | `telemetri/*.bat` | Başlatma, başlangıca ekleme, test |

## Telemetri veri formatı

`GET http://localhost:8765/` adresi her istekte en son toplanan veriyi döndürür. Veriler 2 saniyede bir yenilenir.

```json
{
  "cpu": 23.0,          // CPU yükü, %
  "ram": 58.2,          // kullanılan bellek, %
  "disk": 71.4,         // C: diski doluluk, %
  "temp": 52.0,         // CPU sıcaklığı, °C (okunamazsa null)
  "netType": "wifi",    // "wifi" | "ethernet" | "none"
  "signal": 84,         // Wi-Fi sinyal kalitesi, % (kabloluda 100)
  "ssid": "EvAgi_5G",   // ağ adı (kabloluda adaptör adı)
  "online": true,       // 1.1.1.1 / 8.8.8.8 ping başarılı mı
  "ping": 18,           // ms (çevrimdışıysa null)
  "down": 1.25,         // indirme, MB/s
  "up": 0.08,           // yükleme, MB/s
  "uptimeMin": 754.3    // bilgisayarın açık kalma süresi, dakika
}
```

Yanıt `Access-Control-Allow-Origin: *` başlığıyla gönderilir. Böylece `file://` üzerinden açılan duvar kağıdı veriyi okuyabilir.

### Sıcaklık kaynakları (sırayla denenir)

1. LibreHardwareMonitor web sunucusu: `http://localhost:8085/data.json`
2. LibreHardwareMonitor / OpenHardwareMonitor WMI ad alanı
3. Windows `MSAcpi_ThermalZoneTemperature` (bazı anakartlarda çalışır)

Kullanılan değer, *CPU Package*, *Tctl* ya da *Tdie* sensörlerinden en yüksek olanıdır.

### Wi-Fi

`netsh wlan show interfaces` çıktısındaki *Signal* / *Sinyal* satırı okunur. Türkçe ve İngilizce Windows desteklenir. Wi-Fi yoksa ve kablolu bağlantı varsa `ethernet` ve `signal: 100` döner.

## Duvar kağıdı tarafı

- **Veri bağlantısı:** `pollTele()` önce `localhost`, sonra `127.0.0.1` adresini dener. Üst üste 3 deneme başarısız olursa "veri yok" moduna geçer. Bu modda göstergeler sahte değer göstermez, `--` / `VERİ YOK` yazar ve servis ışığı yanar.
- **Medya:** Wallpaper Engine'in `wallpaperRegisterMediaPropertiesListener`, `...ThumbnailListener`, `...PlaybackListener` ve `...TimelineListener` API'leri kullanılır.
- **Ayarlar:** `window.wallpaperPropertyListener.applyUserProperties`
- **Katmanlar:**
  1. Arka plan
  2. İçerik (ayrı bir canvas'a çizilir, mod geçişinde bulanıklaşıp ölçeklenir)
  3. HTML katmanı (uyarı ışıkları, orta ekran)
  4. Cam katmanı (`#fx` canvas: yansıma, leke, doku)
- **Paralaks:** Katmanlar fare konumuna göre farklı miktarlarda kayar. Fare 4 saniye hareket etmezse katmanlar yavaşça süzülür.
