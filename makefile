#############################################################################
# Makefile for building Flurry
# Command: make debug
#          make release
#          make openmp
#############################################################################

####### Compiler, tools and options

CXX           = g++
F90           = mpif90
LINK          = g++
MPICXX        = mpicxx
MPILD         = mpicxx
LIBS          = $(SUBLIBS)

TARGET        = Tempest

# Location of libmetis.a, metis.h
METIS_LIB_DIR = /usr/local/lib/
METIS_INC_DIR = /usr/local/include/

# Location of mpi.h 
MPI_INC_DIR   = /usr/lib/openmpi/include

# Location of libtioga.a
TIOGA_INC   = ./lib/tioga/src
TIOGA_LIB   = #./lib/tioga/src/libtioga.a

CXX_BASE    = -pipe -Wunused-parameter -Wuninitialized -std=c++11 -I./include -I$(TIOGA_INC) $(DEFINES)
CXX_STD     = -g -02
CXX_DEBUG   = -g -pg -O0 -rdynamic #-fsanitize=address -fno-omit-frame-pointer
CXX_RELEASE = -O3

CXXFLAGS_RELEASE = $(CXX_BASE) $(CXX_RELEASE) -Wno-unknown-pragmas -D_NO_MPI $(DEFINES)
CXXFLAGS_DEBUG   = $(CXX_BASE) $(CXX_DEBUG) -Wno-unknown-pragmas -D_NO_MPI $(DEFINES)
CXXFLAGS_OPENMP  = $(CXX_BASE) $(CXX_RELEASE) -fopenmp -D_NO_MPI $(DEFINES)
CXXFLAGS_MPI     = $(CXX_BASE) $(DEFINES) -Wno-literal-suffix
CXXFLAGS_MPI    += -I$(METIS_INC_DIR) -I$(MPI_INC_DIR)
CXXFLAGS_MPI    += -L$(METIS_LIB_DIR)

####### Output directory - these do nothing currently

OBJECTS_DIR   = ./obj
DESTDIR       = ./bin

####### Files

SOURCES = 	src/global.cpp \
		src/matrix.cpp \
		src/input.cpp \
		src/geo.cpp \
		src/output.cpp \
		src/solver_bounds.cpp \
		src/flux.cpp \
		rc/tempest.cpp \
		src/solver.cpp

TIOGA_SRC = 	lib/tioga/src/ADT.C \
		lib/tioga/src/MeshBlock.C \
		lib/tioga/src/parallelComm.C \
		lib/tioga/src/tioga.C \
		lib/tioga/src/utils.c \
		lib/tioga/src/kaiser.f \
		lib/tioga/src/cellVolume.f90 \
		lib/tioga/src/median.F90 

OBJECTS = 	obj/global.o \
		obj/matrix.o \
		obj/input.o \
		obj/geo.o \
		obj/output.o \
		obj/flux.o \
		obj/tempest.o \
		obj/solver.o \
		obj/solver_bounds.o

TIOGA_OBJ = 	obj/ADT.o \
		obj/MeshBlock.o \
		obj/parallelComm.o \
		obj/utils.o \
		obj/tioga.o \
		obj/kaiser.o \
		obj/median.o \
		obj/cellVolume.o

####### Implicit rules

.cpp.o:
	$(CXX) -c $(CXXFLAGS) $(INCPATH) -o "$@" "$<"

.f90.o:
	$(F90) -c $(FFLAGS) $(INCPATH) -o "$@" "$<"
	
.F90.o:
	$(F90) -c $(FFLAGS) $(INCPATH) -o "$@" "$<"

####### Build rules

$(TARGET):  $(OBJECTS)
	$(LINK) $(LFLAGS) -o $(DESTDIR)/$(TARGET) $(OBJECTS) $(OBJCOMP) $(LIBS) $(DBG)

clean:
	cd obj && rm -f *.o && cd .. && rm -f bin/Tempest

.PHONY: debug
debug: DBG=-pg
debug: CXXFLAGS=$(CXXFLAGS_DEBUG)
debug: LIBS+= #-lasan
debug: $(TARGET)

.PHONY: release
release: CXXFLAGS=$(CXXFLAGS_RELEASE)
release: $(TARGET)

.PHONY: openmp
openmp: CXXFLAGS=$(CXXFLAGS_OPENMP)
openmp: LIBS+= -fopenmp -lgomp
openmp: $(TARGET)

.PHONY: mpi
mpi: CXX=$(MPICXX)
mpi: LINK=$(MPILD)
mpi: CXXFLAGS=$(CXXFLAGS_MPI) $(CXX_RELEASE)
mpi: FFLAGS=-O3
mpi: LIBS+= -lmetis $(TIOGA_LIB)
mpi: $(TARGET)

.PHONY: mpidebug
mpidebug: CXX=$(MPICXX)
mpidebug: LINK=$(MPILD)
mpidebug: CXXFLAGS=$(CXXFLAGS_MPI) $(CXX_DEBUG)
mpidebug: FFLAGS=-g -O1 -rdynamic #-fsanitize=address -fno-omit-frame-pointer
mpidebug: LIBS+= -lmetis $(TIOGA_LIB) #-lasan
mpidebug: $(TARGET)

