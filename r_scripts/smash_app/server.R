rm(list=ls())
library(shiny)
library(shinydashboard)
library(ggplot2)

source("./subset_data.R")
source("./pivot_stats.R")

df <- download_smash_data()
pv_df <- pivot_smash_data(df)

shinyServer(function(input,output){
    
    output$m <- renderTable({
        aggregate_data(pv_df[pv_df$Character == input$char,], 
                       c("Opponent.Character"), 
                       c("win_percentage", "Time.end.in.secs", 
                         "Stocks.remaining"))
    })
    
    output$ss <- renderTable({
        aggregate_data(pv_df[pv_df$Character == input$char,], 
                       c("Stage"), 
                       c("win_percentage", "Time.end.in.secs", 
                         "Stocks.remaining"))
    })
    
    output$d <- renderTable({
        df_temp <- as.data.frame(table(pv_df[pv_df$Character == input$char,]
                                       [,"Player"]))
        df_temp <- rename(df_temp, c("Var1"= "Player"))
        df_temp
    })
    
    output$qm <- renderTable({
        aggregate_data(pv_df[pv_df$Character == input$char,], 
                       c("Player", "Opponent.Character"), 
                       c("win_percentage", "Time.end.in.secs", 
                         "Stocks.remaining"))
    })
})
    
    
    
    