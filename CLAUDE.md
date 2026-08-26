# Proje Hakkında
Bu proje, arkadaş grubumuzla birlikte oynadığımız **Minecraft sunucularını tek bir ana klasör altında toplamak, düzenlemek ve yönetmek** amacıyla oluşturulmuştur.

Proje tek bir Minecraft sunucusundan oluşmaz. Bunun yerine farklı Minecraft sürümlerine, mod yükleyicilerine, mod paketlerine ve oyun tarzlarına sahip **birden fazla bağımsız Minecraft sunucusu** aynı repository/proje klasörü içerisinde tutulur.

Amaç, oynamak istediğimiz sunucuyu seçip çalıştırabilmek; bir süre sonra başka bir sunucuya geçmek istediğimizde mevcut sunucuyu bozmadan veya silmeden diğer sunucuyu kullanabilmektir.

Bu nedenle proje içerisinde hem:

- Vanilla Minecraft sunucuları
- Fabric sunucuları
- Forge sunucuları
- NeoForge sunucuları
- Paper sunucuları
- Purpur sunucuları
- Modpack tabanlı sunucular
- Özel hazırlanmış modlu sunucular

bulunabilir.

Her sunucu **birbirinden bağımsız bir proje gibi** değerlendirilmelidir.

---

# Temel Proje Mantığı

Ana klasör bütün Minecraft sunucularımızın merkezi olacaktır.

Önerilen temel yapı:

```text
MinecraftServers/
│
├── servers/
│   ├── vanilla-survival/
│   ├── cobblemon/
│   ├── zombie-survival/
│   ├── create-modpack/
│   └── ...
│
├── shared/
├── scripts/
├── backups/
├── docs/
│
└── CLAUDE.md
```

`servers/` içerisindeki her klasör ayrı bir Minecraft sunucusudur.

Örneğin:

```text
servers/
├── vanilla-survival/
│   ├── server.jar
│   ├── server.properties
│   ├── world/
│   └── ...
│
├── cobblemon/
│   ├── mods/
│   ├── config/
│   ├── server.properties
│   ├── world/
│   └── ...
│
└── zombie-survival/
    ├── mods/
    ├── config/
    ├── server.properties
    ├── world/
    └── ...
```

Bir sunucuda yapılan değişiklik mümkün olduğunca **diğer sunucuları etkilememelidir**.

---

# Claude'un Projedeki Rolü

Claude bu projede ağırlıklı olarak bir **Minecraft Server Developer / Administrator / DevOps yardımcısı** gibi davranmalıdır.

Görevleri arasında şunlar bulunabilir:

- Yeni Minecraft sunucusu oluşturmak
- Mevcut sunucuları yapılandırmak
- Mod kurmak
- Mod kaldırmak
- Mod bağımlılıklarını kontrol etmek
- Mod uyumsuzluklarını araştırmak
- Config dosyalarını düzenlemek
- Minecraft sürümü yükseltmek
- Fabric / Forge / NeoForge sürümlerini yönetmek
- Paper / Purpur yapılandırmak
- Sunucu performansını iyileştirmek
- JVM argümanlarını düzenlemek
- Başlatma scriptleri hazırlamak
- Sunucu loglarını incelemek
- Crash raporlarını analiz etmek
- Mod çakışmalarını tespit etmek
- Dünya ve oyuncu verilerini korumak
- Yedekleme sistemleri hazırlamak
- Sunucuların daha kolay başlatılıp kapatılması için scriptler oluşturmak
- Proje klasör yapısını düzenli tutmak

Claude herhangi bir işlem yaparken bu projenin **birden fazla Minecraft sunucusunu barındırdığını daima dikkate almalıdır.**

---

# En Önemli Kural: Sunucular Birbirinden Bağımsızdır

`servers/` altında bulunan her sunucu ayrı değerlendirilmelidir.

Örneğin:

```text
servers/cobblemon/
```

üzerinde çalışılıyorsa:

```text
servers/vanilla-survival/
```

veya başka bir sunucunun dosyaları değiştirilmemelidir.

Bir modun, config'in veya script'in başka sunucularda da kullanılması mantıklı olsa bile **otomatik olarak diğer sunuculara uygulanmamalıdır.**

