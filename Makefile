JRA_ROOT ?= /lustre/f2/pdata/gfdl/gfdl_O/datasets/reanalysis/JRA55-do/v1.4.0/
DATA_DIRS ?= original
OUT_DIR ?= .
MD5SUM_FILE ?= $(OUT_DIR)/md5sums.txt

# Tested with nco version 4.6.4
# Fails with nco 4.3.0 (on GFDL systems)
# Wrong sums with nco 4.1.0 because of a "NCO" global attribute

SHELL=/bin/bash

space :=
space +=
ALL_SOURCE = $(filter-out areacell% sftof% sos_% uos_% vos_%,$(notdir $(wildcard $(foreach f,$(DATA_DIRS),$(JRA_ROOT)/$(f)/*.nc))))
ALL_TARGETS = $(sort $(subst .nc,.padded.nc,$(foreach f,$(ALL_SOURCE),$(OUT_DIR)/$(f))))
VPATH = $(subst $(space),:,$(foreach f,$(DATA_DIRS),$(JRA_ROOT)/$(f)))
NCRCAT = ncrcat -h
NCKS = ncks -h

all: $(ALL_TARGETS)
check: $(MD5SUM_FILE)
	cd $(<D); md5sum -c $(<F)
md5: $(MD5SUM_FILE)
$(MD5SUM_FILE): $(foreach f,$(ALL_TARGETS),$(dir $(f))/.$(notdir $(f)).md5sum)
	@echo Constructing $@
	@cat $^ > $@
$(OUT_DIR)/.%.md5sum: $(OUT_DIR)/%
	@echo Calculating $(@F)
	@cd $(@D); md5sum $(^F) | tee $(@F)

#Year = $(word 2,$(subst -,$(space),$(subst _,$(space),$(word 2,$(subst 1-4-0_,$(space),$(notdir $(1)))))))
Year = $(shell echo $(1) | sed 's/.*_\([0-9][0-9][0-9][0-9]\).*/\1/')
YearM1 = $(shell echo $(call Year,$(1))-1 | bc)
YearP1 = $(shell echo $(call Year,$(1))+1 | bc)

IfExist = $(shell test -f $(1) && echo $(1))
PrevFileName = $(subst $(call Year,$(1)),$(call YearM1,$(1)),$(1))
PrevFile = $(call IfExist, $(call PrevFileName, $(1)))
NextFileName = $(shell echo $(1) | sed 's/$(call Year,$(1)).*/$(call YearP1,$(1))\*/')
NextFile = $(call IfExist, $(call NextFileName, $(1)))

TIME_HEAD = 0,0
TIME_TAIL = -1,

$(OUT_DIR)/%.padded.nc: %.nc
	@echo Making $@ from $(notdir $(call PrevFile,$<)) $(notdir $<) $(notdir $(call NextFile,$<))
	@rm -f head.nc tail.nc firstslice.nc
	@test -f $(call PrevFileName,$<) && $(NCKS) -d time,$(TIME_TAIL) $(call PrevFileName,$<) head.nc || :
	@if [[ $(notdir $<) == *"195801010130"* ]] ; then ncks -h -d time,0,0 $< firstslice.nc ; ncap2 -h -s 'time=time*0+21184.0' firstslice.nc head.nc ; fi
	@test -f $(call NextFileName,$<) && $(NCKS) -d time,$(TIME_HEAD) $(call NextFileName,$<) tail.nc || :
	@test -f tail.nc -a ! -f head.nc && $(NCRCAT) $< tail.nc $@ || :
	@test -f head.nc -a ! -f tail.nc && $(NCRCAT) head.nc $< $@ || :
	@test -f head.nc -a -f tail.nc && $(NCRCAT) head.nc $< tail.nc $@ || :
	@F=$@; if [[ $${F:0:4} == "rlds"  && -f $@ ]] ; then ncatted -h -O -a comment,rlds,d,, $@; else echo ...skiping ; fi # Remove long comment in rlds files
	@rm -f head.nc tail.nc firstslice.nc

clean:
	rm -f $(OUT_DIR)/.*.md5sum
Clean: clean
	rm -f $(ALL_TARGETS)
