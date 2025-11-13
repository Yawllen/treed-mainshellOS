# TreeD MainshellOS

Инфраструктурный репозиторий для настройки образа **MainsailOS** под стек TreeD:

- кастомный сплэш-экран загрузки (**Plymouth**);
- пользовательская тема для веб-интерфейса **Mainsail**;
- базовый конфиг **Klipper** под плату **MKS Robin Nano 1.2 (RN12)**;
- установочные скрипты (`loader/*.sh`) для воспроизводимого деплоя на новые платы.

Основная цель — получить состояние «готовый к работе базовый принтер» по нескольким командам, без ручного копирования файлов.

---

## Стек и окружение

Целевое окружение:

- **SBC:** Raspberry Pi 3B  
- **ОС:** MainsailOS (Debian 12 / Bookworm, 64-бит)
- **MCU:** MKS Robin Nano 1.2 (STM32F103, прошитый Klipper’ом, USB /dev/serial/by-id/…)
- **UI:**
  - HDMI-экран 5″ 960×544 с USB-тачем (KlipperScreen);
  - Mainsail в браузере.

Термины:

- **Plymouth** — программа, которая рисует «красивый экран загрузки» вместо текстовых сообщений ядра.
- **Mainsail .theme** — папка с кастомным оформлением веб-интерфейса Mainsail (CSS, иконки, шрифты).
- **Профиль Klipper** — набор конфигов под конкретную плату/кинематику (`profiles/<имя>/root.cfg`).

---

## Структура репозитория

```text
loader/
  loader.sh              # основной установочный скрипт
  klipper-config.sh      # настройка конфигов Klipper (профиль RN12)
  plymouth/treed/        # тема Plymouth "treed"
  systemd/KlipperScreen.service.d/override.conf (опционально)

klipper/
  printer_root.cfg       # точка входа: include profiles/current/root.cfg
  profiles/
    rn12_hbot_v1/
      root.cfg           # минимальный профиль под MKS Robin Nano 1.2
    current -> rn12_hbot_v1
  switch_profile.sh      # переключение профиля + restart klipper

mainsail/
  .theme/                # полная тема для веб-интерфейса Mainsail

.gitignore
readme.md
