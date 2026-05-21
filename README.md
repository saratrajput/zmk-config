# zmk-config

ZMK firmware configuration for a Ferris Sweep (cradio) with nice!nano v2.

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
