[Türkçe](README.tr.md) | [English](README.md)

# AGGuard — Kendi Sunucunda Ev Ağı Geçidi

Tek VPS üzerinde birleşik ev ağı geçidi:

- **Ağ geneli reklam engelleme** — her cihaz, sıfır istemci ayarı (WireGuard tüneli üzerinden AdGuard Home)
- **Seçici yönlendirme** — engelli domainler Tor'dan çıkar; diğer her şey ev ISS'inden akar
- **Kendi kendini öğrenen engel listesi** — ziyaret edilen domainler otomatik tespit edilip yönlendirilir
  (hem DNS zehirleme hem SNI/TLS reset engellerini yakalar)
- **Tek komutla onarım** — restore.sh her kesinti sonrası her şeyi yeniden senkronlar

## Mimari

    İstemci cihazlar
          |
          v
    Ev router (WireGuard istemci)
          |  rotalar: engelli IP'ler -> tünel
          v
    VPS geçidi (tek sunucu)
          |- AdGuard Home --> DNS cevapları (reklamlar = 0.0.0.0)
          |- redsocks --> Tor (SOCKS5) --> engelli site trafiği buradan çıkar
          +- policy routing --> normal trafik ev ISS'inden çıkar

## Tespit nasıl çalışır

| Engelleme tipi | Dedektör | Nerede |
|---|---|---|
| DNS zehirleme | Sunucu watcher'ı: temiz çözücü vs İSS çözücüsü karşılaştırması | VPS |
| SNI / TLS reset | Windows istemci: TCP bağlanır + TLS reset = engelli | PC |

Her iki dedektör de domaini geçide iter; geçit router rota tablosuna ekler.

## Kurulum (özet)

1. **VPS**: WireGuard, AdGuard Home (host network), Tor + redsocks
2. **Router**: VPS'e WG tünelleri — biri public (trafik), biri private (yönetim)
3. **Router DNS**: çözücüyü AdGuard Home'a (tünel IP) bağla
4. **Statik rotalar**: engelli IP'leri tünelden yönlendir
5. **İstemci yardımcısı (opsiyonel, Windows)**: DNS cache izleyici

## Script'ler

| Script | Görevi |
|---|---|
| scripts/watch.sh | sorgu log izleyici |
| scripts/ban.sh | elle ban |
| scripts/restore.sh | tam restore |
| scripts/cleanup-routes.sh | rota temizliği |
| client/ban-helper.ps1 | Windows dedektör |

## Sorumluluk reddi

Kişisel kullanım projesi. Yaşadığın yargı bölgesinin yasalarına uymak sana aittir. Garanti yok.
