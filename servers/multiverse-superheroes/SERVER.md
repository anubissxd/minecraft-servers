# Multiverse Superheroes

Minecraft Version: 1.20.1
Server Type: Forge
Forge Version: 47.4.10
Java Version: 17 (proje içinde taşınabilir JRE: `shared/jre17`)
RAM: 8GB (Xmx8G / Xms8G)
Port: 25566

## Amaç

CrazyCraft tarzı: macera, fabrika/otomasyon, süper kahraman güçleri, büyü ve büyük boss savaşları. Arkadaş grubunun uzun süreli survival sunucusu.

## Mod Sayısı

87 mod (server-side). Client-only ek modlar için [client-info.md](client-info.md) dosyasına bak.

## Önemli Notlar

- **Türkçe Windows locale bug'ı**: JVM varsayılan olarak `tr-TR` locale kullanıyor, bu bazı modların (Palladium, KubeJS tabanlı enum lookup'lar) çökmesine sebep oluyor. `user_jvm_args.txt` içinde `-Duser.language=en -Duser.country=US` ile düzeltildi. **Bu satırları silme.**
- **Palladium sürümü 4.5.8'de sabitlendi** (4.5.9 değil) — Gravestone Core/HeroTime ve AlienEvo ile uyumsuzluk çıkardığı için düşürüldü.
- **Powerborne Heroes** kendi KubeJS scriptinde bug içeriyordu (`custom_potions.js` içinde efekt/potion registry sırası). Script içindeki `StartupEvents.registry` çağrılarına priority parametresi eklenerek (jar içi dosya patch'lendi) düzeltildi. Orijinal (patch'siz) kopya `disabled_mods/` altında duruyor, referans için.
- Mod paketinin **oynanabilir client kopyası** Modrinth App'te `MultiSH Deneme` profilinde tutuluyor — arkadaşlarla paylaşmak için bu profili kullan. Sunucu mod listesiyle senkron tutulmalı.

## Oyuncu Client Gereksinimleri

Bkz. [client-info.md](client-info.md) — client-only modlar (Xaero Minimap/WorldMap, Jade, JEI, AppleSkin, YUNG's Menu Tweaks).
