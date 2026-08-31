// ============================================================
// TRAIN CONTROLLER v3 - self-contained (no external DXF)
// Identical geometry to design2.scad, but the ergonomic outline is
// embedded directly as a polygon() instead of import()ing a DXF.
// The outline was extracted/simplified from the original Left.stl.
// ============================================================
//
// COORDINATE CONVENTION (adopted from the source STL outline):
//   X = along the controller length. Head/finger-slot at -X, grip/butt at +X.
//   Z = up/down (the silhouette height).
//   Y = thickness (the two shell halves separate along Y).
//
// The outline is defined in a plane X(length) x Y(height), thin in Z.
// We rotate it [90,0,0] so its height becomes our Z.

$fn = 48;

// --- RENDER SELECTION ---
// Options: "body"
part_to_render = "left_shell";

// --- THICKNESS TAPER (Y) : slim grip, broad head ---
grip_thick   = 25.0;   // Y thickness at the grip / trigger region (mm)
head_thick   = 60.0;   // Y thickness at the rear-top head (mm)
taper_head_x = -20.0;  // X at/below which full head_thick is used (head side, -X)
taper_grip_x =   5.0;  // X at/above which grip_thick is used (grip side, +X)

// --- BUTTON CLEARANCE : room above the pot for buttons + wiring ---
// Pushes the angled ~50 deg "top" button face (outline edge 30->31) OUTWARD
// along its own normal by this amount, keeping the face's angle. This opens up
// space between the internal pot and the button-mounting surface.
// (See button_face_normal / button_move_idx below.) Play with this to taste.
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

// path[0] = outer body only. The small pivot hole (points 44-48) is NOT
// referenced here: we keep the body solid and drill the pivot as a proper
// hole later when the trigger is designed (see pivot_pos below). Leaving it in
// the outline made minkowski() distort it into a slot.
outline_paths = [
  [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19,
   20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33]
];

module outline_2d() {
    polygon(points = outline_points, paths = outline_paths);
}

// Outline with the HEAD's "top" (the ~50-deg blue button face) pushed OUTWARD
// along its own normal by button_clearance, adding room between the internal
// pot and the button-mounting surface while keeping the surface's angle.
//
// We move the blue face together with the ROUNDED CORNER FILLETS at each end
// so the curves travel with the surface (no ugly welded-block kinks). The
// fillet clusters are: rear corner {28,29,30} and front corner {31,32,33,0}.
// Including both seam points (33 and 0) at the front keeps that fillet intact
// and lets the long bottom edge (0->1) gently re-angle instead of the tiny
// fillet edge stretching into a gash. All other points stay put, so the two
// adjacent long edges (top-rear 27->28 and bottom 0->1) smoothly follow.
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
pot_lever_side = 1;  // +1: lever/pocket offset toward +Y half; -1 toward -Y
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
// (the caller intersects this with body_solid() and keep_left())

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
// TRIGGER PIVOT LOCATION (was a small hole in the original outline)
// ------------------------------------------------------------
// The original STL had a small hole here for the trigger-lever pivot pin.
// We keep the body solid for now and record the location as data; the pivot
// will be drilled as a proper hole through both shells when the trigger is
// designed. Centre is in the outline X-Z plane, on Y=0 (through the thickness).
pivot_pos = [-12.81, 1.92];   // [X, Z] centre of the trigger pivot
pivot_dia = 4.0;              // intended pivot pin diameter (mm) — bigger than
                              // the ~1.9mm marker in the source STL

// TRIGGER GEOMETRY NOTES (agreed while planning the trigger):
//  - The trigger pivots at pivot_pos above.
//  - The trigger BLADE (finger part) exits the body through the concave THROAT
//    notch RIGHT NEXT TO the pivot, at approx [X,Z] = [-8, 3] (the point on the
//    outline nearest the pivot). It does NOT exit lower/forward in the grip.
//  - The trigger ACTUATOR ARM reaches from the pivot up to the pot lever along
//    the pot axis (pot_axis_rear/front); the pot is inset+shifted so the arm can
//    sweep in the clear channel at the split plane (see pot_inset / pot_shift).
trigger_exit = [-8, 3];       // [X, Z] where the trigger blade exits the throat

// Visualises the recorded pot axis (for debugging / placing the mount later).
module pot_location_marker() {
    // rod along the slot centerline
    hull() {
        translate([pot_axis_rear[0],  0, pot_axis_rear[1]])  sphere(2);
        translate([pot_axis_front[0], 0, pot_axis_front[1]]) sphere(2);
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
screw_boss_pos = [ [11, -28], [68, -1], [55, 17], [-31, 18], [-80, -3], [-45, -45] ];

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
        intersection() {
            union() {
                body_hollow();
                intersection() { all_boss_columns(); body_solid(); }
                pot_mount_add();
            }
            keep_left();
        }
        screw_holes();
        head_recesses();
        spigot_bores();
        pot_mount_cut();
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
                }
                keep_right();
            }
            spigots();
        }
        screw_holes();
        nut_recesses();
        pot_lever_slot();   // clearance for the pot lever that crosses the split
    }
}

// --- EXECUTION ---
if (part_to_render == "body") {
    body_solid();
} else if (part_to_render == "body_potmark") {
    body_solid();
    color("Crimson") pot_location_marker();
} else if (part_to_render == "pot_debug") {
    color("LightSteelBlue", 0.5) body_solid();
    color("Red") pot_body_envelope();
} else if (part_to_render == "hollow") {
    body_hollow();
} else if (part_to_render == "left_shell") {
    left_shell();
} else if (part_to_render == "right_shell") {
    right_shell();
} else if (part_to_render == "exploded_assembly") {
    color("LightSteelBlue") translate([0,  6, 0]) left_shell();
    color("SlateGray")      translate([0, -6, 0]) right_shell();
} else if (part_to_render == "closed_assembly") {
    color("LightSteelBlue") left_shell();
    color("SlateGray")      right_shell();
}
