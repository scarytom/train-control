// ========================================================
// PARMA / TRUSPEED CONTROLLER - CORRECTED TRIGGER HOOK (v3.5)
// ========================================================

$fn = 36;

// --- RENDER SELECTION ---
// Options: "exploded_assembly", "closed_assembly", "left_shell", "right_shell", "trigger"
part_to_render = "exploded_assembly"; 

// --- HOUSING DIMENSIONS ---
wall               = 3.0;        // Shell wall thickness (mm)
shell_width        = 44.0;       // Body thickness across Y axis (mm)
cable_entry_dia    = 7.5;        // Rear cable exit hole (mm)

// --- ERGONOMIC WIDTH TAPER (wide top, slim grip at bottom) ---
head_width         = 44.0;       // Body width (Y) at the top/head (mm)
grip_width         = 30.0;       // Body width (Y) at the bottom/grip (mm)
taper_top_z        = 0.0;        // Z above which full head_width is used
taper_bottom_z     = -45.0;      // Z at which grip_width is reached

// --- PANEL & CONTROL CUTOUTS ---
front_knob_hole_dia = 7.2;       // Front face rotary pot holes (mm)
top_button_dia     = 12.2;       // Top red thumb button hole (mm)
led_hole_dia       = 5.2;        // Status LED holes (mm)

// --- TOP MOUNTING PLATFORM (flared switch panel) ---
platform_len       = 40.0;       // Platform size along X (front<->rear) (mm)
platform_width     = 50.0;       // Platform size along Y (flares wider than 44mm body) (mm)
platform_thick     = 4.0;        // Flat plate thickness (mm)
platform_center_x  = 32.0;       // X position of platform centre (over head/button area)
platform_top_z     = 33.0;       // Z of the flat top surface (mm)
platform_skirt     = 8.0;        // How far the platform blends down into the shell (mm)
switch_hole_dia    = 6.5;        // Sample toggle-switch mounting hole diameter (mm)

// --- HARDWARE SPECIFICATIONS ---
pot_length         = 50.0;       // Internal slide pot mounting rail length (mm)
pot_width          = 9.5;        // Slide pot casing width (mm)
screw_dia          = 3.2;        // M3 bolt clearance hole (mm)
screw_boss_dia     = 7.5;        // Screw boss diameter (mm)
trigger_pivot_dia  = 4.0;        // Pivot pin diameter (mm)
trigger_pivot_pos  = [0, 0, -15];// Pivot location near bottom slot exit

// --- EXECUTION ---
if (part_to_render == "exploded_assembly") {
    color("LightSteelBlue", 0.75) translate([0, 35, 0]) left_shell();
    color("SlateGray", 0.75) translate([0, -35, 0]) right_shell();
    color("Crimson") trigger_lever();
} else if (part_to_render == "closed_assembly") {
    color("LightSteelBlue", 0.8) left_shell();
    color("SlateGray", 0.8) right_shell();
    color("Crimson") trigger_lever();
} else if (part_to_render == "left_shell") {
    left_shell();
} else if (part_to_render == "right_shell") {
    right_shell();
} else if (part_to_render == "trigger") {
    trigger_lever();
}

// ========================================================
// 2D CONTOUR PROFILES
// ========================================================

module outer_profile_2d() {
    offset(r=3.0) {
        polygon(points=[
            [-100, -20], // Handle rear top
            [-65, -8],   // Upper handle curve
            [-30, -2],   // Handle transition
            [-10, 5],    // Thumb web rest crook
            [15, 30],    // Top head rear
            [78, 26],    // Top front nose
            [70, -42],   // Slanted front nose bottom
            [25, -42],   // Front bottom curve
            [8, -18],    // Trigger arch apex
            [-25, -35],  // Lower throat
            [-60, -42],  // Lower handle curve
            [-95, -45],  // Handle rear bottom
            [-102, -32]  // Handle butt center
        ]);
    }
}

module inner_profile_2d() {
    offset(r=-wall) outer_profile_2d();
}

// Corrected Concave Trigger Blade Profile (Finger rest on +X front face)
module trigger_blade_profile_2d() {
    offset(r=1.5) {
        polygon(points=[
            [2, -12],     // Top neck front
            [10, -20],    // Upper sweep out of housing
            [6, -30],     // Deep concave finger cup (recessed for finger pad)
            [12, -41],    // Forward hook tip (prevents finger slipping off)
            [8, -43],     // Bottom rounded tip
            [3, -39],     // Rear blade bottom
            [1, -30],     // Rear blade middle
            [4, -20],     // Rear upper sweep
            [-2, -12]     // Top neck rear
        ]);
    }
}