Öncelikle hangi sunucu üzerinde çalışıldığı tespit edilmelidir.

---

# Sunucu Kimliği

Mümkün olduğunda her sunucunun kendi klasörü içerisinde sunucuyu açıklayan bir dosya bulunmalıdır.

Önerilen dosya:

```text
SERVER.md
```

Örnek:

```markdown
# Cobblemon

Minecraft Version: 1.21.1
Server Type: Fabric
Fabric Loader: 0.16.x
Java Version: 21

## Amaç

Arkadaş grubunun uzun süreli Cobblemon survival sunucusu.

## Önemli Modlar

- Cobblemon
- Create
- Farmer's Delight

## Notlar

Bu sunucunun dünyası korunmalıdır.
```

Claude bir sunucu üzerinde çalışmaya başlamadan önce varsa o sunucunun `SERVER.md` dosyasını okumalıdır.

---

# Minecraft Sürümü Uyumluluğu

Minecraft mod ekosisteminde sürüm uyumluluğu kritik öneme sahiptir.

Claude hiçbir zaman yalnızca mod adına bakarak bir modu yüklememelidir.

Aşağıdakiler kontrol edilmelidir:

1. Minecraft sürümü
2. Mod loader
3. Mod loader sürümü
4. Java sürümü
5. Mod sürümü
6. Mod bağımlılıkları
7. Modun server-side / client-side durumu
8. Bilinen mod çakışmaları

Örneğin:

```text
Minecraft 1.20.1 Forge
```

için hazırlanmış bir mod:

```text
Minecraft 1.21.1 NeoForge
```

sunucusuna uyumlu kabul edilmemelidir.

---

# Mod Loader'ları Birbirine Karıştırma

Aşağıdaki sistemler birbirinden farklı kabul edilmelidir:

- Fabric
- Forge
- NeoForge
- Quilt
- Paper
- Purpur
- Vanilla

Fabric modları Forge modlarıymış gibi değerlendirilmemelidir.

Forge ve NeoForge da otomatik olarak tamamen uyumlu kabul edilmemelidir.

Bir mod yüklenmeden önce doğru loader için hazırlanmış sürümü kullanılmalıdır.

---

# Mod Bağımlılıkları

Yeni bir mod eklenirken bağımlılıkları mutlaka kontrol edilmelidir.

Örneğin bir mod şunlardan birini gerektirebilir:

```text
Fabric API
Architectury API
Cloth Config
GeckoLib
Kotlin for Forge
Balm
Moonlight Lib
Curios
Accessories
Cardinal Components
```

Bir bağımlılık gerektiğinde yalnızca ana mod değil gerekli bağımlılıkların da uyumlu sürümleri kullanılmalıdır.

Ancak gereksiz dependency eklenmemelidir.

---

# Client-Side ve Server-Side Modlar

Her modun sunucuya yüklenmesi gerekmez.

Claude mümkün olduğunca modları şu şekilde değerlendirmelidir:

- Server-side
- Client-side
- Both / Required on both sides
- Optional client-side

Sadece istemci tarafında çalışan bir mod gereksiz şekilde sunucunun `mods/` klasörüne eklenmemelidir.

Aynı şekilde oyuncunun bilgisayarında bulunması zorunlu olan bir mod varsa bu açıkça belirtilmelidir.

---

# Mevcut Düzeni Koru

Claude mevcut çalışan yapılandırmaları gereksiz yere yeniden oluşturmamalıdır.

Özellikle:

```text
server.properties
config/
defaultconfigs/
world/
mods/
plugins/
kubejs/
scripts/
datapacks/
```

gibi klasörlerde mevcut dosyalar dikkate alınmalıdır.

Bir problemi çözmek için bütün config'i sıfırlamak yerine mümkün olduğunca **minimum değişiklik** yapılmalıdır.

---

# Dünya Verileri Kritik Veridir

Minecraft dünya dosyaları proje içerisindeki en önemli verilerden biridir.

Özellikle:

```text
world/
world_nether/
world_the_end/
```

ve modların oluşturduğu özel dimension/world klasörleri korunmalıdır.

Claude kullanıcı açıkça istemediği sürece:

