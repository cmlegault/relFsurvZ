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


# Define UI for application that draws a histogram
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
                     choices = c("a", "b", "c"))
      ),
      
      # Show a plot of the generated distribution
      mainPanel(
         tableOutput("delme")
      )
   )
)

# Define server logic required to draw a histogram
server <- function(input, output) {
   
   output$delme <- renderTable({
     decoder
   })
}

# Run the application 
shinyApp(ui = ui, server = server)

