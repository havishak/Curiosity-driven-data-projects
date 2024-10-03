# load libraries
library(tidyverse)
library(showtext)
library(rchess)

chess <- readr::read_csv('https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/data/2024/2024-10-01/chess.csv')

# plot top 15 opening positions and probability of winning the game

chess_opening <- chess %>%
    rowwise() %>%
    mutate(first_four = paste(str_split_1(moves, "\\s")[1:4], collapse = " ")) %>%
    ungroup() %>%
    group_by(opening_name, first_four) %>%
    summarize(
        n_games = n(),
        prob_white = sum(winner == "white")/n_games,
        prob_black = sum(winner == "black")/n_games,
        prob_draw = sum(winner == "draw")/n_games
    ) %>%
    arrange(desc(n_games))
