#HOWTO: add new weapon type
#-add new entry inside <weight> in -set.xml (for all pylons where
# it can be mounted)
#-add new int resolver in setLoadInt() below (with yet unused value)
#-add necessary animation/model show code in proper places in the
# L-159/Models folder

#initialize MP transferred ints
#pylons
props.globals.initNode("/sim/weight[0]/payload-int", 1, "INT");
#right wing (right-to-left)
props.globals.initNode("/sim/weight[1]/payload-int", 0, "INT");
props.globals.initNode("/sim/weight[2]/payload-int", 0, "INT");
props.globals.initNode("/sim/weight[3]/payload-int", 0, "INT");
#fuselage
props.globals.initNode("/sim/weight[4]/payload-int", 0, "INT");
#left wing (right-to-left)
props.globals.initNode("/sim/weight[5]/payload-int", 0, "INT");
props.globals.initNode("/sim/weight[6]/payload-int", 0, "INT");
props.globals.initNode("/sim/weight[7]/payload-int", 0, "INT");
props.globals.initNode("/sim/weight[8]/payload-int", 0, "INT");
setprop("/systems/refuel/serviceable", 0);

#function for resolving MP transferred load type int
#all weapon types have this value identical on all pylons
#(even if some types are not available there)
var setLoadInt = func(pylon_index) {
	var payload = getprop("/sim/weight["~pylon_index~"]/selected");
	#print("Index:" ~ pylon_index ~ "  Payload: " ~ payload);
	if( payload == "None" or payload == "Mount only used pylons" )
		setprop("/sim/weight["~pylon_index~"]/payload-int", 0);
	else if( payload == "Mount all pylons" )
		setprop("/sim/weight["~pylon_index~"]/payload-int", 1);
	else if( payload == "AIM-9" )
		setprop("/sim/weight["~pylon_index~"]/payload-int", 2);
	else if( payload == "PL-20 Plamen" )
		setprop("/sim/weight["~pylon_index~"]/payload-int", 3);
	else if( payload == "AGM-65 Maverick" )
		setprop("/sim/weight["~pylon_index~"]/payload-int", 4);
	else if( payload == "GBU-12 Paveway II" )
		setprop("/sim/weight["~pylon_index~"]/payload-int", 5);
	else if( payload == "GBU-16 Paveway II" )
		setprop("/sim/weight["~pylon_index~"]/payload-int", 6);
	else if( payload == "Mk82" )
		setprop("/sim/weight["~pylon_index~"]/payload-int", 7);
	else if( payload == "Mk83" )
		setprop("/sim/weight["~pylon_index~"]/payload-int", 8);
	else if( payload == "350l Tactical droptank" )
		setprop("/sim/weight["~pylon_index~"]/payload-int", 9);
	else if( payload == "500l Ferry droptank" )
		setprop("/sim/weight["~pylon_index~"]/payload-int", 10);
	else if( payload == "Probe mounted" ) 
		setprop("/systems/refuel/serviceable", 1);
	else if( payload == "No probe" )
		setprop("/systems/refuel/serviceable", 0);
	
		
	#error case - weapon from payloads dialog not implemented here
	else setprop("/sim/weight["~pylon_index~"]/payload-int", 999);
}

setlistener("/sim/weight[0]/selected", func {setLoadInt(0)});
setlistener("/sim/weight[1]/selected", func {setLoadInt(1)});
setlistener("/sim/weight[2]/selected", func {setLoadInt(2)});
setlistener("/sim/weight[3]/selected", func {setLoadInt(3)});
setlistener("/sim/weight[4]/selected", func {setLoadInt(4)});
setlistener("/sim/weight[5]/selected", func {setLoadInt(5)});
setlistener("/sim/weight[6]/selected", func {setLoadInt(6)});
setlistener("/sim/weight[7]/selected", func {setLoadInt(7)});
setlistener("/sim/weight[8]/selected", func {setLoadInt(8)});


#PL-20 Plamen trigger

#initialize triggers
props.globals.initNode("/controls/armament/trigger", 0, "BOOL");
props.globals.initNode("/controls/armament/mode-fast", 0, "BOOL");
#fast variant: 2600 rounds/min
props.globals.initNode("/controls/armament/trigger-fastPlamenC", 0, "BOOL");
props.globals.initNode("/controls/armament/trigger-fastPlamenR", 0, "BOOL");
props.globals.initNode("/controls/armament/trigger-fastPlamenL", 0, "BOOL");
#slow variant: 780 rounds/min
props.globals.initNode("/controls/armament/trigger-slowPlamenC", 0, "BOOL");
props.globals.initNode("/controls/armament/trigger-slowPlamenR", 0, "BOOL");
props.globals.initNode("/controls/armament/trigger-slowPlamenL", 0, "BOOL");

