# load libraries
library(tidyverse)
library(rchess)
library(patchwork)

theme_set(
    theme_void(base_family = "Segoe UI") + 
        theme(legend.position = "none")
)

#install package
#devtools::install_github("jbkunst/rchess")


chess <- readr::read_csv('https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/data/2024/2024-10-01/chess.csv')

# chesss opening move names, with first four moves, and probability of each outcome
chess_opening <- chess %>%
    rowwise() %>%
    mutate(first_four = paste(str_split_1(moves, "\\s")[1:4], collapse = " ")) %>%
    ungroup() %>%
    group_by(opening_name) %>%
    summarize(
        first_four = first_four[10], #randomly pick one since the first four moves should be same
        n_games = n(),
        prob_white = sum(winner == "white")/n_games,
        prob_black = sum(winner == "black")/n_games,
        prob_draw = sum(winner == "draw")/n_games
    ) %>%
    arrange(desc(n_games))



chessboard_after_four <- function(game_play){
    # chessboard data - original configuration
    chess_board <- rchess:::.chessboarddata() %>%
        select(cell, col, row, x, y, cc, text) %>%
        mutate(text = ifelse(row == 7, "♙", text),
        piece = case_when(
            row %in% c(1,2) ~ "white",
            row %in% c(7,8) ~ "black",
            TRUE ~ NA_character_))

    # convert game play to long format
    game_play_df <- Chess$new()
    game_play_df$load_pgn(game_play)
    new_pos <- game_play_df$history_detail() %>%
        select(from, to, number_move) %>%
        arrange(number_move) %>%
        head(4)
    
    # move pieces to correct position 
    for(i in 1:4){
        chess_board[chess_board$cell == new_pos$to[i],]$text <- chess_board[chess_board$cell == new_pos$from[i],]$text
        chess_board[chess_board$cell == new_pos$to[i],]$piece <- chess_board[chess_board$cell == new_pos$from[i],]$piece
        chess_board[chess_board$cell == new_pos$from[i],]$text <- ""
        chess_board[chess_board$cell == new_pos$from[i],]$piece <- NA_character_
    }
    
    return(chess_board)
}

chessboard_ggplot <- function(chessboard_data, statistic_data){
    
    plot <- ggplot() +
        geom_tile(data = chessboard_data, aes(x, y, fill = cc)) +
        geom_text(data = chessboard_data %>% filter(text != ""),
                  aes(x, y, label = text, color = piece), 
                  size = 6) +
        scale_fill_manual(values = c("w" = "#D2B48C",
                                     "b" = "#8B4513"))+
        scale_color_manual(values = c("white" = "white",
                                      "black" = "black"))+
        annotate(geom = "linerange", xmin = 0.5,
                 xmax = 0.5 + 8, y =0, linewidth = 3, color = "#8B4513")+
        annotate(geom = "linerange", xmin = 0.5,
                 xmax = (0.5 + 8*statistic_data$prob_white + 8*statistic_data$prob_draw), 
                 y =0, linewidth = 3, color = "gray80") +
        annotate(geom = "linerange", xmin = 0.5,
                 xmax = (0.5 + 8*statistic_data$prob_white), y =0, linewidth = 3, color = "#D2B48C") +
        labs(title = str_wrap(statistic_data$opening_name, 30)) +
        # add 50% line
        annotate(geom = "point", x = 4.5,
                 y = 0, color = "darkred", shape = "|", size = 4) +
        annotate(geom = "text", x = 1, y = 0,
             label = paste0(round(statistic_data$prob_white*100),"%"),
             color = "#8B4513",family = "DejaVu Sans",
             size = 2.5, fontface = "bold") +
        annotate(geom = "text", x = 8, y = 0,
                 label = paste0(round(statistic_data$prob_black*100),"%"),
                 color = "#D2B48C",family = "DejaVu Sans", size = 2.5, fontface = "bold") +
            theme(
                plot.title = element_text(family = "DejaVu Sans",
                                          face = "bold",
                                          size = 10, hjust = 0.5),
                plot.background = element_rect(fill = "#fcf7ec", color = NA)
            )
    
    return(plot)
}

