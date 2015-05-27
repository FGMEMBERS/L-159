#node holding the current MP 
props.globals.initNode("/instructor/target-MP", "", "STRING");
props.globals.initNode("/instructor/hide-me", 1, "BOOL");

var posNode = props.globals.getNode("/position");
var orientNode = props.globals.getNode("/orientation");
var veloNode = props.globals.getNode("/velocities");
var canopyNode = props.globals.getNode("/canopy");
var engineNode = props.globals.getNode("/engines/engine[0]");
var gearNode = props.globals.getNode("/gear");
var lightsNode = props.globals.getNode("/controls");
var disintNode = props.globals.getNode("/disintegration");
var surfNode = props.globals.getNode("/surface-positions");
var disintNode = props.globals.getNode("/disintegration");
var genericNode = props.globals.getNode("/sim/multiplay/generic");
var simNode = props.globals.getNode("/sim");
var livNode = props.globals.getNode("/sim/model/livery");

var posNodeMP = nil;
var orientNodeMP = nil;
var veloNodeMP = nil;
var canopyNodeMP = nil;
var engineNodeMP = nil;
var gearNodeMP = nil;
var controlsNodeMP = nil;
var surfNodeMP = nil;
var disintNodeMP = nil;
var genericNodeMP = nil;
var simNodeMP = nil;
var livNodeMP = nil;

var recentTarg = nil;

var setNodes = func {
	var targ = getprop("/instructor/target-MP");
	if(targ=="" or targ==nil) {
		if(recentTarg!=nil) setprop(recentTarg~"/instructor/hide-me", 0);
		setprop("/instructor/hide-me", 1);
		recentTarg = targ;
		return;
	}
	setprop("/instructor/hide-me", 0);
	setprop(targ~"/instructor/hide-me", 1);
	
	posNodeMP = props.globals.getNode(targ~"/position");
	orientNodeMP = props.globals.getNode(targ~"/orientation");
	veloNodeMP = props.globals.getNode(targ~"/velocities");
	canopyNodeMP = props.globals.getNode(targ~"/canopy");
	engineNodeMP = props.globals.getNode(targ~"/engines/engine[0]");
	gearNodeMP = props.globals.getNode(targ~"/gear");
	controlsNodeMP = props.globals.getNode(targ~"/controls");
	surfNodeMP = props.globals.getNode(targ~"/surface-positions");
	disintNodeMP = props.globals.getNode(targ~"/disintegration");
	genericNodeMP = props.globals.getNode(targ~"/sim/multiplay/generic");
	simNodeMP = props.globals.getNode(targ~"/sim");
	livNodeMP = props.globals.getNode(targ~"/sim/model/livery");
	recentTarg = targ;
}

var update = func {
	var targ = getprop("/instructor/target-MP");
	if(targ=="" or targ==nil) return;
	
	#do some stuff manually to spare copying of larger prop tree parts
	var alt = getprop(targ~"/position/altitude-ft");
	var lat = getprop(targ~"/position/latitude-deg");
	var lon = getprop(targ~"/position/longitude-deg");
	var head = getprop(targ~"/orientation/true-heading-deg");
	var pitch = getprop(targ~"/orientation/pitch-deg");
	var roll = getprop(targ~"/orientation/roll-deg");
	var speed = getprop(targ~"/velocities/true-airspeed-kt");
	var crashed = getprop(targ~"/sim/crashed");
	#TODO: speed (especially for disintegration)
	if(alt==nil or lat==nil or lon==nil or head==nil or pitch==nil or roll==nil or speed==nil or crashed==nil) return;
	
	
	#copy certain subtrees into local tree
#	if(posNodeMP!=nil) props.copy(posNodeMP, posNode);
#	if(orientNodeMP!=nil) props.copy(orientNodeMP, orientNode);
	if(veloNodeMP!=nil) props.copy(veloNodeMP, veloNode);
	if(canopyNodeMP!=nil) props.copy(canopyNodeMP, canopyNode);
	if(engineNodeMP!=nil) props.copy(engineNodeMP, engineNode);
	if(gearNodeMP!=nil) props.copy(gearNodeMP, gearNode);
	if(controlsNodeMP!=nil) props.copy(controlsNodeMP, lightsNode);
	if(surfNodeMP!=nil) props.copy(surfNodeMP, surfNode);
#	if(disintNodeMP!=nil) props.copy(disintNodeMP, disintNode);
	if(genericNodeMP!=nil) props.copy(genericNodeMP, genericNode);
	if(livNodeMP!=nil) props.copy(livNodeMP, livNode);
	
	#payload info
	forindex(var iNode; simNodeMP.getChildren("weight")) {
		var id = getprop(targ~"/sim/weight["~iNode~"]/payload-int");
		if(id!=nil) setprop("/sim/weight["~iNode~"]/payload-int", id);
	}
		
	#fix for heading vs true-heading
#	var heading = getprop(targ~"/orientation/true-heading-deg");
#	if(heading!=nil) setprop("/orientation/heading-deg", heading);


	setprop("/position/altitude-ft", alt);
	setprop("/position/latitude-deg", lat);
	setprop("/position/longitude-deg", lon);
	setprop("/orientation/heading-deg", head);
	setprop("/orientation/pitch-deg", pitch);
	setprop("/orientation/roll-deg", roll);
	setprop("/velocities/airspeed-kt", speed);
	if(crashed!=getprop("/sim/crashed")) setprop("/sim/crashed", crashed); #if work-around to prevent Bombable from picking up writes
	
	#AGL calculation - can be disabled to improve performance
	var geoI = geodinfo(lat, lon);
	if(geoI!=nil) setprop("/position/altitude-agl-ft", alt-M2FT*geoI[0]);
	
}


var listenFrame_Instructor = setlistener("/sim/signals/frame", update, 1, 1);
var listenTargChange_Instructor = setlistener("/instructor/target-MP", setNodes, 1, 1);

print("Instructor MP code initialized");


###temporary
#setprop("/instructor/target-MP", "/ai/models/multiplayer[0]");