// ========================================================
// 3D SHELL MODULES
// ========================================================

module main_outer_shape() {
    intersection() {
        rotate([90, 0, 0])
            linear_extrude(height = shell_width, center = true)
                outer_profile_2d();
        width_mask(0);
    }
}

module main_inner_cavity() {
    intersection() {
        rotate([90, 0, 0])
            linear_extrude(height = shell_width - wall*2, center = true)
                inner_profile_2d();
        // Cavity mask is inset by one wall on each side so the tapered
        // side walls stay 'wall' thick where the body narrows.
        width_mask(-wall*2);
    }
}

// Width-limiting mask: full head_width up top, tapering down to grip_width
// at the bottom so the top is broad and the grip is slim. 'inset' shrinks
// the width on both sides (use -2*wall for the inner cavity). Extents in X
// (front/rear) are generous; only the Y (width) varies with Z.
module width_mask(inset = 0) {
    hw_head = head_width + inset;
    hw_grip = grip_width + inset;
    x_span  = 400;   // big X extent (front/rear), mask only limits Y vs Z
    z_top   =  200;  // well above the top of the body
    z_bot   = -200;  // well below the bottom of the body
    hull() {
        // Top block: full width, from taper_top_z upward
        translate([0, 0, (taper_top_z + z_top)/2])
            cube([x_span, hw_head, z_top - taper_top_z], center=true);
        // Bottom block: slim grip width, from taper_bottom_z downward
        translate([0, 0, (taper_bottom_z + z_bot)/2])
            cube([x_span, hw_grip, taper_bottom_z - z_bot], center=true);
    }
}

module cable_exit_hole() {
    translate([-100, 0, -32])
        rotate([0, -100, 0])
            cylinder(h=30, d=cable_entry_dia, center=true);
}

// --- POTENTIOMETER MOUNTING RAILS ---
module left_pot_mount() {
    translate([12, pot_width/2, 2])
        cube([pot_length + 10, shell_width/2 - pot_width/2, 14]);
}

module right_pot_mount() {
    translate([12, -shell_width/2, 2])
        cube([pot_length + 10, shell_width/2 - pot_width/2, 14]);
}

// --- INTERNAL SPRING ANCHOR POSTS ---
module spring_anchor_post(y_dir) {
    translate([-5, y_dir * (shell_width/2 - wall - 5), 2])
        rotate([90, 0, 0])
            difference() {
                cylinder(h=8, d=6.0, center=true);
                cylinder(h=2.5, d=3.8, center=true);
            }
}

// --- PERIMETER BOLT BOSSES ---
module bolt_boss_locations() {
    boss_pts = [
        [-95, -32],  // Handle rear tip
        [-25, -20],  // Lower throat
        [15, 18],    // Top rear head
        [70, 16],    // Top front nose
        [62, -34]    // Bottom front nose
    ];
    
    for (pt = boss_pts) {
        translate([pt[0], 0, pt[1]])
            children();
    }
}

module left_bolt_bosses() {
    boss_len = shell_width/2 - wall;
    intersection() {
        bolt_boss_locations() {
            difference() {
                rotate([-90, 0, 0]) cylinder(h=boss_len, d=screw_boss_dia, center=false);
                rotate([-90, 0, 0]) translate([0, 0, -1]) cylinder(h=boss_len + 5, d=screw_dia, center=false);
            }
        }
        // Keep bosses inside the (tapered) body so they don't pierce the
        // narrowed handle walls. Inset by wall so the boss stays buried.
        width_mask(-wall*2);
    }
}

module right_bolt_bosses() {
    boss_len = shell_width/2 - wall;
    intersection() {
        bolt_boss_locations() {
            difference() {
                rotate([90, 0, 0]) cylinder(h=boss_len, d=screw_boss_dia, center=false);
                rotate([90, 0, 0]) translate([0, 0, -1]) cylinder(h=boss_len + 5, d=screw_dia, center=false);
            }
        }
        width_mask(-wall*2);
    }
}

// ========================================================
// TOP MOUNTING PLATFORM (flared flat panel for switches)
// ========================================================

// Solid platform body. Straddles the split plane; each shell half is
// clipped to its own side by the existing split-plane cube.
// The panel flat top is at platform_top_z; a skirt below it blends the
// flare down into the curved shell top so there is no floating gap.
module top_mount_platform() {
    panel_bottom_z = platform_top_z - platform_thick;
    skirt_bottom_z = panel_bottom_z - platform_skirt;

