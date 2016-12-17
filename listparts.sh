#!/bin/bash

list="$(grep -r name L-159.ac | awk '{ print $2 }')"
list2="${list//$'\n'\"/$'\n'<object-name>}"
echo "${list2//\"/</object-name>}" | tail -n +2