# plot top n opening moves

top_n <- 15

plot_chess_opening <- chess_opening %>%
    head(top_n)

updated_positions <- map(plot_chess_opening$first_four, chessboard_after_four)
plots <- map2(updated_positions, 1:top_n, ~chessboard_ggplot(.x, 
                                                             plot_chess_opening[.y,]))

# legend plot
legend_plot <-  ggplot() +
    annotate(geom = "linerange", xmin = 0.5,
             xmax = 0.5 + 8, y =0, linewidth = 3, color = "#8B4513")+
    annotate(geom = "linerange", xmin = 0.5,
             xmax = (0.5 + 8*plot_chess_opening$prob_white[1] + 8*plot_chess_opening$prob_draw[1]), 
             y =0, linewidth = 3, color = "gray80") +
    annotate(geom = "linerange", xmin = 0.5,
             xmax = (0.5 + 8*plot_chess_opening$prob_white[1]), y =0, linewidth = 3, color = "#D2B48C") +
    # labs(
    #     title = "Legend"
    # ) +
    annotate(geom = "point", x = 4.5,
             y = 0, color = "darkred", shape = "|", size = 4) +
    # annotate(geom = "text", x = 1, y = 0,
    #          label ="w%",
    #          color = "#8B4513",family = "DejaVu Sans",
    #          size = 2, fontface = "bold") +
    # annotate(geom = "text", x = 8, y = 0,
    #          label = "b%",
    #          color = "#D2B48C",family = "DejaVu Sans", size = 2.5, fontface = "bold") +
    annotate(geom = "text", x = 0, y = 0,
             label = "% games won\nby White", 
             color = "#8B4513",family = "DejaVu Sans", size = 2.5, fontface = "bold") +
    annotate(geom = "text", x = 3.5, y = -0.01,
             label = "% draw",
             color = "gray15",family = "DejaVu Sans", size = 2.5, fontface = "bold") +
    annotate(geom = "text", x = 9.2, y = 0,
             label = "% won by\nBlack",
             color = "#8B4513",family = "DejaVu Sans", size = 2.5, fontface = "bold") +
    geom_curve(
        data = data.frame(
            x = c(0.1, 3.5, 9),
            y = c(0, -0.01, 0),
            xend = c(1,3.6,8) , 
            yend = c(0,0,0)),
        aes(x = x, xend = xend, y = y, yend = yend),
        stat = "unique", curvature = 0.2, size = 0.2, color = "grey12",
        arrow = arrow(angle = 20, length = unit(1, "mm"))
    ) +
    ylim(c(-0.015, 0.01))+
    xlim(c(-1,9.5))
    # theme(
    #     # plot.title = element_text(family = "DejaVu Sans",
    #     #                           face = "bold",
    #     #                           size = 10, hjust = 0.5),
    #     #plot.background = element_rect(fill = "#fcf7ec", color = NA)
    # )

combined_plot <- wrap_plots(plots, nrow = 3) +
    inset_element(legend_plot, l = -0.5, r = 0.9,  t = 3.73, b = 3.48,
                  align_to = "plot",
                  clip = F) +
    plot_annotation(title = "Top 15 Chessboard Configurations After the First Four Moves",
                    subtitle = "Some openings favor White, others Black\nVan't Kruijs sees Black win 61%, while Philidor Defense #3 gives White a 64% win rate.",
                    caption = "Source: Lichess.org via Kaggle/Mitchell J.") &
    theme(
        plot.title = element_text(family = "DejaVu Sans",
                                                face = "bold"),
        plot.subtitle = element_text(family = "DejaVu Sans",
                                  face = "italic"),
        plot.caption = element_text(family = "DejaVu Sans",
                                  face = "italic"),
        plot.background = element_rect(fill = "#fcf7ec", color = NA)
    ) 




ggsave("products/tt_oct124_chessopening.png", width = 13, height = 9)
