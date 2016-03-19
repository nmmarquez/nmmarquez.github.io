rm(list=ls())
library(shiny)
library(shinydashboard)
library(ggplot2)

source("./subset_data.R")
source("./pivot_stats.R")

df <- download_smash_data()
pv_df <- pivot_smash_data(df)

header <- dashboardHeader(
    title = "Dream Hack Descriptive Stats"
)

body <- dashboardBody(
    fluidRow(
        column(width=12,
               tabBox(
                   id='tabvals',
                   width=NULL,
                   #tabPanel("Matchup", tableOutput("m"), value=1), 
                   #tabPanel("Stage Selection", tableOutput("ss"), value=2),
                   tabPanel("Players", plotOutput("d"), value=3),
                   tabPanel("Player-Matchup", plotOutput("qm"), value=4)
               )
        ) 
    )
)

sidebar <- dashboardSidebar(
    selectInput('char', 'Character', sort(unique(pv_df$Character)))
)

dashboardPage(
    header,
    sidebar,
    body
)