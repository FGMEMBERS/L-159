#node holding the current MP 
props.globals.initNode("/instructor/target-MP", "", "STRING");
props.globals.initNode("/instructor/hide-me", 1, "BOOL");

#model path to match
var hostModel = "Aircraft/L-159/Models/L-159.xml";


var PICKHOST_DLG = 0;
var pickHost_dialog = {};
############################################################
pickHost_dialog.init = func (host_type, x = nil, y = nil) {
	me.x = x;
	me.y = y;
	me.bg = [0, 0, 0, 0.3]; # background color
	me.fg = [[1.0, 1.0, 1.0, 1.0]]; 
	#
	# "private"
	me.title = "Host aircraft selection";
	
	me.basenode = props.globals.getNode("/sim/remote", 1);
	me.dialog = nil;
	me.namenode = props.Node.new({"dialog-name" : me.title });
	me.listeners = [];
	me.host_type = host_type;
	props.globals.initNode(me.basenode.getPath()~"/host-callsign", "", "STRING");
}
############################################################
pickHost_dialog.create = func {
	if (me.dialog != nil)
		me.close();

	me.dialog = gui.Widget.new();
	me.dialog.set("name", me.title);
	if (me.x != nil)
		me.dialog.set("x", me.x);
	if (me.y != nil)
		me.dialog.set("y", me.y);

	me.dialog.set("layout", "vbox");
	me.dialog.set("default-padding", 0);
	var titlebar = me.dialog.addChild("group");
	titlebar.set("layout", "hbox");
	titlebar.addChild("empty").set("stretch", 1);
	titlebar.addChild("text").set("label", "Hosts available online");
	var w = titlebar.addChild("button");
	w.set("pref-width", 16);
	w.set("pref-height", 16);
	w.set("legend", "");
	w.set("default", 0);
	w.set("key", "esc");
	w.setBinding("nasal", "instructor_pickHost.pickHost_dialog.destroy(); ");
	w.setBinding("dialog-close");
	me.dialog.addChild("hrule");

	var content = me.dialog.addChild("group");
	content.set("layout", "vbox");
	content.set("halign", "center");
	content.set("default-padding", 5);

	# Generate the dialog contents.
	me.players = me.find_copilot_players();
	var i = 0;
	var tmpbase  = me.basenode.getNode("dialog", 1);
	var selected = me.basenode.getNode("host-callsign").getValue();
	foreach (var p; me.players) {
		var tmp = tmpbase.getNode("b[" ~ i ~ "]", 1);
		tmp.setBoolValue(streq(selected, p));
		var w = content.addChild("checkbox");
		w.node.setValues({"label"    : p,
						  "halign"   : "left",
						  "property" : tmp.getPath()});
		w.setBinding
			("nasal",
			 "instructor_pickHost.pickHost_dialog.select_action(" ~ i ~ ");");
		i = i + 1;
	}
	me.dialog.addChild("hrule");

	# Display the dialog.
	fgcommand("dialog-new", me.dialog.prop());
	fgcommand("dialog-show", me.namenode);
}
############################################################
pickHost_dialog.close = func {
	fgcommand("dialog-close", me.namenode);
}
############################################################
pickHost_dialog.destroy = func {
	PICKHOST_DLG = 0;
	me.close();
	foreach(var l; me.listeners)
		removelistener(l);
	delete(gui.dialog, "\"" ~ me.title ~ "\"");
}
############################################################
pickHost_dialog.show = func (host_type) {
#	print("Showing MPCopilots dialog!");
	if (!PICKHOST_DLG) {
		PICKHOST_DLG = int(getprop("/sim/time/elapsed-sec"));
		me.init(host_type);
		me.create();
		me._update_(PICKHOST_DLG);
	}
}
############################################################
pickHost_dialog._redraw_ = func {
	if (me.dialog != nil) {
		me.close();
		me.create();
	}
}
############################################################
pickHost_dialog._update_ = func (id) {
	if (PICKHOST_DLG != id) return;
	me._redraw_();
	settimer(func { me._update_(id); }, 4.1);
}
############################################################
pickHost_dialog.select_action = func (n) {
	var selected = me.basenode.getNode("host-callsign").getValue();
	var bs = me.basenode.getNode("dialog").getChildren();
	# Assumption: There are two true b:s or none. The one not matching selected
	#             is the new selection.
	var i = 0;
	me.basenode.getNode("host-callsign").setValue("");
	foreach (var b; bs) {
		if (!b.getValue() and (i == n)) {
			b.setValue(1);
			me.basenode.getNode("host-callsign").setValue(me.players[i]);
		} else {
			b.setValue(0);
		}
		i = i + 1;
	}
	
	foreach(var nodeMP; props.globals.getNode("/ai/models").getChildren("multiplayer")) {
		var thisCall = nodeMP.getNode("callsign").getValue();
		if( thisCall!=nil and streq(thisCall, me.basenode.getNode("host-callsign").getValue()) ) setprop("/instructor/target-MP", nodeMP.getPath());
	}
	
	#dual_control.main.reset();
	me._redraw_();
}
############################################################
# Return a list containing all nearby copilot players of the right type.
pickHost_dialog.find_copilot_players = func {
	var mpplayers =
		props.globals.getNode("/ai/models").getChildren("multiplayer");

	var res = [];
	foreach (var pilot; mpplayers) {
		if ((pilot.getNode("valid") != nil) and
			(pilot.getNode("valid").getValue()) and
			(pilot.getNode("sim/model/path") != nil)) {
			var type = pilot.getNode("sim/model/path").getValue();

			if (type == me.host_type) {
				append(res, pilot.getNode("callsign").getValue());
			}
		}
	}
#	debug.dump(res);
	return res; 
}



