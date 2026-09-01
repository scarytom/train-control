# Train Controller (slot-car hand controller)

Parametric OpenSCAD model of an ergonomic pistol-grip slot-car controller,
based on the shape of an existing printed controller (`Left.stl` / `Right.stl`).

## Files

| File                            | Purpose                                                                           | Status                |
|---------------------------------|-----------------------------------------------------------------------------------|-----------------------|
| `design3.scad`                  | **Current working model.** Self-contained (no external files).                    | Active — work here    |
| `design2.scad`                  | Same geometry as v3 but loads the outline from `profiles/body_outline.dxf`.       | Superseded by v3      |
| `design.scad`                   | Original hand-drawn v1 (chunky constant-thickness box, trigger, bosses, cutouts). | Legacy reference only |
| `profiles/body_outline.dxf`     | Ergonomic outline projected from `Left.stl`. Used by `design2.scad`.              | Input for v2          |
| `ref/Left.stl`, `ref/Right.stl` | Example printed controller shells (ground-truth ergonomic shape).                 | Reference             |
| `controller3.jpg`               | Photo of the reference controller.                                                | Reference             |
| `renders/`                      | Rendered preview PNGs.                                                            | Build output          |

Recommended: continue in **`design3.scad`** — it is a single self-contained file.

## Coordinate convention

- **X** = along the controller length. Head / (former) finger-slot at **−X**, grip / butt at **+X**.
- **Z** = up / down (the silhouette height).
- **Y** = thickness. The two shell halves separate along **Y**; the profile is centred on Y = 0.

## What the model produces

`design3.scad` produces a complete, print-ready **hollow two-part shell** with
trigger, internal pot mount, control panel and connector:

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
   trap) with alignment spigots
9. **Linear pot mount** — a solid cradle in the LEFT half holding a Bourns
   PTA3043 (45×9×6.5 mm) along the recorded diagonal pot axis. The pot is inset
   into the left half so only its 10 mm lever crosses the split (leaving a
   channel for the trigger armature), seats against a ledge, and has a 3 mm
   wire-exit gap at the pot's higher end.
10. **Trigger + pivot + return spring** — a trigger lever (`trigger_lever()`)
    pivoting at `pivot_pos`: a BENT finger blade exiting the throat up-and-forward
    at ~45°, then curling back to a finger tip near `[0, 30]`, and an actuator arm
    with an elongated fork slot driving the pot lever.
    The pivot pin and spring anchor share a 3 mm rod (`rod_dia`), each captured
    in blind-bore bosses. A return spring hooks a hole in the armature and a
    rod in a body anchor boss, pulling the trigger to rest.
11. **Control panel** — holes drilled into the raised blue face along its normal
    via a face frame built from the face's four corners (`panel_face_place`). The
    LEFT half has four 6 mm toggle holes (master on its own row; horn / reverse /
    lights in a row at 15 mm pitch); the RIGHT half has the LED battery-meter
    cutout (square 25.5 × 2.2 mm slot + two 3.5 mm end holes, 33 mm apart). All
    clear of the bolt bosses.
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

## Assembly & fasteners

- **Bolts:** six M3 through-bolts (`screw_boss_pos`). Each drops into a round
  head recess on the LEFT outer face, through a 3.4 mm clearance hole, into a
  hex **nut trap** (`nut_af = 5.5 mm` A/F) on the RIGHT face. Right-half
  **spigots** register into left-half counterbores for alignment.
- **Rods:** the trigger pivot pin and the spring anchor share one `rod_dia`
  (3 mm) steel rod, each captured in blind-bore bosses.
- **Print plate:** `part_to_render = "export_stl"` lays all three parts on the
  bed in print orientation (left shell −90°, right shell / trigger +90° about X),
  each on `Z = 0` and spaced along Y. Each part is manifold (`Simple: yes`).
  The `left_shell` / `right_shell` / `trigger` modes export a single part in its
  native orientation.

## Notes

- The inline outline is a simplified version of the DXF (49 points via
  Douglas-Peucker, ~0.3 mm tolerance). Regenerate with a tighter tolerance if a
  closer match to the original mesh is ever needed.
- The pot axis is diagonal (~−51°); the slide pot mounts at that angle.
- Edge rounding uses `minkowski()`, which needs a full CGAL render
  (`openscad --render ...`) and is slow (~15–30 s). For fast iteration while
  working on other features, set `grip_round = 0`, then restore it for final
  renders / export.
