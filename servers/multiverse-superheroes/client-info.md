# Multiverse Superheroes — Client-Only Modlar

Bu modlar sunucunun `mods/` klasörüne **eklenmedi** çünkü tamamen istemci tarafında çalışıyorlar (UI/görsel özellikler). Oyuncular sunucuya bağlanmadan önce bunları kendi `mods/` klasörlerine kurmalı — sunucu ile uyum sorunu yaşamazlar, sadece kurmayan oyuncu o özelliği görmez.

| Mod | İşlev | Versiyon | İndirme |
|---|---|---|---|
| Xaero's Minimap | Ekranda mini harita | forge-1.20.1-26.4.2 | https://cdn.modrinth.com/data/1bokaNcj/versions/A1JacFsh/xaerominimap-forge-1.20.1-26.4.2.jar |
| Xaero's World Map | Tam ekran dünya haritası | forge-1.20.1-1.45.0 | https://cdn.modrinth.com/data/NcUtCpym/versions/3fGuLVo4/xaeroworldmap-forge-1.20.1-1.45.0.jar |
| Jade | Baktığın blok/mob için bilgi kutusu (WAILA benzeri) | 11.13.3+forge | https://cdn.modrinth.com/data/nvQzSEkH/versions/xJQHCmWJ/Jade-1.20.1-Forge-11.13.3.jar |
| JEI (Just Enough Items) | Craft tarifi/item arama rehberi | 15.49.0.193 | https://cdn.modrinth.com/data/u6dRKJwZ/versions/JhEb3Vl1/jei-1.20.1-forge-15.49.0.193.jar |
| AppleSkin | Açlık/doygunluk değerlerini gösterir | 2.5.1+mc1.20.1 | https://cdn.modrinth.com/data/EsAfCjCV/versions/XdXDExVF/appleskin-forge-mc1.20.1-2.5.1.jar |
| YUNG's Menu Tweaks | Menü gezinmesini kolaylaştırır | 1.20.1-Forge-1.0.2 | https://cdn.modrinth.com/data/Hcy2DFKF/versions/3FmFt8jI/YungsMenuTweaks-1.20.1-Forge-1.0.2.jar |
| Embeddium | Sodium tabanlı render/FPS optimizasyonu (client-only) | 0.3.31+mc1.20.1 | https://curseforge.com/minecraft/mc-mods/embeddium (CF referans paketinden al) |
| Oculus | Shader desteği | 1.8.0 | CF referans paketinden al |
| EntityCulling | Görünmeyen entity render'ını keser (FPS) | 1.10.5 | CF referans paketinden al |
| Smooth Chunk | Chunk render optimizasyonu | 4.1 | CF referans paketinden al (**Cupboard** bağımlılığı gerekli, aşağıda) |
| Cupboard | Smooth Chunk'ın zorunlu bağımlılığı | 3.9 | CF referans paketinden al |
| Yet Another Config Lib | Config-menü kütüphanesi | 3.6.6 | Sunucuda da var (Variants and Ventures bağımlılığı) |
| Mouse Tweaks | Envanter fare kısayolları | 2.25.1 | CF referans paketinden al |
| Clean Swing | Silah sallama animasyon düzeltmesi | 1.8 | CF referans paketinden al |
| Essential | Arkadaş listesi, ekran paylaşımı, cosmetic | 1.4.1 | CF referans paketinden al — **sunucudan çıkarıldı**, aşağıda neden var |

## Not
Xaero Minimap/World Map, Jade ve AppleSkin sunucuda hiç olmadan da çalışır (server-agnostic). Bu yüzden sunucu tarafına eklemek gereksiz — CLAUDE.md kuralı gereği sadece gerekli modlar server'a konur.

## Essential neden sunucudan çıkarıldı
Essential'ın kendi loader'ı (`gg.essential.loader`) dedicated server ortamında `org.apache.commons.codec.digest.DigestUtils` sınıfını bulamayıp çöküyordu (`NoClassDefFoundError`). Bu tamamen client-side bir mod — sunucuda hiç işlevi yok, yanlışlıkla server mods'a eklenmişti. Client'ta sorunsuz çalışmaya devam ediyor, sadece server mods listesinden kaldırıldı.
