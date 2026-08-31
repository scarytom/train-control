// ============================================================
// TRAIN CONTROLLER - self-contained parametric hand controller.
// The ergonomic outline is embedded as a polygon() (simplified from Left.stl).
//
// COORDINATE CONVENTION:
//   X = controller length (head/nose at -X, grip/butt at +X)
//   Z = up/down (silhouette height)
//   Y = thickness (the two shell halves separate along Y=0)
// ============================================================

$fn = 48;

// --- RENDER SELECTION ---
// Options: "left_shell", "right_shell", "trigger", "export_stl",
//          "partial_exploded_assembly", "exploded_assembly", "closed_assembly".
part_to_render = "partial_exploded_assembly";

// --- THICKNESS TAPER (Y) : slim grip, broad head ---
grip_thick   = 25.0;   // Y thickness at the grip / trigger region (mm)
head_thick   = 60.0;   // Y thickness at the rear-top head (mm)
taper_head_x = -20.0;  // X at/below which full head_thick is used (head side, -X)
taper_grip_x =   5.0;  // X at/above which grip_thick is used (grip side, +X)

// --- BUTTON CLEARANCE : room above the pot for buttons + wiring ---
// Pushes the angled ~50deg button face (outline edge 30->31) OUTWARD along its
// normal by this amount (see button_face_normal / button_move_idx below).
button_clearance = 20.0;   // mm the button face is pushed out along its normal

// ------------------------------------------------------------
// 2D OUTLINE (embedded)
// ------------------------------------------------------------
// Ergonomic pistol-grip silhouette in its native X x height plane.
// Points 0-33 = outer body, 34-43 = (former finger slot, now unused),
// 44-48 = small pivot hole. See outline_paths for which are used.
outline_points = [
  [-30.17, -39.54], [0.26, -31.57], [5.49, -31.68], [11.58, -33.66],
  [13.32, -33.58], [14.57, -32.37], [18.05, -24.45], [22.6, -20.38],
  [45.87, -15.85], [62.59, -10.8], [68.85, -8.08], [71.59, -5.88],
  [73.74, -2.77], [74.46, 0.39], [73.97, 2.85], [58.71, 22.07],
  [55.61, 23.47], [52.26, 22.74], [17.33, 8.76], [12.72, 6.1],
  [6.95, 1.06], [1.48, -0.33], [-3.5, -0.13], [-6.68, 1.4],
  [-21.98, 20.46], [-25.57, 23.54], [-28.68, 24.7], [-35.32, 24.67],
  [-71.14, 13.34], [-72.45, 10.9], [-71.77, 8.39], [-33.8, -37.68],
  [-32.1, -39.13], [-30.33, -39.55],
  // finger slot
  [-34.06, -29.16], [-35.75, -28.26], [-60.86, 2.22], [-61.42, 4.05],
  [-60.52, 5.74], [-58.69, 6.3], [-57, 5.4], [-31.89, -25.08],
  [-31.52, -27.67], [-33.66, -29.17],
  // small pivot hole
  [-12.9, 1.13], [-13.78, 2.14], [-12.76, 3.11], [-11.79, 2.09],
  [-12.81, 1.12]
];

// path[0] = outer body only. Points 34-48 (former finger slot + pivot marker)
// are intentionally not referenced; the pivot is bored later (see pivot_pos).
outline_paths = [
  [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19,
   20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33]
];

module outline_2d() {
    polygon(points = outline_points, paths = outline_paths);
}

// Outline with the blue button face pushed OUTWARD along its normal by
// button_clearance. The face is moved together with its corner-fillet points
// (rear {28,29,30}, front {31,32,33,0}) so the curves travel with it and the
// adjacent long edges re-angle smoothly instead of kinking.
button_face_normal = [-0.772, -0.636];  // outward normal of edge 30->31 (~ -140.5 deg)
button_move_idx    = [28, 29, 30, 31, 32, 33, 0];  // blue face + both corner fillets

function _moved(i) =
    (search(i, button_move_idx) != [])
        ? [ outline_points[i][0] + button_face_normal[0] * button_clearance,
            outline_points[i][1] + button_face_normal[1] * button_clearance ]
        : outline_points[i];

raised_outline_points = [ for (i = [0 : len(outline_points) - 1]) _moved(i) ];

module raised_outline_2d() {
    polygon(points = raised_outline_points, paths = outline_paths);
}

// ------------------------------------------------------------
// LINEAR POT LOCATION (was the original finger slot)
// ------------------------------------------------------------
// The finger slot we removed marks exactly where the internal slide
// potentiometer mounts. We preserve its geometry here as data so the future
// pot mount/pocket can be placed on the same axis. Coordinates are in the
// outline's X (length) x Z (height) plane (pot lies in the X-Z plane, centred
// on Y=0). Derived from the original slot polygon points.
pot_axis_rear  = [-59.7,  4.7];   // rear-upper end of the slot centerline [X, Z]
pot_axis_front = [-33.4, -27.9];  // front-lower end of the slot centerline [X, Z]
pot_axis_len   = 41.9;            // centerline length (mm)
pot_axis_angle = -51.1;           // angle of the slot from +X in the X-Z plane (deg)
pot_axis_mid   = [ (pot_axis_rear[0]+pot_axis_front[0])/2,
                   (pot_axis_rear[1]+pot_axis_front[1])/2 ];  // = ~[-46.5, -11.6]

