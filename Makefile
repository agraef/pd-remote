# -*- mode: makefile-gmake -*-

# This needs GNU make.

# You may want to set this if you want to install the external in a custom
# directory.

#PDLIBDIR = /usr/lib/pd/extra

lib.name = pd-remote

# No need to edit anything below this line, usually.

datafiles = pd-remote.pd

include Makefile.pdlibbuilder

install: installplus

installplus:
	cp -r examples "${installpath}"
