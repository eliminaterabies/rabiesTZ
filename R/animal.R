library(readr)
library(dplyr)
library(shellpipes)
rpcall("animal.Rout R/animal.R cleanHead_Animal.Rout.csv")

## Use this call to make animal.Rout independently
rpcall("animal.Rout R/animal.R cleanHead_Animal.Rout.csv")

animals <- (csvRead()
	%>% mutate(NULL
		, Date.bitten = as.Date(Date.bitten, "%d-%b-%Y")
  		, Symptoms.started = as.Date(Symptoms.started, "%d-%b-%Y")
		, Year.bitten = as.numeric(format(Date.bitten, "%Y"))
		, Year.symptoms = as.numeric(format(Symptoms.started, "%Y"))
	)
	## Keep things with valid ID and some evidence of bite
	%>% filter(
		!is.na(ID) & ID>0
		& (!is.na(Year.bitten) | !is.na(Year.symptoms))
	)
	%>% dplyr:::select(Year.bitten, Year.symptoms, everything(.))
)

print(names(animals))
print(dim(animals))

csvSave(animals)

rdsSave(animals)