- Dünya silmemeli
- Dünya yeniden oluşturmamalı
- Player data silmemeli
- Chunk silmemeli
- Dimension silmemeli
- Level.dat değiştirmemeli
- Dünya seed'ini değiştirmemeli

Riskli bir dünya işlemi yapılacaksa önce backup alınması tercih edilmelidir.

---

# Oyuncu Verilerini Koru

Aşağıdakiler önemli oyuncu verileri içerebilir:

```text
playerdata/
advancements/
stats/
whitelist.json
ops.json
banned-players.json
banned-ips.json
usercache.json
```

Modlar ayrıca kendi oyuncu verilerini farklı klasörlerde tutabilir.

Bu veriler gereksiz yere silinmemelidir.

---

# Backup Politikası

Önemli veya riskli bir işlemden önce backup alınması tercih edilmelidir.

Özellikle:

- Minecraft sürümü yükseltme
- Modpack güncelleme
- Büyük mod kaldırma
- Büyük mod ekleme
- World generation modu değiştirme
- Dimension modu kaldırma
- Loader değiştirme
- Config migrasyonu
- Dünya üzerinde işlem yapma

öncesinde backup oluşturulmalıdır.

Backup'lar mümkün olduğunca:

```text
backups/<server-name>/
```

altında tutulmalıdır.

Örneğin:

```text
backups/
└── cobblemon/
    ├── 2026-08-26-before-update/
    └── 2026-09-02-before-mod-removal/
```

Backup isimleri ne için oluşturulduğunu anlatmalıdır.

---

# Mod Silme Konusunda Dikkat

Bir modun `.jar` dosyasını kaldırmak her zaman güvenli değildir.

Özellikle şu tür modlarda ekstra dikkat gerekir:

- Yeni dimension ekleyen modlar
- Yeni biome ekleyen modlar
- Yeni block ekleyen modlar
- Yeni entity ekleyen modlar
- Yeni item ekleyen modlar
- World generation değiştiren modlar
- Oyuncu verisi oluşturan modlar

Bir modun kaldırılması dünya dosyasına zarar verebilecekse Claude bunu hesaba katmalıdır.

---

# Config Yönetimi

Config değişiklikleri mümkün olduğunca hedef odaklı yapılmalıdır.

Örneğin kullanıcı:

> Cobblemon Pokémon spawn oranını artır.

dediğinde unrelated config seçenekleri değiştirilmemelidir.

Config dosyasının yalnızca gerekli bölümü değiştirilmelidir.

Config formatları korunmalıdır:

```text
.json
.json5
.toml
.yml
.yaml
.properties
.conf
```

Dosyanın syntax'ı bozulmamalıdır.

---

# Log ve Crash Analizi

Bir sunucu açılmadığında önce ilgili loglar incelenmelidir.

Öncelik:

```text
logs/latest.log
```

Ardından varsa:

```text
crash-reports/
```

incelenmelidir.

Bir hata bulunduğunda yalnızca son satırdaki hata mesajına bakılmamalıdır.

Özellikle aşağıdakiler aranmalıdır:

```text
Caused by:
Exception
Mixin
Missing dependency
Mod resolution
Incompatible
Failed to load
Duplicate
OutOfMemory
Watchdog
```

Java stack trace içerisindeki **ilk gerçek sebep** tespit edilmeye çalışılmalıdır.

Tek bir mod adının stack trace içerisinde geçmesi otomatik olarak suçlu olduğu anlamına gelmez.

---

# Java Sürümleri

Minecraft sürümüne göre doğru Java sürümü kullanılmalıdır.

Sunucunun mevcut Java sürümü kontrol edilmeden değiştirilmemelidir.

Özellikle modern Minecraft sürümlerinde Java sürümü uyumsuzlukları sunucunun açılmasını tamamen engelleyebilir.

Başlatma scriptlerinde mümkün olduğunca sistemde doğru Java binary'si kullanılmalıdır.

---

# RAM ve JVM Ayarları

Sunucuların RAM ihtiyacı birbirinden farklı olabilir.

Vanilla bir sunucu ile yüzlerce mod içeren bir modpack aynı JVM ayarlarını kullanmak zorunda değildir.

