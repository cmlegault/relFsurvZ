#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# This Shiny app runs the Sinclair Z estimation for the stocks in file_decoder.csv
# Can make changes to age ranges or use survey and save in survey_options_use.csv

library(shiny)
library(ggplot2)
library(dplyr)

decoder <- read.csv("..\\..\\..\\..\\ADIOS_data\\file_decoder.csv", stringsAsFactors = FALSE)
so_use <- read.csv("..\\..\\..\\..\\ADIOS_data\\survey_options_use.csv", stringsAsFactors = FALSE)

datdf <- data.frame()
for (irow in 1:length(decoder[,1])){
  dat <- read.csv(paste0("..\\..\\..\\..\\ADIOS_data\\", decoder$ADIOS.name[irow], ".csv"), 
                  stringsAsFactors = FALSE)
  dat$stock <- decoder$Short.Name[irow]
  datdf <- rbind(datdf, dat)
}

# modification of calc_Sinclair_Z function from ASAPplots to use data frame as input
# mydf has columns Year, Age, cohort, lnVal and all lnVal=NA already removed
# returned list has just error flag and Zests and resids data frames for use in ggplot
get_Sinclair_Z_df <- function(mydf){
  res <- list()

  if (length(mydf$lnVal) == 0){
    res$error <- TRUE
    return(res)
  }
  
  firstyear <- min(mydf$Year)
  lastyear <- max(mydf$Year)
  year <- seq(firstyear, lastyear)
  ny <- lastyear - firstyear + 1

  est.Sinclair.Z <- matrix(NA, nrow=(ny-3), ncol=3)
  plot.year <- rep(NA, ny-3)
  
  res$resids <- data.frame()
  
  for (i in 1:(ny-3)){
    data <- filter(mydf, Year %in% seq(year[i], year[i + 3]))
    can.calc <- FALSE
    if (length(data[,1]) >= 2){
      if (max(table(data$cohort)) >= 3){
        can.calc <- TRUE
      }
    }
    if (can.calc == TRUE){
      my.lm <- lm(data$lnVal ~ as.factor(data$cohort) + data$Age)
      data$pred <- predict(my.lm)
      data$resid <- residuals(my.lm)
      #res[[i]] <- data
      res$resids <- rbind(res$resids, data)
      est.Sinclair.Z[i,1] <- -1 * my.lm$coefficients[names(my.lm$coefficients) == "data$Age"]
      est.Sinclair.Z[i,2:3] <- -1 * rev(confint(my.lm, "data$Age", level=0.90))
    }
    else{  
      #res[[i]] <- data
      est.Sinclair.Z[i,] <- rep(NA, 3)
    }
    plot.year[i] <- year[i] + 1.5
  }
  #colnames(est.Sinclair.Z) <- c("Sinclair_Z","low90%","high90%")
  #res$est.Sinclair.Z <- est.Sinclair.Z
  #res$plot.year <- plot.year
  res$Zests <- data.frame(Year = plot.year,
                          Sinclair_Z = est.Sinclair.Z[,1],
                          low90 = est.Sinclair.Z[,2],
                          high90 = est.Sinclair.Z[,3])
  res$error <- FALSE
  return(res)
}

###########################
# Define UI for application
ui <- fluidPage(
   
   titlePanel("Sinclair Z Examiner"),
   
   sidebarLayout(
      sidebarPanel(
         selectInput("stock",
                     "Choose a stock:",
                     choices = decoder$Short.Name),
         
         uiOutput("surveyselect"),
         
         sliderInput("ages",
                     "Age range for Z calcs:",
                     min = 0,
                     max = 30,
                     value=c(0, 30)),
         
         checkboxInput("usesurvey",
                       "Check to use survey",
                       value = TRUE),
         
         actionButton("update", "Update Values")
         
      ),
      
      # Show a plot of the generated distribution
      mainPanel(
        plotOutput("resids"),
        plotOutput("SinclairZ")
      )
   )
)

#####################
# Define server logic
server <- function(input, output) {
  
  observeEvent(input$update, {
    my_use <- read.csv("..\\..\\..\\..\\ADIOS_data\\survey_options_use.csv", stringsAsFactors = FALSE)
    my_use$usesurvey[myrow()] <-  input$usesurvey
    my_use$startage[myrow()] <-  input$ages[1]
    my_use$endage[myrow()] <-  input$ages[2]
    my_use$note[myrow()] <- "modified by Shiny app"
    write.csv(my_use, file="..\\..\\..\\..\\ADIOS_data\\survey_options_use.csv", row.names = FALSE)
  })
  
  myrow <- reactive({
    filter(so_use, stock==input$stock, survey==input$survey) %>%
      select(rowID) %>%
      as.numeric(.)
  })
  
  mydef <- reactive({
    filter(so_use, rowID==myrow())
  })
  
  mydat <- reactive({
    filter(datdf, stock==input$stock, SURVEY==input$survey) %>%
      filter(AGE %in% seq(input$ages[1], input$ages[2])) %>%
      mutate(Year = YEAR, Age = AGE, cohort = YEAR - AGE, lnVal = log(NO_AT_AGE)) %>%
      select(Year, Age, cohort, lnVal)
  })
  
  res <- reactive({
    get_Sinclair_Z_df(mydat())
  })
  
  surveyoption <- reactive({
    filter(so_use, stock==input$stock) %>%
      select(survey)
  })
  
  output$surveyselect <- renderUI({
    selectInput("survey",
                "Choose a survey:",
                choices = surveyoption())
  })
  
  output$resids <- renderPlot({
    ggplot(res()$resids, aes(x=as.factor(Age), y=resid)) +
      geom_hline(yintercept = 0, col="red") +
      geom_boxplot(na.rm = TRUE) +
      xlab("Age") +
      ylab("Residuals") +
      theme_minimal(base_size = 20)
  })
  
  output$SinclairZ <- renderPlot({
    ggplot(res()$Zests, aes(x=Year, y=Sinclair_Z)) +
      geom_hline(yintercept = 0, col="blue") +
      geom_point(na.rm = TRUE) +
      geom_line(na.rm = TRUE) +
      geom_ribbon(aes(ymin=low90, ymax=high90), alpha = 0.3) +
      ylab("Sinclair Z") +
      theme_minimal(base_size = 20)
  })
  
}

# Run the application 
shinyApp(ui = ui, server = server)

