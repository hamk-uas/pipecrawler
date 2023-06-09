use <3rd-party/threads-scad/threads.scad>; // https://github.com/rcolyer/threads-scad

pipe_id = 114;
pipe_od = 120;
pipe_height = 300;

helix_pitch = 20;
wheel_angle = atan2(helix_pitch, PI*pipe_id);

wheel_bearing_with_washers_height = 7; // 10 if washers, 7 if without
wheel_bearing_height = 7;
wheel_bearing_od = 22;
wheel_bearing_id = 8;
wheel_bearing_bevel = 0.5;

wheel_od = 25;
wheel_height = 8;

wheel_tight = 2;

bolt_nominal_diameter = 3;
bolt_head_diameter = 6;
bolt_head_height = 3;

wheel_support_height = 11;
wheel_vertical_clearance = 2;
wheel_horizontal_clearance = 10;
wheel_support_width = 13;
wheel_support_depth = 13;
wheel_shoulder_diameter = 12;

spring_radius = 18;
spring_shift_x = pipe_id/2 - wheel_od/2 + wheel_tight - spring_radius ;
spring_shift_y = wheel_support_width/2;
spring_angles = [-0.6, 134.9];
spring_extra_angles = [0, 140.8];
spring_n = 4;
spring_t = 1;

spring2_radius = pipe_id/2 - wheel_od/2 + wheel_tight;
spring2_shift_x = 0;
spring2_shift_y = 0;
spring2_angles = [7.8, 60];
spring2_extra_angles = [4, 60 + 30];
spring2_n = 4;
spring2_t = 1;

body_id = 34;
body_od = 50;

conn_screw_r = 21;

$fn = 16;

// Pipe
module pipe() {
    translate([0, 0, -wheel_bearing_with_washers_height/2 - wheel_vertical_clearance - wheel_support_height])
    difference() {
        cylinder(pipe_height, pipe_od/2, pipe_od/2, $fn = 32);
        cylinder(pipe_height, pipe_id/2, pipe_id/2, $fn = 32);
        // Cutout to show what's inside
        translate([0, -pipe_od/2, 0]) cube([pipe_od, pipe_od, pipe_height], center=false);
    }
}

// wheel_bearing
module wheel_bearing() {
    translate([0, 0, (wheel_bearing_with_washers_height - wheel_bearing_height)/2]) difference() {
        union() {
            cylinder(wheel_bearing_bevel, wheel_bearing_od/2 - wheel_bearing_bevel, wheel_bearing_od/2);
            translate([0, 0, wheel_bearing_bevel]) cylinder(wheel_bearing_height - 2*wheel_bearing_bevel, wheel_bearing_od/2, wheel_bearing_od/2);
            translate([0, 0, wheel_bearing_height - wheel_bearing_bevel]) cylinder(wheel_bearing_bevel, wheel_bearing_od/2, wheel_bearing_od/2 - wheel_bearing_bevel);    
        }
        cylinder(wheel_bearing_height, wheel_bearing_id/2, wheel_bearing_id/2);
    }
}

module wheel() {
    wheel_bearing();
    translate([0, 0, (wheel_bearing_with_washers_height - wheel_bearing_height)/2]) import("wheel.stl", convexity=3);
}

module sector(height, small_r, big_r, angles = [-60, 60], $fn = $fn) {    
    points = [
        for(step = [0:$fn]) [big_r * cos(angles[0] + (angles[1] - angles[0])*step/$fn), big_r * sin(angles[0] + (angles[1] - angles[0])*step/$fn)],
        for(step = [0:$fn]) [small_r * cos(angles[1] + (angles[0] - angles[1])*step/$fn), small_r * sin(angles[1] + (angles[0] - angles[1])*step/$fn)]
    ];
    linear_extrude(height) polygon(points);
}

function ease(x, n) = pow(1 - 2*sqrt(x*(1 - x)), n);

function smooth(x) = 0.5 - 0.5*cos(180*x);

