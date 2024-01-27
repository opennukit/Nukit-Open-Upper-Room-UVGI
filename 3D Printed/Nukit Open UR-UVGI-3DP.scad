/* [Model Options] */

Print_Part = "shade"; // ["shade","cap","assembly"]

/* [UV Lampshade] */
Shade_Height = 120;   // [50:400]
Shade_Diameter = 120; // [50:400]
Shade_Bore = 70;      // [20:100]
Base_Height = 2;      // [0:5]

/* [Light Ports] */
Top_Wedge = true; 
Port_X_Count = 44;  // [0:60]
Port_Y_Count = 12;   // [0:30]
Port_Wall = 0.8;      // [0:0.1:5]
Port_Segments = 100; // [5:200]
Port_Angle = 0;     // [-30:45]

/* [Screw Thread] */
Thread_Height = 10;      // [5:20]
Thread_Pitch = 3;        // [1:0.1:5]
Thread_Angle = 30;	    // [20:45]
Thread_Resolution = 60; // [60,120,180]

/* [Screw Cap] */
Cap_Height = 70;        // [10:100]
Cap_Bore = 40;          // [0:100]
Cap_Hole_Count   = 0;   // [0:20]
Cap_Hole_Offset  = 30;  // [0:0.1:100]
Cap_Hole_Size = 4;      // [1:0.1:40]
Cap_Thread_Tolerance = 0.3; // [0:0.1:0.5]

/* [Assembly] */
Cutaway = false;


/* [Hidden] */
Thread_Diameter = Shade_Bore + 15;

use <quickthread.scad> 

if(Print_Part=="shade") {
	lightshade();
} else if(Print_Part=="cap") {
	translate([0,0,Cap_Height]) rotate([180,0,0]) lightshade_cap();
} else if(Print_Part=="dev") {
	if(1) helix();
	if(0) helix_wedge(segments=10);
} else if(Print_Part=="assembly") {
	if(1) difference() {
		color("gold") lightshade();
		if(Cutaway) color("red") translate([0,0,Base_Height+10+0.001]) cube([100,100,120]);
	}

	if(1) translate([0,0,Shade_Height + 0.0]) difference() {
		color("gold") lightshade_cap();
		if(Cutaway) color("red") translate([0,0,-0.001]) cube([Shade_Diameter/2,Shade_Diameter/2,120]);
	}
}


function circle_p(theta) = [cos(theta),sin(theta),0];

module helix(or=50,ir=20,h=40,wall=2,wrap=0.2,segments=50) {
	rz = (or-ir)*sin(Port_Angle); // radial height change
	base = (Port_Angle<0) ? rz : 0;
	zh = h + (Top_Wedge ? abs(base) : abs(rz));
	ai = 360*wrap/segments;
	zi = zh/segments;
	points = [for(i=[0:segments]) each [ 
		// commpute the four points of this segment
		ir*circle_p(i*ai) + wall/2*circle_p(i*ai+90) + [0,0,base+i*zi-rz],
		ir*circle_p(i*ai) + wall/2*circle_p(i*ai-90) + [0,0,base+i*zi-rz],
		or*circle_p(i*ai) + wall/2*circle_p(i*ai-90) + [0,0,base+i*zi],
		or*circle_p(i*ai) + wall/2*circle_p(i*ai+90) + [0,0,base+i*zi]
	]];
	//echo(points);
	bottom_face = [0,1,2,3];
	top_face = [3,2,1,0] + (segments)*[4,4,4,4];
	connect_faces = [
		[1,0, 4,5],
		// [2,1, 5,6],
		[2,1,5], [2,5,6],
		[3,2, 6,7],
		// [0,3, 7,4],
		[0,3,4], [3,7,4]
	];
	faces = [ 
		bottom_face,
		for(i=[0:segments-1]) for(v = connect_faces) v + i*[4,4,4,4],
		top_face 
	];
	//echo(faces);
	polyhedron(points = points, faces = faces, convexity=4);
}


module helix_wedge(or=50,ir=20,h=40,wall=2,wrap=0.1,segments=50) {
	ai = 360*wrap/segments;
	zi = h/segments;
	zri = (or-ir)*sin(Port_Angle);
	points = [for(i=[0:segments]) each let(w = wall/2 * (segments-i)/segments, ratio=1-i/(segments) ) [ 
		// commpute the four points of this segment
		ir*circle_p(i*ai)  + w*circle_p(i*ai+90)  + [0,0,i*zi-zri],
		ir*circle_p(-i*ai) + w*circle_p(-i*ai-90) + [0,0,i*zi-zri],
		or*circle_p(-i*ai) + w*circle_p(-i*ai-90) + [0,0,i*zi],
		or*circle_p(i*ai)  + w*circle_p(i*ai+90)  + [0,0,i*zi]
	]];
	//echo(points);
	bottom_face = [0,1,2,3];
	top_face = [3,2,1,0] + (segments)*[4,4,4,4];
	connect_faces = [
		[1,0, 4,5],
		// [2,1, 5,6],
		[2,1,5], [2,5,6],
		[3,2, 6,7],
		// [0,3, 7,4],
		[0,3,4], [3,7,4]
	];
	faces = [ 
		bottom_face,
		for(i=[0:segments-1]) for(v = connect_faces) v + i*[4,4,4,4],
		top_face 
	];
	//echo(faces);
	if(Port_Angle<0) {
		hull() polyhedron(points = points, faces = faces, convexity=4);
	} else {
		polyhedron(points = points, faces = faces, convexity=4);
	}
}

