# Train Controller (slot-car hand controller)

Parametric OpenSCAD model of an ergonomic pistol-grip slot-car controller,
based on the shape of an existing printed controller (`Left.stl` / `Right.stl`).

## Files

| File | Purpose | Status |
|------|---------|--------|
| `design3.scad` | **Current working model.** Self-contained (no external files). | Active — work here |
| `design2.scad` | Same geometry as v3 but loads the outline from `profiles/body_outline.dxf`. | Superseded by v3 |
| `design.scad`  | Original hand-drawn v1 (chunky constant-thickness box, trigger, bosses, cutouts). | Legacy reference only |
| `profiles/body_outline.dxf` | Ergonomic outline projected from `Left.stl`. Used by `design2.scad`. | Input for v2 |
| `Left.stl`, `Right.stl` | Original printed controller shells (ground-truth ergonomic shape). | Reference |
| `controller3.jpg` | Photo of the reference controller. | Reference |
| `renders/` | Rendered preview PNGs. | Build output |

Recommended: continue in **`design3.scad`** — it is a single self-contained file.

## Coordinate convention

- **X** = along the controller length. Head / (former) finger-slot at **−X**, grip / butt at **+X**.
- **Z** = up / down (the silhouette height).
- **Y** = thickness. The two shell halves separate along **Y**; the profile is centred on Y = 0.

## What the model currently produces

`design3.scad` produces a **hollow two-part shell** (no trigger / internal
mounts yet):

1. **Ergonomic outline** — the real pistol-grip silhouette, embedded as an inline
   `polygon()` (`outline_points` / `outline_paths`), simplified from `Left.stl`.
2. **Slot removed** — the original finger slot has been deleted from the outline
   (its path is no longer referenced). Its location is preserved as data (see below).
3. **Thickness taper (Y)** — `head_thick = 60 mm` at the head, tapering to
   `grip_thick = 25 mm` at the grip, via `thickness_mask()`.
4. **Raised button surface** — the angled ~50° "top" face (the button-mounting
   surface, outline edge 30→31) is pushed outward along its own normal by
   `button_clearance = 20 mm`, with its corner fillets travelling with it so it
   blends smoothly into the body.
5. **Rounded edges** — the whole body is softened via `minkowski()` with a
   sphere of radius `grip_round = 3 mm`, so the edges the hand wraps are
   comfortable. Set `grip_round = 0` to disable (see speed note below).
6. **Hollow shell** — the body is hollowed to a uniform `wall = 1.5 mm` shell
   (`inner_cavity()` = the outer surface shrunk inward by `wall`;
   `body_hollow()` = `body_solid()` minus that cavity). Verified 1.5 mm walls.
7. **Split into two halves** — `left_shell()` / `right_shell()` clip the hollow
   body at the Y = 0 plane into two mating halves.
