# Ferris Sweep (nice!nano v2 (or clones), wireless) ZMK Setup Notes

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

> **Shortcut:** Pre-compiled `.uf2` files are ready in the `uf2_files/` directory if you don't want to follow all the steps below. Use `uf2_files/default_config/` for the default keymap, or `uf2_files/with_function_keys_config/` for the keymap with function keys, then skip to [Flashing](#flashing).

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

# zmk-config

ZMK firmware configuration for a Ferris Sweep (cradio) with nice!nano v2.

## Right layer

Reached by **holding the right inner thumb** (`&lt 1 BSPC`,
`config/cradio.keymap:47`). Provides a numpad and editing keys on the left
half, navigation on the right half, and function keys on the bottom-right row.

```
╭────┬────┬────┬────┬────╮   ╭────┬────┬────┬────┬────╮
│INS │ 1  │ 2  │ 3  │    │   │HOME│PGDN│PGUP│END │ :  │
├────┼────┼────┼────┼────┤   ├────┼────┼────┼────┼────┤
│DEL │ 4  │ 5  │ 6  │    │   │LEFT│DOWN│ UP │RGHT│ ;  │
├────┼────┼────┼────┼────┤   ├────┼────┼────┼────┼────┤
│CAPS│ 7  │ 8  │ 9  │ 0  │   │ F1 │ F2 │F10 │F11 │F12 │
╰────┴────┴────┼────┼────┤   ├────┼────┼────┴────┴────╯
               │    │ESC │   │    │BSP │
               ╰────┴────╯   ╰────┴────╯
```

The function keys (`F1`/`F2`/`F10`/`F11`/`F12`) sit on the `N`/`M`/`,`/`.`/`/`
positions: hold the right inner thumb, then press with the right hand.

## Bluetooth Pairing

### How the tri-layer works

The keymap has a **conditional layer** (`config/cradio.keymap:27-30`): when
layers **1 (right_layer)** AND **2 (left_layer)** are both active at the same
time, layer **3 (tri_layer)** turns on automatically.

Those two layers are triggered by the **inner thumb keys** on the base layer
(`config/cradio.keymap:47`):

- **Left inner thumb** = `&lt 2 TAB` → hold to activate layer 2 (left_layer)
- **Right inner thumb** = `&lt 1 BSPC` → hold to activate layer 1 (right_layer)

**Hold BOTH inner thumbs together → tri_layer is active.** While still holding
them, tap the BT key.

### Step 1: Hold both inner thumb keys

```
╭────┬────┬────┬────┬────╮   ╭────┬────┬────┬────┬────╮
│ Q  │ W  │ E  │ R  │ T  │   │ Y  │ U  │ I  │ O  │ P  │
├────┼────┼────┼────┼────┤   ├────┼────┼────┼────┼────┤
│ A  │ S  │ D  │ F  │ G  │   │ H  │ J  │ K  │ L  │ '  │
├────┼────┼────┼────┼────┤   ├────┼────┼────┼────┼────┤
│ Z  │ X  │ C  │ V  │ B  │   │ N  │ M  │ ,  │ .  │ /  │
╰────┴────┴────┼────┼────┤   ├────┼────┼────┴────┴────╯
               │▓TAB│ENT │   │SPC │▓BSP│
               ╰────┴────╯   ╰────┴────╯
                 HOLD           HOLD
                 ▲▲▲▲           ▲▲▲▲
```

### Step 2: While still holding both, tap the BT key you want

```
╭────┬────┬────┬────┬────╮   ╭────┬────┬────┬────┬────╮
│RST │    │    │    │BT0 │   │    │    │    │    │RST │
├────┼────┼────┼────┼────┤   ├────┼────┼────┼────┼────┤
│BOOT│    │    │    │BT1 │   │    │    │    │    │BOOT│
├────┼────┼────┼────┼────┤   ├────┼────┼────┼────┼────┤
│    │    │    │CLR │BT2 │   │    │    │    │    │    │
╰────┴────┴────┼────┼────┤   ├────┼────┼────┴────┴────╯
               │HOLD│    │   │    │HOLD│
               ╰────┴────╯   ╰────┴────╯
```

Key positions (left hand):

- **BT0 / BT1 / BT2** = `T` / `G` / `B` position (top/middle/bottom of column 5)
- **CLR** (clear current profile) = `V` position

### Pairing a fresh device

1. Hold left-TAB + right-BSPC thumbs.
2. Tap `T` (profile 0) — or `G`/`B` for profile 1/2.
3. Release thumbs. On the host (Mac/PC/phone), pair to "cradio" from its
   Bluetooth menu.
4. If it won't pair cleanly: hold thumbs again, tap `V` (BT_CLR) to wipe that
   profile, then retry.
