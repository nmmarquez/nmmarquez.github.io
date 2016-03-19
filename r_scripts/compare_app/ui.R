library(shiny); library(gsheet)
rm(list=ls())

link <- paste0("https://docs.google.com/spreadsheets/d/1XsWOxX099kS0ynf40s",
               "FTqaTrnfpxbe_N8_cRs5gOhzQ/edit?usp=sharing")
df <- as.data.frame(gsheet2tbl(link, sheetid=0) [,1:5])
df[df$Deck == "","Deck"] <- "Unknown"
df$Date_id <- as.Date(df$Date_id, format="%m/%d/%Y")

# Define UI for application that draws a histogram
shinyUI(pageWithSidebar(
    
    # Application title
    headerPanel("Player Analysis for Some Serious Spot-It"),
    
    
    sidebarPanel(
        
        selectInput('deck', 'Deck', sort(c("all", unique(df$Deck))), selected="all"),
        
        selectInput('metric', 'Metric', c("avg_rank", "ppg", "linear_scores", "elo", "elo2")),
        
        dateRangeInput("date", "Date", start = min(df$Date_id), 
                       end = max(df$Date_id), min = min(df$Date_id), 
                       max = max(df$Date_id), format = "yyyy-mm-dd", 
                       startview = "month", weekstart = 0, language = "en", 
                       separator = " to "),
        
        sliderInput("k", 'Elo "k" Parameter', 
                    min=1, max=100, value=25)
        
    ),
    
    # Show a plot of the generated distribution
    mainPanel(
        tabsetPanel(
            tabPanel("Standings", tableOutput("standings")), 
            tabPanel("Games Played", tableOutput("gp")),
            tabPanel("Elo Graph", plotOutput("graphs"))
        )
    )))