# get_Sinclair_Z.R
# estimate total mortality rate from survey catch at age data in ADIOS format using Sinclair method

library("ASAPplots")
library("dplyr")
library("ggplot2")

decoder <- read.csv(".\\ADIOS_data\\file_decoder.csv")
nstocks <- length(decoder$Short.Name)

# create default list of stocks, surveys, usesurvey (T/F), start age, end age, first year, last year
defdf <- data.frame(stockID = integer(),
                    stock = character(),
                    survey = character(),
                    usesurvey = logical(),
                    startage = integer(),
                    endage = integer(),
                    firstyear = integer(),
                    endyear = integer(),
                    note = character())
for (istock in 1:nstocks){
  dat <- read.csv(paste0(".\\ADIOS_data\\", decoder$ADIOS.name[istock], ".csv"))
  surveys <- unique(dat$SURVEY)
  nsurveys <- length(surveys)
  for (isurvey in 1:nsurveys){
    sdat <- dat %>%
      filter(SURVEY == surveys[isurvey])
    minyear <- min(sdat$YEAR)
    maxyear <- max(sdat$YEAR)
    minage <- min(sdat$AGE)
    maxage <- max(sdat$AGE)
    thisdf <- data.frame(stockID = istock,
                         stock = decoder$Short.Name[istock],
                         survey = as.character(surveys[isurvey]),
                         usesurvey = TRUE,
                         startage = minage,
                         endage = maxage,
                         firstyear = minyear,
                         endyear = maxyear,
                         note = "original")
    defdf <- rbind(defdf, thisdf)
  }
}
defdf$rowID <- seq(1, length(defdf[,1]))
defdf
write.csv(defdf, file=".\\ADIOS_data\\survey_options_orig.csv", row.names = FALSE)

#############################################################################################
# need to do some work by hand outside this program - described in this block of comments
# save survey_options_use.csv only when run the first time
# write.csv(defdf, file=".\\ADIOS_data\\survey_options_use.csv", row.names = FALSE)
# now run Shiny app.R and change survey_options_use.csv for each stock/survey combination
# note survey_options_use.csv will be overwritten if click Update button - so be careful
# survey_options_use_backup.csv provided in case accidently overwrite the file
# Shiny app located in directory ./inst/shiny_examples/SetUp/SinclairZ
#############################################################################################

# Estimate Sinclair Z based on age ranges for used surveys only and plot
so_use <- read.csv(".\\ADIOS_data\\survey_options_use.csv", stringsAsFactors = FALSE)

res <- list()
resdf <- data.frame()
for (istock in 1:nstocks){
  dat <- read.csv(paste0(".\\ADIOS_data\\", decoder$ADIOS.name[istock], ".csv"))
  surveys <- unique(dat$SURVEY)
  nsurveys <- length(surveys)
  res[[istock]] <- list()
  res[[istock]]$stock <- decoder$Short.Name[istock]
  res[[istock]]$surveys <- surveys
  res[[istock]]$z <- list()
  for (isurvey in 1:nsurveys){
    myrow <- filter(so_use, stock == decoder$Short.Name[istock], survey == surveys[isurvey]) %>%
      select(rowID) %>%
      as.numeric(.)
    if (so_use$usesurvey[myrow] == TRUE){
      sdat <- dat %>%
        filter(SURVEY == surveys[isurvey]) %>%
        filter(AGE %in% seq(so_use$startage[myrow], so_use$endage[myrow]))
      minyear <- min(sdat$YEAR)
      maxyear <- max(sdat$YEAR)
      minage <- min(sdat$AGE)
      maxage <- max(sdat$AGE)
      mat <- matrix(NA, nrow = (maxyear - minyear + 1), ncol = (maxage - minage + 1), 
                    dimnames = list(seq(minyear, maxyear), seq(minage, maxage)))
      for (j in 1:length(sdat[,1])){
        myrow <- sdat$YEAR[j] - minyear + 1
        mycol <- sdat$AGE[j] - minage + 1
        mat[myrow, mycol] <- sdat$NO_AT_AGE[j]
      }
      myres <- calc_Sinclair_Z(mat)
      res[[istock]]$z[[isurvey]] <- myres
      if (myres$error == FALSE & !all(is.na(myres$est.Sinclair.Z))){
        thisdf <- data.frame(stock = decoder$Short.Name[istock],
                             survey = as.character(surveys[isurvey]),
                             plotyear = rep(myres$plot.year, 3),
                             Sinclair_Z = myres$est.Sinclair.Z[,1],
                             low90 = myres$est.Sinclair.Z[,2],
                             high90 = myres$est.Sinclair.Z[,3])
        resdf <- rbind(resdf, thisdf)
      }
    }
  }
}
resdf
write.csv(resdf, file=".\\figs\\resdf.csv", row.names = FALSE)

# Sinclair Z plots
pdf(file = ".\\figs\\Sinclair_Z_plots.pdf")
for (istock in 1:nstocks){
  thisstock <- decoder$Short.Name[istock]
  p <- ggplot(filter(resdf, stock == thisstock), aes(x=plotyear, y=Sinclair_Z)) +
    geom_point(na.rm = TRUE) +
    geom_line(na.rm = TRUE) +
    geom_ribbon(aes(ymin=low90, ymax=high90), alpha=0.3) +
    facet_wrap(~survey) +
    xlab("Year") +
    ylab("Sinclair Z") +
    ggtitle(thisstock) +
    theme_bw()
  print(p)
}
dev.off()