module spring(r, angles, t_angles, t_in, extra_in_start, extra_in_end, t_out, extra_out_start, extra_out_end, n, height, $fn = $fn) {    
    points = [
        for(step = [0:$fn]) [r * cos(angles[0] + (angles[1] - angles[0])*smooth(step/$fn)) + (t_out + extra_out_start*ease(smooth(step/$fn), n)) * cos(t_angles[0] + (t_angles[1] - t_angles[0])*smooth(step/$fn)), r * sin(angles[0] + (angles[1] - angles[0])*smooth(step/$fn)) + (t_out + extra_out_start*ease(smooth(step/$fn), n)) * sin(t_angles[0] + (t_angles[1] - t_angles[0])*smooth(step/$fn))],
        for(step = [0:$fn]) [r * cos(angles[1] + (angles[0] - angles[1])*smooth(step/$fn)) - (t_in + extra_in_start*ease(smooth(step/$fn), n)) * cos(t_angles[1] + (t_angles[0] - t_angles[1])*smooth(step/$fn)), r * sin(angles[1] + (angles[0] - angles[1])*smooth(step/$fn)) - (t_in + extra_in_start*ease(smooth(step/$fn), n)) * sin(t_angles[1] + (t_angles[0] - t_angles[1])*smooth(step/$fn))]
    ];
    linear_extrude(height) polygon(points);
}

module crown(top = false) {
// Wheels and springs
for (i = [0:2]) rotate([0, 0, 360/3*i]) {
    difference() {
        union() {            
            // Spring
            if (i == 0) {
                translate([spring_shift_x, spring_shift_y, -wheel_bearing_with_washers_height/2 - wheel_vertical_clearance - wheel_support_height]) spring(spring_radius, spring_angles, spring_extra_angles, spring_t/2, spring_t/2, 1, spring_t/2, spring_t/2, 1, spring_n, wheel_support_height, $fn=64);
                translate([spring2_shift_x, spring2_shift_y, -wheel_bearing_with_washers_height/2 - wheel_vertical_clearance - wheel_support_height]) mirror([0, 1, 0]) spring(spring2_radius, spring2_angles, spring2_extra_angles, spring2_t/2, spring2_t/2, 1, spring2_t/2, spring2_t/2, 1, spring2_n, wheel_support_height, $fn=64);
            }

     translate([pipe_id/2 - wheel_od/2 + wheel_tight, 0, 0]) difference() {
        union() {
        rotate([wheel_angle, 0, 0]) {
            // Wheel boltway
            translate([0, 0, -wheel_bearing_with_washers_height/2])    cylinder(wheel_bearing_with_washers_height / 2 + 5, wheel_bearing_id/2, wheel_bearing_id/2, $fn=64);

        }
        hull() {
        rotate([wheel_angle, 0, 0]) {
            // Wheel support shoulder
            translate([0, 0, -wheel_bearing_with_washers_height/2])    translate([0, 0, - wheel_vertical_clearance - 1]) cylinder(wheel_vertical_clearance + 1, wheel_shoulder_diameter/2, wheel_shoulder_diameter/2, $fn=64);
        }
        // Wheel support
        translate([0, 0,  - wheel_bearing_with_washers_height/2 - wheel_vertical_clearance - wheel_support_height]) cylinder(wheel_support_height, wheel_support_width/2, wheel_support_width/2, $fn=64); 
        }       
    } 
        // Deleting slab
        multmatrix([[1, 0, 0, 0], [0, 1, -tan(wheel_angle), 0], [0, 0, 1, 0], [0, 0, 0, 1]]) {
        translate([0, -wheel_support_width/2, 5 - 1]) cube([wheel_support_width, wheel_support_depth, 10], center = true);
        translate([0, 0, 5 + 1]) cube([wheel_support_width, wheel_support_depth, 10], center = true);
        }
    }
    }
}}
// Structural parts

