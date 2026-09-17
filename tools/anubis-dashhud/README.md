# Anubis Dash HUD

Medieval Fantasy paketi için client-only Forge 1.20.1 modu.

- Combat Dash çubuklarını kendisi çizer: doluyken kaybolmaz, yan elde eşya varken gizlenmez, solunda dash tuşunun adı yazar. Konum Combat Dash'in kendi client config'inden okunur.
- Iron's Spells büyü çubuğunu mixin ile 5'li satırlar halinde, sol alta yaslı bir ızgaraya çevirir (varsayılan piramit dizilimi yerine).

Derleme VDS'te: `/root/dev/dashhud`, `JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64 ./gradlew build`. `libs/irons_spellbooks.jar` sunucudaki Iron's Spells jar'ının kopyasıdır (derleme bağımlılığı). Çıktı `build/libs/anubis-dashhud-<sürüm>.jar` → `client-extra/mods/`.