props.globals.initNode("/sim/multiplay/generic/int[6]", 0, "INT");

#ammo counter
props.globals.initNode("/controls/armament/roundsLeft", 210, "INT");
props.globals.initNode("/controls/armament/roundsCount", 210, "DOUBLE");
var reloadPlamen = func {
	#TODO: add ground&stopped check (when finished testing)
	setprop("/controls/armament/roundsLeft", 210);
	setprop("/controls/armament/roundsCount", 210);
	
}

#A resource friendly way of ammo counting: Instead of counting every bullet, I set an interpolate on float variant of ammo counter. But I need a timer to cut off fire when out of ammo. 

var outOfAmmo = maketimer(1.0, 
	func { 
		print("Out of ammo! ");
		setprop("/controls/armament/trigger-fastPlamenC", 0);
		setprop("/controls/armament/trigger-fastPlamenR", 0);
		setprop("/controls/armament/trigger-fastPlamenL", 0);
		setprop("/controls/armament/trigger-slowPlamenC", 0);
		setprop("/controls/armament/trigger-slowPlamenR", 0);
		setprop("/controls/armament/trigger-slowPlamenL", 0);
		setprop("/sim/multiplay/generic/int[6]", 0);
		setprop("/controls/armament/roundsCount", 0);
		setprop("/controls/armament/roundsLeft", 0);
	}
);
outOfAmmo.singleShot = 1;

#check which cannons are mounted, set their own triggers
var triggerControl = func {
	triggerState = getprop("controls/armament/trigger");
	if(triggerState and getprop("/controls/armament/roundsLeft") > 0) {
		var pylonC = getprop("/sim/weight[4]/payload-int");
		var pylonR = getprop("/sim/weight[3]/payload-int");
		var pylonL = getprop("/sim/weight[5]/payload-int");
		
		if(pylonC == 3 or pylonR == 3 or pylonL == 3) {
			if(getprop("/controls/armament/mode-fast")) {
				var fireTime = 4.846; #continuous fire for 2600 r/min
				if(pylonC == 3)
					setprop("/controls/armament/trigger-fastPlamenC", 1);
				if(pylonR == 3)
					setprop("/controls/armament/trigger-fastPlamenR", 1);
				if(pylonL == 3)
					setprop("/controls/armament/trigger-fastPlamenL", 1);
				setprop("/sim/multiplay/generic/int[6]", 2);
			}
			else {
				var fireTime = 16.154; #continuous fire for 780 r/min
				if(pylonC == 3)
					setprop("/controls/armament/trigger-slowPlamenC", 1);
				if(pylonR == 3)
					setprop("/controls/armament/trigger-slowPlamenR", 1);
				if(pylonL == 3)
					setprop("/controls/armament/trigger-slowPlamenL", 1);
				setprop("/sim/multiplay/generic/int[6]", 1);
		
			}
			var roundsLeft = getprop("/controls/armament/roundsLeft");
			setprop("/controls/armament/roundsCount", roundsLeft);
			interpolate("/controls/armament/roundsCount", 0, 
				fireTime*(roundsLeft/210));
			outOfAmmo.restart(fireTime*(roundsLeft/210));
		}
	}
	else {
		setprop("/controls/armament/trigger-fastPlamenC", 0);
		setprop("/controls/armament/trigger-fastPlamenR", 0);
		setprop("/controls/armament/trigger-fastPlamenL", 0);
		setprop("/controls/armament/trigger-slowPlamenC", 0);
		setprop("/controls/armament/trigger-slowPlamenR", 0);
		setprop("/controls/armament/trigger-slowPlamenL", 0);
		
		setprop("/sim/multiplay/generic/int[6]", 0);
		
		setprop("/controls/armament/roundsLeft", 
			getprop("/controls/armament/roundsCount"));#gets truncated
		interpolate("/controls/armament/roundsCount", 
			getprop("/controls/armament/roundsLeft"), 0);
		outOfAmmo.stop();
		#ammo count report on trigger release
		if(getprop("/controls/armament/report-ammo"))
			screen.log.write("Plamen rounds left: " ~ getprop("/controls/armament/roundsLeft"), 1, 0.6, 0.1);
	}
}


setlistener("controls/armament/trigger", triggerControl);


print("L-159 weapons and payload system initialized");

