#.SUFFIXES: .o .cxx

options= -Ofast -march=native -fopenmp

CFLAGS =-I./sprng/include -I/usr/local/include -DMOVECENTROIDTEST 

#Below is the LDFLAGS Toby Zeng use on nlogn
LDFLAGS=-L/home/pnroy/Dev/lib64/ -lm -L./sprng/lib -llcg -L/home/pnroy/Dev/lib64/ -lgfortran  -L/opt/intel/mkl/lib/intel64 -lmkl_intel_lp64 -lmkl_sequential -lmkl_core
#below is the LDFLAGS with minimum flags
#LDFLAGS= -lm -L./sprng/lib -llcg -lgfortran
 
#-------------------------------------------------------------------------
#  Compilers
#-------------------------------------------------------------------------

#CC=mpic++
#CC=g++
CC=/home/pnroy/Dev/bin/g++
FC=gfortran
#FC=/home/pnroy/Dev/bin/gfortran

#-------------------------------------------------------------------------
# objects for QMC
 
pimcOBJS=mc_piqmc.o mc_estim.o mc_qworm.o mc_input.o mc_setup.o mc_poten.o mc_randg.o mc_utils.o rotden.o rotpro_sub.o rotred.o potred.o vcord.o vcalc.o initconf.o vspher.o caleng_tip4p_gg.o omprng.o rngstream.o
 
#----------------------------------------- PIMC --------------------------

pimc:			mc_main.o $(pimcOBJS) 
			$(CC) -o $@  mc_main.o $(pimcOBJS) $(LDFLAGS) -fopenmp

mc_main.o:		mc_main.cc mc_confg.h mc_input.h mc_setup.h mc_randg.h mc_utils.h mc_const.h mc_piqmc.h mc_estim.h mc_qworm.h
			$(CC) $(options) -c  $(CFLAGS) -o $@ $*.cc
 
mc_input.o:        	mc_input.cc mc_input.h	mc_confg.h mc_setup.h mc_utils.h mc_const.h
			$(CC) $(options) -c  $(CFLAGS) -o $@ $*.cc

mc_setup.o:        	mc_setup.cc mc_setup.h mc_confg.h mc_utils.h mc_const.h
			$(CC) $(options) -c  $(CFLAGS) -o $@ $*.cc

mc_randg.o:        	mc_randg.cc mc_randg.h mc_input.h mc_confg.h mc_utils.h mc_const.h 
			$(CC) $(options) -c  $(CFLAGS) -o $@ $*.cc

mc_utils.o:        	mc_utils.cc mc_utils.h mc_confg.h mc_const.h
			$(CC) $(options) -c  $(CFLAGS) -o $@ $*.cc

mc_poten.o:        	mc_poten.cc mc_poten.h mc_setup.h mc_confg.h mc_utils.h mc_const.h mc_input.cc
			$(CC) $(options) -c  $(CFLAGS) -o $@ $*.cc

mc_piqmc.o:        	mc_piqmc.cc mc_piqmc.h mc_poten.h mc_const.h mc_setup.h mc_utils.h mc_estim.h
			$(CC) $(options) -c  $(CFLAGS) -o $@ $*.cc

mc_estim.o:        	mc_estim.cc mc_estim.h mc_setup.h mc_utils.h mc_poten.h mc_input.h mc_qworm.h mc_confg.h 
			$(CC) $(options) -c  $(CFLAGS) -o $@ $*.cc

mc_qworm.o:        	mc_qworm.cc mc_qworm.h mc_setup.h mc_utils.h mc_confg.h mc_randg.h mc_piqmc.h 
			$(CC) $(options) -c  $(CFLAGS) -o $@ $*.cc

omprng.o:               omprng.cc omprng.h
			$(CC) -c -fopenmp -lgomp omprng.cc

rngstream.o: 		rngstream.cc rngstream.h
			$(CC) -c -fopenmp -lgomp rngstream.cc

.PHONY: clean
			
clean:
			rm -f *.o core pimc 

wipe:
			rm -f mc00* mc00*.*old *.dump

.f.o:
	${FC} -O3 -c $<
#---------------------------------------------------------------------------
# %.o: %.cxx
# $(CC) $(options) -c  $(CFLAGS) $(CPPFLAGS) $< -o $@
#---------------------------------------------------------------------------
