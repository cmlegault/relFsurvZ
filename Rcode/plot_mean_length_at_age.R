# plot_mean_length_at_age.R
# use the summary stats in ADIOS csv files to show changes in mean length at age over time

library("ggplot2")
library("dplyr")

decoder <- read.csv(".\\ADIOS_data\\file_decoder.csv")
nstocks <- length(decoder$Short.Name)
so_use <- read.csv(".\\ADIOS_data\\survey_options_use.csv", stringsAsFactors = FALSE)

origtext <- "strat_mean_age"
reptext <- "mean_length_at_age"
getfiles <- gsub(origtext, reptext, decoder$ADIOS.name)

pdf(file = ".\\figs\\mean_length_at_age_plots.pdf")

for (istock in 1:nstocks){
  dat <- read.csv(file = paste0(".\\ADIOS_data\\", getfiles[istock], ".csv"))
  mystock <- decoder$Short.Name[istock]
  surveys <- unique(dat$SURVEY)
  nsurveys <- length(surveys)
  for (isurvey in 1:nsurveys){
    myrow <- filter(so_use, stock == decoder$Short.Name[istock], survey == surveys[isurvey]) %>%
      select(rowID) %>%
      as.numeric(.)
    if (so_use$usesurvey[myrow] == TRUE){
      sdat <- dat %>%
        filter(SURVEY == surveys[isurvey]) %>%
        filter(SAMP_SIZE >= 5)  # this is an arbitrary decision point, gets rid of ages with few obs
      mean_len <- sdat %>%
        group_by(AGE) %>%
        summarize(mean_length = mean(MEAN, na.rm=TRUE))
      
      p <- ggplot(sdat, aes(x=YEAR, y=MEAN)) +
        geom_point() +
        geom_errorbar(aes(ymin = P25, ymax = P75)) +  # shows inter-quartile range
        facet_grid(AGE~., scales = "free_y") +
        geom_hline(aes(yintercept = mean_length), mean_len, color="red", linetype="dashed") +
        ggtitle(paste(mystock, surveys[isurvey])) +
        theme_bw()
      print(p)
    }
  }
}
dev.off()
