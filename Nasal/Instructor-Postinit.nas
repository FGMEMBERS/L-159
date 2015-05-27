setprop("/sim/is-MP-Aircraft", 1);

#view fix for instructor
setprop("/sim/current-view/view-number", 0);
setprop("/sim/current-view/field-of-view", getprop("/sim/view/config/default-field-of-view-deg"));
