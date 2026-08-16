// =====================================================================
//  Pantheon, Rome  —  OpenSCAD model   (万神殿, 罗马)
//  Units: meters.  The rotunda interior is a true inscribed sphere:
//  interior diameter = interior height = 43.3 m (the dome is a hemisphere).
//  Options (hollow / coffers / cutaway / inscription) at the top.
// =====================================================================

$fn = 96;

/* ---------- key dimensions (real measurements) ---------- */
R_int    = 21.65;   // rotunda interior radius  (43.3 m diameter)
wall     = 6.2;     // drum wall thickness
R_out    = R_int + wall;   // exterior drum radius
drum_h   = R_int;   // dome springing height (interior hemisphere)
oculus_r = 4.46;    // oculus radius (8.92 m diameter)

/* ---------- portico ---------- */
p_w     = 33.5;     // width (frontage)
p_d     = 15.5;     // depth
col_h   = 11.8;     // column height
col_r   = 0.74;     // shaft radius (1.48 m diameter)
roof_h  = 15.3;     // entablature top (eave)
ped_h   = 5.0;      // pediment height
floor_h = 1.35;     // raised pronaos floor

/* ---------- options ---------- */
hollow      = true;    // hollow the rotunda/dome (true sphere-in-cylinder)
coffers     = true;    // coffered dome ceiling
cutaway     = false;   // cut away the front half to reveal the interior section
inscription = true;    // pediment inscription

/* ---------- derived ---------- */
front_y = -(R_out + p_d);     // portico front edge
back_y  = -R_out;             // portico back edge (tangent to drum)
port_cy = (front_y + back_y) / 2;

/* ===================================================================== */

// upper hemisphere of radius r (z >= 0)
module hemisphere(r) {
    difference() {
        sphere(r = r);
        translate([0, 0, -r/2])
            cube([2*r, 2*r, r], center = true);   // remove z < 0
    }
}

// rotunda: drum + hemispherical dome + oculus, hollowed with coffers
module rotunda() {
    difference() {
        union() {
            cylinder(r = R_out, h = drum_h);
            translate([0, 0, drum_h]) hemisphere(R_out);
            // cornice ring where the dome springs from the drum
            translate([0, 0, drum_h]) cylinder(r = R_out + 1.0, h = 0.8);
        }
        // oculus (open to the sky)
        translate([0, 0, drum_h]) cylinder(r = oculus_r, h = R_out + 1);
        // hollow interior (inscribed sphere)
        if (hollow) {
            cylinder(r = R_int, h = drum_h + 0.01);
            translate([0, 0, drum_h]) hemisphere(R_int);
        }
        // coffer recesses on the inner dome surface (5 rows, 28 each in reality)
        if (coffers) {
            for (row = [0:4]) {
                phi = 22 + row * 13;
                n = 24;
                for (k = [0:n-1]) {
                    theta = k * 360 / n + (row % 2) * (360 / n / 2);
                    rotate([0, 0, theta])
                        rotate([phi, 0, 0])
                            translate([0, 0, R_int + 0.6])
                                cube([2.4, 2.4, 1.2], center = true);
                }
            }
        }
    }
}

// fluted column shaft
module fluted_shaft(h, r, n = 20) {
    difference() {
        cylinder(r1 = r, r2 = 0.92 * r, h = h);
        for (i = [0:n-1])
            rotate([0, 0, i * 360 / n])
                translate([0, r * 0.88, h/2])
                    cube([r * 0.2, r * 0.26, h + 0.2], center = true);
    }
}

// Corinthian-ish column
module column(h = col_h, r = col_r) {
    // plinth + base
    translate([0, 0, 0.2]) cylinder(r = 1.5 * r, h = 0.4);
    translate([0, 0, 0.6]) cylinder(r1 = 1.5 * r, r2 = r, h = 0.5);
    // fluted shaft
    translate([0, 0, 1.1]) fluted_shaft(h - 2.3, r);
    // capital (bell) + abacus
    translate([0, 0, h - 1.2]) cylinder(r1 = r, r2 = 1.6 * r, h = 0.7);
    translate([0, 0, h - 0.5]) cylinder(r = 1.7 * r, h = 0.5);
    translate([0, 0, h - 0.5]) cube([3.6 * r, 3.6 * r, 0.25], center = true);
}

// entablature slab (architrave + frieze + cornice)
module entablature() {
    translate([0, port_cy, roof_h - (roof_h - col_h) / 2])
        cube([p_w, p_d, roof_h - col_h], center = true);
}

// gable roof (its front face is the pediment)
module roof() {
    translate([0, port_cy, roof_h])
        rotate([90, 0, 0])
            linear_extrude(p_d, center = true)
                polygon([[-p_w/2, 0], [p_w/2, 0], [0, ped_h]]);
}

// rectangular intermediate block rising from the portico roof to the drum
module attic_block() {
    d = p_d - 2.5;
    cy = front_y + 2.5 + d / 2;
    translate([0, cy, roof_h])
        cube([p_w, d, drum_h - roof_h + 0.01], center = true);
}

// solid cella side walls
module side_walls() {
    t = 1.0;
    for (sx = [-1, 1])
        translate([sx * (p_w/2 - t/2), port_cy, floor_h + (roof_h - floor_h)/2])
            cube([t, p_d, roof_h - floor_h], center = true);
}

// 16 free-standing columns: 8 front + two rows of 4 (aligned 2,3,6,7)
module columns() {
    margin = 2.2;
    xspan = p_w - 2 * margin;
    xf = [ for (i = [0:7]) -xspan/2 + i * xspan/7 ];
    for (x = xf)
        translate([x, front_y + 1.3, floor_h]) column();
    xi = [ xf[1], xf[2], xf[5], xf[6] ];
    for (x = xi)
        translate([x, front_y + p_d * 0.42, floor_h]) column();
    for (x = xi)
        translate([x, front_y + p_d * 0.70, floor_h]) column();
}

// three front steps
module steps() {
    for (i = [0:2]) {
        cy = front_y - i * 0.6 - 0.3;
        topz = floor_h - i * 0.45;
        translate([0, cy, topz - 0.225])
            cube([p_w + 1.0, 0.6, 0.45], center = true);
    }
}

// pediment inscription
module inscription_text() {
    translate([0, front_y + 0.02, roof_h + ped_h * 0.45])
        rotate([90, 0, 0])
            linear_extrude(0.4)
                text("M·AGRIPPA·L·F·COS·TERTIVM·FECIT",
                     size = 1.7,
                     halign = "center", valign = "center");
}

// portico assembly
module portico() {
    columns();
    entablature();
    roof();
    attic_block();
    side_walls();
    steps();
    if (inscription) inscription_text();
}

// full building
module pantheon() {
    // plaza base
    translate([0, 0, -0.6]) cylinder(r = R_out + 22, h = 0.6);
    rotunda();
    portico();
}

// render
if (cutaway) {
    difference() {
        pantheon();
        // remove y <= 0 (front half) to reveal the interior section
        translate([0, -80, 0]) cube([160, 160, 160], center = true);
    }
} else {
    pantheon();
}
