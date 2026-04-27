# net-debug: диагностика “интернет умер на этом ПК”

Набор скриптов, чтобы **не ребутаться вслепую**, а собрать состояние сети в момент поломки и восстановить нормальный интернет.

Контекст текущей машины:

- Ubuntu 24.04;
- Wi‑Fi интерфейс: `wlp9s0`;
- Wi‑Fi адаптер: MediaTek `mt7925e`;
- основная сеть: `Dom_Chuni`;
- gateway/router: `192.168.50.1`;
- v2rayN/sing-box может включать TUN `singbox_tun`;
- Android camera experiments могут давать локальную нагрузку 35–60+ Mbps по Wi‑Fi.

## Файлы

```text
tools/net-debug/
├── README.md
├── net_debug_snapshot.sh       # собрать диагностический снимок
├── fix_net_after_v2rayn.sh     # убрать мусор после v2rayN/sing-box TUN
└── fix_wifi_mt7925e.sh         # локальные Wi‑Fi stability tweaks для mt7925e/wlp9s0
```

## Aliases

В `~/.bashrc` добавлены:

```bash
alias net_debug='bash "$HOME/code/tools/net-debug/net_debug_snapshot.sh"'
alias fix_net='bash "$HOME/code/tools/net-debug/fix_net_after_v2rayn.sh"'
alias fix_wifi='bash "$HOME/code/tools/net-debug/fix_wifi_mt7925e.sh"'
```

Чтобы aliases появились в текущем терминале:

```bash
source ~/.bashrc
```

## TL;DR: что делать при падении интернета

### 1. Не ребутаться сразу

Сначала собрать снимок:

```bash
net_debug ~/net-debug-broken
```

### 2. Если использовался v2rayN/sing-box/TUN

```bash
fix_net
```

### 3. Если после `fix_net` всё ещё не пингуется router/gateway

```bash
fix_wifi
```

### 4. После восстановления собрать второй снимок

```bash
net_debug ~/net-debug-after-fix
```

Полезная последовательность:

```bash
net_debug ~/net-debug-broken
fix_net
fix_wifi
net_debug ~/net-debug-after-fix
```

## Главная идея диагностики

Нужно различать **две разные проблемы**, которые могут выглядеть одинаково как “интернет умер”.

### Проблема A: v2rayN/sing-box оставил stale TUN/DNS/routes

Симптомы:

```text
singbox_tun существует
ip rule содержит 9000/9001/9002/9003/9010
table 2022 default via 172.18.0.2 dev singbox_tun
DNS Domain: ~. на singbox_tun
DNS server: 172.18.0.2
google.com -> 198.18.x.x
```

Это лечится:

```bash
fix_net
```

### Проблема B: локальный Wi‑Fi драйвер/firmware на ПК отвалился

Симптомы:

```text
ping 192.168.50.1 FAIL
ip neigh: 192.168.50.1 INCOMPLETE
kernel: mt7925e ... Message ... timeout
kernel: wlp9s0: Driver requested disconnection from AP
NetworkManager: wlp9s0 completed -> disconnected -> scanning -> associating
```

Это уже **не DNS и не роутер**. Это локальный Wi‑Fi адаптер/драйвер/firmware на ПК.

Это лечится/смягчается:

```bash
fix_wifi
```

## Что случилось в нашем debug log

В `debug-out.log` после лечебного скрипта `fix_net` было видно:

- `singbox_tun` уже отсутствует;
- `ip rule` чистый:

```text
0:      from all lookup local
32766:  from all lookup main
32767:  from all lookup default
```

- DNS уже нормальный, через router:

```text
DNS Servers: 192.168.50.1
```

То есть v2rayN/sing-box мусор был убран.

Но при этом:

```text
192.168.50.1 FAIL
1.1.1.1 FAIL
8.8.8.8 FAIL
```

И:

```text
192.168.50.1 dev wlp9s0 INCOMPLETE
```

А в kernel log было главное:

```text
mt7925e 0000:09:00.0: Message 00020002 (seq 3) timeout
wlp9s0: Driver requested disconnection from AP f0:2f:74:b7:7b:34
```

Вывод: после очистки TUN осталась/проявилась отдельная локальная проблема `mt7925e` на ПК.

## Почему это могло проявиться во время экспериментов с камерой

Камера сама по себе не меняет DNS/routes/hosts. Наши camera experiments трогали:

```text
v4l2loopback
/dev/video10
Python venv
WebSocket/RTSP/MJPEG stream с телефона
OBS/virtual camera
```

Это не должно напрямую менять:

```text
ip route
ip rule
/etc/resolv.conf
systemd-resolved
NetworkManager DNS
```

Но WebsocketCAM гонял постоянный локальный поток:

```text
Pixel -> Wi‑Fi -> PC
~35–60+ Mbps JPEG traffic
```

Это могло **вскрыть баг локального Wi‑Fi драйвера `mt7925e`** под нагрузкой. Поэтому ошибка могла впервые проявиться именно во время ковыряний с камерой.

Важно: то, что Meta Quest гонит 300 Mbps и всё ок, не опровергает это. Quest — другой Wi‑Fi клиент. Здесь падает конкретно Wi‑Fi адаптер/драйвер на этом ПК:

```text
MEDIATEK 14c3:0717
Kernel driver: mt7925e
Interface: wlp9s0
```

## Что делает `net_debug_snapshot.sh`

Скрипт собирает:

