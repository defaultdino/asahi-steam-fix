#!/bin/bash
mkdir -p /run/dbus
[ -S /run/dbus/system_bus_socket ] || /usr/bin/dbus-daemon --system --fork
exit 0
