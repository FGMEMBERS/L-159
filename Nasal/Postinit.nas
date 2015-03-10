
lights_dialog = gui.Dialog.new("/sim/gui/dialogs/L-159/lights-dialog/dialog", "Aircraft/L-159/Dialogs/LightsDialog.xml");

props.globals.initNode("/controls/armament/flares-release", 0, "BOOL");
props.globals.initNode("/controls/armament/chaff-release", 0, "BOOL");

props.globals.initNode("/controls/armament/report-ammo", 0, "BOOL");


#global periodical checks loop - the only periodical stuff not included is fuel system
var globalLoop = 0.1;
var globalChecks = func {
	weight.weightCheck();
	flaps.flapCheck();
	speedbrake.speedCheck();
	
	settimer(globalChecks, globalLoop);
}
globalChecks();