####### Compile

obj/global.o: src/global.cpp include/global.hpp \
		include/error.hpp \
		include/matrix.hpp
	$(CXX) -c $(CXXFLAGS) $(INCPATH) -o obj/global.o src/global.cpp

obj/funcs.o: src/funcs.cpp include/funcs.hpp include/global.hpp
	$(CXX) -c $(CXXFLAGS) $(INCPATH) -o obj/funcs.o src/funcs.cpp

obj/matrix.o: src/matrix.cpp include/matrix.hpp \
		include/error.hpp
	$(CXX) -c $(CXXFLAGS) $(INCPATH) -o obj/matrix.o src/matrix.cpp

obj/input.o: src/input.cpp include/input.hpp \
		include/global.hpp \
		include/error.hpp \
		include/matrix.hpp
	$(CXX) -c $(CXXFLAGS) $(INCPATH) -o obj/input.o src/input.cpp

obj/geo.o: src/geo.cpp include/geo.hpp \
		include/global.hpp \
		include/error.hpp \
		include/matrix.hpp \
		include/input.hpp \
		include/solver.hpp
	$(CXX) -c $(CXXFLAGS) $(INCPATH) -o obj/geo.o src/geo.cpp

obj/output.o: src/output.cpp include/output.hpp \
		include/global.hpp \
		include/error.hpp \
		include/matrix.hpp \
		include/solver.hpp \
		include/geo.hpp \
		include/input.hpp
	$(CXX) -c $(CXXFLAGS) $(INCPATH) -o obj/output.o src/output.cpp

obj/solver_bounds.o: src/solver_bounds.cpp include/solver.hpp
	$(CXX) -c $(CXXFLAGS) $(INCPATH) -o obj/solver_bounds.o src/solver_bounds.cpp

obj/flux.o: src/flux.cpp include/flux.hpp \
		include/global.hpp \
		include/error.hpp \
		include/matrix.hpp \
		include/input.hpp
	$(CXX) -c $(CXXFLAGS) $(INCPATH) -o obj/flux.o src/flux.cpp

obj/tempest.o: src/tempest.cpp include/tempest.hpp \
		include/global.hpp \
		include/error.hpp \
		include/matrix.hpp \
		include/input.hpp \
		include/geo.hpp \
		include/solver.hpp \
		include/output.hpp
	$(CXX) -c $(CXXFLAGS) $(INCPATH) -o obj/tempest.o src/tempest.cpp

obj/solver.o: src/solver.cpp include/solver.hpp \
		include/global.hpp \
		include/error.hpp \
		include/matrix.hpp \
		include/geo.hpp \
		include/input.hpp
	$(CXX) -c $(CXXFLAGS) $(INCPATH) -o obj/solver.o src/solver.cpp
	
obj/ADT.o: lib/tioga/src/ADT.C lib/tioga/src/ADT.h \
  	lib/tioga/src/codetypes.h \
	lib/tioga/src/utils.h
	$(CXX) -c $(CXXFLAGS) $(INCPATH) -o obj/ADT.o lib/tioga/src/ADT.C

obj/utils.o: lib/tioga/src/utils.c lib/tioga/src/utils.h 
	$(CXX) -c $(CXXFLAGS) $(INCPATH) -o obj/utils.o lib/tioga/src/utils.c
	
obj/parallelComm.o: lib/tioga/src/parallelComm.C lib/tioga/src/parallelComm.h \
  	lib/tioga/src/codetypes.h
	$(CXX) -c $(CXXFLAGS) $(INCPATH) -o obj/parallelComm.o lib/tioga/src/parallelComm.C
	
obj/MeshBlock.o: lib/tioga/src/MeshBlock.C lib/tioga/src/MeshBlock.h \
  	lib/tioga/src/codetypes.h \
	lib/tioga/src/utils.h \
	lib/tioga/src/ADT.h \
	lib/tioga/src/parallelComm.h \
	include/solver.hpp
	$(CXX) -c $(CXXFLAGS) $(INCPATH) -o obj/MeshBlock.o lib/tioga/src/MeshBlock.C

obj/tioga.o: lib/tioga/src/tioga.C lib/tioga/src/tioga.h \
  	lib/tioga/src/codetypes.h \
	lib/tioga/src/utils.h \
	lib/tioga/src/parallelComm.h \
	lib/tioga/src/MeshBlock.h
	$(CXX) -c $(CXXFLAGS) $(INCPATH) -o obj/tioga.o lib/tioga/src/tioga.C

obj/kaiser.o: lib/tioga/src/kaiser.f 
	$(F90) -c $(FFLAGS) $(INCPATH) -o obj/kaiser.o lib/tioga/src/kaiser.f
	
obj/cellVolume.o: lib/tioga/src/cellVolume.f90
	$(F90) -c $(FFLAGS) $(INCPATH) -o obj/cellVolume.o lib/tioga/src/cellVolume.f90

obj/median.o: lib/tioga/src/median.F90 
	$(F90) -c $(FFLAGS) $(INCPATH) -o obj/median.o lib/tioga/src/median.F90
