library(dplyr)
library(ggplot2); theme_set(theme_bw())

library(shellpipes)
rpcall("SD_dogs.incubation.Rout R/incubation.R SD_dogs.dat.rds R/convert.R")
sourceFiles()
animals <- rdsRead()

flag <- list(low=7, high=180)
censor <- list(low=4, high=730)
badRatio <- 3

## We want to create bestInc from dateInc and reportedInc
## We have dateInc < 0 days
## We have less NAs in dateInc than reportedInc, so we would like to use dateInc for bestInc and "fill in" the handful of problematic cases using reportedInc

incs <- (animals
	%>% mutate(dateInc = as.numeric(Symptoms.started - Date.bitten)
	, reportedInc = Incubation.period*as.numeric(convertDay(Incubation.period.units))
	)
)

## We have more NAs in reporting than dates
with(incs, {
	print(table(is.na(dateInc), is.na(reportedInc)))
	print(table(is.na(Incubation.period), Incubation.period.units))
})

incsonly <- (incs
	%>% filter(!is.na(dateInc+reportedInc))
	%>% select(dateInc, reportedInc)
	%>% add_count(dateInc, reportedInc)
)

print(summary(incsonly))

print(ggplot(incsonly, aes(x=dateInc, y=reportedInc, size=n))
	+ geom_point()
	+ scale_color_manual(values=c(2,1))
	+ ylim(0,200)
	+ xlim(0,200)
	+ scale_x_log10() + scale_y_log10()
	+ xlab("Incubation period from dates")
	+ ylab("Incubation period from reports")
	+ geom_abline(slope=1)
	+ scale_size_area()
)

badInc <- (incs 
	%>% filter(!between(dateInc, flag$low, flag$high))
	%>% mutate(code = "inc1")
	%>% select(Notes, code, ID, dateInc, reportedInc, Date.bitten, Symptoms.started, everything())
)

print(
	  ggplot(incsonly, aes(x=dateInc, y=reportedInc/dateInc, size=n))
	  + xlim(0,200)
	  + geom_point()
	  + scale_x_log10() + scale_y_log10()
	  + geom_hline(yintercept=c(1/7, 7/30, 1/30, 30/7))
	  + scale_size_area()
)

## Flag potential unit problems
badunits <- (incs
	%>% filter(dateInc > 0)
	%>% filter (dateInc/reportedInc > badRatio | reportedInc/dateInc > badRatio)
	%>% mutate(code = "inc2")
	%>% select(Notes, code, ID, dateInc, Incubation.period, Incubation.period.units, everything())
)

dat <- rbind(badInc, badunits)

csvSave(dat, ext="check.csv")

bestInc <- (incs
	%>% mutate(
		bestInc = if_else(!is.na(dateInc) & (dateInc>=3)
			, dateInc, reportedInc
		), bestInc = if_else(between(bestInc, censor$low, censor$high)
			, bestInc, NA
		)
	)
)

summary(bestInc)

csvSave(bestInc)
