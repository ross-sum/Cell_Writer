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
ifeq ($(TARGET),pi)
	FLAGS+=-largs -lwiringPi
endif

cellwriter:
	$(ACC) -P $(TS) $(FLAGS)

tobase64s:
	$(ACC) -P $(BS) $(FLAGS)

# Define the target "all"
all:
	cellwriter:
	tobase64s:

# Clean up to force the next compilation to be everything
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
	cp $(SD)/$(TA).xsd $(ETC)
	mkdir -p $(ETC)/init.d/
	cp $(SD)/$(TA).rc $(ETC)/init.d/$(TA)
	mkdir -p $(ETC)/default/
	cp $(SD)/$(TA).default $(ETC)/default/$(TA)
	mkdir -p $(ETC)/systemd/system/
	cp $(SD)/$(TA).service $(ETC)/systemd/system/
	mkdir -p /var/log/$(TA)

