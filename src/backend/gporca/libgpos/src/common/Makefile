#
# Makefile for optimizer
#
# src/backend/gporca/libgpos/src/common/Makefile
#

subdir = src/backend/gporca/libgpos/src/common
top_builddir = ../../../../../..
include $(top_builddir)/src/Makefile.global

override CPPFLAGS := -I$(top_builddir)/src/backend/gporca/libgpos/include $(CPPFLAGS)
override CPPFLAGS := -I$(top_builddir)/src/backend/gporca/libgpopt/include $(CPPFLAGS)
override CPPFLAGS := -I$(top_builddir)/src/backend/gporca/libnaucrates/include $(CPPFLAGS)
override CPPFLAGS := -I$(top_builddir)/src/backend/gporca/libgpdbcost/include $(CPPFLAGS)
# FIXME: Would be better to include gporca.mk, but hitting a warning
override CXXFLAGS := -Wno-variadic-macros -fno-omit-frame-pointer $(CXXFLAGS)

OBJS        = CAutoTimer.o \
              CBitSet.o \
              CBitSetIter.o \
              CBitVector.o \
              CDebugCounter.o \
              CHeapObject.o \
              CMainArgs.o \
              CRandom.o \
              CRefCount.o \
              CStackDescriptor.o \
              CStackObject.o \
              CTimerUser.o \
              CWallClock.o \
              clibwrapper.o \
              syslibwrapper.o

include $(top_srcdir)/src/backend/common.mk

