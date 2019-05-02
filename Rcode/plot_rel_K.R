# plot_rel_K.R
# use summarized relative K csv files derived from ADIOS data to plot changes in condition factor over time

library("ggplot2")
library("dplyr")

decoder <- read.csv(".\\ADIOS_data\\file_decoder.csv")
nstocks <- length(decoder$Short.Name)
so_use <- read.csv(".\\ADIOS_data\\survey_options_use.csv", stringsAsFactors = FALSE)
mso_use <- so_use %>%
  mutate(SURVEY = survey) %>%
  select(stock, SURVEY, usesurvey)

origtext <- "strat_mean_age"
reptext <- "relative_k_summarized"
getfiles <- gsub(origtext, reptext, decoder$ADIOS.name)

pdf(file = ".\\figs\\condition_factor_plots.pdf")

for (istock in 1:nstocks){

  dat <- read.csv(file = paste0(".\\ADIOS_data\\", getfiles[istock], ".csv"))
  mystock <- decoder$Short.Name[istock]
  suppressWarnings(suppressMessages(sdat <- left_join(dat, mso_use) %>%
    filter(usesurvey == TRUE)))
  
  p <- ggplot(sdat, aes(x=YEAR, y=medianK)) +
    geom_point() +
    geom_errorbar(aes(ymin = P25, ymax = P75)) +  # shows inter-quartile range
    facet_wrap(~SURVEY, ncol=1) +
    geom_hline(aes(yintercept = 1), color="red", linetype="dashed") +
    geom_text(aes(x=YEAR, y=Inf, label=samp_size), vjust=2, size=2) +
    ggtitle(mystock) +
    xlab("Year") +
    ylab("Relative K") +
    theme_bw()
  print(p)
}
dev.off()
