#########################################################
#              Make file for Cell Writer                #
#########################################################

# Use standard variables to define compile and link flags
ACC=gprbuild
TA=cell_writer
TS=$(TA).gpr
BA=tobase64
BS=$(BA).gpr
DB=$(TA).db
HOST_TYPE := $(shell uname -m)
ARCH := $(shell dpkg --print-architecture)
ifeq ($(HOST_TYPE),amd)
	TARGET=sparc
else ifeq ($(HOST_TYPE),x86_64)
	ifeq ($(ARCH),i386)
		TARGET=x86
        else
		TARGET=amd64
	endif
else ifeq ($(HOST_TYPE),x86)
	TARGET=x86
else ifeq ($(HOST_TYPE),i686)
	TARGET=x86
else ifeq ($(HOST_TYPE),arm)
	TARGET=pi
else ifeq ($(HOST_TYPE),armv7l)
	TARGET=pi
else ifeq ($(HOST_TYPE),aarch64)
	TARGET=pi64
endif

BIN=/usr/local/bin
ETC=/usr/local/etc
VAR=/var/local/lib
TD=obj_$(TARGET)
SD=system
ifeq ("$1.",".")
	FLAGS=-Xhware=$(TARGET)
else
	FLAGS=-Xhware=$(TARGET) $1
endif
FLAGS+=-largs -lxdo

# Define the target "all"
all: cellwriter tobase64s
.PHONY : all

cellwriter:
	echo "TARGET='$(TARGET)'."
	$(ACC) -P $(TS) $(FLAGS)

tobase64s:
	$(ACC) -P $(BS) $(FLAGS)

# Clean up to force the next compilation to be everything
.PHONY: clean
clean:
	gprclean -P $(TS)
	gprclean -P $(BS)

dist-clean: distclean

distclean: clean

install:
	cp $(TD)/$(TA) $(BIN)
	cp $(TD)/$(BA) $(BIN)
ifneq (,$(wildcard $(VAR)/$(DB))) 
	echo "Not overwriting $(VAR)/$(DB)."
else
	cp $(SD)/$(DB) $(VAR)
endif
	mkdir -p /var/log/$(TA)
	chgrp users /var/log/$(TA)
	chmod u+w /var/log/$(TA)

