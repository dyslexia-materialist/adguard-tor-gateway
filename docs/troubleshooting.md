# Troubleshooting — hard-won gotchas

1. **Keenetic WG recreate → random key**: arayüz silinip yeniden yaratılınca
   Keenetic rastgele private key üretir. Set et: `wireguard private-key <key>`,
   doğrula: `show interface` → public-key beklenen değere dönmeli.

2. **/24 vs /32 çakışması**: iki WG arayüzü aynı alt ağda /24 maskeli olursa
   ikisi de çakışma (conflict) yüzünden kalkmaz. Her ikisini `/32` yap.

3. **Cryptokey routing (allow-ips)**: peer'da `allow-ips` boşsa handshake
   kurulur AMA tüm veri paketleri sessizce düşer (handshake canlı görünür!).
   Trafik geçmiyorsa önce allow-ips'e bak.

4. **listen-port churn**: WG arayüzü her down/up'ta yeni listen-port alır.
   Karşı taraf endpoint'i handshake'ten öğrenir — keepalive atıldığı sürece
   toparlanır.

5. **MTU/MSS blackhole**: TCP SYN'de mss 1460 pazarlanırsa sunucu 1500'lük
   segment gönderir → tünel MTU'suna sığmaz → SACK'ta büyük segment kayıp,
   küçük gelenir (tcpdump kanıtı). Fix: her iki yönde TCPMSS clamp.

6. **redsocks bind adresi**: REDIRECT, hedefi gelen arayüzün adresine çevirir.
   redsocks `127.0.0.1` değil, **WG arayüz adresine** bind olmalı
   (uyuşmazlık = paketler sessizce düşer, sayaç artar ama cevap yok).

7. **QUIC bypass**: Tor UDP desteklemez; tarayıcılar QUIC'e düşmemesi için
   yönlendirilen IP'lere UDP/443 REJECT ekle → TCP fallback.

8. **PS 5.1 tuzağı**: `SslStream.BeginAuthenticateAsClient($domain)` tek-arg
   overload'u Windows PowerShell 5.1'de YOK → exception → her domain "engelli"
   sanılır. Fix: 3-parametreli overload
   (`BeginAuthenticateAsClient($domain, $null, $null)`).

9. **nslookup ≠ cache**: `nslookup` Windows DNS cache'ine YAZMAZ —
   `Resolve-DnsName` kullan (ya da tarayıcıdan gir).

10. **Tarayıcı DoH her şeyi bypass eder**: "Güvenli DNS" açıksa çözümleme
    OS resolver'ı hiç geçmez → hem reklam engeli hem dedektör kör olur.
