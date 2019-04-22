# get_Sinclair_Z.R
# estimate total mortality rate from survey catch at age data in ADIOS format using Sinclair method

library("ASAPplots")
library("dplyr")
library("ggplot2")

decoder <- read.csv(".\\ADIOS_data\\file_decoder.csv")
nstocks <- length(decoder$Short.Name)

res <- list()
resdf <- data.frame()
for (istock in 1:nstocks){
  dat <- read.csv(paste0(".\\ADIOS_data\\", decoder$ADIOS.name[istock], ".csv"))
  surveys <- unique(dat$SURVEY)
  nsurveys <- length(surveys)
  res[[istock]] <- list()
  res[[istock]]$stock <- decoder$ADIOS.name[istock]
  res[[istock]]$surveys <- surveys
  res[[istock]]$z <- list()
  for (isurvey in 1:nsurveys){
    sdat <- dat %>%
      filter(SURVEY == surveys[isurvey])
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
    mysum <- apply(mat, 2, sum, na.rm=TRUE)
    itest <- 1
    while(mysum[itest + 1] - mysum[itest] > 0){
      mat[, itest] <- NA
      itest <- itest + 1
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
resdf

for (istock in 1:nstocks){
  thisstock <- decoder$Short.Name[istock]
  p <- ggplot(filter(resdf, stock == thisstock), aes(x=plotyear, y=Sinclair_Z)) +
    geom_point() +
    geom_line() +
    geom_ribbon(aes(ymin=low90, ymax=high90), alpha=0.3) +
    facet_wrap(~survey) +
    ggtitle(thisstock) +
    theme_bw()
  print(p)
}
