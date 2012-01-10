########################################################################
#
# Arduino command line tools Makefile
# System part (i.e. project independent)
#
# Copyright (C) 2010 Martin Oldfield <m@mjo.tc>, based on work that is
# Copyright Nicholas Zambetti, David A. Mellis & Hernando Barragan
#
# This file is free software; you can redistribute it and/or modify it
# under the terms of the GNU Lesser General Public License as
# published by the Free Software Foundation; either version 2.1 of the
# License, or (at your option) any later version.
#
# Adapted from Arduino 0011 Makefile by M J Oldfield
#
# Original Arduino adaptation by mellis, eighthave, oli.keller
#
# Version 0.1  17.ii.2009  M J Oldfield
#
#         0.2  22.ii.2009  M J Oldfield
#                          - fixes so that the Makefile actually works!
#                          - support for uploading via ISP
#                          - orthogonal choices of using the Arduino for
#                            tools, libraries and uploading
#
#         0.3  21.v.2010   M J Oldfield
#                          - added proper license statement
#                          - added code from Philip Hands to reset
#                            Arduino prior to upload
#
#         0.4  25.v.2010   M J Oldfield
#                          - tweaked reset target on Philip Hands' advice
#
#         0.5  23.iii.2011 Stefan Tomanek
#                          - added ad-hoc library building
#              17.v.2011   M J Oldfield
#                          - grabbed said version from Ubuntu
#
#         0.6  22.vi.2011  M J Oldfield
#                          - added ard-parse-boards supports
#                          - added -lc to linker opts,
#                            on Fabien Le Lez's advice
#
#         0.7  06.x.2011  Tobias Bielohlawek (rngtng)
#                          - updated for Arduino 1.0 support
#                          - customizable ARDUINO_LIB_PATH
#                          - multiple library path support
#
########################################################################
#
# STANDARD ARDUINO WORKFLOW
#
# Given a normal sketch directory, all you need to do is to create
# a small Makefile which defines a few things, and then includes this one.
#
# For example:
#
#       ARDUINO_DIR  = /Applications/arduino-0013
#
#       TARGET       = CLItest
#       ARDUINO_LIBS = LiquidCrystal
#
#       BOARD_TAG    = uno
#       ARDUINO_PORT = /dev/cu.usb*
#       # Used for the make console command
#       ARDUINO_BAUDRATE = 115200
#
#       include /usr/local/share/Arduino.mk
#
# Hopefully these will be self-explanatory but in case they're not:
#
#    ARDUINO_DIR  - Where the Arduino software has been unpacked
#    TARGET       - The basename used for the final files. Canonically
#                   this would match the .ino file, but it's not needed
#                   here: you could always set it to xx if you wanted!
#    ARDUINO_LIBS - A list of any libraries used by the sketch (we assume
#                   these are in $(ARDUINO_DIR)/hardware/libraries
#    ARDUINO_PORT - The port where the Arduino can be found (only needed
#                   when uploading
#    BOARD_TAG    - The ard-parse-boards tag for the board e.g. uno or mega
#                   'make show_boards' shows a list
#    GIT_ENABLE   - This option will enable the generaiton of a "git_version.h"
#                   header file that will define lastest revision of
#                   files used to generate the binary.
#
#                   For example:
# #define GIT_VERSION_TARGET "b12bdd45e75ba275e2b10abf84411305989bb399"
# #define GIT_DATE_TARGET "Wed Jan 4 18:05:08 2012 +0100"
# 					Thoses formats can be overridden with the following flags:
# 	 GIT_VERSION_FMT
# 	 GIT_DATE_FMT
#
# You might also want to specify these, but normally they'll be read from the
# boards.txt file i.e. implied by BOARD_TAG
#
#    MCU,F_CPU    - The target processor description
#
# Once this file has been created the typical workflow is just
#
#   $ make upload
#
# All of the object files are created in the build-cli subdirectory
# All sources should be in the current directory and can include:
#  - at most one .ino file which will be treated as C++ after the standard
#    Arduino header and footer have been affixed.
#  - any number of .c, .cpp, .s and .h files
#
# Included libraries are built in the build-cli/libs subdirectory.
#
# Besides make upload you can also
#   make             - no upload
#   make clean       - remove all our dependencies
#   make depends     - update dependencies
#   make reset       - reset the Arduino by tickling DTR on the serial port
#   make raw_upload  - upload without first resetting
#   make show_boards - list all the boards defined in boards.txt
#   make console     - launch cu on your device
#
########################################################################
#
# ARDUINO WITH OTHER TOOLS
#
# If the tools aren't in the Arduino distribution, then you need to
# specify their location:
#
#    AVR_TOOLS_PATH = /usr/bin
#    AVRDUDE_CONF   = /etc/avrdude/avrdude.conf
#
########################################################################
#
# ARDUINO WITH ISP
#
# You need to specify some details of your ISP programmer and might
# also need to specify the fuse values:
#
#     ISP_PROG	   = -c stk500v2
#     ISP_PORT     = /dev/ttyACM0
#
# You might also need to set the fuse bits, but typically they'll be
# read from boards.txt, based on the BOARD_TAG variable:
#
#     ISP_LOCK_FUSE_PRE  = 0x3f
#     ISP_LOCK_FUSE_POST = 0xcf
#     ISP_HIGH_FUSE      = 0xdf
#     ISP_LOW_FUSE       = 0xff
#     ISP_EXT_FUSE       = 0x01
#
# I think the fuses here are fine for uploading to the ATmega168
# without bootloader.
#
# To actually do this upload use the ispload target:
#
#    make ispload
#
#
########################################################################
# Some paths
#