// ------------------------------------------------------------
// LINEAR POT MOUNT (Bourns PTA3043, held directly by the shell — option B)
// ------------------------------------------------------------
// Body envelope 45 (L) x 9 (W) x 6.5 (H) mm, 30 mm travel. The pot lies with:
//   local X = length  -> along the pot axis (pot_axis_angle in the X-Z plane)
//   local Z = width   -> across the axis, in the X-Z plane
//   local Y = height  -> along global Y; the slider LEVER emerges across the
//                        split plane (toward one half).
pot_len    = 45.0;   // body length (mm)
pot_wid    = 9.0;    // body width (mm)
pot_hgt    = 6.5;    // body height (mm) -> along Y
pot_fit    = 0.4;    // clearance around the body in the pocket (mm)
pot_inset  = 5.0;    // how far the pot TOP sits below the split (into +Y), so
                     // the trigger armature can travel past it near Y=0. The
                     // 10 mm lever still reaches across the split.
pot_wall   = 1.6;    // cradle wall thickness around the pocket (mm)
pot_pin_gap = 3.0;   // clearance below the body for solder pins (mm, -Y of body)
pot_lever_slot_w = 6.0;  // width of the lever clearance slot across the split
pot_shift  = 10.0;   // shift along the pot LONG axis; +ve = toward the back of
                     // the controller (grip/butt side), giving the trigger
                     // armature an easier sweep to reach the pot.

// Places children into the pot's local frame: origin at pot_axis_mid (Y=0),
// local +X along the pot axis (local +X points toward the back/grip side of the
// controller, so pot_shift>0 moves the pot toward the back). Rotation about
// global Y by -pot_axis_angle maps local X onto the axis direction in the X-Z plane.
module pot_place() {
    translate([pot_axis_mid[0], 0, pot_axis_mid[1]])
        rotate([0, -pot_axis_angle, 0])
            translate([pot_shift, 0, 0])
                children();
}

// The pot BODY occupies Y in [pot_inset, pot_inset+pot_hgt]; the top of the pot
// is at Y=pot_inset (leaving ~pot_inset mm of clearance at the split for the
// trigger armature). The LEVER (10 mm) protrudes from that face across the
// split into -Y. The pot inserts from the split side and seats against a LEDGE
// at Y = pot_inset+pot_hgt (the cradle floor), so only the lever crosses.
module pot_body_envelope(extra = 0) {
    pot_place()
        translate([0, pot_inset + pot_hgt/2, 0])
            cube([pot_len + 2*extra, pot_hgt + 2*extra, pot_wid + 2*extra], center = true);
}

// Cradle SOLID: a block around the pot that reaches from just below the pot top
// (Y=pot_inset) out to the left half's OUTER wall, so it melds with the side
// wall. Trimmed to the body so it fuses to the shell. Starting at Y=pot_inset
// (not the split) leaves an open channel Y in [0, pot_inset] at the split for
// the trigger armature to travel past. Lives only in the +Y (left) half.
module pot_cradle_solid() {
    y0 = pot_inset;          // cradle top (toward split)
    y1 = 100;                // well beyond the outer wall
    pot_place()
        translate([0, (y0 + y1)/2, 0])
            cube([pot_len + 2*pot_wall, y1 - y0, pot_wid + 2*pot_wall], center = true);
}

// Pocket the pot body drops into (fit clearance), OPEN at the split face and
// stopping at the LEDGE (Y = pot_inset + pot_hgt + fit). Beyond the ledge stays
// solid. Depth spans from -2 (open past the split) up to the ledge.
module pot_pocket() {
    ledge = pot_inset + pot_hgt + pot_fit;   // +Y face of the pocket (the ledge)
    y_lo  = -2;                               // open a bit past the split
    pot_place()
        translate([0, (y_lo + ledge)/2, 0])
            cube([pot_len + 2*pot_fit, ledge - y_lo, pot_wid + 2*pot_fit], center = true);
}

// Lever clearance slot: a narrow channel on the split (Y ~ 0) crossing into the
// other half, along the pot's travel, so the slider lever + trigger arm move
// freely. Narrower than the pot so it doesn't undercut the cradle walls.
module pot_lever_slot() {
    pot_place()
        translate([0, 0, 0])
            cube([pot_len - 2, 10, pot_lever_slot_w], center = true);  // Y -5..+5 across split
}

// Pin clearance: channel beyond the ledge (deep +Y end) for solder pins.
module pot_pin_clearance() {
    pot_place()
        translate([0, pot_inset + pot_hgt + pot_fit + pot_pin_gap/2, 0])
            cube([pot_len - 4, pot_pin_gap + 2, pot_wid - 1], center = true);
}

// Wire-exit gap: a narrow notch through the short end of the cradle at the
// HIGHER end of the pot (local -X end, higher in Z), from the pin region out
// through the end wall, so the wires soldered to the pins escape into the cavity.
pot_wire_gap_w = 3.0;   // wire gap width across the pot (local Z), mm
module pot_wire_gap() {
    y0 = pot_inset;                                       // from the pot top...
    y1 = pot_inset + pot_hgt + pot_fit + pot_pin_gap + 3; // ...to beyond the pins
    pot_place()
        // at the -X (higher) end; thin in local X to punch the end wall,
        // pot_wire_gap_w wide across the pot (local Z).
        translate([-pot_len/2, (y0 + y1)/2, 0])
            cube([pot_wall*2 + 4, y1 - y0, pot_wire_gap_w], center = true);
}