8. **Mate features** — six perimeter M3 bolt bosses (through-bolt + hex nut
   trap) with alignment spigots (see next-steps #3).
9. **Linear pot mount** — a solid cradle in the LEFT half holding a Bourns
   PTA3043 (45×9×6.5 mm) along the recorded diagonal pot axis. The pot is inset
   into the left half so only its 10 mm lever crosses the split (leaving a
   channel for the trigger armature), seats against a ledge, and has a 3 mm
   wire-exit gap at the pot's higher end. See next-steps #4.

### Key parameters (top of `design3.scad`)

- `grip_thick`, `head_thick` — body thickness (Y) at grip / head.
- `taper_head_x`, `taper_grip_x` — where the thickness taper starts/ends along X.
- `button_clearance` — how far the button face is pushed out (room above the pot).
- `button_face_normal`, `button_move_idx` — direction and which outline points move
  (the blue face + both corner fillets: `[28,29,30,31,32,33,0]`).
- `grip_round` — edge-rounding radius (mm); `0` disables it.
- `wall` — shell wall thickness (mm).
- `screw_boss_pos` — list of `[X, Z]` boss/bolt locations (currently six).
- `screw_clear_dia`, `screw_boss_dia` — bolt clearance hole / boss diameter.
- `screw_head_dia`, `screw_head_depth` — round bolt-head recess (left face).
- `nut_af`, `nut_depth` — hex nut recess across-flats / depth (right face).
- `spigot_dia`, `spigot_len`, `spigot_clear` — boss alignment spigot / fit.
- `pot_len`, `pot_wid`, `pot_hgt` — PTA3043 body envelope (45 / 9 / 6.5 mm).
- `pot_fit` — clearance around the pot body in the pocket.
- `pot_inset` — how far the pot top sits below the split (armature clearance).
- `pot_shift` — shift along the pot long axis (+ve = toward the back/grip).
- `pot_wall`, `pot_pin_gap`, `pot_lever_slot_w`, `pot_wire_gap_w` — cradle wall,
  solder-pin clearance, lever slot width, wire-exit gap width.
- `part_to_render` — `body`, `body_potmark`, `pot_debug`, `hollow`, `left_shell`,
  `right_shell`, `closed_assembly`, `exploded_assembly`.

### Recorded trigger pivot location (data only — no trigger yet)

The source STL had a small pivot hole; it is not cut into the body (carrying it
through `minkowski()` distorted it into a slot). The body is kept solid and the
location is recorded as data, to be drilled when the trigger is designed:

- `pivot_pos = [-12.81, 1.92]` — [X, Z] centre of the trigger pivot
- `pivot_dia = 4.0` — intended pin diameter (source marker was ~1.9 mm)

### Recorded pot location (was the finger slot)

The removed finger slot marks exactly where the internal **linear slide pot** mounts.
It is preserved as data so the pot mount can be placed on the same axis:

- `pot_axis_rear  = [-59.7,  4.7]`  — rear-upper end of the pot centreline [X, Z]
- `pot_axis_front = [-33.4, -27.9]` — front-lower end [X, Z]
- `pot_axis_len   = 41.9`           — centreline length (mm)
- `pot_axis_angle = -51.1`          — angle from +X in the X-Z plane (deg)
- `pot_axis_mid   ≈ [-46.5, -11.6]`

`part_to_render = "body_potmark"` overlays a marker showing this axis.

## How to render

From the project root (paths in the file are relative):

```bash
# quick preview (isometric)
openscad -o renders/iso.png --camera=200,-260,150,-5,0,5 --viewall design3.scad

# clean orthographic side view (the ergonomic silhouette)
openscad -o renders/side.png --camera=0,300,0,0,0,0 --viewall --projection=o design3.scad

# show the recorded pot axis
openscad -o renders/potmark.png -D 'part_to_render="body_potmark"' \
  --camera=200,-260,150,-5,0,5 --viewall design3.scad
```

Tip: `--viewall` frames the model automatically; `--projection=o` gives a true
orthographic view (best for judging profiles).

## Next steps (roughly in order)

1. ~~**Hollow the body into a shell.**~~ **DONE** — `wall = 1.5 mm`,
   `inner_cavity()` = `body_core(grip_round + wall)` (re-rounded), verified
   uniform 1.5 mm walls.

2. ~~**Split into left / right shells along Y = 0.**~~ **DONE** —
   `left_shell()` / `right_shell()` clip `body_hollow()` at Y = 0; render
   options `hollow`, `left_shell`, `right_shell`, `closed_assembly`,
   `exploded_assembly` all added.

3. ~~**Mate features for the two halves.**~~ **DONE** — **six** M3 bolt bosses
   spread around the perimeter (`screw_boss_pos`), kept CLEAR of the trigger↔pot
   armature path through the head centre. Each boss is a solid column spanning
   the split. Fastening is a **through-bolt with a captive nut**: an M3 bolt
   drops into a **round head recess** on the LEFT outer face, passes through a
   3.4 mm clearance hole in both halves, and is held by a nut in a **hexagonal
   recess** (`nut_af = 5.5 mm` A/F) on the RIGHT outer face. Recesses follow the
   local surface via `face_recess()` (handles the varying body thickness).
   Alignment is integral to the bosses: right-half male **spigots** register
   into left-half counterbores (no free-standing pins, so nothing floats). Each
   half is a clean 2-volume solid; the closed assembly mates without collision.

4. ~~**Linear pot mount** at the recorded `pot_axis_*`.~~ **DONE** — a solid
   cradle (`pot_mount_add()`/`pot_mount_cut()`) in the LEFT half holds a Bourns
   PTA3043 (45×9×6.5 mm) along the diagonal pot axis, placed via `pot_place()`
   (`translate(pot_axis_mid)` + `rotate` by `pot_axis_angle`). The cradle melds
   with the side wall; the pot is INSET (`pot_inset = 5 mm`) so only its 10 mm
   lever crosses the split (leaving a clear channel for the trigger armature),
   SHIFTED back along its axis (`pot_shift = +10 mm`) for an easier armature
   sweep, and SEATS against a ledge. A 3 mm wire-exit gap sits at the pot's
   higher end. Cradle is left-half only; the right half gets just the lever slot.

5. **Button / switch holes on the raised blue face.**
   - Place holes on the ~50° button surface (normal = `button_face_normal`).
   - Add hole diameter/pattern parameters; drill from the outside through the wall.
   - Add wiring clearance / channels down to the electronics bay.

6. **Trigger + pivot.** *(Not yet in `design3.scad` — only the pivot LOCATION
   and exit are recorded as data: `pivot_pos = [-12.81, 1.92]`, `pivot_dia = 4.0`,
   `trigger_exit = [-8, 3]`.)*
   - Design a trigger lever (a legacy `trigger_lever()` exists in `design.scad`
     v1 as a starting point) to fit the new throat.
   - **The trigger blade exits the body through the concave THROAT notch right
     next to the pivot, at approx `[-8, 3]`** (agreed during planning) — NOT
     lower/forward in the grip.
   - Drill the pivot hole through both shells at `pivot_pos`.
   - Add an actuator arm reaching from the pivot up to the pot lever along
     `pot_axis_*`; the pot's `pot_inset`/`pot_shift` leave a clear channel at the
     split for the arm to sweep.

7. **Cable exit** at the base of the grip (rear/bottom of the butt).

8. **Validate & export.**
   - `validate_scad` / build with no CGAL errors.
   - Export `left_shell` and `right_shell` to STL for printing.

## Known cleanups / notes

- The inline outline is a simplified version of the DXF (49 points via
  Douglas-Peucker, ~0.3 mm tolerance). Regenerate with a tighter tolerance if a
  closer match to the original mesh is ever needed.
- The pot axis is diagonal (~−51°); the slide pot mounts at that angle.
- Edge rounding uses `minkowski()`, which needs a full CGAL render
  (`openscad --render ...`) and is slow (~15–30 s). For fast iteration while
  working on other features, set `grip_round = 0`, then restore it for final
  renders / export.
