## This is the TZ new_pipeline:
## https://github.com/eliminaterabies/rabiesTZ.git

Sources += Makefile README.md TODO.md

######################################################################

include setup.mk
-include makestuff/perl.def

######################################################################

## Dropbox for confidential inputs and outputs
## Default location ~/Dropbox/Rabies_TZ
## Set location in personal local.mk
## Store if needed in <yourname>.local
Sources += $(wildcard *.local)
## katie.config: katie.local
## jd.config: jd.local

Sources += katie.setup

Ignore += local.mk
-include local.mk

include dropbox.mk

dropsetup: datadir outdir
	$(MAKE) Animal_CT.csv Human_CT.csv

##################################################################

README.html: README.md

##################################################################

## Copies of main inputs (don't commit!)

Ignore += Animal_CT.csv Human_CT.csv

## del Animal_CT.csv ## to update for new data
Animal_CT.csv: datadir/*Animal*.csv
	$(LNF) `ls -t datadir/*Animal*.csv | head -1` $@
	$(touch)

## del Human_CT.csv ## to update for new data
Human_CT.csv:
	$(LNF) datadir/*Human*.csv $@

##################################################################

## R friendly csv
cleanHead_Animal.Rout: R/cleanHead.R Animal_CT.csv
	$(rrule)

## Some basic cleaning
animal.Rout: R/animal.R cleanHead_Animal.Rout.csv
	$(rrule)

######################################################################

## Examine: on hold 2022 Nov 15 (Tue)

animal.look.Rout: R/look.R animal.rds
	$(rrule)

######################################################################

## Branching: 
## Try config files for now

.PRECIOUS: branch/%.Rout branch/%.rda
branch/%.rda: $(lscheck)
branch/%.Rout: branch/%.R
	$(rrule)

## SD_dogs.dat.Rout: R/dat.R branch/SD_dogs.R
pipeRimplicit += dat
%.dat.Rout: R/dat.R animal.rds branch/%.rda
	$(rrule)

## branch/SD_new_dogs.R

######################################################################

## Checks

## SD_dogs.IDCheck.Rout: R/IDCheck.R
pipeRimplicit += IDCheck
%.IDCheck.Rout: R/IDCheck.R %.dat.rds
	$(rrule)

## SD_dogs.ageCheck.Rout: R/ageCheck.R
pipeRimplicit += ageCheck
%.ageCheck.Rout: R/ageCheck.R %.dat.rds 
	$(rrule)

## SD_dogs.suspectCheck.Rout: R/suspectCheck.R
pipeRimplicit += suspectCheck
%.suspectCheck.Rout: R/suspectCheck.R %.dat.rds 
	$(rrule)

## SD_dogs.outcomeCheck.Rout: R/outcomeCheck.R
pipeRimplicit += outcomeCheck
%.outcomeCheck.Rout: R/outcomeCheck.R %.dat.rds 
	$(rrule)

## Basic check for incubation periods
## SD_dogs.incCheck.Rout: R/incCheck.R
pipeRimplicit += incCheck
%.incCheck.Rout:  R/incCheck.R %.dat.rds R/convert.R
	$(rrule)

## Process incubation periods (FIXME what is the check file?)
## SD_dogs.incubation.Rout: R/incubation.R
## SD_dogs.incubation.check.csv: R/incubation.R
Ignore += *.incubation.check.csv
.PRECIOUS: %.incubation.check.csv
%.incubation.check.csv: %.incubation.Rout ;
%.incubation.Rout: R/incubation.R %.dat.rds R/convert.R
	$(rrule)

## SD_dogs.wildlifeCheck.Rout: R/wildlifeCheck.R
pipeRimplicit += wildlifeCheck
%.wildlifeCheck.Rout: R/wildlifeCheck.R %.dat.rds 
	$(rrule)

## SD_dogs.dateCheck.Rout: R/dateCheck.R
pipeRimplicit += dateCheck
%.dateCheck.Rout: R/dateCheck.R %.dat.rds 
	$(rrule)

## SD_dogs.symptomCheck.Rout: R/symptomCheck.R
pipeRimplicit += symptomCheck
%.symptomCheck.Rout: R/symptomCheck.R %.dat.rds 
	$(rrule)

## SD_dogs.infCheck.Rout: R/infCheck.R
pipeRimplicit += infCheck
%.infCheck.Rout: R/infCheck.R %.dat.rds 
	$(rrule)

######################################################################

## Curate output csvs

Ignore += *.allchecks
%.allchecks: %.dat.Rout %.IDCheck.Rout %.ageCheck.Rout %.suspectCheck.Rout %.outcomeCheck.Rout %.incCheck.Rout %.wildlifeCheck.Rout %.dateCheck.Rout %.symptomCheck.Rout %.infCheck.Rout %.incubation.Rout ;
	$(touch)

outdir/%/stamp: %.allchecks
	rsync $*.*.csv outdir/$*/
	date > $@

## outdir/SD_dogs/stamp:

######################################################################

## Make report

## SD_dogs.report.html: report.rmd
Ignore += *.report.html
%.report.html: report.rmd outdir/%/stamp
	$(knithtml)

## This is not piped yet! 2022 Nov 28 (Mon)
Sources += $(wildcard *.script)
SD_dogs.noscript: makestuff/pipeRscript.pl clonedir/make.log
	$(PUSH)

######################################################################

## Cribbing; this should be removed once we have finished cannibalizing
## the private repo

## Transfer version of p1/Makefile
Sources += content.mk

Ignore += p1
p1:
	cp -r ../tz_pipeline $@ \
	|| git clone https://github.com/wzmli/rabies_db_pipeline $@

.PRECIOUS: R/%.R
R/%.R:
	/bin/cp p1/R/$*.R .

######################################################################

### Makestuff

Ignore += makestuff
msrepo = https://github.com/dushoff

Makefile: makestuff/00.stamp
makestuff/%.stamp:
	- $(RM) makestuff/*.stamp
	(cd makestuff && $(MAKE) pull) || git clone --depth 1 $(msrepo)/makestuff
	touch $@

-include makestuff/os.mk

-include makestuff/pipeR.mk

-include makestuff/git.mk
-include makestuff/visual.mk