// ADD material for the cradle (left half only), and the CUTS to remove.
module pot_mount_add() {
    intersection() { pot_cradle_solid(); body_solid(); keep_left(); }
}
module pot_mount_cut() { pot_pocket(); pot_lever_slot(); pot_pin_clearance(); pot_wire_gap(); }

// ------------------------------------------------------------
// TRIGGER PIVOT LOCATION
// ------------------------------------------------------------
// Centre of the trigger-lever pivot, in the outline X-Z plane on Y=0
// (from the small marker hole in the source STL). The pivot is captured in
// blind-bore bosses in both shells (see pivot_boss / pivot_bore).
pivot_pos = [-12.81, 1.92];   // [X, Z] centre of the trigger pivot
// A single metal ROD diameter is used for BOTH the trigger pivot pin and the
// spring anchor rod (cut from the same stock). 3mm is a common, easily-sourced
// steel dowel / silver-steel size.
rod_dia   = 3.0;              // shared pivot-pin / spring-anchor rod diameter (mm)
pivot_dia = rod_dia;          // pivot pin uses the shared rod

// The trigger BLADE exits the body through the concave THROAT notch next to the
// pivot at ~trigger_exit; the ACTUATOR ARM reaches from the pivot to the pot
// lever, sweeping in the clear channel at the split (see pot_inset / pot_shift).
trigger_exit = [-8, 3];       // [X, Z] where the trigger blade exits the throat
// ------------------------------------------------------------
// BUTTON / SWITCH PANEL on the raised blue face (edge 30->31, raised)
// ------------------------------------------------------------
// Frame built directly from the FOUR CORNERS of the blue face (given as ground
// truth). No angle guessing. The local frame at the face:
//   +u (local X) = along the face edge in X-Z (toward the low-Z / +X corner)
//   +v (local Y) = along the face's Y direction (~ global +Y; left half = +Y)
//    n (local Z) = OUTWARD face normal (= uedge x uy). A child built at +Z sits
//                  outside the face; cutters extend along -Z to drill inward.
// panel_face_place(u,v) places a child at (u,v) mm on the face in this frame.
// Corners: TL(+Y,Zhi) TR(+Y,Zlo) BL(-Y,Zhi) BR(-Y,Zlo)
bf_TL = [ -85,  30,   0 ];
bf_TR = [ -48,  30, -50 ];
bf_BL = [ -88, -30,   0 ];
bf_BR = [ -48, -30, -50 ];

bf_center = (bf_TL + bf_TR + bf_BL + bf_BR) / 4;
function _unit(v) = v / norm(v);
bf_uedge = _unit(((bf_TR - bf_TL) + (bf_BR - bf_BL)) / 2);  // +u toward Zlo/+X
bf_uy    = _unit(((bf_TL - bf_BL) + (bf_TR - bf_BR)) / 2);  // +v toward +Y
bf_n     = _unit(cross(bf_uedge, bf_uy));                   // outward normal

module panel_face_place(u, v) {
    // columns: local X = uedge, local Y = uy, local Z = outward normal, + origin
    multmatrix([
        [ bf_uedge[0], bf_uy[0], bf_n[0], bf_center[0] ],
        [ bf_uedge[1], bf_uy[1], bf_n[1], bf_center[1] ],
        [ bf_uedge[2], bf_uy[2], bf_n[2], bf_center[2] ],
        [ 0,           0,        0,       1            ],
    ])
    translate([u, v, 0])
        children();
}

// --- switch / meter parameters ---
toggle_hole_dia = 6.2;   // 6mm bushing + clearance
panel_drill     = 30;    // how far the drill cylinder runs (through the wall)

// The 4 toggles sit on the LEFT (+v) half of the face. They must stay clear of
// the two bolt bosses that pass under the face at u=-25 and u=+29 (which span
// the full Y), so all switches live in the clear window u in [-18, +22].
// Layout: MASTER on its own upper row; HORN / REVERSE / LIGHTS in a lower row.
toggle_master_u   = 2;                 // master switch u (upper row)
toggle_master_v   = 20;                // master switch v (nearer the +Y edge)
toggle_row_u      = [ -13, 2, 17 ];    // horn / reverse / lights u (lower row, 15mm pitch)
toggle_row_v      = 7;                 // lower-row v (nearer the split)

// meter (right half)
meter_slot_l = 25.5;     // slot length
meter_slot_w = 2.2;      // slot width
meter_end_holes = 3.5;   // end hole diameter
meter_hole_span = 33;    // distance between the two end holes
meter_v_right   = -19;   // Y offset into the RIGHT (-Y) half
meter_u         = 0;     // along-edge position of the meter centre

// A single round toggle mounting hole. The drill starts slightly OUTSIDE the
// face (local +Z = outward) and runs inward (-Z) through the wall, so it always
// fully penetrates regardless of small origin offsets.
module toggle_hole(u, v) {
    panel_face_place(u, v)
        // span local z from +5 (outside) to +5 - panel_drill (inside)
        translate([0, 0, 5 - panel_drill/2])
            cylinder(h = panel_drill, d = toggle_hole_dia, center = true);
}

// LED battery-meter cutout: central slot + two end holes, on the face at meter_u.
module meter_cutout(u, v) {
    panel_face_place(u, v)
        translate([0, 0, 5 - panel_drill/2]) {
            // central rectangular slot (square corners)
            cube([meter_slot_l, meter_slot_w, panel_drill], center = true);
            // two end holes, meter_hole_span apart, centred on the slot line
            translate([ meter_hole_span/2, 0, 0]) cylinder(h = panel_drill, d = meter_end_holes, center = true);
            translate([-meter_hole_span/2, 0, 0]) cylinder(h = panel_drill, d = meter_end_holes, center = true);
        }
}

