library(gsheet)

avg_rank_single <- function(player, df){
    sub_df <- subset(df, Player == player)
    sum(sub_df$Rank) / nrow(sub_df)
}

avg_rank <- function(df){
    players <- unique(df$Player)
    standings <- data.frame(players, Rank=sapply(players, avg_rank_single, df))
    standings <- standings[order(standings$Rank),]
    rownames(standings) <- NULL
    standings
}

ppg_single <- function(player, df){
    sub_df <- subset(df, Player == player)
    pts <- nrow(subset(sub_df, Rank == 1)) * 3 + nrow(subset(sub_df, Rank == 2))
    pts / nrow(sub_df)
}

ppg <- function(df){
    players <- unique(df$Player)
    standings <- data.frame(players, Points=sapply(players, ppg_single, df))
    standings <- standings[order(-standings$Points),]
    rownames(standings) <- NULL
    standings
}

standings <- function(df, metric, k=NULL){
    metrics <- list(avg_rank=avg_rank, ppg=ppg, linear_scores=linear_scores, elo=elo, elo2=elo2)
    if (metric %in% c("elo", "elo2")){
        return(metrics[[metric]](df, k=k))
    }
    metrics[[metric]](df)
}

deck_subset <- function (df, deck="all"){
    if (deck == "all"){
        return(df)
    }
    else{
        return(subset(df, Deck == deck))
    }
}

games_played <- function(player, df){
    nrow(subset(df, Player == player))
}

games_played_df <- function(df){
    players <- unique(df$Player)
    played <- data.frame(players, Played=sapply(players, games_played, df))
    played <- played[order(played$players),]
    rownames(played) <- NULL
    played
}

create_elo_base <- function(df){
    Player <- unique(df$Player)
    data.frame(Player, date=min(df$Date_id) - 1, score=1000)
}

calculate_s <- function(ranks){
    #s <- sort(seq(0,1,length.out=length(ranks)), decreasing=TRUE)
    #sapply(ranks, function(x) s[x])
    as.numeric(ranks == 1)
}

calculate_s2 <- function(ranks){
    #s <- sort(seq(0,1,length.out=length(ranks)), decreasing=TRUE)
    #sapply(ranks, function(x) s[x])
    sapply(1:(max(ranks)-1), function(x) as.numeric(ranks == x))
}

calculate_e <- function(score){
    normalize <- sum(10**(score/400))
    (10**(score/400))/normalize
}

calculate_e2 <- function(score){
    n <- length(score)
    sapply(1:(length(score)-1), function(x)
        c(rep(0,(x-1)),calculate_e(score[x:n])))
}

update_elo <- function(new_game, base, k){
    players <- new_game$Player
    current <- base[!duplicated(base$Player, fromLast = TRUE),]
    current <- subset(current, Player %in% players)
    current <- merge(new_game, current)
    current$s <- calculate_s(current$Rank)
    current$e <- calculate_e(current$score)
    current$new <- current$score + k * (current$s - current$e)
    new_df <- data.frame(Player=current$Player, date=current$Date_id,
                         score=current$new)
    rbind(base, new_df)
}

update_elo2 <- function(new_game, base, k){
    players <- new_game$Player
    current <- base[!duplicated(base$Player, fromLast = TRUE),]
    current <- subset(current, Player %in% players)
    current <- merge(current, new_game)
    current <- current[order(current$Rank),]
    s <- calculate_s2(current$Rank)
    e <- calculate_e2(current$score)
    current$new <- current$score + rowSums(k * (s - e))
    new_df <- data.frame(Player=current$Player, date=current$Date_id,
                         score=current$new)
    rbind(base, new_df)
}

elo <- function(df, k=25, update_function=update_elo, for_graph=FALSE){
    Player <- unique(df$Player)
    base <- create_elo_base(df)
    df <- df[order(df$Date_id),]
    for(i in unique(df$Game_ID)){
        new_game <- subset(df, Game_ID == i)
        base <- update_function(new_game, base, k)
    }
    standings <- base[!duplicated(base$Player, fromLast = TRUE),]
    standings <- standings[order(-standings$score),]
    rownames(standings) <- NULL
    if (for_graph){
        best <- standings$Player[1:min(c(5, nrow(standings)))]
        base <- subset(base, Player %in% best)
        base <- base[duplicated(base$Player),]
        return(base[!duplicated(base[,c("Player", "date")], fromLast=TRUE),])
    }
    standings$date <- NULL
    standings
}

elo2 <- function(df, k){
    elo(df, k, update_function=update_elo2)
}

reshape_game <- function(single_game, all_players){
    player_matrix <- matrix(0, nrow=1, ncol=length(all_players), 
                            dimnames=list(NULL, all_players))
    players <- unique(single_game$Player)
    n <- 1
    for(i in 1:(nrow(single_game) - 1)){
        p1 <- single_game$Player[single_game$Rank == i]
        for (j in (i + 1):(nrow(single_game))){
            player_matrix <- rbind(player_matrix, 0)
            p2 <- single_game$Player[single_game$Rank== j]
            player_matrix[n,p1] <- 1
            player_matrix[n,p2] <- -1
            n <- n + 1
        }
    }
    player_matrix
}

reshape_all <- function(df){
    players <- unique(df$Player)
    reshaped_data <- do.call(rbind, sapply(unique(df$Game_ID), function(x)
        reshape_game(subset(df, Game_ID == x), players)))
    reshaped_data <- cbind(Y=1, reshaped_data)
    as.data.frame(reshaped_data)
}


linear_scores <- function(df){
    df <- reshape_all(df)
    model <- glm(Y ~ . - 1, data=df, family="binomial")
    score <- model$coefficients
    players <- names(score)
    lower_bound <- score - (1.96 * sqrt(diag(vcov(model))))
    upper_bound <- score + (1.96 * sqrt(diag(vcov(model))))
    standings <- data.frame(players, score, lower_bound, upper_bound)
    standings <- standings[order(-standings$score),]
    rownames(standings) <- NULL
    standings
}
