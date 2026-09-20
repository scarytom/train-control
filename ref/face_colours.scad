// Face identification rendering - X-Z plane projection (looking down Y-axis)
// Each face of the controller outline is coloured distinctly
// 10 logical faces identified
// Rotated 135 degrees clockwise so Instrument Panel (Magenta) is at top

$fn = 48;

// The raised outline points (with instrument panel pushed out)
button_clearance = 20.0;
button_face_normal = [-0.772, -0.636];

outline_points = [
  [-30.17, -39.54], [0.26, -31.57], [5.49, -31.68], [11.58, -33.66],
  [13.32, -33.58], [14.57, -32.37], [18.05, -24.45], [22.6, -20.38],
  [45.87, -15.85], [62.59, -10.8], [68.85, -8.08], [71.59, -5.88],
  [73.74, -2.77], [74.46, 0.39], [73.97, 2.85], [58.71, 22.07],
  [55.61, 23.47], [52.26, 22.74], [17.33, 8.76], [12.72, 6.1],
  [6.95, 1.06], [1.48, -0.33], [-3.5, -0.13], [-6.68, 1.4],
  [-21.98, 20.46], [-25.57, 23.54], [-28.68, 24.7], [-35.32, 24.67],
  [-71.14, 13.34], [-72.45, 10.9], [-71.77, 8.39], [-33.8, -37.68],
  [-32.1, -39.13], [-30.33, -39.55]
];

button_move_idx = [28, 29, 30, 31, 32, 33, 0];

function _moved(i) =
    (search(i, button_move_idx) != [])
        ? [ outline_points[i][0] + button_face_normal[0] * button_clearance,
            outline_points[i][1] + button_face_normal[1] * button_clearance ]
        : outline_points[i];

raised_outline_points = [ for (i = [0 : len(outline_points) - 1]) _moved(i) ];

// Draw a thick coloured line between two points
module edge_line(p1, p2, col, thick=2.0) {
    color(col)
    hull() {
        translate([p1[0], 0, p1[1]]) sphere(r=thick);
        translate([p2[0], 0, p2[1]]) sphere(r=thick);
    }
}

// Apply 135 degree clockwise rotation (= -135 degrees)
rotate([0, 135, 0]) {

    // Face 1: REAR FACE (Red) - points 0→1
    for (i = [0:0]) edge_line(raised_outline_points[i], raised_outline_points[i+1], "Red");

    // Face 2: TANG TOP (Cyan) - points 1→5
    for (i = [1:4]) edge_line(raised_outline_points[i], raised_outline_points[i+1], "Cyan");

    // Face 3: TANG BOTTOM (Orange) - points 5→7
    for (i = [5:6]) edge_line(raised_outline_points[i], raised_outline_points[i+1], "Orange");

    // Face 4: GRIP REAR (Indigo) - points 7→14
    for (i = [7:13]) edge_line(raised_outline_points[i], raised_outline_points[i+1], "Indigo");

    // Face 5: GRIP BUTT (Yellow) - points 14→16
    for (i = [14:15]) edge_line(raised_outline_points[i], raised_outline_points[i+1], "Yellow");

    // Face 6: GRIP FRONT (Green) - points 16→19
    for (i = [16:18]) edge_line(raised_outline_points[i], raised_outline_points[i+1], "Green");

    // Face 7: TRIGGER THROAT (White) - points 19→23
    for (i = [19:22]) edge_line(raised_outline_points[i], raised_outline_points[i+1], "White");

    // Face 8: UNDERBELLY (Brown) - points 23→27
    for (i = [23:26]) edge_line(raised_outline_points[i], raised_outline_points[i+1], "SaddleBrown");

    // Face 9: FRONT FACE (Black) - points 27→30
    for (i = [27:29]) edge_line(raised_outline_points[i], raised_outline_points[i+1], "Black");

    // Face 10: INSTRUMENT PANEL (Magenta) - points 30→0
    edge_line(raised_outline_points[30], raised_outline_points[31], "Magenta", 3.0);
    for (i = [31:32]) edge_line(raised_outline_points[i], raised_outline_points[(i+1) % 34], "Magenta");
    edge_line(raised_outline_points[33], raised_outline_points[0], "Magenta");
}
