library(dplyr)
library(tidyverse)
library(shellpipes)
rpcall("SD_dogs.dat.Rout R/dat.R animal.rds branch/SD_dogs.rda")

animals <- rdsRead()
loadEnvironments()

dim(animals)

if(exists("DistrictF"))
	animals <- filter(animals, District==DistrictF)

if(exists("SpeciesF"))
	animals <- filter(animals, Species==SpeciesF)

if(exists("firstYear"))
	animals <- filter(animals, 
		(!is.na(Year.bitten) & (Year.bitten >= firstYear))
		| ((!is.na(Year.symptoms) & (Year.symptoms >= firstYear)))
	)

dim(animals)
rdsSave(animals)
csvSave(animals)