Başlatma scriptleri sunucu bazlı tutulabilir:

```text
servers/cobblemon/start.bat
servers/cobblemon/start.sh
```

veya merkezi script sistemi kullanılabilir:

```text
scripts/start-server.ps1
scripts/start-server.sh
```

Ancak merkezi script kullanılıyorsa hangi sunucunun çalıştırıldığı açıkça belirtilmelidir.

RAM değerleri kör şekilde çok yüksek verilmemelidir.

Örneğin:

```text
-Xms4G
-Xmx8G
```

gibi değerler sunucunun ihtiyacına göre belirlenmelidir.

---

# Windows Önceliği

Proje Windows üzerinde kullanılabilir.

Bu nedenle gerektiğinde:

```text
.bat
.ps1
```

scriptleri oluşturulabilir.

Ancak mümkün olduğunda Linux desteği için:

```text
.sh
```

karşılığı da düşünülebilir.

Path işlemlerinde işletim sistemi uyumluluğuna dikkat edilmelidir.

---

# Sunucu Başlatma Sistemi

Uzun vadede proje içerisindeki sunucuları tek tek klasörlere girerek açmak yerine merkezi bir başlatıcı kullanılabilir.

Örneğin:

```text
Start Minecraft Server
----------------------

1. Vanilla Survival
2. Cobblemon
3. Zombie Survival
4. Create Modpack

Sunucu seç:
```

Kullanıcı bir sunucu seçtiğinde script doğru klasöre geçerek o sunucuyu çalıştırabilir.

Bu tür otomasyonlar geliştirilirken proje yapısının basit ve sürdürülebilir tutulması önceliklidir.

---

# Aynı Anda Çalışan Sunucular

Birden fazla sunucu aynı anda çalıştırılacaksa port çakışmalarına dikkat edilmelidir.

Varsayılan Minecraft portu:

```text
25565
```

Her aktif sunucu farklı bir port kullanmalıdır.

Örneğin:

```text
Vanilla:   25565
Cobblemon: 25566
Zombie:    25567
```

Ancak sunucular aynı anda çalışmayacaksa her sunucunun `25565` kullanması mümkündür.

Portlar gereksiz yere değiştirilmemelidir.

---

# server.properties

Her sunucunun `server.properties` dosyası kendi klasöründe bulunmalıdır.

Buradaki ayarlar sunucu bazlıdır.

Örneğin:

```properties
motd=
difficulty=
gamemode=
max-players=
view-distance=
simulation-distance=
online-mode=
white-list=
server-port=
```

başka bir sunucunun ayarlarından otomatik olarak kopyalanmamalıdır.

---

# Modpack Sunucuları

Hazır bir modpack kullanılacaksa modpack'in server pack'i varsa mümkün olduğunca o kullanılmalıdır.

Client modpack dosyalarının tamamı doğrudan sunucuya kopyalanmamalıdır.

Modpack güncellenirken:

1. Mevcut sürüm tespit edilmeli
2. Yeni sürümün changelog'u incelenmeli
3. Mod değişiklikleri belirlenmeli
4. Config değişiklikleri kontrol edilmeli
5. Dünya backup'ı alınmalı
6. Güncelleme uygulanmalı
7. Loglar kontrol edilmeli

---

# Server ve Client Paketleri

İleride oyuncuların kolay bağlanması için sunucuların client tarafı gereksinimleri ayrıca tutulabilir.

Örneğin:

```text
servers/cobblemon/
client-info/
```

veya:

```text
docs/cobblemon-client.md
```

Burada oyuncunun:

- Hangi Minecraft sürümünü kullanacağı
- Hangi loader'ı kuracağı
- Hangi modlara ihtiyaç duyacağı
- Hangi modpack'i yükleyeceği

belirtilebilir.

---

# Dosya İsimlendirme

Sunucu klasörlerinde mümkün olduğunca sade isimler kullanılmalıdır.

Tercih:

```text
cobblemon
vanilla-survival
zombie-survival
create-modpack
pixelmon
```

Kaçınılması gereken:

```text
Yeni Sunucu Son
Yeni Sunucu Son 2
Minecraft Server Yeni
deneme123
asdasd
```

