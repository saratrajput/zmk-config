# Ferris Sweep (nice!nano v2, wireless) — ZMK Setup Notes

## Background

- **Board:** nice!nano v2 (nRF52840) — uses **UF2 bootloader**, not DFU.
- **Firmware:** **ZMK** (not QMK). Wireless BLE split keyboards use ZMK.
- **Shield name in ZMK:** `cradio` (Ferris Sweep == cradio).
- A `.hex` file from QMK Configurator is for the wired ATmega32U4 Sweep — wrong board.

## Entering the bootloader

- Single tap on RST→GND just reboots → device flickers connect/disconnect.
- **Double-tap RST→GND quickly** (within ~500 ms) to enter UF2 bootloader.
- A USB drive named `NICENANO` mounts in Finder when successful.

## Getting the firmware (.uf2 files)

1. Use the ZMK config template: `https://github.com/zmkfirmware/zmk-config`.
2. During setup wizard pick:
   - Board: `nice_nano_v2`
   - Shield: `cradio`
   - The script generates `.gitignore`, `build.yaml`, `config/cradio.conf`, `config/cradio.keymap`.
3. Commit and push:
   ```bash
   git add .gitignore build.yaml config/cradio.conf config/cradio.keymap
   git commit -m "Initial Ferris Sweep config for nice!nano v2"
   git push
   ```
4. To use SSH instead of HTTPS for the remote:
   ```bash
   git remote set-url origin git@github.com:<user>/zmk-config.git
   git remote -v
   ssh -T git@github.com   # verify key is set up
   ```
5. GitHub **Actions** tab → wait ~2-3 min → download `firmware.zip` from Artifacts.
6. Zip contains:
   - `cradio_left-nice_nano_v2-zmk.uf2`
   - `cradio_right-nice_nano_v2-zmk.uf2`
   - `settings_reset-nice_nano_v2-zmk.uf2` (keep for pairing fixes)

## Flashing

1. Plug in **left** half → double-tap reset → drag `cradio_left...uf2` onto `NICENANO`.
2. Plug in **right** half → double-tap reset → drag `cradio_right...uf2`.

## How a ZMK split works

- Only the **central** half (left, by default for cradio) talks to the host over USB/BLE.
- The **peripheral** half (right) connects wirelessly to the central — it should **not** appear as its own keyboard to the computer. That is correct behavior.
- If keys on the right half don't register at all on the host: pairing between halves is broken.

## Fixing right-half not registering / pairing reset

For each half:

1. Flash `settings_reset-nice_nano_v2-zmk.uf2`.
2. Immediately re-flash the matching `cradio_left...uf2` or `cradio_right...uf2`.

Then power both halves on at the same time → they auto-pair.

## Home row keys not repeating on long press

- Not a bug — it's **home row mods** (HRMs) in the keymap.
- Home row keys (`asdfg` / `hjkl;`) become Shift/Ctrl/Alt/GUI when held, letters when tapped.
- Check `config/cradio.keymap`: bindings like `&hm`, `&mt`, `&hml`, `&hmr` indicate HRMs.
- To disable: replace with plain `&kp <KEY>` and rebuild + reflash.

## GUI keymap editor

- `https://nickcoutsos.github.io/keymap-editor/` — point it at your zmk-config repo for visual editing. Each push triggers a new Actions build.