ifneq (ARDUINO_DIR,)

ifndef AVR_TOOLS_PATH
AVR_TOOLS_PATH    = $(ARDUINO_DIR)/hardware/tools/avr/bin
endif

ifndef ARDUINO_ETC_PATH
ARDUINO_ETC_PATH  = $(ARDUINO_DIR)/hardware/tools/avr/etc
endif

ifndef AVRDUDE_CONF
AVRDUDE_CONF     = $(ARDUINO_ETC_PATH)/avrdude.conf
endif

ifndef ARDUINO_LIB_PATH
ARDUINO_LIB_PATH  = $(ARDUINO_DIR)/libraries
endif

ARDUINO_CORE_PATH = $(ARDUINO_DIR)/hardware/arduino/cores/arduino

ARDUINO_PIN_PATH = $(ARDUINO_DIR)/hardware/arduino/variants/standard

endif

########################################################################
# git_version.h
#
ifndef GIT_VERSION_FMT
GIT_VERSION_FMT = %H
endif

ifndef GIT_DATE_FMT
GIT_DATE_FMT = %ai
endif

ifndef GIT_HEADER
GIT_HEADER = git_version.h
endif

########################################################################
# boards.txt parsing
#
ifndef BOARD_TAG
BOARD_TAG   = uno
endif

ifndef BOARDS_TXT
BOARDS_TXT  = $(ARDUINO_DIR)/hardware/arduino/boards.txt
endif

ifndef PARSE_BOARD
PARSE_BOARD = ard-parse-boards --boards_txt=$(BOARDS_TXT)
endif

# processor stuff
ifndef MCU
MCU   = $(shell $(PARSE_BOARD) $(BOARD_TAG) build.mcu)
endif

ifndef F_CPU
F_CPU = $(shell $(PARSE_BOARD) $(BOARD_TAG) build.f_cpu)
endif

# normal programming info
ifndef AVRDUDE_ARD_PROGRAMMER
AVRDUDE_ARD_PROGRAMMER = $(shell $(PARSE_BOARD) $(BOARD_TAG) upload.protocol)
endif

ifndef AVRDUDE_ARD_BAUDRATE
AVRDUDE_ARD_BAUDRATE   = $(shell $(PARSE_BOARD) $(BOARD_TAG) upload.speed)
endif

# fuses if you're using e.g. ISP
ifndef ISP_LOCK_FUSE_PRE
ISP_LOCK_FUSE_PRE  = $(shell $(PARSE_BOARD) $(BOARD_TAG) bootloader.unlock_bits)
endif

ifndef ISP_LOCK_FUSE_POST
ISP_LOCK_FUSE_POST = $(shell $(PARSE_BOARD) $(BOARD_TAG) bootloader.lock_bits)
endif

ifndef ISP_HIGH_FUSE
ISP_HIGH_FUSE      = $(shell $(PARSE_BOARD) $(BOARD_TAG) bootloader.high_fuses)
endif

ifndef ISP_LOW_FUSE
ISP_LOW_FUSE       = $(shell $(PARSE_BOARD) $(BOARD_TAG) bootloader.low_fuses)
endif

ifndef ISP_EXT_FUSE
ISP_EXT_FUSE       = $(shell $(PARSE_BOARD) $(BOARD_TAG) bootloader.extended_fuses)
endif

