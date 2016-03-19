# This is a script where stats will be generated that are easier to calculate on 
# A pivoted version of the data
library(plyr)

pivot_smash_data <- function(df){
    # Pivot smash data so each row is a single player-game
    #
    # :param df: data frame
    #       data frame to pivot
    # :return: data frame
    #       data frame with each row representing a single player-game
    df_p1 <- rename(df, c("Player.1"="Player", "Player.2"="Opponent",
                             "Player.1.Character"="Character",
                             "Player.2.Character"="Opponent.Character"))
    df_p2 <- rename(df, c("Player.2"= "Player", "Player.1"="Opponent",
                             "Player.2.Character"="Character",
                             "Player.1.Character"="Opponent.Character"))
    df_pivot <- rbind(df_p1, df_p2)
    df_pivot$win_percentage <- df_pivot$Player == df_pivot$Winner
    df_pivot$Stocks.remaining <- df_pivot$Stocks.remaining * ((df_pivot$win_percentage * 2) - 1)
    return(df_pivot)
}


aggregate_data <- function(pv_df, groups, stats, func=mean){
    # Returns a group by data frame similar to pandas
    # 
    # :param pv_df: data frame
    #       A pivoted data frame
    # :param groups: character
    #       Character vector of what to group by
    # :param stats: character 
    #       Character vector to perform stats on
    # :func: function
    #       function to perform on grouped data
    # :return: data frame
    #       data frame with grouped stats
    rhs <- paste("~", paste(groups, collapse = " + "))
    l <- lapply(stats, function(x) 
        aggregate(formula=formula(paste(x,rhs)), data=pv_df, FUN=func))
    join_all(l, type='inner')
}
