# Sweep dongle setup

Target: separate nice!nano v2 / compatible nRF52840; ZMK v0.3.

## Build

- GitHub Actions: push → build matrix → `firmware` ZIP.
- `sweep_dongle.uf2`: USB receiver; two BLE peripherals; existing `cradio.keymap`.
- `cradio_left_peripheral.uf2`, `cradio_right_peripheral.uf2`: Sweep halves.
- `nice_nano_v2_settings_reset.uf2`: clears bonds/settings; same board on all three.
- Original `cradio_left-nice_nano_v2-zmk.uf2` / `cradio_right-nice_nano_v2-zmk.uf2`: direct-host rollback.

## Flash + pair

1. Keep other ZMK keyboards off. Identify each board before copying firmware.
2. Bootloader: double reset; buttonless board → briefly bridge **RST to GND** twice. Mount: `NICENANO`.
3. Each board: flash settings-reset UF2; let it boot; enter bootloader again; flash matching dongle/peripheral UF2. Power off until all three ready.
4. Plug dongle into USB; power both halves. Automatic split pairing; no OS Bluetooth pairing.
5. Check both halves, thumbs, HRM, layers, reconnect, idle/wake. Then test Ubuntu with host Bluetooth off.

## Notes

- Dongle stays awake; halves retain 15-minute sleep + 10-minute battery reports.
- Keymap changes: flash dongle. Split/config changes: rebuild/check all three.
- USB default output. BT profiles now belong to dongle; halves cannot pair directly with hosts.
- Reset/bootloader bindings follow ZMK behavior locality; use each board's physical reset for flashing.
- Battery proxy uses BLE; existing Mac BLE app does not read battery levels over USB HID.
- Rollback: settings reset both halves, flash original direct-host builds, re-pair host.
- [ZMK v0.3 dongle guide](https://v0-3-branch.zmk.dev/docs/development/hardware-integration/dongle)