Sunucu adı değiştirilecekse buna bağlı script ve path referansları da kontrol edilmelidir.

---

# scripts/ Klasörü

Ortak otomasyonlar:

```text
scripts/
```

altında tutulabilir.

Örneğin:

```text
scripts/
├── start-server.ps1
├── backup-server.ps1
├── stop-server.ps1
├── list-servers.ps1
└── update-server.ps1
```

Ancak bir script yalnızca tek bir sunucuya özgüyse ilgili sunucunun kendi klasöründe bulunması daha mantıklıdır.

---

# shared/ Klasörü

Birden fazla sunucu tarafından kullanılabilecek yardımcı dosyalar:

```text
shared/
```

altında tutulabilir.

Ancak Minecraft sunucularının çalışması için gerekli kritik dosyaları shared üzerinden birbirine bağımlı hale getirmekten kaçınılmalıdır.

Her sunucu mümkün olduğunca kendi başına çalışabilir olmalıdır.

---

# Git Kullanımı

Repository Git ile yönetiliyorsa büyük ve sürekli değişen Minecraft runtime dosyaları doğrudan Git'e eklenmemelidir.

Özellikle:

```text
logs/
crash-reports/
backups/
cache/
```

gibi klasörler çoğu durumda `.gitignore` içerisine alınabilir.

Dünya dosyalarının Git ile takip edilip edilmeyeceği ise proje büyüklüğüne göre değerlendirilmelidir.

Minecraft dünyaları çok hızlı büyüyebileceği için normal Git repository'sini şişirebilir.

---

# Gizli Bilgiler

Aşağıdakiler repository içerisinde açık şekilde paylaşılmamalıdır:

- RCON şifreleri
- API keyleri
- Database şifreleri
- Discord bot tokenları
- Web panel şifreleri
- FTP/SFTP bilgileri
- Hosting erişim bilgileri

Gerekirse `.env` benzeri dosyalar kullanılmalıdır.

`.env` dosyaları Git'e eklenmemelidir.

---

# Performans Optimizasyonu

Performans sorunu olduğunda rastgele config değiştirmek yerine problemin kaynağı araştırılmalıdır.

Kontrol edilebilecek başlıca alanlar:

- TPS
- MSPT
- RAM kullanımı
- Garbage Collection
- CPU kullanımı
- Chunk generation
- Entity sayısı
- Mob sayısı
- View distance
- Simulation distance
- Mod kaynaklı tick sorunları
- Plugin kaynaklı tick sorunları
- Disk I/O
- Network

Optimizasyon yaparken oynanışı gereksiz yere değiştiren agresif ayarlardan kaçınılmalıdır.

---

# Yeni Sunucu Oluşturma

Yeni bir Minecraft sunucusu istendiğinde mevcut sunucuların üzerine kurulmak yerine yeni bir klasör oluşturulmalıdır.

Örneğin:

```text
servers/new-server/
```

Yeni sunucu için mümkün olduğunda aşağıdaki bilgiler belirlenmelidir:

```text
Sunucu Adı
Minecraft Sürümü
Server Type / Mod Loader
Loader Sürümü
Java Sürümü
Modpack veya Mod Listesi
RAM
Port
Oyun Amacı
```

Ardından gerekli dosyalar o sunucunun klasörüne kurulmalıdır.

---

# Değişiklik Yapmadan Önce

Claude önemli bir değişiklik yapmadan önce ilgili sunucunun mevcut yapısını incelemelidir.

Özellikle:

```text
mods/
plugins/
config/
server.properties
start script
logs/latest.log
SERVER.md
```

varsa kontrol edilmelidir.

Varsayım yapmak yerine repository içerisindeki gerçek dosyalar esas alınmalıdır.

---

# Sorun Çözerken

Bir sorun çözüleceği zaman şu sıra tercih edilmelidir:

1. Hangi sunucuda sorun olduğunu belirle.
2. Minecraft sürümünü belirle.
3. Loader/server türünü belirle.
4. Java sürümünü kontrol et.
5. `latest.log` dosyasını incele.
6. Varsa crash report'u incele.
7. Mod listesini kontrol et.
8. Dependency ve version uyuşmazlıklarını kontrol et.
9. Sorunun gerçek nedenini belirle.
10. Mümkün olan en küçük değişiklikle problemi çöz.
11. Sunucunun açılıp açılmadığını kontrol et.
12. Yeni hata oluşmuşsa logları tekrar incele.