- время, hostname, kernel, OS;
- `ip link`, `ip addr`;
- все routes: `ip route show table all`;
- policy routing: `ip rule`;
- ARP/neighbors;
- NetworkManager состояние;
- Wi‑Fi состояние;
- `/etc/resolv.conf`;
- `resolvectl status/dns/domain/statistics`;
- `/etc/hosts`;
- proxy environment variables;
- подозрительные процессы:
  - `v2rayN`
  - `sing-box`
  - `xray`
  - `clash`
  - `mihomo`
  - VPN/tun-related процессы;
- system/user services;
- autostart entries;
- TUN interfaces;
- ping до:
  - `192.168.50.1`
  - `1.1.1.1`
  - `8.8.8.8`
  - `9.9.9.9`
- DNS checks через `getent` и `resolvectl`;
- HTTP checks через `curl`;
- route и порт до Pixel `192.168.50.30:3535`;
- логи за последний час:
  - `NetworkManager`
  - `systemd-resolved`
  - user-service `app-v2rayN@autostart.service`
  - kernel network logs;
- v2rayN config с best-effort redaction секретов.

## Где будут результаты `net_debug`

Если путь не указан, snapshots идут сюда:

```text
~/net-debug-snapshots/
```

Если путь указан, например:

```bash
net_debug ~/net-debug-broken
```

то внутри появятся папка и архив вида:

```text
~/net-debug-broken/net-debug-kcnc-pc-YYYYMMDD-HHMMSS/
~/net-debug-broken/net-debug-kcnc-pc-YYYYMMDD-HHMMSS.tar.gz
```

Можно дать локальный путь к архиву/папке для анализа.

## Что делает `fix_net_after_v2rayn.sh`

Скрипт пытается вернуть сеть в обычное состояние после кривого shutdown v2rayN/sing-box TUN:

1. Останавливает user-service v2rayN.
2. Убивает процессы `v2rayN` и `sing-box`.
3. Удаляет policy rules `9000`, `9001`, `9002`, `9003`, `9010`.
4. Чистит route table `2022`.
5. Удаляет интерфейс `singbox_tun`.
6. Перезапускает `systemd-resolved`.
7. Перезапускает `NetworkManager`.
8. Пробует поднять Wi‑Fi connection `Dom_Chuni`.
9. Показывает итоговую диагностику.

Запуск:

```bash
fix_net
```

или:

```bash
bash ~/code/tools/net-debug/fix_net_after_v2rayn.sh
```

## Что делает `fix_wifi_mt7925e.sh`

Скрипт применяет локальные Wi‑Fi stability tweaks для `mt7925e`/`wlp9s0`:

1. Отключает Wi‑Fi powersave глобально в NetworkManager:

```ini
/etc/NetworkManager/conf.d/wifi-powersave-off.conf
[connection]
wifi.powersave = 2
```

2. Отключает powersave для connection `Dom_Chuni`:

```bash
nmcli con modify Dom_Chuni 802-11-wireless.powersave 2
```

3. Ставит PMF client-side в disabled/compatible режим:

```bash
nmcli con modify Dom_Chuni 802-11-wireless-security.pmf 1
```

4. Переподключает Wi‑Fi.

5. Если установлен `iw`, делает runtime:

```bash
sudo iw dev wlp9s0 set power_save off
```

Запуск:

```bash
fix_wifi
```

или:

```bash
bash ~/code/tools/net-debug/fix_wifi_mt7925e.sh
```

Если `iw` не установлен:

```bash
sudo apt install iw
```

## Быстрые проверки руками

### Проверить, есть ли stale TUN

```bash
ip -br link | grep sing
ip rule
ip route show table 2022
resolvectl status
getent ahosts google.com
```

Плохо, если видно:

```text
singbox_tun
9000/9001/9002/9003/9010
172.18.0.2
198.18.x.x
```

### Проверить, жив ли локальный Wi‑Fi до роутера

```bash
ping -c3 192.168.50.1
ip neigh show 192.168.50.1
journalctl -k --since '30 min ago' --no-pager | grep -iE 'mt7925|wlp9s0|timeout|deauth|disconn|firmware'
```

Плохо, если:

```text
ping 192.168.50.1 FAIL
192.168.50.1 INCOMPLETE
mt7925e ... timeout
Driver requested disconnection
```

## Если `fix_wifi` не хватит

Дополнительные варианты, которые можно попробовать позже:

### 1. Зафиксировать BSSID

Сейчас `Dom_Chuni` виден на нескольких BSSID. Можно зафиксировать конкретную точку, например 5 GHz:

```bash
nmcli con modify Dom_Chuni 802-11-wireless.bssid F0:2F:74:B7:7B:34
nmcli con down Dom_Chuni
nmcli con up Dom_Chuni
```

Снять lock:

```bash
nmcli con modify Dom_Chuni 802-11-wireless.bssid ""
nmcli con down Dom_Chuni
nmcli con up Dom_Chuni
```

### 2. Проверить/обновить firmware/kernel

Проблема `mt7925e ... Message ... timeout` может зависеть от версии kernel/firmware. Если будет повторяться, смотреть:

```bash
uname -a
ethtool -i wlp9s0
journalctl -k --since '1 hour ago' --no-pager | grep -i mt7925
```

### 3. Временно уйти на Ethernet/другой Wi‑Fi адаптер

Если нужно срочно стабильное соединение под стрим/камеру, самый быстрый обходной путь — Ethernet или USB Wi‑Fi adapter с другим чипсетом.

## Важно про приватность

`net_debug_snapshot.sh` пытается редактировать секреты в v2rayN config, но это **best-effort**. Перед тем как куда-то публично отправлять архив, лучше проверить:

```bash
grep -RniE 'uuid|password|server|public_key|short_id' ~/net-debug-snapshots/net-debug-* | head -50
```

Локальный путь к архиву/папке можно давать для анализа на этой машине.
