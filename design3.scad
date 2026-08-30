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
part_to_render = "body";

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
// TRIGGER PIVOT LOCATION (was a small hole in the original outline)
// ------------------------------------------------------------
// The original STL had a small hole here for the trigger-lever pivot pin.
// We keep the body solid for now and record the location as data; the pivot
// will be drilled as a proper hole through both shells when the trigger is
// designed. Centre is in the outline X-Z plane, on Y=0 (through the thickness).
pivot_pos = [-12.81, 1.92];   // [X, Z] centre of the trigger pivot
pivot_dia = 4.0;              // intended pivot pin diameter (mm) — bigger than
                              // the ~1.9mm marker in the source STL

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

// --- EXECUTION ---
if (part_to_render == "body") {
    body_solid();
} else if (part_to_render == "body_potmark") {
    body_solid();
    color("Crimson") pot_location_marker();
}
