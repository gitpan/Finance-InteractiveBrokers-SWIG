#
# Finance::InteractiveBrokers::SWIG - Makefile for SWIG build
#
# Copyright (c) 2010-2011 Jason McManus
# Version: 0.01
#
# This is usually invoked by 'perl Makefile.PL && make', but if you need to
# run it separately, you can run it by:
#
#   make -fMakefile.swig [ OPTIONS ]
#
# OPTIONS:
#   IB_BUILD_PATH=/path/to/IBJts		# wherever your un-jar'ed API is
#   SWIG=/path/to/swig					# path to SWIG binary program
#   IB_API_VERSION=X.XX					# version of the IB API [def: 9.64]
#
# Pre-existing files:
#   Makefile.swig
#   IBAPI-VER.i
#   IBAPI-VER.cxx
#   IBAPI-VER.h
#   ezembed.h
#   $IB_BUILD_PATH/cpp/PosixSocketClient/EClientSocketBase.cpp
#   $IB_BUILD_PATH/cpp/PosixSocketClient/EPosixClientSocket.cpp
# Intermediate files:
#   EClientSocketBase.o
#   EPosixClientSocket.o
#   IBAPI_wrap.cxx
#   IBAPI_wrap.o
#   IBAPI.o
# Final targets:
#   IBAPI.pm
#   IBAPI.so
#

###
### Options
###

CC=g++
LD=ld
CXXEXT=cxx
DLEXT=so
SWIGEXT=i
PMEXT=pm
OBJEXT=o

# These should be overridden on the command-line
SWIG=swig
IB_BUILD_PATH=$(PROJDIR)/ass/tws_api/IBJts
IB_API_VERSION=9.64
BUILD_TIME=0

ifdef DEBUG
DDEBUG=-DDEBUG
else
DDEBUG=
endif

SOCKDIR=$(IB_BUILD_PATH)/cpp/PosixSocketClient
INCLUDES=-I$(IB_BUILD_PATH)/cpp/Shared -I$(SOCKDIR)
IB_API_VER=-$(IB_API_VERSION)

MODBASE=Finance::InteractiveBrokers::SWIG
MODNAME=IBAPI
MODFULL=$(MODBASE)::$(MODNAME)
LIBNAME=$(MODNAME).$(DLEXT)

# Get the perl C opts from perl itself, and clean them up for C++
PERLJUNK=$(shell perl -MExtUtils::Embed -e ccopts)
PERLOPTS=$(PERLJUNK:-Wdeclaration-after-statement=)

SWIGOPTS=-c++ -perl -Wall -DBUILD_TIME=$(BUILD_TIME)
CCOPTS=-fPIC -DBUILD_TIME=$(BUILD_TIME)
LDOPTS=-shared -Wl,-E

IBSTRING=-DIB_USE_STD_STRING

###
### Build rules
###

.PHONY: all
all: lib

.PHONY: lib
lib: $(MODNAME).$(DLEXT)

.PHONY: swig
swig: $(MODNAME).$(PMEXT)

$(MODNAME).$(DLEXT): $(MODNAME).$(PMEXT)
	@echo --------------------------
	@echo Building module library...
	@echo --------------------------
	$(CC) $(CCOPTS) $(DDEBUG) $(INCLUDES) $(IBSTRING) $(PERLOPTS) -c $(MODNAME)$(IB_API_VER).$(CXXEXT) -o $(MODNAME).$(OBJEXT)
	$(CC) $(CCOPTS) $(DDEBUG) $(INCLUDES) $(IBSTRING) $(PERLOPTS) -c $(MODNAME)_wrap.cxx -o $(MODNAME)_wrap.$(OBJEXT)
	$(CC) $(CCOPTS) $(DDEBUG) $(INCLUDES) $(IBSTRING) -c $(SOCKDIR)/EClientSocketBase.cpp -o EClientSocketBase.$(OBJEXT)
	$(CC) $(CCOPTS) $(DDEBUG) $(INCLUDES) $(IBSTRING) -c $(SOCKDIR)/EPosixClientSocket.cpp -o EPosixClientSocket.$(OBJEXT)
	$(CC) $(LDOPTS) $(DDEBUG) -o $@ $(MODNAME).$(OBJEXT) $(MODNAME)_wrap.$(OBJEXT) EClientSocketBase.$(OBJEXT) EPosixClientSocket.$(OBJEXT)

$(MODNAME).$(PMEXT): $(MODNAME)$(IB_API_VER).$(SWIGEXT) $(MODNAME)$(IB_API_VER).$(CXXEXT) $(MODNAME)$(IB_API_VER).h
	@echo --------------------------------------------
	@echo Building SWIG interface for $(IB_API_VER)...
	@echo --------------------------------------------
	$(SWIG) $(SWIGOPTS) $(INCLUDES) -o $(MODNAME)_wrap.$(CXXEXT) $<

.PHONY: clean
clean:
	rm -f $(MODNAME)_wrap.* $(MODNAME).$(PMEXT) *.$(OBJEXT) *.$(DLEXT)

# END