// All panel cuts for the LEFT half (the 4 toggles, in two rows).
module panel_cuts_left() {
    toggle_hole(toggle_master_u, toggle_master_v);   // master (upper row)
    for (u = toggle_row_u) toggle_hole(u, toggle_row_v);  // horn / reverse / lights
}
// All panel cuts for the RIGHT half (the LED meter).
module panel_cuts_right() {
    meter_cutout(meter_u, meter_v_right);
}

// --- THUMB BUTTON (on the split) ---
// A 6mm push button on the Y=0 split (halved into a semicircle in each shell),
// drilled along the measured local surface normal at thumb_pos.
thumb_pos      = [ 9, -32 ];        // [X, Z] centre on the surface
thumb_dia      = 6.2;              // 6mm button + clearance (matches the toggles)
thumb_normal   = [ -0.16, 0, -0.99 ];  // measured outward surface normal
thumb_drill    = 10;               // just deep enough to clear the wall (spans
                                   // ~5mm outside to ~5mm inside the surface)

// Full round cutter (both halves see it; keep_left/keep_right split it into two
// semicircles at Y=0). Built along the local normal, starting outside the face.
module thumb_button_cut() {
    // basis: align local +Z with thumb_normal
    n  = thumb_normal / norm(thumb_normal);
    // pick any in-plane axis: cross with global Y
    ax0 = cross([0,1,0], n);
    ax  = ax0 / norm(ax0);
    ay  = cross(n, ax);
    translate([thumb_pos[0], 0, thumb_pos[1]])
        multmatrix([
            [ ax[0], ay[0], n[0], 0 ],
            [ ax[1], ay[1], n[1], 0 ],
            [ ax[2], ay[2], n[2], 0 ],
            [ 0,     0,     0,    1 ],
        ])
        translate([0, 0, 5 - thumb_drill/2])
            cylinder(h = thumb_drill, d = thumb_dia, center = true);
}

// --- DX16 CONNECTOR (rear of the grip butt) ---
// A DX16 aviation socket (16mm hole, 7mm thread, retained by an inner nut) needs
// a FLAT full-thickness pad, not a split semicircle. So we mould a round flat
// pad into the LEFT shell, centred on the Y=0 line, that crosses the split into
// the RIGHT shell (which gets a matching recess). The socket goes in from
// outside; the nut tightens on the inside flat.
cable_pos    = [ 65, 12 ];          // [X, Z] centre on the rear of the grip butt
cable_normal = [ 0.78, 0, 0.62 ];   // outward surface normal (back-up)
conn_hole_dia = 16.0;               // DX16 panel hole
conn_pad_dia  = 19.0;               // flat mounting pad (round)
conn_pad_proud = 2.0;               // pad thickness proud of the surface (<= thread)
conn_pad_y    = 5.0;                // total pad length (2mm proud + 3mm inward)
conn_recess_clear = 0.3;            // clearance around the pad in the right-shell recess
// Internal reinforcement collar: thickens the wall locally around the socket so
// the Ø16 hole has more material to grip (strength). Reaches inward from the
// surface; the hole bores through it. Crosses the seam like the pad.
conn_reinf_dia = 28.0;              // collar outer diameter
conn_reinf_len = 3.0;               // inward reach (kept short so the thread still
                                    // projects through for the nut)

// Transform: origin at the surface point [X,0,Z], local +Z along the OUTWARD
// normal. Children built at +Z sit outside; at -Z go inward.
module normal_place(pos, nrm) {
    n   = nrm / norm(nrm);
    ax0 = cross([0,1,0], n);
    ax  = ax0 / norm(ax0);
    ay  = cross(n, ax);
    translate([pos[0], 0, pos[1]])
        multmatrix([
            [ ax[0], ay[0], n[0], 0 ],
            [ ax[1], ay[1], n[1], 0 ],
            [ ax[2], ay[2], n[2], 0 ],
            [ 0,     0,     0,    1 ],
        ])
            children();
}

// Flat round pad, proud of the surface by conn_pad_proud and reaching inward,
// coaxial with the connector hole. (Trimmed to fuse with the body by the caller.)
module connector_pad(extra = 0) {
    normal_place(cable_pos, cable_normal)
        translate([0, 0, conn_pad_proud - conn_pad_y])
            cylinder(h = conn_pad_y, d = conn_pad_dia + 2*extra, center = false);
}
// Ø16 through-hole along the normal (from outside the pad, well through the wall).
module connector_hole() {
    normal_place(cable_pos, cable_normal)
        translate([0, 0, -25 + conn_pad_proud])
            cylinder(h = 40, d = conn_hole_dia, center = false);
}
// Recess in the RIGHT shell for the pad to nest into (pad shape + clearance).
module connector_recess() {
    connector_pad(conn_recess_clear);
}

// Internal reinforcing collar around the socket (adds material inward from the
// surface). Trimmed to the body so it never protrudes outside; the hole bores
// through it. Kept in the LEFT half only (clipped at the seam) so it thickens
// the left wall without removing material from the right shell.
module connector_reinforce() {
    intersection() {
        normal_place(cable_pos, cable_normal)
            translate([0, 0, -conn_reinf_len])
                cylinder(h = conn_reinf_len + 0.01, d = conn_reinf_dia, center = false);
        body_solid();
        keep_left();
    }
}