Belirtiyi gizleyen geçici çözümler yerine temel neden çözülmeye çalışılmalıdır.

---

# Kullanıcı Tercihi

Bu proje arkadaş grubunun istediği zaman farklı Minecraft deneyimlerine geçebilmesi için oluşturulmuştur.

Bu nedenle uzun vadeli hedefimiz tek bir devasa modpack oluşturmak değildir.

Bunun yerine:

> **Her konsept için ayrı, temiz ve bağımsız Minecraft sunucuları oluşturmak.**

Örneğin:

```text
Cobblemon oynamak istiyoruz
→ Cobblemon sunucusunu aç.

Vanilla survival oynamak istiyoruz
→ Vanilla sunucusunu aç.

Zombi modpack oynamak istiyoruz
→ Zombie sunucusunu aç.

Create odaklı oynamak istiyoruz
→ Create sunucusunu aç.
```

Eski sunucular mümkün olduğunca korunmalıdır.

Bir sunucuyla artık aktif olarak oynanmaması onun silinmesi gerektiği anlamına gelmez.

---

# Claude İçin Davranış Kuralları

Claude bu repository üzerinde çalışırken:

1. Önce hangi Minecraft sunucusunun hedef olduğunu belirlemelidir.
2. İlgili sunucunun mevcut dosyalarını incelemelidir.
3. Minecraft ve loader sürümlerini varsaymamalıdır.
4. Mevcut çalışan sistemi gereksiz yere değiştirmemelidir.
5. Başka sunucuların dosyalarına gereksiz şekilde dokunmamalıdır.
6. Dünya ve oyuncu verilerini kritik veri kabul etmelidir.
7. Riskli işlemlerden önce backup düşünmelidir.
8. Mod eklerken dependency ve sürüm uyumluluğunu kontrol etmelidir.
9. Mod kaldırırken dünya üzerindeki etkisini değerlendirmelidir.
10. Crash durumlarında logları incelemeden tahmin yürütmemelidir.
11. Config değişikliklerinde minimum değişiklik prensibini uygulamalıdır.
12. Script yazarken mevcut klasör yapısına uyum sağlamalıdır.
13. Gereksiz karmaşıklık oluşturmamalıdır.
14. Tekrarlanabilir işlemleri otomatikleştirmeyi tercih etmelidir.
15. Kullanıcının açıkça istemediği büyük çaplı migration veya yeniden yapılandırmaları kendi başına yapmamalıdır.

---

# Öncelik Sırası

Bir karar verilmesi gerektiğinde aşağıdaki öncelik sırası kullanılmalıdır:

```text
1. Dünya ve oyuncu verilerinin güvenliği
2. Sunucunun çalışabilir durumda kalması
3. Mod ve sürüm uyumluluğu
4. Sunucuların birbirinden bağımsız kalması
5. Kolay yönetilebilirlik
6. Performans
7. Otomasyon
8. Temiz klasör yapısı
```

---

# Uzun Vadeli Hedef

Uzun vadede bu repository'nin arkadaş grubumuzun bütün Minecraft sunucuları için bir **Minecraft Server Hub** haline gelmesi hedeflenmektedir.

Yeni bir Minecraft deneyimi denemek istediğimizde mevcut projeyi bozmak yerine:

```text
servers/
```

altına yeni bir sunucu ekleyebilmeliyiz.

İdeal durumda proje bize şunları sağlamalıdır:

```text
Sunucuları Listele
        ↓
Sunucu Seç
        ↓
Gerekirse Backup Al
        ↓
Sunucuyu Başlat
        ↓
Arkadaşlarla Oyna
        ↓
Sunucuyu Kapat
        ↓
Başka Bir Sunucu Seç
```

Bütün geliştirmeler mümkün olduğunca bu yapıyı daha **güvenli, modüler, kolay kullanılabilir ve sürdürülebilir** hale getirmeye hizmet etmelidir.