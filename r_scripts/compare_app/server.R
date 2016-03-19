library(shiny); library(gsheet); library(ggplot2)
rm(list=ls())

link <- paste0("https://docs.google.com/spreadsheets/d/1XsWOxX099kS0ynf40s",
               "FTqaTrnfpxbe_N8_cRs5gOhzQ/edit?usp=sharing")
df <- as.data.frame(gsheet2tbl(link, sheetid=0) [,1:5])
df[df$Deck == "","Deck"] <- "Unknown"
df$Date_id <- as.Date(df$Date_id, format="%m/%d/%Y")


source("./functions.R")

shinyServer(function(input, output) {
    
    # Expression that generates a histogram. The expression is
    # wrapped in a call to renderPlot to indicate that:
    #
    #  1) It is "reactive" and therefore should re-execute automatically
    #     when inputs change
    #  2) Its output type is a plot
    
    output$standings <- renderTable({
        df <- subset(deck_subset(df, input$deck), Date_id >= input$date[1] & 
                         Date_id <= input$date[2])
        standings(df, input$metric, input$k)
    })
    
    output$gp <- renderTable({
        games_played_df(subset(deck_subset(df, input$deck), 
                               Date_id >= input$date[1] & 
                                   Date_id <= input$date[2]))
    })
    
    output$graphs <- renderPlot({
        if (input$metric %in% c("avg_rank", "ppg", "linear_scores")){
            return(NULL)
        }
        df <- subset(deck_subset(df, input$deck), Date_id >= input$date[1] & 
                         Date_id <= input$date[2])
        update_function <- c(update_elo, update_elo2)[[(input$metric!="elo")+1]]
        df <- elo(df, update_function=update_function, for_graph=TRUE, k=input$k)
        p <- ggplot(data=df, aes(x=date, y=score, group=Player, color=Player))
        p + geom_line() + labs(title="Elo Over Time", x="Date", y="Score")
    })
})