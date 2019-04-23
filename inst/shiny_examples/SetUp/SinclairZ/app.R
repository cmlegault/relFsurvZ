#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# This Shiny app runs the Sinclair Z estimation for the stocks in file_decoder.csv
# Can make changes to age ranges or use survey and save in survey_options_use.csv

library(shiny)
library(ggplot2)
library(dplyr)

decoder <- read.csv("..\\..\\..\\..\\ADIOS_data\\file_decoder.csv")
so_use <- read.csv("..\\..\\..\\..\\ADIOS_data\\survey_options_use.csv")

datdf <- data.frame()
for (irow in 1:length(decoder[,1])){
  dat <- read.csv(paste0("..\\..\\..\\..\\ADIOS_data\\", decoder$ADIOS.name[irow], ".csv"))
  dat$decoder_row <- irow
  datdf <- rbind(datdf, dat)
}

# tempo - replace with real Sinclair Z function
Z = runif(30)
szdf <- data.frame(Year = seq(1981, 2010),
                  Z = Z,
                  low90 = Z - 0.2,
                  high90 = Z + 0.2)

###########################
# Define UI for application
ui <- fluidPage(
   
   # Application title
   titlePanel("Sinclair Z Examiner"),
   
   # Sidebar with a slider input for number of bins 
   sidebarLayout(
      sidebarPanel(
         selectInput("stock",
                     "Choose a stock:",
                     choices = decoder$Short.Name),
         
         # need to get this interactive using so_use info
         selectInput("survey",
                     "Choose a survey:",
                     choices = c("a", "b", "c")),
         
         # need to make dependent on survey
         sliderInput("ages",
                     "Age range for Z calcs:",
                     min = 0,
                     max = 50,
                     value=c(4,10)),
         
         # need to make dependent on input file
         checkboxInput("usesurvey",
                       "Check to use survey",
                       value = TRUE)
      ),
      
      # Show a plot of the generated distribution
      mainPanel(
        plotOutput("SinclairZ"),
        tableOutput("delme")
      )
   )
)

#####################
# Define server logic
server <- function(input, output) {
  
  
  output$SinclairZ <- renderPlot({
    ggplot(szdf, aes(x=Year, y=Z)) +
      geom_point() +
      geom_line() +
      geom_ribbon(aes(ymin=low90, ymax=high90), alpha = 0.3) +
      theme_bw()
  })
  
  output$delme <- renderTable({
    decoder
  })
}

# Run the application 
shinyApp(ui = ui, server = server)

