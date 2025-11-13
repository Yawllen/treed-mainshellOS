# Профиль rn12_hbot_v1 (MKS Robin Nano 1.2)

Структура модулей (включать по мере готовности железа):
- mcu_rn12.cfg — MCU и serial
- drivers_tmc2209.cfg — драйверы TMC2209 (X/Y/Z/E0, E1 позже под конвейер)
- kinematics_hbot.cfg — кинематика H-bot
- motion_limits.cfg — лимиты движений (скорости/ускорения/углы)
- heaters_hotend_tzv6.cfg — хотэнд TZ V6 3.0 (нагреватель + термистор)
- bed_ac220_ssr.cfg — стол 220 В через SSR-DA + ограничения
- sensors_endstops_mech.cfg — механические X/Y/Z концевики
- sensor_filament_pb2.cfg — датчик филамента на PB2
- fans_cooling.cfg — вентиляторы хотэнда/обдува/камеры
- macros_core.cfg — базовые макросы START/END/PARK/PAUSE
- ui_integration.cfg — статусы/меню/интеграции UI
- local_overrides.example.cfg — пример локальных оверрайдов; реальный `local_overrides.cfg` не коммитим (см. .gitignore)