    // Center cylinder
    difference() {
        translate([0, 0, -wheel_bearing_with_washers_height/2 - wheel_support_height - wheel_vertical_clearance]) cylinder(wheel_bearing_with_washers_height/2 + wheel_vertical_clearance + wheel_support_height, body_od/2, body_od/2, $fn = 64);
        
        // Center hole
        translate([0, 0, -wheel_bearing_with_washers_height/2 - wheel_support_height - wheel_vertical_clearance]) cylinder(wheel_bearing_with_washers_height/2 + wheel_support_height + wheel_vertical_clearance, body_id/2, body_id/2, $fn = 64);                
    }
 }
 
 
 module drilledcrown(top = false, mir = false) {
    difference() {
    if (top) {
        // TOP
        // Wheel screws
        //ClearanceHole(bolt_head_diameter, bolt_head_height, position=[cos(120*0)*(pipe_id/2 - wheel_od/2 + wheel_tight), sin(120*0)*(pipe_id/2 - wheel_od/2 + wheel_tight),-(wheel_bearing_with_washers_height/2 + wheel_support_height + wheel_vertical_clearance)])
        ClearanceHole( bolt_nominal_diameter, wheel_bearing_with_washers_height/2 + wheel_support_height + wheel_vertical_clearance + 1, position=[cos(120*0)*(pipe_id/2 - wheel_od/2 + wheel_tight), sin(120*0)*(pipe_id/2 - wheel_od/2 + wheel_tight),-(wheel_bearing_with_washers_height/2 + wheel_support_height + wheel_vertical_clearance)])  
         
        //ClearanceHole(bolt_head_diameter, bolt_head_height, position=[cos(120*1)*(pipe_id/2 - wheel_od/2 + wheel_tight), sin(120*1)*(pipe_id/2 - wheel_od/2 + wheel_tight),-(wheel_bearing_with_washers_height/2 + wheel_support_height + wheel_vertical_clearance)])
        ClearanceHole( bolt_nominal_diameter, wheel_bearing_with_washers_height/2 + wheel_support_height + wheel_vertical_clearance + 1, position=[cos(120*1)*(pipe_id/2 - wheel_od/2 + wheel_tight), sin(120*1)*(pipe_id/2 - wheel_od/2 + wheel_tight),-(wheel_bearing_with_washers_height/2 + wheel_support_height + wheel_vertical_clearance)])  
   
        //ClearanceHole(bolt_head_diameter, bolt_head_height, position=[cos(120*2)*(pipe_id/2 - wheel_od/2 + wheel_tight), sin(120*2)*(pipe_id/2 - wheel_od/2 + wheel_tight),-(wheel_bearing_with_washers_height/2 + wheel_support_height + wheel_vertical_clearance)])
        ClearanceHole( bolt_nominal_diameter, wheel_bearing_with_washers_height/2 + wheel_support_height + wheel_vertical_clearance + 1, position=[cos(120*2)*(pipe_id/2 - wheel_od/2 + wheel_tight), sin(120*2)*(pipe_id/2 - wheel_od/2 + wheel_tight),-(wheel_bearing_with_washers_height/2 + wheel_support_height + wheel_vertical_clearance)])  
         
             
        // Body screws
        //ClearanceHole(bolt_head_diameter, bolt_head_height, position=[cos(60 + 120*0)*conn_screw_r, sin(60 + 120*0)*conn_screw_r,-(wheel_bearing_with_washers_height/2 + wheel_support_height + wheel_vertical_clearance)])
        ClearanceHole( bolt_nominal_diameter, (wheel_bearing_with_washers_height/2 + wheel_support_height + wheel_vertical_clearance), position=[cos(60 + 120*0)*conn_screw_r, sin(60 + 120*0)*conn_screw_r,-(wheel_bearing_with_washers_height/2 + wheel_support_height + wheel_vertical_clearance)])
        
        //ClearanceHole(bolt_head_diameter, bolt_head_height, position=[cos(60 + 120*1)*conn_screw_r, sin(60 + 120*1)*conn_screw_r,-(wheel_bearing_with_washers_height/2 + wheel_support_height + wheel_vertical_clearance)])
        ClearanceHole( bolt_nominal_diameter, (wheel_bearing_with_washers_height/2 + wheel_support_height + wheel_vertical_clearance), position=[cos(60 + 120*1)*conn_screw_r, sin(60 + 120*1)*conn_screw_r,-(wheel_bearing_with_washers_height/2 + wheel_support_height + wheel_vertical_clearance)])
        
        //ClearanceHole(bolt_head_diameter, bolt_head_height, position=[cos(60 + 120*2)*conn_screw_r, sin(60 + 120*2)*conn_screw_r,-(wheel_bearing_with_washers_height/2 + wheel_support_height + wheel_vertical_clearance)])
        ClearanceHole( bolt_nominal_diameter, (wheel_bearing_with_washers_height/2 + wheel_support_height + wheel_vertical_clearance), position=[cos(60 + 120*2)*conn_screw_r, sin(60 + 120*2)*conn_screw_r,-(wheel_bearing_with_washers_height/2 + wheel_support_height + wheel_vertical_clearance)])

        // Additional body screws
        ScrewHole( bolt_nominal_diameter, (wheel_bearing_with_washers_height/2 + wheel_support_height + wheel_vertical_clearance), position=[cos(60 + 40 + 120*0)*conn_screw_r, sin(60 + 40 + 120*0)*conn_screw_r,-(wheel_bearing_with_washers_height/2 + wheel_support_height + wheel_vertical_clearance)])        
        ScrewHole( bolt_nominal_diameter, (wheel_bearing_with_washers_height/2 + wheel_support_height + wheel_vertical_clearance), position=[cos(60 + 40 + 120*1)*conn_screw_r, sin(60 + 40 + 120*1)*conn_screw_r,-(wheel_bearing_with_washers_height/2 + wheel_support_height + wheel_vertical_clearance)])
        ScrewHole( bolt_nominal_diameter, (wheel_bearing_with_washers_height/2 + wheel_support_height + wheel_vertical_clearance), position=[cos(60 + 40 + 120*2)*conn_screw_r, sin(60 + 40 + 120*2)*conn_screw_r,-(wheel_bearing_with_washers_height/2 + wheel_support_height + wheel_vertical_clearance)])
         
        mirror([0, mir? 1: 0, 0]) crown(top);
    } else {
        // BOTTOM
        // Wheel screws
        ScrewHole( bolt_nominal_diameter, wheel_support_height + wheel_vertical_clearance, position=[cos(120*0)*(pipe_id/2 - wheel_od/2 + wheel_tight), sin(120*0)*(pipe_id/2 - wheel_od/2 + wheel_tight),-(wheel_bearing_with_washers_height/2 + wheel_support_height + wheel_vertical_clearance)])
        ClearanceHole( bolt_nominal_diameter, wheel_bearing_with_washers_height/2 + 1, position=[cos(120*0)*(pipe_id/2 - wheel_od/2 + wheel_tight), sin(120*0)*(pipe_id/2 - wheel_od/2 + wheel_tight),-wheel_bearing_with_washers_height/2])   
         
        ScrewHole( bolt_nominal_diameter, wheel_support_height + wheel_vertical_clearance, position=[cos(120*1)*(pipe_id/2 - wheel_od/2 + wheel_tight), sin(120*1)*(pipe_id/2 - wheel_od/2 + wheel_tight),-(wheel_bearing_with_washers_height/2 + wheel_support_height + wheel_vertical_clearance)])
        ClearanceHole( bolt_nominal_diameter, wheel_bearing_with_washers_height/2 + 1, position=[cos(120*1)*(pipe_id/2 - wheel_od/2 + wheel_tight), sin(120*1)*(pipe_id/2 - wheel_od/2 + wheel_tight),-wheel_bearing_with_washers_height/2])   
         
        ScrewHole( bolt_nominal_diameter, wheel_support_height + wheel_vertical_clearance, position=[cos(120*2)*(pipe_id/2 - wheel_od/2 + wheel_tight), sin(120*2)*(pipe_id/2 - wheel_od/2 + wheel_tight),-(wheel_bearing_with_washers_height/2 + wheel_support_height + wheel_vertical_clearance)])
        ClearanceHole( bolt_nominal_diameter, wheel_bearing_with_washers_height/2 + 1, position=[cos(120*2)*(pipe_id/2 - wheel_od/2 + wheel_tight), sin(120*2)*(pipe_id/2 - wheel_od/2 + wheel_tight),-wheel_bearing_with_washers_height/2])
                     
        // Body screws
        ScrewHole( bolt_nominal_diameter, (wheel_bearing_with_washers_height/2 + wheel_support_height + wheel_vertical_clearance), position=[cos(60 + 120*0)*conn_screw_r, sin(60 + 120*0)*conn_screw_r,-(wheel_bearing_with_washers_height/2 + wheel_support_height + wheel_vertical_clearance)])        
        ScrewHole( bolt_nominal_diameter, (wheel_bearing_with_washers_height/2 + wheel_support_height + wheel_vertical_clearance), position=[cos(60 + 120*1)*conn_screw_r, sin(60 + 120*1)*conn_screw_r,-(wheel_bearing_with_washers_height/2 + wheel_support_height + wheel_vertical_clearance)])
        ScrewHole( bolt_nominal_diameter, (wheel_bearing_with_washers_height/2 + wheel_support_height + wheel_vertical_clearance), position=[cos(60 + 120*2)*conn_screw_r, sin(60 + 120*2)*conn_screw_r,-(wheel_bearing_with_washers_height/2 + wheel_support_height + wheel_vertical_clearance)])

        // Additional body screws
        ScrewHole( bolt_nominal_diameter, (wheel_bearing_with_washers_height/2 + wheel_support_height + wheel_vertical_clearance), position=[cos(60 + 40 + 120*0)*conn_screw_r, sin(60 + 40 + 120*0)*conn_screw_r,-(wheel_bearing_with_washers_height/2 + wheel_support_height + wheel_vertical_clearance)])        
        ScrewHole( bolt_nominal_diameter, (wheel_bearing_with_washers_height/2 + wheel_support_height + wheel_vertical_clearance), position=[cos(60 + 40 + 120*1)*conn_screw_r, sin(60 + 40 + 120*1)*conn_screw_r,-(wheel_bearing_with_washers_height/2 + wheel_support_height + wheel_vertical_clearance)])
        ScrewHole( bolt_nominal_diameter, (wheel_bearing_with_washers_height/2 + wheel_support_height + wheel_vertical_clearance), position=[cos(60 + 40 + 120*2)*conn_screw_r, sin(60 + 40 + 120*2)*conn_screw_r,-(wheel_bearing_with_washers_height/2 + wheel_support_height + wheel_vertical_clearance)])
         
        mirror([0, mir? 1: 0, 0]) crown(top);
    }
    if (top) {
    // Wheel support bolt head slots
    for (i = [0:2]) rotate([0, 0, 360/3*i]) {
        translate([pipe_id/2 - wheel_od/2 + wheel_tight, 0, -(wheel_bearing_with_washers_height/2 + wheel_support_height + wheel_vertical_clearance)]) cylinder(bolt_head_height, bolt_head_diameter/2, bolt_head_diameter/2);
        translate([pipe_id/2 - wheel_od/2 + wheel_tight, 0, -(wheel_bearing_with_washers_height/2 + wheel_support_height + wheel_vertical_clearance) + bolt_head_height]) cylinder(bolt_head_diameter/2, bolt_head_diameter/2, 0);
    }

    // Body bolt head slots
    for (i = [0:2]) rotate([0, 0, 60 + 360/3*i]) {
        translate([conn_screw_r, 0, -(wheel_bearing_with_washers_height/2 + wheel_support_height + wheel_vertical_clearance)]) cylinder(bolt_head_height, bolt_head_diameter/2, bolt_head_diameter/2);
        translate([conn_screw_r, 0, -(wheel_bearing_with_washers_height/2 + wheel_support_height + wheel_vertical_clearance) + bolt_head_height]) cylinder(bolt_head_diameter/2, bolt_head_diameter/2, 0);
    }
    
    }
    // Additional Body bolt head channels
    for (i = [0:2]) rotate([0, 0, 60 + 80 + 360/3*i]) {
        translate([conn_screw_r, 0, -(wheel_bearing_with_washers_height/2 + wheel_support_height + wheel_vertical_clearance)]) cylinder((wheel_bearing_with_washers_height/2 + wheel_support_height + wheel_vertical_clearance), bolt_head_diameter/2, bolt_head_diameter/2);
    }
    }
 }
 
 module hardware() {
     for (i = [0:2]) rotate([0, 0, 360/3*i]) translate([pipe_id/2 - wheel_od/2 + wheel_tight, 0, 0]) rotate([wheel_angle, 0, 0]) translate([0, 0, -wheel_bearing_with_washers_height/2]) wheel();
 }
 
 //pipe();
 
 //rotate([180, 0, 0]) drilledcrown(true);
 //drilledcrown(false, true);
 //translate([0, 0, -16.5]) cylinder(16.5, body_od, body_od);
 //hardware();
 
crown(true);