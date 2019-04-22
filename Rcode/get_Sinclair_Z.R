# get_Sinclair_Z.R
# estimate total mortality rate from survey catch at age data in ADIOS format using Sinclair method

# rem set working directory to source file location to start
library("ASAPplots")
library("dplyr")

decoder <- read.csv("..\\ADIOS_data\\file_decoder.csv")
nstocks <- length(decoder$Short.Name)

res <- list()
for (istock in 1:nstocks){
  dat <- read.csv(paste0("..\\ADIOS_data\\", decoder$ADIOS.name[istock], ".csv"))
  surveys <- unique(dat$SURVEY)
  nsurveys <- length(surveys)
  res[[istock]] <- list()
  res[[istock]]$stock <- decoder$ADIOS.name[istock]
  res[[istock]]$surveys <- surveys
  res[[istock]]$z <- list()
  for (i in 1:nsurveys){
    sdat <- dat %>%
      filter(SURVEY == surveys[i])
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
    res[[istock]]$z[[i]] <- calc_Sinclair_Z(mat)
  }
}
