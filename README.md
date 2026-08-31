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
10. **Trigger + pivot + return spring** — a trigger lever (`trigger_lever()`)
    pivoting at `pivot_pos`: a BENT finger blade exiting the throat up-and-forward
    at ~45°, then curling back to a finger tip near `[0, 30]`, and an actuator arm
    with an elongated fork slot driving the pot lever.
    The pivot pin and spring anchor share a 3 mm rod (`rod_dia`), each captured
    in blind-bore bosses. A return spring hooks a hole in the armature and a
    rod in a body anchor boss, pulling the trigger to rest. See next-steps #6.
11. **Control panel** — holes drilled into the raised blue face along its normal
    via a face frame built from the face's four corners (`panel_face_place`). The
    LEFT half has four 6 mm toggle holes (master on its own row; horn / reverse /
    lights in a row at 15 mm pitch); the RIGHT half has the LED battery-meter
    cutout (square 25.5 × 2.2 mm slot + two 3.5 mm end holes, 33 mm apart). All
    clear of the bolt bosses. See next-steps #5.
12. **Thumb button** — a 6 mm push-button hole (`thumb_button_cut()`) on the
    lower-front surface at `thumb_pos`, drilled along the local surface normal
    (`thumb_normal`). It sits ON the Y = 0 split, so it is halved into a matching
    semicircle in each shell.
13. **DX16 connector** — a panel-mount aviation socket (16 mm hole, 7 mm thread,
    inner retaining nut) on the rear of the grip butt at `cable_pos`, drilled
    along the local surface normal. Because a threaded connector needs a flat
    full-thickness seat (not a split semicircle), it uses a moulded round **pad**
    (`connector_pad()`, Ø19, 2 mm proud + 3 mm in) on the LEFT shell that crosses
    the seam so the hole stays centred; the RIGHT shell has a matching recess
    (`connector_recess()`). An internal **reinforcing collar**
    (`connector_reinforce()`, LEFT half only) thickens the wall around the socket
    for strength. The Ø16 bore (`connector_hole()`) cuts through both halves.

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
- `rod_dia` — shared metal-rod diameter for BOTH the trigger pivot pin and the
  spring anchor rod (default 3 mm, a common steel dowel / silver-steel size).
- `trigger_thick`, `trigger_hub_dia` — trigger lever thickness / pivot hub.
- `trigger_blade_len`, `trigger_blade_ang` — first blade segment reach/angle out
  of the throat.
- `trigger_blade_knee`, `trigger_blade_tip2` — the bend: knee (near the pivot,
  end of the first segment) and the curled finger tip `[X,Z]` (default `[0,30]`).
- `trigger_arm_aim`, `trigger_arm_extra`, `trigger_arm_w` — actuator arm target,
  extra length, width.
- `trigger_fork_slot`, `trigger_fork_len`, `trigger_fork_pivot_ext` — elongated
  fork slot (width / length / extension toward the pivot) that drives the pot lever.
- `trigger_throat_ext`, `trigger_throat_lowext` — throat cutout swing clearance.
- `pivot_boss_dia`, `pivot_hub_gap`, `pivot_bore_depth` — pivot boss / blind bore.
- `spring_trigger_pos`, `spring_hole_dia` — spring hook hole in the armature.
- `spring_anchor_pos`, `spring_boss_dia`, `spring_bore_depth` — body spring-anchor
  boss + blind bore for the captured rod.
- `bf_TL`, `bf_TR`, `bf_BL`, `bf_BR` — the four corners of the blue panel face
  (ground-truth coordinates); the `panel_face_place(u,v)` frame is built from them.
- `toggle_hole_dia`, `panel_drill` — toggle hole diameter / drill depth.
- `toggle_master_u`, `toggle_master_v` — master switch position (upper row).
- `toggle_row_u`, `toggle_row_v` — horn / reverse / lights positions (lower row).
- `meter_slot_l`, `meter_slot_w`, `meter_end_holes`, `meter_hole_span`,
  `meter_u`, `meter_v_right` — LED battery-meter slot + end-hole geometry / placement.
- `thumb_pos`, `thumb_dia`, `thumb_normal`, `thumb_drill` — thumb-button hole
  centre `[X,Z]`, diameter (6 mm), local surface normal, and drill depth. The
  hole is centred on Y = 0 so it splits into a semicircle per shell.
- `cable_pos`, `cable_normal` — DX16 connector centre `[X,Z]` on the grip butt
  and its local outward surface normal (the drilling / socket axis).