// ------------------------------------------------------------
// TRIGGER LEVER (pivots at pivot_pos; blade exits the throat; actuator arm
// reaches the pot lever). All in the X-Z plane, extruded in Y and centred so it
// lives in the clear channel at the split plane.
// ------------------------------------------------------------
trigger_thick   = 6.0;    // Y thickness of the trigger lever (mm)
trigger_pin_dia = pivot_dia;          // pivot pin diameter (matches body hole)
trigger_bore    = pivot_dia + 0.4;    // pivot bore in the trigger (running fit)
trigger_hub_dia = 10.0;   // hub diameter around the pivot
// Blade: exits the throat at trigger_exit and extends OUTSIDE the body up-and-
// forward (+X, +Z) at ~45 deg for the finger to pull.
trigger_blade_len = 25.0;             // blade length beyond the exit (mm)
trigger_blade_ang = 45;               // direction from the exit, deg (+X,+Z)
trigger_blade_tip = [ trigger_exit[0] + trigger_blade_len*cos(trigger_blade_ang),
                      trigger_exit[1] + trigger_blade_len*sin(trigger_blade_ang) ];
trigger_blade_w   = 7.0;        // blade width
// The blade is BENT: it runs straight from the exit to a knee, then curls back
// toward the finger tip. trigger_blade_knee is partway along the first (45 deg)
// segment; trigger_blade_tip2 is the final tip (curled up-and-back).
trigger_blade_knee = [ trigger_exit[0] + 6*cos(trigger_blade_ang),
                       trigger_exit[1] + 6*sin(trigger_blade_ang) ];
trigger_blade_tip2 = [ 0, 30 ];   // curled finger tip [X, Z]
// Actuator arm: a STRAIGHT run from the pivot to the pot lever engagement point
// (roughly opposite the blade). Longer + fatter, with a FORK slot cut right
// through the tip so it straddles the pot lever and drives it both ways.
trigger_arm_aim   = [-40, -19]; // aim point along the arm direction (~pot centre)
trigger_arm_extra = 4.0;        // extend the arm this far past the aim point (mm)
// arm tip = aim point pushed further along the pivot->aim direction by extra
trigger_arm_end   = let(
        dx = trigger_arm_aim[0] - pivot_pos[0],
        dz = trigger_arm_aim[1] - pivot_pos[1],
        L  = sqrt(dx*dx + dz*dz)
    ) [ trigger_arm_aim[0] + trigger_arm_extra*dx/L,
        trigger_arm_aim[1] + trigger_arm_extra*dz/L ];
trigger_arm_w     = 10.0;       // arm width (fatter)
trigger_arm_pad   = 12.0;       // diameter of the forked tip pad
trigger_fork_slot = 4.5;        // fork slot width (fits the ~3mm pot lever)
trigger_fork_len  = 6.0;        // elongated slot length along the arm (kept
                                // inside the tip pad so it's an enclosed hole)
trigger_fork_pivot_ext = 7.0;   // extend the slot this far toward the pivot end

// --- RETURN SPRING ---
// A small extension spring pulls the armature toward lower Z (rest position).
// One end hooks a 2mm hole in the armature; the other end attaches to a rod
// captured in a blind-bore boss in the body (like the pivot rod).
spring_trigger_pos = [-17, -5]; // [X,Z] spring hole in the armature
spring_hole_dia    = 2.0;       // spring hook hole diameter
spring_anchor_pos  = [0, -25];  // [X,Z] body anchor point (spring pulls to here)
spring_rod_dia     = rod_dia;   // anchor rod uses the shared rod (same stock)
spring_boss_dia    = 6.0;       // anchor boss diameter
spring_bore_depth  = 8.0;       // blind bore depth into each anchor boss

// 2D trigger profile in the X-Z plane (before extrude).
module trigger_profile_2d() {
    difference() {
        union() {
            // pivot hub
            translate(pivot_pos) circle(d = trigger_hub_dia);
            // blade: hub -> throat exit -> finger tab
            hull() {
                translate(pivot_pos) circle(d = trigger_blade_w);
                translate(trigger_exit) circle(d = trigger_blade_w);
            }
            // bent blade: exit -> knee (straight up-forward) ...
            hull() {
                translate(trigger_exit)      circle(d = trigger_blade_w);
                translate(trigger_blade_knee) circle(d = trigger_blade_w);
            }
            // ... then knee -> curled tip (bends back toward the finger)
            hull() {
                translate(trigger_blade_knee) circle(d = trigger_blade_w);
                translate(trigger_blade_tip2) circle(d = trigger_blade_w);
            }
            // actuator arm: hub -> pot engagement pad
            hull() {
                translate(pivot_pos) circle(d = trigger_arm_w);
                translate(trigger_arm_end) circle(d = trigger_arm_pad);
            }
        }
        // pivot bore
        translate(pivot_pos) circle(d = trigger_bore);
        // spring anchor hole (for the return spring hook)
        translate(spring_trigger_pos) circle(d = spring_hole_dia);
    }
}