# console baudrate
ifndef ARDUINO_BAUDRATE
ARDUINO_BAUDRATE = 115200
endif


# Everything gets built in here
OBJDIR  	  = build-cli

########################################################################
# Local sources
#
LOCAL_C_SRCS    = $(wildcard *.c)
LOCAL_CPP_SRCS  = $(wildcard *.cpp)
LOCAL_CC_SRCS   = $(wildcard *.cc)
LOCAL_INO_SRCS  = $(wildcard *.ino)
LOCAL_AS_SRCS   = $(wildcard *.S)
LOCAL_OBJ_FILES = $(LOCAL_C_SRCS:.c=.o) $(LOCAL_CPP_SRCS:.cpp=.o) \
		$(LOCAL_CC_SRCS:.cc=.o) $(LOCAL_INO_SRCS:.ino=.o) \
		$(LOCAL_AS_SRCS:.S=.o)
LOCAL_OBJS      = $(patsubst %,$(OBJDIR)/%,$(LOCAL_OBJ_FILES))

# Dependency files
DEPS            = $(LOCAL_OBJS:.o=.d)

# core sources
ifeq ($(strip $(NO_CORE)),)
ifdef ARDUINO_CORE_PATH
CORE_C_SRCS     = $(wildcard $(ARDUINO_CORE_PATH)/*.c)
CORE_CPP_SRCS   = $(wildcard $(ARDUINO_CORE_PATH)/*.cpp)
CORE_OBJ_FILES  = $(CORE_C_SRCS:.c=.o) $(CORE_CPP_SRCS:.cpp=.o)
CORE_OBJS       = $(patsubst $(ARDUINO_CORE_PATH)/%,  \
			$(OBJDIR)/%,$(CORE_OBJ_FILES))
endif
endif

# all the objects!
OBJS            = $(LOCAL_OBJS) $(CORE_OBJS) $(LIB_OBJS)

########################################################################
# Rules for making stuff
#

# The name of the main targets
TARGET_HEX = $(OBJDIR)/$(TARGET).hex
TARGET_ELF = $(OBJDIR)/$(TARGET).elf
TARGETS    = $(OBJDIR)/$(TARGET).*

# A list of dependencies
DEP_FILE   = $(OBJDIR)/depends.mk

# Names of executables
CC      = $(AVR_TOOLS_PATH)/avr-gcc
CXX     = $(AVR_TOOLS_PATH)/avr-g++
OBJCOPY = $(AVR_TOOLS_PATH)/avr-objcopy
OBJDUMP = $(AVR_TOOLS_PATH)/avr-objdump
AR      = $(AVR_TOOLS_PATH)/avr-ar
SIZE    = $(AVR_TOOLS_PATH)/avr-size
NM      = $(AVR_TOOLS_PATH)/avr-nm
REMOVE  = rm -f
MV      = mv -f
CAT     = cat
ECHO    = echo

# General arguments
SYS_LIBS      = $(foreach LPATH, $(ARDUINO_LIB_PATH), $(patsubst %,$(LPATH)/%,$(ARDUINO_LIBS)) )
SYS_INCLUDES  = $(patsubst %,-I%,$(SYS_LIBS))
SYS_OBJS      = $(wildcard $(patsubst %,%/*.o,$(SYS_LIBS)))
LIB_SRC       = $(wildcard $(patsubst %,%/*.cpp,$(SYS_LIBS)))
LIB_OBJS      = $(filter %.o, $(foreach LPATH, $(ARDUINO_LIB_PATH), $(patsubst $(LPATH)/%.cpp,$(OBJDIR)/libs/%.o,$(LIB_SRC)) ) )

# Git git_version.h final filepath
ifdef GIT_ENABLE
GIT_FHEADER   = $(OBJDIR)/$(GIT_HEADER)
endif

CPPFLAGS      = -mmcu=$(MCU) -DF_CPU=$(F_CPU) \
			-I. -I$(ARDUINO_PIN_PATH) -I$(ARDUINO_CORE_PATH) \
			$(SYS_INCLUDES) -g -Os -w -Wall \
			-ffunction-sections -fdata-sections
ifndef ARDUINO
ARDUINO=100
endif
CPPFLAGS	 += -DARDUINO=$(ARDUINO)

CFLAGS        = -std=gnu99
CXXFLAGS      = -fno-exceptions
ASFLAGS       = -mmcu=$(MCU) -I. -x assembler-with-cpp
LDFLAGS       = -mmcu=$(MCU) -lm -Wl,--gc-sections -Os

# Rules for making a CPP file from the main sketch (.cpe)
INOHEADER     = \\\#include \"Arduino.h\"

# Expand and pick the first port
ARD_PORT      = $(firstword $(wildcard $(ARDUINO_PORT)))

# Implicit rules for building everything (needed to get everything in
# the right directory)
#
# Rather than mess around with VPATH there are quasi-duplicate rules
# here for building e.g. a system C++ file and a local C++
# file. Besides making things simpler now, this would also make it
# easy to change the build options in future

# library sources
$(OBJDIR)/libs/%.o:
	mkdir -p $(dir $@)
	for HAY in $(LIB_SRC); do [[ $$HAY =~ $* ]] && IN=$$HAY; done || echo "" && \
	$(CC) -c $(CPPFLAGS) $(CFLAGS) $$IN -o $@

# normal local sources
# .o rules are for objects, .d for dependency tracking
# there seems to be an awful lot of duplication here!!!
$(OBJDIR)/%.o: %.c
	$(CC) -c $(CPPFLAGS) $(CFLAGS) $< -o $@

$(OBJDIR)/%.o: %.cc
	$(CXX) -c $(CPPFLAGS) $(CXXFLAGS) $< -o $@

$(OBJDIR)/%.o: %.cpp
	$(CXX) -c $(CPPFLAGS) $(CXXFLAGS) $< -o $@

$(OBJDIR)/%.o: %.S
	$(CC) -c $(CPPFLAGS) $(ASFLAGS) $< -o $@

$(OBJDIR)/%.o: %.s
	$(CC) -c $(CPPFLAGS) $(ASFLAGS) $< -o $@

$(OBJDIR)/%.d: %.c
	$(CC) -MM $(CPPFLAGS) $(CFLAGS) $< -MF $@ -MT $(@:.d=.o)

$(OBJDIR)/%.d: %.cc
	$(CXX) -MM $(CPPFLAGS) $(CXXFLAGS) $< -MF $@ -MT $(@:.d=.o)

$(OBJDIR)/%.d: %.cpp
	$(CXX) -MM $(CPPFLAGS) $(CXXFLAGS) $< -MF $@ -MT $(@:.d=.o)

$(OBJDIR)/%.d: %.S
	$(CC) -MM $(CPPFLAGS) $(ASFLAGS) $< -MF $@ -MT $(@:.d=.o)

$(OBJDIR)/%.d: %.s
	$(CC) -MM $(CPPFLAGS) $(ASFLAGS) $< -MF $@ -MT $(@:.d=.o)

# the ino -> cpp -> o file
$(OBJDIR)/%.cpp: %.ino $(GIT_FHEADER)
	$(ECHO) $(INOHEADER) > $@
	$(CAT)  $< >> $@

$(OBJDIR)/%.o: $(OBJDIR)/%.cpp
	$(CXX) -c $(CPPFLAGS) $(CXXFLAGS) $< -o $@

$(OBJDIR)/%.d: $(OBJDIR)/%.cpp
	$(CXX) -MM $(CPPFLAGS) $(CXXFLAGS) $< -MF $@ -MT $(@:.d=.o)

# core files
$(OBJDIR)/%.o: $(ARDUINO_CORE_PATH)/%.c
	$(CC) -c $(CPPFLAGS) $(CFLAGS) $< -o $@

$(OBJDIR)/%.o: $(ARDUINO_CORE_PATH)/%.cpp
	$(CXX) -c $(CPPFLAGS) $(CXXFLAGS) $< -o $@

# various object conversions
$(OBJDIR)/%.hex: $(OBJDIR)/%.elf
	$(OBJCOPY) -O ihex -R .eeprom $< $@

$(OBJDIR)/%.eep: $(OBJDIR)/%.elf
	-$(OBJCOPY) -j .eeprom --set-section-flags=.eeprom="alloc,load" \
		--change-section-lma .eeprom=0 -O ihex $< $@

$(OBJDIR)/%.lss: $(OBJDIR)/%.elf
	$(OBJDUMP) -h -S $< > $@

$(OBJDIR)/%.sym: $(OBJDIR)/%.elf
	$(NM) -n $< > $@

########################################################################
#
# Avrdude
#
ifndef AVRDUDE
AVRDUDE          = $(AVR_TOOLS_PATH)/avrdude
endif

AVRDUDE_COM_OPTS = -q -V -p $(MCU)
ifdef AVRDUDE_CONF
AVRDUDE_COM_OPTS += -C $(AVRDUDE_CONF)
endif

AVRDUDE_ARD_OPTS = -c $(AVRDUDE_ARD_PROGRAMMER) -b $(AVRDUDE_ARD_BAUDRATE) -P $(ARD_PORT)

ifndef ISP_PROG
ISP_PROG	   = -c stk500v2
endif

AVRDUDE_ISP_OPTS = -P $(ISP_PORT) $(ISP_PROG)


########################################################################
#
# Explicit targets start here
#

all:		$(OBJDIR) $(TARGET_HEX) $(GIT_FHEADER)

$(OBJDIR):
		mkdir $(OBJDIR)

$(TARGET_ELF): 	$(OBJS)
		$(CC) $(LDFLAGS) -o $@ $(OBJS) $(SYS_OBJS) -lc

$(DEP_FILE):	$(OBJDIR) $(DEPS)
		cat $(DEPS) > $(DEP_FILE)

upload:		reset raw_upload

raw_upload:	$(TARGET_HEX)
		$(AVRDUDE) $(AVRDUDE_COM_OPTS) $(AVRDUDE_ARD_OPTS) \
			-U flash:w:$(TARGET_HEX):i

# stty on MacOS likes -F, but on Debian it likes -f redirecting
# stdin/out appears to work but generates a spurious error on MacOS at
# least. Perhaps it would be better to just do it in perl ?
reset:
		for STTYF in 'stty --file' 'stty -f' 'stty <' ; \
		  do $$STTYF /dev/tty >/dev/null 2>/dev/null && break ; \
		done ;\
		$$STTYF $(ARD_PORT)  hupcl ;\
		(sleep 0.1 || sleep 1)     ;\
		$$STTYF $(ARD_PORT) -hupcl

ispload:	$(TARGET_HEX)
		$(AVRDUDE) $(AVRDUDE_COM_OPTS) $(AVRDUDE_ISP_OPTS) -e \
			-U lock:w:$(ISP_LOCK_FUSE_PRE):m \
			-U hfuse:w:$(ISP_HIGH_FUSE):m \
			-U lfuse:w:$(ISP_LOW_FUSE):m \
			-U efuse:w:$(ISP_EXT_FUSE):m
		$(AVRDUDE) $(AVRDUDE_COM_OPTS) $(AVRDUDE_ISP_OPTS) -D \
			-U flash:w:$(TARGET_HEX):i
		$(AVRDUDE) $(AVRDUDE_COM_OPTS) $(AVRDUDE_ISP_OPTS) \
			-U lock:w:$(ISP_LOCK_FUSE_POST):m

$(GIT_FHEADER):
		> $(GIT_FHEADER)
		for repo in . $(foreach LPATH, $(ARDUINO_LIB_PATH), $(patsubst %,$(LPATH)/%,$(ARDUINO_LIBS)) ) ; do \
			if [ "$$repo" = "." ]; then \
				reponame=`echo $(TARGET) | tr '[:lower:]' '[:upper:]'` ; \
			else \
				reponame=`basename $${repo} | tr '[:lower:]' '[:upper:]'`; \
			fi ; \
			if [ -d $${repo} ]; then \
				git_output=`git log -1 $${repo} 2>/dev/null` ; \
				if [ $$? = 0 ]; then \
					pushd $${repo} >/dev/null; \
					git_version=`git log --pretty=format:'$(GIT_VERSION_FMT)' -1` ; \
					git_date=`git log --pretty=format:'$(GIT_DATE_FMT)' -1` ; \
					popd >/dev/null; \
					echo "#define GIT_VERSION_$${reponame} \"$${git_version}\"" >> $(GIT_FHEADER); \
					echo "#define GIT_DATE_$${reponame} \"$${git_date}\"" >> $(GIT_FHEADER); \
					echo "" >> $(GIT_FHEADER) ; \
				else \
					echo "Repository $${repo} is not managed thru git." ; \
				fi ; \
			fi ; \
		done ;\

clean:
		$(REMOVE) $(OBJS) $(TARGETS) $(DEP_FILE) $(DEPS) $(GIT_FHEADER)

depends:	$(DEPS)
		cat $(DEPS) > $(DEP_FILE)

console:
		socat - $(ARDUINO_PORT),echo=0,crnl,crtscts=0,cs8,igncr=1,b$(ARDUINO_BAUDRATE),echoctl=0

show_boards:
		$(PARSE_BOARD) --boards

.PHONY:	all clean depends upload raw_upload reset show_boards

include $(DEP_FILE)