- `conn_hole_dia`, `conn_pad_dia`, `conn_pad_proud`, `conn_pad_y` — DX16 bore
  (16 mm), pad diameter (19 mm), pad proud height, and total pad length.
- `conn_reinf_dia`, `conn_reinf_len` — internal reinforcing collar diameter /
  inward depth (LEFT half only). `conn_recess_clear` — right-shell recess fit.
- `part_to_render` — `left_shell`, `right_shell`, `trigger`, `export_stl`,
  `partial_exploded_assembly`, `closed_assembly`, `exploded_assembly`.

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

## How to render

From the project root (paths in the file are relative):

```bash
# quick preview (isometric)
openscad -o renders/iso.png --camera=200,-260,150,-5,0,5 --viewall design3.scad

# clean orthographic side view (the ergonomic silhouette)
openscad -o renders/side.png --camera=0,300,0,0,0,0 --viewall --projection=o design3.scad

# export the print-ready plate (all three parts, print orientation)
openscad -o stl/export_plate.stl --render -D 'part_to_render="export_stl"' design3.scad
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

5. ~~**Button / switch holes on the raised blue face.**~~ **DONE** — the control
   panel is drilled into the raised blue face along the face normal, using a
   local face frame (`panel_face_place(u,v)`) built directly from the face's four
   corners. The LEFT half (`+Y`) carries **four 6 mm toggle holes**: the **master
   switch on its own upper row** and **horn / reverse / lights in a lower row**
   (15 mm pitch). The RIGHT half (`-Y`) carries the **LED battery-meter cutout**:
   a square `25.5 × 2.2 mm` slot with a `3.5 mm` hole at each end, `33 mm` apart.
   All holes stay clear of the two bolt bosses that pass under the face.

6. ~~**Trigger + pivot.**~~ **DONE** — `trigger_lever()` pivots at `pivot_pos`
   with: a **finger blade** exiting the concave throat notch right next to the
   pivot at ~`[-8, 3]` (`trigger_exit`), pointing up-and-forward at ~45°, then
   BENDING at a knee back to a curled finger tip near `[0, 30]`; and an
   **actuator arm** with an enclosed **elongated fork slot** that straddles the
   pot lever. The **pivot** uses a short rod captured in blind-bore bosses in
   both halves (the trigger hub rotates in the gap between them); the throat has
   a swing cutout (`trigger_throat_cut()`). A **return spring** hooks a 2 mm
   hole in the armature (`spring_trigger_pos`) and a rod in a body anchor boss
   (`spring_anchor_pos`), pulling the trigger toward rest. Pivot pin and spring
   rod share one `rod_dia = 3 mm` stock. Render via `part_to_render = "trigger"`
   or see it in the assemblies.

7. ~~**Cable exit / connector** at the base of the grip.~~ **DONE** — a
   panel-mount **DX16** aviation socket on the rear of the grip butt at
   `cable_pos = [65, 12]`, along the local surface normal. Since a threaded
   connector needs a flat full-thickness seat, it is NOT a split semicircle:
   instead a moulded round **pad** (`connector_pad()`, Ø19, 2 mm proud + 3 mm in)
   on the LEFT shell crosses the seam so the Ø16 hole stays centred, the RIGHT
   shell has a matching recess, and an internal **reinforcing collar**
   (`connector_reinforce()`, LEFT half only) thickens the wall for strength. The
   nut tightens on the inside; ~2 mm of the 7 mm thread projects past the pad.

8. ~~**Validate & export.**~~ **DONE** — full CGAL renders (`grip_round = 3`,
   minkowski rounding) with no errors; each part is manifold (`Simple: yes`).
   `part_to_render = "export_stl"` renders a **single print-ready plate** with
   all three parts (both shells + trigger) pre-rotated to their print
   orientation (split face on the bed: left shell −90°, right shell / trigger
   +90° about X), sat on `Z = 0` and spaced apart along Y. Export it in one go:

   `openscad -o stl/export_plate.stl --render -D 'part_to_render="export_stl"' design3.scad`

   The individual `left_shell` / `right_shell` / `trigger` part modes are still
   available for exporting a single part (in the model's native orientation).

## Known cleanups / notes

- The inline outline is a simplified version of the DXF (49 points via
  Douglas-Peucker, ~0.3 mm tolerance). Regenerate with a tighter tolerance if a
  closer match to the original mesh is ever needed.
- The pot axis is diagonal (~−51°); the slide pot mounts at that angle.
- Edge rounding uses `minkowski()`, which needs a full CGAL render
  (`openscad --render ...`) and is slow (~15–30 s). For fast iteration while
  working on other features, set `grip_round = 0`, then restore it for final
  renders / export.
