# Katkıda Bulunma Rehberi

Katkıların için teşekkürler! Hata bildirimi, yeni fikir, tasarım önerisi ya da kod: hepsine açığız.

## Hata bildirimi ve öneriler

[Issues](../../issues) sayfasında yeni bir kayıt aç. Mümkünse şunları ekle:

- Windows sürümü ve Wallpaper Engine sürümü
- Ekran görüntüsü
- Telemetriyle ilgili bir sorunsa `telemetri/telemetri-log.txt` dosyasının içeriği. Paylaşmadan önce Wi-Fi adın (SSID) gibi kişisel bilgileri silebilirsin.
- `http://localhost:8765/` adresinde ne göründüğü (`telemetri/Test-Et.bat` bu adresi açar)

## Kod katkısı

1. Depoyu **fork**'la ve yeni bir dal aç: `git checkout -b ozellik/gpu-gostergesi`
2. Değişikliğini yap ve tarayıcıda test et:
   - `wallpaper/index.html?demo` — örnek verilerle Klasik Kadran
   - `wallpaper/index.html?demo&sport` — Spor Kadran
3. Telemetri scriptini değiştirdiysen Windows PowerShell 5.1 ile dene. Yönetici yetkisi gerektirmemesine dikkat et.
4. Açıklayıcı bir commit mesajı yaz ve **Pull Request** aç. Görsel bir değişiklikse önce/sonra ekran görüntüsü ekle.

## Kod düzeni

- **`wallpaper/index.html`**: Bütün arayüz bu dosyada. Harici kütüphane kullanılmıyor, tek dosya kalmasını tercih ediyoruz.
  - Çizimler `<canvas>` üzerinde. Kadranlar `dial()`, spor barı `sportBar()`, yan göstergeler `ladder()`, cam katmanı `glass()` içinde.
  - Veriler tek bir `S` nesnesinde toplanıyor. Telemetri bağlantısı `pollTele()` içinde.
  - Yeni bir uyarı ışığı eklemek için `IC` (ikon), `LIGHTS` (liste) ve `ui()` içindeki koşulları güncelle.
- **`wallpaper/project.json`**: Wallpaper Engine ayarları (renk, mod, şehir...).
- **`telemetri/PC-Telemetri.ps1`**: Sistem verisini toplar ve `localhost:8765` adresinden JSON olarak sunar. Veri formatı [`docs/MIMARI.md`](docs/MIMARI.md) dosyasında.

## İlkeler

- **Gizlilik:** Telemetri yalnızca yerel bilgisayarda çalışır. Dışarıya veri gönderen bir değişiklik kabul edilmez.
- **Performans:** Duvar kağıdı sürekli çalışıyor. Ağır efektleri her karede yeniden hesaplamak yerine önceden üretmeyi tercih et.
- **Özgün tasarım:** Bir otomobil markasının gösterge tasarımını, logosunu ya da adını birebir kopyalayan katkılar kabul edilmez. İlham almak serbest, kopyalamak değil.
- **Türkçe öncelikli:** Arayüz metinleri Türkçe. İngilizce dil desteği yol haritasında var.

---

# Contributing (English)

Thanks for helping! Bug reports, ideas, design suggestions and code are all welcome.

- **Bugs and ideas:** open an Issue. Include your Windows and Wallpaper Engine versions, a screenshot and, for data problems, the contents of `telemetri/telemetri-log.txt` (remove your Wi-Fi name if you like). Also include what `http://localhost:8765/` shows; `telemetri/Test-Et.bat` opens that address.
- **Code:** fork the repo, create a branch, and test in a browser with `wallpaper/index.html?demo` and `?demo&sport`. Test telemetry changes on Windows PowerShell 5.1 without admin rights. Then open a pull request, with before/after screenshots for visual changes.
- **Code map:** the whole UI is `wallpaper/index.html`. It draws dials in `dial()`, the sport bar in `sportBar()`, the side gauges in `ladder()` and the glass layer in `glass()`. Data lives in the `S` object and the telemetry link is `pollTele()`. Wallpaper Engine settings are in `wallpaper/project.json`. The data collector is `telemetri/PC-Telemetri.ps1`.
- **Principles:** telemetry stays local, so changes that send data off the machine won't be accepted. Keep it light, because the wallpaper runs all the time. Keep designs original: contributions that copy a car maker's cluster design, logo or name won't be accepted. UI text is Turkish-first, and English support is on the roadmap.