// The 3D trigger lever, centred on Y=0, thickness trigger_thick, with a FORK
// slot cut into the actuator tip so it straddles the pot lever.
module trigger_lever() {
    // arm direction angle (pivot -> tip), for orienting the slot along the arm
    arm_ang = atan2(trigger_arm_end[1] - pivot_pos[1],
                    trigger_arm_end[0] - pivot_pos[0]);
    difference() {
        rotate([90, 0, 0])
            linear_extrude(height = trigger_thick, center = true)
                trigger_profile_2d();
        // Fork slot at the arm tip: an ENCLOSED elongated (obround) hole. It is
        // elongated ALONG THE ARM (radially from the pivot) so the pot lever
        // slides along the slot as the arm swings. Cut right through the arm
        // thickness (centred on Y=0), staying inside the tip pad so it does NOT
        // break out of the end.
        translate([trigger_arm_end[0], 0, trigger_arm_end[1]])
            rotate([0, -arm_ang, 0])             // align long axis with the arm
                rotate([90, 0, 0])               // extrude along Y (through the arm)
                    linear_extrude(height = trigger_thick + 4, center = true)
                        hull() {
                            // tip-side end (unchanged); pivot-side end extended
                            // by trigger_fork_pivot_ext toward the pivot (local -X).
                            translate([ trigger_fork_len/2, 0]) circle(d = trigger_fork_slot);
                            translate([-trigger_fork_len/2 - trigger_fork_pivot_ext, 0])
                                circle(d = trigger_fork_slot);
                        }
    }
}

// Pivot support: a BOSS on each half around the pivot axis, with a BLIND bore
// for a short metal pivot rod captured between the halves. The trigger's hub
// (trigger_thick wide, centred on Y=0) rotates in the gap between the bosses.
pivot_boss_dia  = 10.0;               // pivot boss diameter
pivot_hub_gap   = trigger_thick/2 + 0.5;  // Y where the boss stops (clear of hub)
pivot_bore_dia  = pivot_dia + 0.3;    // rod bore (running fit)
pivot_bore_depth = 8.0;               // blind bore depth into each boss

// side = +1 -> +Y (left) half, -1 -> -Y (right) half.
module pivot_boss(side) {
    // boss column from the hub gap outward to well past the outer wall,
    // trimmed to the body so it fuses to the wall.
    intersection() {
        translate([pivot_pos[0], side*pivot_hub_gap, pivot_pos[1]])
            rotate([side>0 ? -90 : 90, 0, 0])
                cylinder(h = head_thick, d = pivot_boss_dia);
        body_solid();
    }
}
// Blind bore for the rod: from the hub-gap face inward (outward in Y) by depth.
module pivot_bore(side) {
    translate([pivot_pos[0], side*pivot_hub_gap, pivot_pos[1]])
        rotate([side>0 ? -90 : 90, 0, 0])
            cylinder(h = pivot_bore_depth, d = pivot_bore_dia);
}

// Spring ANCHOR boss + blind bore: captures a short rod between the halves at
// spring_anchor_pos, that the return spring's far end attaches to. Same scheme
// as the pivot. The rod is exposed near the split (Y ~ 0) for the spring hook.
module spring_boss(side) {
    intersection() {
        translate([spring_anchor_pos[0], side*pivot_hub_gap, spring_anchor_pos[1]])
            rotate([side>0 ? -90 : 90, 0, 0])
                cylinder(h = head_thick, d = spring_boss_dia);
        body_solid();
    }
}
module spring_bore(side) {
    translate([spring_anchor_pos[0], side*pivot_hub_gap, spring_anchor_pos[1]])
        rotate([side>0 ? -90 : 90, 0, 0])
            cylinder(h = spring_bore_depth, d = spring_rod_dia + 0.3);
}

// Throat cutout: a slot in the body at the throat so the blade can pass through
// the wall and swing. Spans from the pivot out past the exit point (for swing
// clearance) with extra opening toward LOWER Z for the blade's downward sweep.
// Slightly wider than the blade, spanning the trigger thickness + clearance.
trigger_throat_ext    = 6.0;    // extension past the exit along the blade dir
trigger_throat_lowext = 8.0;    // extra opening toward lower Z (blade swing)
module trigger_throat_cut() {
    slot_w = trigger_blade_w + 3;      // clearance around the blade
    slot_t = trigger_thick + 2;        // Y clearance
    // extension past the exit along the blade direction, for swing room
    ext = [ trigger_exit[0] + trigger_throat_ext*cos(trigger_blade_ang),
            trigger_exit[1] + trigger_throat_ext*sin(trigger_blade_ang) ];
    // a point extended toward LOWER Z (and slightly +X) to open the low-Z end
    lowext = [ trigger_exit[0] + trigger_throat_lowext*cos(trigger_blade_ang - 90),
               trigger_exit[1] + trigger_throat_lowext*sin(trigger_blade_ang - 90) ];
    hull() {
        translate([pivot_pos[0], 0, pivot_pos[1]])
            rotate([90,0,0]) cylinder(h=slot_t, d=slot_w, center=true);
        translate([trigger_exit[0], 0, trigger_exit[1]])
            rotate([90,0,0]) cylinder(h=slot_t, d=slot_w, center=true);
        translate([ext[0], 0, ext[1]])
            rotate([90,0,0]) cylinder(h=slot_t, d=slot_w, center=true);
        translate([lowext[0], 0, lowext[1]])
            rotate([90,0,0]) cylinder(h=slot_t, d=slot_w, center=true);
    }
}

// ------------------------------------------------------------
// THICKNESS MASK: full head_thick over the head (-X), tapering to
// grip_thick over the grip (+X). Generous in X and Z; only Y varies.
// 'inset' shrinks Y on both sides (use -2*wall for inner cavity later).
// ------------------------------------------------------------
module thickness_mask(inset = 0) {
    ty_head = head_thick + inset;
    ty_grip = grip_thick + inset;
    z_span  = 400;
    x_end   = 300;   // far beyond either end
    eps     = 0.02;