module lightshade() {
	// do we need the top wedge, either because requested or because we have a positive port angle
	need_wedge = Top_Wedge; //  || (Port_Angle>0) ? true : false;
	cap_fn = need_wedge ? Port_X_Count : 180;
	// start with a solid base
	linear_extrude(height=Base_Height, convexity=2) {
		circle(d=Shade_Diameter+1.001, $fn=180);
	}
	intersection() {
		// confine to the cylinder
		cylinder(d=Shade_Diameter+10, h=Shade_Height, $fn=Port_X_Count*2);
		union() {
			// helixes
			hh = (Shade_Height - Base_Height * 2) / (Port_Y_Count + (need_wedge ? 0.5 : 0));
			for(j=[0:Port_X_Count-1]) translate([0,0,Base_Height]) {
				rotate(360/Port_X_Count*j) {
					w = 1/Port_X_Count * Port_Y_Count;
					h = hh * Port_Y_Count;
					helix(or=Shade_Diameter/2, ir=Shade_Bore/2, h=h, wall=Port_Wall, wrap=w,  segments=Port_Segments);
					helix(or=Shade_Diameter/2, ir=Shade_Bore/2, h=h, wall=Port_Wall, wrap=-w, segments=Port_Segments);
				}
			}
			// top wedges
			if(need_wedge) {
				for(j=[0:Port_X_Count-1]) translate([0,0,Shade_Height-Base_Height-hh/2]) {
					rotate(360/Port_X_Count*j) {
						w = 1/Port_X_Count;
						h = hh / 2;
						helix_wedge(or=Shade_Diameter/2, ir=Shade_Bore/2, h=h, wall=Port_Wall, wrap=w/2,  segments=floor(Port_Segments/Port_Y_Count/2));
					}
				}
			}
		}
	}
	// cap with bore hole
	translate([0,0,Shade_Height-Base_Height-0.001]) rotate(need_wedge ? 180/Port_X_Count : 0 ) {
		linear_extrude(height=Base_Height, convexity=2) difference() {
			circle(d=Shade_Diameter, $fn=cap_fn);
			circle(d=Shade_Bore, $fn=cap_fn);
		}
		zri = (Shade_Diameter-Shade_Bore)/2*sin(Port_Angle);
		mirror([0,0,1]) difference() {
			cylinder(d1=Shade_Diameter, d2=Shade_Bore, h=zri, $fn=cap_fn);
			translate([0,0,-1]) cylinder(d=Shade_Bore, h=zri+2, $fn=cap_fn);
		}
	}
	// thread on top
	translate([0,0,Shade_Height-0.002]) difference() {
		isoThread(d=Thread_Diameter, h=Thread_Height, pitch=Thread_Pitch,angle=Thread_Angle,internal=false,$fn=Thread_Resolution);
		rotate(Top_Wedge ? 180/Port_X_Count : 0 ) translate([0,0,-1]) cylinder(d=Shade_Bore, h=Thread_Height+2, $fn=cap_fn);
	}
}

module lightshade_cap(h=Cap_Height,base_h=3) {
	difference() {
		translate([0,0,0.001]) cylinder(d=Thread_Diameter+6, h=h, $fn=Thread_Resolution);
		union() {
			// thread 
			isoThread(d=Thread_Diameter+Cap_Thread_Tolerance*2, h=Thread_Height+1, pitch=Thread_Pitch,angle=Thread_Angle,internal=true,$fn=Thread_Resolution);
			// above-thread space
			translate([0,0,Thread_Height+1-0.01]) cylinder(d=max(Cap_Bore, Thread_Diameter-4), h=h-Thread_Height-base_h-1, $fn=Thread_Resolution);
			// cap bore
			if(Cap_Bore) cylinder(d=Cap_Bore, h=h+0.01, $fn=Thread_Resolution);
			// cap holes
			if(Cap_Hole_Count) {
				for(i=[0:Cap_Hole_Count-1]) rotate(i*360/Cap_Hole_Count) 
					translate([Cap_Hole_Offset,0,0]) cylinder(d=Cap_Hole_Size, h=h+0.01, $fn=24);
			}
		}
	}
}

