// ============================================================
// TRAIN CONTROLLER v2 - based on real ergonomic outline (Left/Right.stl)
// Built fresh around the imported silhouette in profiles/body_outline.dxf
// ============================================================
//
// COORDINATE CONVENTION (adopted from the source STL outline):
//   X = along the controller length. Head/finger-slot at -X, grip/butt at +X.
//   Z = up/down (the silhouette height).
//   Y = thickness (the two shell halves separate along Y).
//
// The outline DXF lives in a plane X(length) x Y(height), thin in Z.
// We rotate it [90,0,0] so its height becomes our Z.

$fn = 48;

// --- RENDER SELECTION ---
// Options: "body"
part_to_render = "body";

// --- OUTLINE SOURCE ---
outline_file = "profiles/body_outline.dxf";

// --- THICKNESS TAPER (Y) : slim grip, broad head ---
grip_thick   = 25.0;   // Y thickness at the grip / trigger region (mm)
head_thick   = 60.0;   // Y thickness at the rear-top head (mm)
taper_head_x = -20.0;  // X at/below which full head_thick is used (head side, -X)
taper_grip_x =   5.0;  // X at/above which grip_thick is used (grip side, +X)

// ------------------------------------------------------------
// 2D OUTLINE
// ------------------------------------------------------------
// Raw imported silhouette (in its native X x height plane).
module outline_2d() {
    import(outline_file);
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
// ------------------------------------------------------------
module body_solid() {
    intersection() {
        // Extrude the oriented outline to more than head_thick, centred on Y.
        rotate([90, 0, 0])
            linear_extrude(height = head_thick + 10, center = true)
                outline_2d();
        thickness_mask(0);
    }
}

// --- EXECUTION ---
if (part_to_render == "body") {
    body_solid();
}