    // Flat HEAD block: X from -x_end to taper_head_x, at head thickness.
    translate([(-x_end + taper_head_x)/2, 0, 0])
        cube([x_end + taper_head_x, ty_head, z_span], center=true);

    // Flat GRIP block: X from taper_grip_x to +x_end, at grip thickness.
    translate([(taper_grip_x + x_end)/2, 0, 0])
        cube([x_end - taper_grip_x, ty_grip, z_span], center=true);

    // Transition: hull only between the two boundary faces (thin slabs),
    // giving a straight taper from head to grip across [taper_head_x, taper_grip_x].
    hull() {
        translate([taper_head_x, 0, 0])
            cube([eps, ty_head, z_span], center=true);
        translate([taper_grip_x, 0, 0])
            cube([eps, ty_grip, z_span], center=true);
    }
}

// ------------------------------------------------------------
// SOLID BODY: outline extruded thick, then trimmed to the taper.
// The whole body is softened by grip_round so the edges the hand wraps are
// comfortable. Implemented by building the body slightly undersized (mask and
// extrude reduced by grip_round) then minkowski()-growing it back with a
// sphere, which fillets ALL edges by grip_round while preserving net size.
// ------------------------------------------------------------
grip_round = 3.0;   // edge rounding radius (mm); 0 disables rounding

module body_core(shrink = 0) {
    intersection() {
        rotate([90, 0, 0])
            linear_extrude(height = head_thick + 10 - 2*shrink, center = true)
                offset(r = -shrink) raised_outline_2d();
        thickness_mask(-2*shrink);   // shrink Y by 'shrink' on each side
    }
}

module body_solid() {
    if (grip_round > 0)
        minkowski() {
            body_core(grip_round);
            sphere(r = grip_round, $fn = 24);
        }
    else
        body_core(0);
}

// ------------------------------------------------------------
// HOLLOW SHELL
// ------------------------------------------------------------
// Inner cavity = the outer body surface shrunk inward by 'wall' everywhere.
// Built the same way as body_solid() but with an extra 'wall' of shrink, so a
// uniform wall thickness is left all around (including the ends).
wall = 1.5;   // shell wall thickness (mm)

module inner_cavity() {
    if (grip_round > 0)
        minkowski() {
            body_core(grip_round + wall);
            sphere(r = grip_round, $fn = 24);
        }
    else
        body_core(wall);
}

module body_hollow() {
    difference() {
        body_solid();
        inner_cavity();
    }
}

// ------------------------------------------------------------
// SPLIT INTO LEFT / RIGHT SHELLS (along Y = 0)
// ------------------------------------------------------------
// Big half-space cubes to keep one side of the split plane.
module keep_left()  { translate([-300, 0, -300]) cube([600, 300, 600]); }   // Y >= 0
module keep_right() { translate([-300, -300, -300]) cube([600, 300, 600]); } // Y <= 0

// ------------------------------------------------------------
// MATE FEATURES: screw bosses (M3 self-tap) with integral alignment spigots
// ------------------------------------------------------------
// All features are centred on the split plane (Y = 0) and run along Y; each
// shell keeps its own half after the keep_left/keep_right clip.
//
// Each screw boss is a solid column spanning the cavity wall-to-wall (so it is
// always anchored — no floating parts). Alignment is integral to the bosses:
// the RIGHT half boss carries a male SPIGOT that crosses the split plane into a
// female COUNTERBORE in the LEFT half boss, so the halves self-register.
// Fastening: an M3 bolt passes through a clearance hole in BOTH bosses; the
// LEFT (outer) face has a round bolt-head recess, the RIGHT (outer) face has a
// hexagonal recess that captures the nut.

// Fastening: an M3 bolt passes ALL THE WAY THROUGH a clearance hole in both
// halves. The LEFT (outer) face has a round recess for the bolt head; the
// RIGHT (outer) face has a HEXAGONAL recess that captures the nut so the bolt
// can be tightened from the head side alone.
screw_clear_dia  = 3.4;   // M3 clearance hole (through both halves)
screw_boss_dia   = 8.0;   // boss outer diameter

screw_head_dia   = 6.2;   // round recess diameter for the bolt head (left face)
screw_head_depth = 2.5;   // depth of the head recess

nut_af           = 5.5;   // M3 nut width across flats (A/F)
nut_across_corners = nut_af / cos(30);   // = ~6.35 mm, used for the hex recess
nut_depth        = 2.6;   // nut thickness + a little (capture depth, right face)

spigot_dia       = 4.5;   // male alignment spigot (on right boss)
spigot_len       = 3.0;   // how far it crosses the split into the left half
spigot_clear     = 0.2;   // fit clearance for the counterbore

// [X, Z] screw/boss locations (in the outline plane). Placed at corners /
// perimeter, kept CLEAR of the trigger<->pot armature path through the head
// centre. Verified inside the body with margin.
screw_boss_pos = [ [10, -13], [63, -5], [48, 15], [-31, 18], [-80, -3], [-45, -45] ];

// One screw-boss column (solid), centred on Y=0, spanning the full thickness.
module boss_column(p) {
    translate([p[0], 0, p[1]]) rotate([90, 0, 0])
        cylinder(h = head_thick + 4, d = screw_boss_dia, center = true);
}
module all_boss_columns() { for (p = screw_boss_pos) boss_column(p); }

