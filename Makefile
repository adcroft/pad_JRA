JRA_ROOT ?= /lustre/f1/pdata/gfdl_O/datasets/reanalysis/JRA55-do
DATA_DIRS ?= v1.2/u_10 v1.2/q_10
OUT_DIR ?= .
MD5SUM_FILE ?= $(OUT_DIR)/md5sums.txt

# Tested with nco version 4.2.1 4.3.1, 4.5.4 4.6.4
# Fails with nco 4.3.0 (on GFDL systems)
# Wrong sums with nco 4.1.0 because of a "NCO" global attribute

space :=
space +=
ALL_SOURCE = $(notdir $(wildcard $(foreach f,$(DATA_DIRS),$(JRA_ROOT)/$(f)/*)))
ALL_TARGETS = $(sort $(subst .nc,.padded.nc,$(foreach f,$(ALL_SOURCE),$(OUT_DIR)/$(f))))
ALL_TARGETS = $(OUT_DIR)/q_10.1958.18Aug2017.padded.nc $(OUT_DIR)/q_10.1959.18Aug2017.padded.nc $(OUT_DIR)/q_10.1960.18Aug2017.padded.nc $(OUT_DIR)/q_10.1961.18Aug2017.padded.nc
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

Year = $(word 2,$(subst .,$(space),$(notdir $(1))))
YearM1 = $(shell echo $(call Year,$(1))-1 | bc)
YearP1 = $(shell echo $(call Year,$(1))+1 | bc)

IfExist = $(shell test -f $(1) && echo $(1))
PrevFileName = $(subst .$(call Year,$(1)).,.$(call YearM1,$(1)).,$(1))
PrevFile = $(call IfExist, $(call PrevFileName, $(1)))
NextFileName = $(subst .$(call Year,$(1)).,.$(call YearP1,$(1)).,$(1))
NextFile = $(call IfExist, $(call NextFileName, $(1)))

TIME_TAIL = 0,7
TIME_TAIL = 2912,
$(OUT_DIR)/runoff%: TIME_TAIL = 364,
$(OUT_DIR)/runoff%: TIME_HEAD = 0,0

$(OUT_DIR)/%.padded.nc: %.nc
	@echo Making $@ from $(notdir $(call PrevFile,$<)) $(notdir $<) $(notdir $(call NextFile,$<))
	@rm -f head.nc tail.nc
	@test -f $(call PrevFileName,$<) && $(NCKS) -d time,$(TIME_TAIL) $(call PrevFileName,$<) head.nc || :
	@test -f $(call NextFileName,$<) && $(NCKS) -d time,$(TIME_HEAD) $(call NextFileName,$<) tail.nc || :
	@test ! -f head.nc && $(NCRCAT) $< tail.nc $@ || :
	@test ! -f tail.nc && $(NCRCAT) head.nc $< $@ || :
	@test -f head.nc -a -f tail.nc && $(NCRCAT) head.nc $< tail.nc $@ || :
	@rm -f head.nc tail.nc

clean:
	rm -f $(OUT_DIR)/.*.md5sum
Clean: clean
	rm -f $(ALL_TARGETS)
