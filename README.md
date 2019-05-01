# relFsurvZ

Work in progress looking at relative F, survey Z, and other basic features of index-based approaches across large number of stocks.

## Sinclair Z

Estimates total mortality (Z) from survey catch at age indices using four year moving window catch curve analysis. Within each four year window, cohorts have catch curve analysis applied with same slope but different intercept. Allows for estimation of both the mean and confidence interval associated with the total mortality estimate (negative of the slope). Reference is

Sinclair, A.F. 2001. Natural mortality of cod (Gadus morhua) in the Southern Gulf of St Lawrence. ICES Journal of Marine Science. 58: 1-10.

### Application to Northeast Fisheries Science Center stocks

Survey catch at age indices for 19 stocks were collected. Only surveys available in the ADIOS database were used, which may contain surveys not used in the stock assessment or may miss surveys that are included in the stock assessment. Only NEFSC and MADMF surveys are currently available in the ADIOS database. There is a separate csv file for each stock, see ./ADIOS_data/file_decoder.csv for a (hopefully) short and descriptive name for each stock. Each stock has from one to five surveys available. A Shiny app was written to examine the age range to use for each stock (available in the ./inst/shiny_examples/SetUp/SinclairZ subdirectory). The goal was to get the residuals centered on zero for all ages within the age range. The choices I made are saved in ./ADIOS_data/survey_options_use.csv. You can look at the selections made there and use the Shiny app to see how the total mortality estimates change with different age ranges (typically not much for similar age ranges). These choices are reflected in the ./figs/Sinclair_Z_plots.pdf and associated resdf.csv file of total mortality point estimates and 90% confidence intervals.

## Mean length at age

Data are summarized in csv files by stock, survey, year, and age for a number of length (cm) metrics: the sample size, mean, median, standard deviation, standard error, interquartile range (P25 and P75), minimum, maximum, and whether the strata were completely sampled (some years were not able to sample all survey strata). The ./Rcode/plot_mean_length_at_age.R code uses this information to create ./figs/mean_length_at_age_plots.pdf. Each survey that was used in the Sinclair Z estimation is shown on a separate page with the stock name and survey name shown at the top of the plot. Each plot is a different age (shown in the box on the right) of mean age (dot) and interquartile range (error bars) over time. Each age has its own y-axis scale and the red dashed line is the unweighted mean of the plotted mean values. Note that stock, survey, year, age combinations with less than 5 observations are not included in these plots. The starting year of observations differs among stocks and surveys depending on when ages were first collected for that stock and survey. 