// Screw clearance hole all the way through, along Y, down each boss centre.
module screw_holes(dia = screw_clear_dia) {
    for (p = screw_boss_pos)
        translate([p[0], 0, p[1]]) rotate([90, 0, 0])
            cylinder(h = head_thick + 40, d = dia, center = true);
}

// A recess of the given 2D-ish tool (round or hex) cut into ONE outer face to a
// uniform 'depth' measured from the LOCAL surface. Implemented as:
//   (long tool column on that side)  -  (body shrunk inward by depth)
// so the tool only removes the outermost 'depth' of material, following the
// varying body thickness. 'side' = +1 for the LEFT (+Y) face, -1 for RIGHT.
module face_recess(dia, depth, fn, side) {
    intersection() {
        // long tool columns down each boss axis, only on the chosen side
        for (p = screw_boss_pos)
            translate([p[0], side > 0 ? 0 : -(head_thick+40), p[1]])
                rotate([-90, 0, 0])
                    cylinder(h = head_thick + 40, d = dia, $fn = fn);
        // remove everything deeper than 'depth' from the surface
        difference() {
            translate([-300,-300,-300]) cube([600,600,600]);   // all space
            body_core_or_solid_inset(depth);                    // body shrunk by depth
        }
    }
}

// Body (with rounding if enabled) shrunk inward by 'd' on all faces — used to
// bound recess depth to the local surface.
module body_core_or_solid_inset(d) {
    if (grip_round > 0)
        minkowski() { body_core(grip_round + d); sphere(r = grip_round, $fn = 24); }
    else
        body_core(d);
}

// Round bolt-head recess on the LEFT (+Y) outer face.
module head_recesses() { face_recess(screw_head_dia, screw_head_depth, 48, +1); }
// Hexagonal nut recess on the RIGHT (-Y) outer face (captures the nut).
module nut_recesses()  { face_recess(nut_across_corners, nut_depth, 6, -1); }

// Male alignment spigots: on the RIGHT boss, crossing the split into +Y.
module spigots() {
    for (p = screw_boss_pos)
        translate([p[0], -0.01, p[1]]) rotate([-90, 0, 0])
            cylinder(h = spigot_len, d = spigot_dia, center = false);
}
// Female counterbores in the LEFT boss to receive the spigots.
module spigot_bores() {
    for (p = screw_boss_pos)
        translate([p[0], -0.01, p[1]]) rotate([-90, 0, 0])
            cylinder(h = spigot_len + 0.5, d = spigot_dia + 2*spigot_clear, center = false);
}

// LEFT half (Y >= 0): shell + bosses, minus through clearance hole, the round
// bolt-head recess (outer +Y face) and the spigot counterbores.
module left_shell() {
    difference() {
        union() {
            intersection() {
                union() {
                    body_hollow();
                    intersection() { all_boss_columns(); body_solid(); }
                    pot_mount_add();
                    pivot_boss(1);
                    spring_boss(1);
                }
                keep_left();
            }
            // DX16 pad: full disc on the left shell, deliberately crossing the
            // seam into -Y (the right shell has a matching recess).
            connector_pad();
            connector_reinforce();
        }
        screw_holes();
        head_recesses();
        spigot_bores();
        pot_mount_cut();
        pivot_bore(1);
        spring_bore(1);
        trigger_throat_cut();
        panel_cuts_left();
        thumb_button_cut();
        connector_hole();
    }
}

// RIGHT half (Y <= 0): shell + bosses + alignment spigots, minus through
// clearance hole and the hexagonal nut recess (outer -Y face).
module right_shell() {
    difference() {
        union() {
            intersection() {
                union() {
                    body_hollow();
                    intersection() { all_boss_columns(); body_solid(); }
                    pivot_boss(-1);
                    spring_boss(-1);
                }
                keep_right();
            }
            spigots();
        }
        screw_holes();
        nut_recesses();
        pot_lever_slot();
        pivot_bore(-1);
        spring_bore(-1);
        trigger_throat_cut();
        panel_cuts_right();
        thumb_button_cut();
        connector_recess();   // clearance for the left-shell pad crossing the seam
        connector_hole();
    }
}

// --- EXECUTION ---
if (part_to_render == "left_shell") {
    left_shell();
} else if (part_to_render == "right_shell") {
    right_shell();
} else if (part_to_render == "trigger") {
    trigger_lever();
}else if (part_to_render == "partial_exploded_assembly") {
    color("LightSteelBlue") translate([0,  6, 0]) left_shell();
    color("Crimson")        trigger_lever();
} else if (part_to_render == "exploded_assembly") {
    color("LightSteelBlue") translate([0,  6, 0]) left_shell();
    color("SlateGray")      translate([0, -6, 0]) right_shell();
    color("Crimson")        trigger_lever();
} else if (part_to_render == "closed_assembly") {
    color("LightSteelBlue") left_shell();
    color("SlateGray")      right_shell();
    color("Crimson")        trigger_lever();
} else if (part_to_render == "export_stl") {
    translate([0,   0, 0]) translate([0,0,30]) rotate([-90,0,0]) left_shell();
    translate([0,  95, 0]) translate([0,0,30]) rotate([ 90,0,0]) right_shell();
    translate([0, 40, 0]) translate([0,0, 3]) rotate([ 90,0,0]) trigger_lever();
}
