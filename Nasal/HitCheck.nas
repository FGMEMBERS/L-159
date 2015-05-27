### Submodel hit evaluation procedures by Tomaskom ###

var m2ft = 3.2808399;

var evalPart = func(azimuth, inclination) {
	#will return part string which is damaged
	return "IDK"; #TODO
}

var modelsNode = props.globals.getNode("/ai/models");

#returns closest aircraft if splash=0 or all in range if splash>0; returns list of hashes in the form {aircraft:"path/to/MP", distance:distToImpact}
var getAircraft = func(elev, lat, lon, splash) {
	#TODO
	var impactCoord = geo.Coord.new();
	impactCoord.set_latlon(lat, lon, elev);
	var closestDist = 5000; #maximal distance on which damage can occur
	var planeCoord = geo.Coord.new();
	var mpInRange = [];
	
	forindex (var iMP; modelsNode.getChildren("multiplayer")) {
		#print("Processing MP #"~iMP);
		#print("MPlat: "~getprop("/ai/models/multiplayer["~iMP~"]/position/latitude-deg"));
		#print("MPlon: "~getprop("/ai/models/multiplayer["~iMP~"]/position/altitude-ft"));
		#print("MPalt: "~getprop("/ai/models/multiplayer["~iMP~"]/position/altitude-ft"));
		var latDeg = getprop("/ai/models/multiplayer["~iMP~"]/position/latitude-deg");
		var lonDeg = getprop("/ai/models/multiplayer["~iMP~"]/position/longitude-deg");
		var altFt = getprop("/ai/models/multiplayer["~iMP~"]/position/altitude-ft");
		if(latDeg == nil or lonDeg == nil or altFt == nil) continue;
		planeCoord.set_latlon(latDeg, lonDeg, altFt);
		var dist = impactCoord.direct_distance_to(planeCoord);
		if(splash>0 and dist<splash) {
			append(mpInRange, {aircraft:"/ai/models/multiplayer["~iMP~"]", distance:dist});
		}
		else if(dist<closestDist) {
			mpInRange = [];
			append(mpInRange, {aircraft:"/ai/models/multiplayer["~iMP~"]", distance:dist});
			closestDist = dist;
		}
	}
	return mpInRange;
}

var transmit = func(target, damage, part) {
	screen.log.write("Damaged "~target~" with "~damage~" damage to the "~part);
	#setprop("/sim/multiplay/chat", "Damaged "~target);
	#TODO
};

#class representing a projectile type
var projectile = {
	
	#constructor
	new: func(reportPath) {
		var m = { parents: [projectile] };
		m.reportPath = reportPath;
		m.baseDamage = 10;
		m.reportMP = 1;
		m.reportGround = 0;
		m.splash = 0; #if 0, closest is damaged; if > 0, all in range damaged (proportional to distance)
		m.alwaysDamageNearest = 0; #irrelevant for non-splash non-ground, which always damages nearest
		m.listen = setlistener(reportPath, 
			func {
				#processing TODO, add turn on/off switch
				var path = getprop(reportPath);
				var impactType = getprop(path~"/impact/type");
				print("impactType: "~impactType);
				if( (m.reportMP and (impactType=="multiplayer")) or (m.reportGround and (impactType=="terrain")) ) {
					var elev = m2ft*getprop(path~"/impact/elevation-m");
					var lat = getprop(path~"/impact/latitude-deg");
					var lon = getprop(path~"/impact/longitude-deg");
					#print("reporting impact:");
					var hitMP = getAircraft(elev, lat, lon, m.splash);
					foreach(var hit; hitMP) {
						transmit(getprop(hit.aircraft~"/callsign")~" (dist="~hit.distance~"m)", m.baseDamage, evalPart(0, 0));
					}
					
					#linear interpolate of damage (baseDamage->0 as dist->splash) in case of splash
				}	
			}
		);
		
		return m;
	},
	
	#destructor
	del: func {
		removelistener(me.listen);
	},
};

plamen = projectile.new("sim/ai/aircraft/impact/bullet");
plamen.reportGround = 0;


print("L-159 hit checking initialized");