    // Hull a full-width flared plate on top down to a narrower footprint
    // that sinks into the curved shell top, giving a smooth blend with
    // no floating gap.
    hull() {
        // Flat flared plate (full 50mm width, sits proud of the shell)
        translate([platform_center_x, 0, (panel_bottom_z + platform_top_z)/2])
            cube([platform_len, platform_width, platform_thick], center=true);

        // Narrower skirt footprint, pushed down into the shell body so the
        // hull fuses the panel into the existing top surface.
        translate([platform_center_x, 0, skirt_bottom_z + 0.5])
            cube([platform_len - 8, shell_width - 6, 1], center=true);
    }
}

// Sample switch mounting holes drilled from the top through the platform.
// Placed off the Y=0 seam so neither hole lands exactly on the split.
module switch_holes() {
    // Depth generous enough to pass fully through platform + into cavity.
    hole_h = platform_thick + platform_skirt + 12;
    hole_z = platform_top_z + 2;   // start slightly above the surface

    // Three-hole sample pattern across the flat area.
    positions = [
        [platform_center_x - 12,  12],  // rear-left
        [platform_center_x - 12, -12],  // rear-right
        [platform_center_x + 12,   0],  // front-centre
    ];
    for (p = positions) {
        translate([p[0], p[1], hole_z])
            rotate([180, 0, 0])
                cylinder(h=hole_h, d=switch_hole_dia, center=false);
    }
}

// ========================================================
// CUTOUTS & ASSEMBLY MODULES
// ========================================================

module panel_cutouts() {
    // 1. Front Slanted Face: 3 Rotary Potentiometer Control Dials
    translate([74, 0, 10]) rotate([0, 83, 0]) cylinder(h=25, d=front_knob_hole_dia, center=true);
    translate([71, 0, -8]) rotate([0, 83, 0]) cylinder(h=25, d=front_knob_hole_dia, center=true);
    translate([67, 0, -26]) rotate([0, 83, 0]) cylinder(h=25, d=front_knob_hole_dia, center=true);

    // 2. Top Red Pushbutton
    translate([25, 0, 26]) cylinder(h=20, d=top_button_dia, center=true);

    // 3. Status LEDs
    translate([10, -12, 24]) cylinder(h=20, d=led_hole_dia, center=true);
    translate([10,  12, 24]) cylinder(h=20, d=led_hole_dia, center=true);

    // 4. Trigger Pivot Hole (Z = -15mm)
    translate(trigger_pivot_pos) 
        rotate([90, 0, 0]) 
            cylinder(h=shell_width + 10, d=trigger_pivot_dia, center=true);
            
    // 5. Bottom Slot Exit Opening
    translate([-8, -6, -30]) cube([28, 12, 20]);
}

module left_shell() {
    difference() {
        union() {
            difference() {
                main_outer_shape();
                main_inner_cavity();
            }
            left_bolt_bosses();
            left_pot_mount();
            spring_anchor_post(1);
            top_mount_platform();
        }
        
        // Split plane (Keep Left side Y >= 0)
        translate([-150, -150, -150]) cube([300, 150, 300]);
        
        panel_cutouts();
        switch_holes();
        cable_exit_hole();
    }
}

module right_shell() {
    difference() {
        union() {
            difference() {
                main_outer_shape();
                main_inner_cavity();
            }
            right_bolt_bosses();
            right_pot_mount();
            spring_anchor_post(-1);
            top_mount_platform();
        }
        
        // Split plane (Keep Right side Y <= 0)
        translate([-150, 0, -150]) cube([300, 150, 300]);
        
        panel_cutouts();
        switch_holes();
        cable_exit_hole();
    }
}

module trigger_lever() {
    difference() {
        union() {
            // 1. Properly Curved Finger Hook
            rotate([90, 0, 0])
                linear_extrude(height = 9.5, center = true)
                    trigger_blade_profile_2d();
            
            // 2. Upper Actuator Arm (Extends up into internal wiper fork)
            translate([0, 0, 5]) {
                cube([9, 8, 32], center=true);
                // Wiper Slot Fork
                translate([2, 0, 16])
                    difference() {
                        cube([12, 8, 8], center=true);
                        cube([14, 3.5, 5], center=true);
                    }
            }
            
            // 3. Return Spring Transverse Pin
            translate([-6, 0, -2])
                rotate([90, 0, 0])
                    cylinder(h=14, d=3.0, center=true);
        }
        
        // 4. Main Pivot Hole (Z = -15mm)
        translate(trigger_pivot_pos) 
            rotate([90, 0, 0]) 
                cylinder(h=20, d=trigger_pivot_dia, center=true);
    }
}