# this is the downloading and subsetting functions script
# it will be imported by the main script to run most of these functions
library(gsheet)

to_seconds <- function(x){
    # Converts a vector of strings formatted as H:M:S and converts to a single
    # second unit
    # :param x: character
    #       character vector formated H:M:S
    # :return: float
    #       vector of floats in units of seconds
    if (!is.character(x)) stop("x must be a character string of the form H:M:S")
    if (length(x)<=0)return(x)
    
    unlist(lapply(x,function(i){
        i <- as.numeric(strsplit(i,':',fixed=TRUE)[[1]])
                if (length(i) == 3) 
                    i[1]*3600 + i[2]*60 + i[3]
                else if (length(i) == 2) 
                    i[1]*60 + i[2]
                else if(length(i) == 1) 
                    i[1]
                else if(length(i) == 0)
                    0
        }  
        )  
    )  
} 


download_smash_data <- function(){
    # Downloads the dream hack data from the google doc sheet as described on
    # reddit here 
    # /r/smashbros/comments/3xgsb7/i_watched_every_melee_singles_game_at_dreamhack/
    #
    # :retrun: data frame
    #   data frame with smash data
    link <- paste0("https://docs.google.com/spreadsheets/d/1ZW5gOWNG-XsA5qE-U",
                   "iNGtbVYPLP5NcKD5rM0OybM4Hw/edit?pref=2&pli=1#gid=657581675")
    df <- as.data.frame(gsheet2tbl(link))
    df$Time.end <- to_seconds(df$Time.end)
    return(df)
}


subset_caharcter <- function(df, char, type="|"){
    # Subset the data frame where player 1 and/or player 2 are a character
    # 
    # :param df: data frame
    #       data frame to subset
    # :param char: character
    #       character string to be used for subsetting
    # :param type: "&" or "|"
    #       the type of subset to use either and "&" or or "|"
    # :return: df
    #       data frame subsetted by a particular character
    if (!(type %in% c("|", "&"))){
        stop("arg 'type' must be either '&' or '|'")
    }
    if (type == "|"){
        df_sub <- subset(df, Player.1.Character == char | 
                             Player.2.Character == char)
    }
    else{
        df_sub <- subset(df, Player.1.Character == char & 
                             Player.2.Character == char)
    }
    return(df_sub)
}


find_matchups <- function(df, char1, char2=""){
    # Alternative subsetting function to find matches using a character
    # :param df: data frame
    #       data frame to subset
    # :param char: char1
    #       character string to be used for subsetting
    # :param char: char2
    #       character string to be used for subsetting
    if(char2 == "" | is.na(char2)){
        df_sub <- subset_caharcter(df, char1, type="|")
    }
    else if(char1 == char2){
        df_sub <- subset_caharcter(df, char1, type="&")
    }
    else{
        df_sub <- subset_caharcter(df, char1, type="|")
        df_sub <- subset_caharcter(df_sub, char2, type="|")
    }
    return(df_sub)
}

df <- download_smash_data()

# that aint falco
subset_caharcter(df, "Fox", "|")

# da space race
find_matchups(df, "Fox")

